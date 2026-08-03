# Migration Guide

This document is designed to assist you in migrating your Stripo environment to the latest release version.

## Update as of August 03, 2026

### Key Changes

- The current `coediting-core-service` release contains database schema migrations (11–19). One of them alters the large `models` table and **can take a long time** on installations with a lot of data. If the migration does not finish before the pod is restarted or killed, the service is left in a broken migration state and will not start.
- New performance tuning options for large emails: NATS large-message offload via Object Storage and server-side patch compaction frequency (see [Editor performance for large emails](#editor-performance-for-large-emails)).

### Action Required

#### Long-running schema migration in coediting-core-service

**Why this matters.** `coediting-core-service` applies schema migrations automatically at startup. Migration 11 runs `ALTER TABLE models ADD COLUMN theme_id ..., theme_version ...` plus an index — on a large `models` table this can run for a long time. If the pod is killed before the migration completes (startup/readiness timeout):

- the `ALTER` keeps running inside the database even though the pod is gone;
- `golang-migrate` leaves `schema_migrations` with `dirty = true`;
- the service will not become ready again, and **pod restarts do not heal the dirty state** — the environment stays down until you intervene manually.

**Recommended upgrade procedure (before the release):**

1. Before upgrading, run the SQL script below manually against the `coediting-core-service` database and wait for it to complete. It contains all migrations of this release (11–19) and finishes by marking them as applied in `schema_migrations`, so the automatic migration at startup becomes a no-op.
2. Upgrade the environment as usual.

> Running the script against a live installation is safe: all added columns have defaults and do not affect running pods.

> **Important:** the migration SQL does not use `IF NOT EXISTS`. Run the manual script **either completely or not at all**, and only before the automatic migration has been attempted. If you apply the schema changes manually but do not update `schema_migrations`, the service will retry migration 11 at startup, fail with a duplicate column/index error, and end up in the dirty state described below.

<details>
<summary>Manual migration script (migrations 11–19)</summary>

```sql
-- Migration 11
CREATE TABLE themes (
    id VARCHAR(36) NOT NULL PRIMARY KEY NONCLUSTERED,
    name VARCHAR(100) NOT NULL,
    val JSON NOT NULL,
    version BIGINT NOT NULL,
    updated_at TIMESTAMP(6) NOT NULL,
    INDEX idx_themes_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE theme_keys (
    theme_id VARCHAR(36) NOT NULL,
    `key` VARCHAR(255) NOT NULL,
    PRIMARY KEY (theme_id, `key`) NONCLUSTERED,
    INDEX idx_theme_keys_key (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE models
    ADD COLUMN theme_id VARCHAR(36),
    ADD COLUMN theme_version BIGINT;

ALTER TABLE models
    ADD INDEX idx_models_theme (theme_id);


-- Migration 12
ALTER TABLE themes
    ADD COLUMN preview TEXT NULL;


-- Migration 13
CREATE TABLE template_theme_quota_locks (
    key_prefix VARCHAR(255) NOT NULL PRIMARY KEY NONCLUSTERED
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Migration 14
CREATE TABLE model_patch_revisions (
    model_id VARCHAR(255) NOT NULL PRIMARY KEY,
    revision BIGINT UNSIGNED NOT NULL DEFAULT 0
);

CREATE TABLE copilot_patch_outbox (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    operation_id VARCHAR(36) NOT NULL,
    model_id VARCHAR(255) NOT NULL,
    payload LONGBLOB NOT NULL,
    patch_originated_at TIMESTAMP(6) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    available_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    lease_owner VARCHAR(255),
    lease_until TIMESTAMP(6),
    attempt_count INT NOT NULL DEFAULT 0,
    published_at TIMESTAMP(6),
    replicas_repaired_at TIMESTAMP(6),
    failed_at TIMESTAMP(6),
    failure_reason VARCHAR(1024),
    UNIQUE INDEX uq_copilot_patch_outbox_operation (operation_id),
    INDEX idx_copilot_patch_outbox_available (
        available_at,
        lease_until,
        created_at
    )
);

CREATE TABLE copilot_patch_replica_receipts (
    operation_id VARCHAR(36) NOT NULL PRIMARY KEY,
    model_id VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    completed_at TIMESTAMP(6),
    INDEX idx_copilot_patch_replica_receipts_model (model_id),
    INDEX idx_copilot_patch_replica_receipts_completed (completed_at)
);


-- Migration 15
CREATE INDEX idx_copilot_patch_outbox_model
    ON copilot_patch_outbox (model_id);


-- Migration 16
CREATE TABLE copilot_patch_replica_receipts_v2 (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    operation_id VARCHAR(36) NOT NULL,
    model_id VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    completed_at TIMESTAMP(6),
    UNIQUE INDEX uq_copilot_patch_replica_receipts_operation (operation_id),
    INDEX idx_copilot_patch_replica_receipts_model (model_id),
    INDEX idx_copilot_patch_replica_receipts_completed (completed_at)
);

INSERT INTO copilot_patch_replica_receipts_v2 (
    operation_id,
    model_id,
    applied_at,
    completed_at
)
SELECT
    operation_id,
    model_id,
    applied_at,
    completed_at
FROM copilot_patch_replica_receipts;

RENAME TABLE
    copilot_patch_replica_receipts
        TO copilot_patch_replica_receipts_common_handle,
    copilot_patch_replica_receipts_v2
        TO copilot_patch_replica_receipts;

DROP TABLE copilot_patch_replica_receipts_common_handle;


-- Migration 17
CREATE TABLE copilot_patch_commit_ledger (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    operation_id VARCHAR(36) NOT NULL,
    model_id VARCHAR(255) NOT NULL,
    expected_revision BIGINT UNSIGNED NOT NULL,
    payload_sha256 BINARY(32) NOT NULL,
    committed_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE INDEX uq_copilot_patch_commit_ledger_operation (operation_id),
    INDEX idx_copilot_patch_commit_ledger_model (model_id)
);


-- Migration 18
CREATE INDEX idx_copilot_patch_outbox_lease_owner
    ON copilot_patch_outbox (lease_owner);


-- Migration 19
ALTER TABLE patches
    ADD COLUMN name VARCHAR(60) NULL;

CREATE TABLE patch_tags (
    model_id VARCHAR(255) NOT NULL,
    patch_id VARCHAR(36) NOT NULL,
    position INT UNSIGNED NOT NULL,
    tag VARCHAR(60) NOT NULL,
    PRIMARY KEY (model_id, patch_id, position) NONCLUSTERED,
    INDEX idx_patch_tags_model_tag (model_id, tag, patch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Mark whole bundle as successfully applied
UPDATE schema_migrations
SET version = 19,
    dirty = FALSE;
```

</details>

**Recovery: the automatic migration already failed.**

1. **Wait for the running migration to finish inside the database.** Even if the pod was killed by a timeout, the started `ALTER TABLE` keeps running in the database. Do not restart the migration on top of it.
2. Check the service logs to find which migration failed and confirm its statements actually completed. (So far each migration file has no critical mid-file failure points — the index creation goes last — but verify against the logs for your case.)
3. In the `schema_migrations` table set `dirty` to `false` and **do not change** `version`. The library writes the version of the migration it is about to run *before* executing it, so after a failure `version` already points at the failed migration (e.g. `version = 11, dirty = TRUE`); clearing the flag marks it as applied, and the next run continues from the following one:

   ```sql
   UPDATE schema_migrations SET dirty = FALSE;
   ```

   > Only do this after confirming in step 2 that the failed migration's statements actually completed. If they did not, finish them manually first (using the corresponding part of the script above) — clearing `dirty` alone would mark a half-applied migration as applied.
4. Re-run the environment upgrade. The remaining migrations will be applied automatically.

#### Editor performance for large emails

Large emails with many accumulated (non-compacted) patches open slowly and, in the worst case, hit the NATS message size limit: `merge-service` successfully merges the patches, but its reply is too large to deliver, `coediting-core-service` waits for a 10-minute timeout, and the email keeps opening slowly with patches accumulating further. Three settings work together to prevent this:

1. **NATS `max_payload` = 32 MiB** — already covered in the deployment manual, see [Prerequisites → NATS](https://github.com/stripoinc/stripo-plugins-helm-example/blob/main/README.md#prerequisites). Remember to restart or reconnect `merge-service` and `coediting-core-service` after changing it: NATS clients cache the limit from the connection handshake.
2. **`settings.nats.maxPayloadSizeToIncludeInMsg: "31457280"`** (30 MiB) — enables offloading of oversized NATS messages through Object Storage instead of sending them inline. Set it on **both** `merge-service` **and** `coediting-core-service` (`charts/merge-service.yaml` and `charts/coediting-core-service.yaml`) with the **same value** (a mismatch between the two services will cause message-processing failures). The value must be slightly lower than the NATS `max_payload` (the 32 MiB / 30 MiB pair above). Rendered as the `NATS_MAX_PAYLOAD_SIZE_TO_INCLUDE_IN_MSG` environment variable; requires chart version 1.3.1+.
3. **`settings.numberOfPatchesToStartCompaction`** — a `coediting-core-service` setting (`charts/coediting-core-service.yaml`) that controls how many accumulated patches trigger server-side model compaction. The service default is `100`, which lets emails accumulate hundreds of non-compacted patches and makes them open for tens of seconds. Recommended value: **20** — a lower value means more frequent compaction and faster email opening. Rendered as the `NUMBER_OF_PATCHES_TO_START_COMPACTION` environment variable; requires chart version 1.3.1+.

**If problematic emails already exist** (patches accumulated while the NATS limit was being hit): temporarily increase `merge-service` memory resources, open each affected email to trigger compaction (opening an email is also a compaction trigger; re-check after ~15 minutes), then scale the resources back down.

## Update as of July 31, 2026

### Key Changes

- Added support for **AWS Aurora MySQL** as an alternative to TiDB for `coediting-core-service` (Stripo Editor V2 only).
  - The backend is selected with a single `settings.dbType` value in `charts/coediting-core-service.yaml` (`TiDB` or `AuroraMySQL`).
  - The Helm chart now mounts the Amazon RDS CA bundle automatically when Aurora is selected, so no manual Deployment patching is needed for TLS.

### Action Required

- **Nothing to do if you stay on TiDB.** Existing installations keep working unchanged. If `settings.dbType` is absent, the rendered Deployment is identical to previous chart versions. If you set it to `TiDB` explicitly, the same `TIDB_*` connection variables are rendered plus the service level `DB_READ_TARGET` and `DB_WRITE_TARGETS`, which does not change how the service behaves.
- If you want to move `coediting-core-service` to Aurora MySQL, follow [Use AWS Aurora MySQL instead of TiDB](https://github.com/stripoinc/stripo-plugins-helm-example/blob/main/README.md#use-aws-aurora-mysql-instead-of-tidb-optional) in the deployment manual. In short:
  1. Create an Aurora MySQL 8.0+ cluster with `utf8mb4` / `utf8mb4_unicode_ci` and `max_allowed_packet = 268435456`.
  2. Create the database and a user with schema-level privileges.
  3. Create the RDS CA ConfigMap in your namespace:
    ```shell
    curl -o global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
    kubectl create configmap coediting-core-service-rds-ca -n <namespace> --from-file=global-bundle.pem
    ```
  4. Set `settings.dbType` to `AuroraMySQL` and fill in the `settings.auroraMysql` block, including `tls.caBundleConfigMap`.
  5. Upgrade the service and verify that the pod has `DB_READ_TARGET=AuroraMySQL` and no `TIDB_*` variables.

  > **Important:** switching the target does not copy existing data. Templates already stored in TiDB will not be available in Aurora. Contact the Stripo team to plan the data migration before switching a live installation.

## Update as of March 06, 2026

### Key Changes

- Added support for **AWS Aurora PostgreSQL** with **IAM authentication** as an alternative to the default local PostgreSQL.
  - All plugin microservices can now connect to Aurora PostgreSQL using IAM-based authentication (no passwords required).
  - A new database initialization script `01_create_databases_iam.sh` has been added to automate the setup of databases, users, and IAM roles on Aurora.

### [Action Required](http://stripoemail.com/)

- If you want to use Aurora PostgreSQL with IAM authentication:
**Affected services** (require ConfigMap + Deployment changes):
  - `ai-service`
  - `countdowntimer`
  - `stripe-html-gen-service`
  - `stripo-plugin-custom-blocks-service`
  - `stripo-plugin-details-service`
  - `stripo-plugin-documents-service`
  - `stripo-plugin-drafts-service`
  - `stripo-plugin-image-bank-service`
  - `stripo-plugin-statistics-service`
  - `stripo-security-service`
  - `stripo-timer-api`
  1. Create an Aurora PostgreSQL cluster with **IAM authentication enabled**.
  2. Create an IAM user and attach a policy with `rds-db:connect` permission for each database user.
    Save the following JSON to `policy.json`, replacing `<region>`, `<account-id>`, and `<cluster-resource-id>` with your values:
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": "rds-db:connect",
        "Resource": [
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_ai_service",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_bank_images",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_countdowntimer",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_custom_blocks",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_documents",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_drafts",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_html_gen",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_plugin_details",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_plugin_stats",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_securitydb",
          "arn:aws:rds-db:<region>:<account-id>:dbuser:<cluster-resource-id>/user_timers"
        ]
      }]
    }
    ```
    Then run:
    > **Save the `create-access-key` output** — `AccessKeyId` and `SecretAccessKey` are shown only once and are needed in step 4.
  3. Run `resources/postgres/01_create_databases_iam.sh` to create databases and IAM-enabled users.
    Prerequisites: machine with network access to Aurora and `psql` installed.
     Required environment variables:
    - `PGHOST` — Aurora cluster writer endpoint
    - `PGPASSWORD` — Aurora master password
    - `CLUSTER_RESOURCE_ID` — from step 2
    - `AWS_ACCOUNT` — AWS account ID
    - `AWS_REGION` — AWS region (optional, defaults to `eu-west-1`)
     Example:
  4. Create a Kubernetes secret with AWS credentials for IAM token generation:
    ```shell
     kubectl create secret generic aurora-db-credentials -n <namespace> \
       --from-literal=access-key-id=<AWS_ACCESS_KEY_ID> \
       --from-literal=secret-access-key=<AWS_SECRET_ACCESS_KEY>
    ```
  5. Download the Amazon RDS CA bundle and create a ConfigMap (required for SSL certificate verification by `countdowntimer`):
    ```shell
     curl -o global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
     kubectl create configmap rds-ca-bundle -n <namespace> --from-file=global-bundle.pem
    ```
    > This is the official AWS RDS root CA certificate bundle. It is used by `countdowntimer` to verify the Aurora server certificate when `DB_SSL_MODE: verify-full`.
  6. Update each service ConfigMap to point to Aurora with IAM settings.
    > **Note:** Skip `countdowntimer` here — it uses a different config format (see step 8).
    >  Database and user mapping (from `01_create_databases_iam.sh`):

    | Service                             | Database                           | Username            |
    | ----------------------------------- | ---------------------------------- | ------------------- |
    | ai-service                          | ai_service                         | user_ai_service     |
    | stripe-html-gen-service             | stripo_plugin_local_html_gen       | user_html_gen       |
    | stripo-plugin-custom-blocks-service | stripo_plugin_local_custom_blocks  | user_custom_blocks  |
    | stripo-plugin-details-service       | stripo_plugin_local_plugin_details | user_plugin_details |
    | stripo-plugin-documents-service     | stripo_plugin_local_documents      | user_documents      |
    | stripo-plugin-drafts-service        | stripo_plugin_local_drafts         | user_drafts         |
    | stripo-plugin-image-bank-service    | stripo_plugin_local_bank_images    | user_bank_images    |
    | stripo-plugin-statistics-service    | stripo_plugin_local_plugin_stats   | user_plugin_stats   |
    | stripo-security-service             | stripo_plugin_local_securitydb     | user_securitydb     |
    | stripo-timer-api                    | stripo_plugin_local_timers         | user_timers         |

    ConfigMap properties (add or replace in `application.properties`):
    ```properties
    spring.datasource.url=jdbc:postgresql://<aurora-endpoint>:5432/<database>?sslmode=require
    spring.datasource.username=<user>
    spring.datasource.password=
    stripo.aurora.enabled=true
    stripo.aurora.region=<aws-region>
    ```
    Use the table above for `<database>` and `<user>` values (e.g. for `stripe-html-gen-service`: database `stripo_plugin_local_html_gen`, user `user_html_gen`).
    > **Important:** Each property must be on its **own line**. Do not combine multiple properties on one line.
    > `spring.datasource.password` must be **empty** — the IAM token is generated at runtime.
    > If your ConfigMap contains both `application.properties` and `base.properties`, **both files must be synchronized** — `application.properties` overrides `base.properties`.
  7. Add AWS environment variables to each service Deployment (excluding `countdowntimer`):
    ```yaml
     env:
       - name: AWS_ACCESS_KEY_ID
         valueFrom:
           secretKeyRef:
             name: aurora-db-credentials
             key: access-key-id
       - name: AWS_SECRET_ACCESS_KEY
         valueFrom:
           secretKeyRef:
             name: aurora-db-credentials
             key: secret-access-key
       - name: AWS_REGION
         value: "<aws-region>"
    ```
  8. Configure `countdowntimer` — see [countdowntimer Aurora setup](#countdowntimer-aurora-setup) below.
  9. Restart all affected services and verify:
    - **Java/Spring services** — logs should contain:
    - **countdowntimer** — pod starts without errors; no `ConnectionRefusedError` or `KeyError` in logs.

### Countdowntimer Aurora Setup

The `countdowntimer` microservice requires extra steps for Aurora IAM authentication:

1. Update `config.yaml` in the ConfigMap:
  ```yaml
   DB_HOST: <aurora-endpoint>
   DB_PORT: 5432
   DB_NAME: countdowntimer
   DB_USER: user_countdowntimer
   DB_PASSWORD: unused_iam_override
   DB_USE_IAM: true
   DB_SSL_MODE: verify-full
   DB_SSL_CA_PATH: /usr/local/countdowntimer/certs/global-bundle.pem
   HOST: <your-external-hostname>
  ```
  > **Note:** `DB_PASSWORD` must be set to any non-empty value due to a known code limitation.
  > `HOST` must be set to your **external** hostname used to access the plugin (e.g., `plugins.example.com`). This is used for generating GIF image URLs.
2. Add environment variables and mount the CA bundle in the Deployment:
  ```yaml
   env:
     - name: AURORA_ENABLED
       value: "true"
     - name: AWS_REGION
       value: "<aws-region>"
     - name: AWS_ACCESS_KEY_ID
       valueFrom:
         secretKeyRef:
           name: aurora-db-credentials
           key: access-key-id
     - name: AWS_SECRET_ACCESS_KEY
       valueFrom:
         secretKeyRef:
           name: aurora-db-credentials
           key: secret-access-key

   volumeMounts:
     - name: rds-ca-bundle
       mountPath: /usr/local/countdowntimer/certs/global-bundle.pem
       subPath: global-bundle.pem

   volumes:
     - name: rds-ca-bundle
       configMap:
         name: rds-ca-bundle
  ```

## Update as of February 19, 2026

### Key Changes

- Hardened `emple-ui` security:
  - Container now runs as a non-root user (`app` user instead of `root`).
  - Changed the container port from 80 to 8080.

### Action Required

- **Update Helm repository**:

```shell
helm repo update stripo
```

- If you maintain a custom configuration for `emple-ui`, please update it as follows:
  - The container now listens on port 8080 instead of 80. Ensure the `containerPort` in your deployment is set to 8080.
  - Optionally, enforce non-root execution at the Kubernetes level by adding `securityContext.runAsNonRoot: true` to your deployment configuration.

## Update as of September 26, 2025

### Key Changes

- Hardened `countdowntimer` security. Added support to run the microservice as a non‑root user via `securityContext.runAsUser: 1000`.

### Action Required

- **Update Helm repository**:

```shell
helm repo update stripo
```

- If you maintain a custom configuration for `countdowntimer`, please update it as follows:
  - Change the `ClusterIP` service port from 80 to 8080.
  - In the `stripo-timer-api` ConfigMap, update the `timer.url` property to `http://countdowntimer:8080/api/` to match the new port.

## Update as of October 25, 2024

### Helm Charts

- **Logstash Configuration:**
  - Relocated the Logstash section from the `ENV` section to the `settings` section, providing a more organized configuration structure.
- **Kubernetes Resources:**
  - Updated the default resource requests and limits for Kubernetes to optimize performance and ensure efficient resource utilization.

## Update as of October 09, 2024

We are excited to announce significant improvements and a comprehensive refactoring of all Helm charts and related documentation.

### Key Changes

- Comprehensive refactoring of all Helm charts.
- Updated and enhanced documentation.

### Action Required

1. **Review Documentation**: Please read the updated `README.md` to understand the changes.
2. **Sync Your Deployment**: Align your deployment with the provided Helm examples.
3. **Update Helm Repository**: Execute the following command to update your Helm repository:
  ```shell
    helm repo update stripo
  ```

## Upgrade to Version 1.125.0

New settings have been added to limit the length of the `html` and `css` fields in requests to the `stripe-html-cleaner-service` via the `/compress` method:

- `email.validation.css-max-size` = 5000000
- `email.validation.html-max-size` = 9000000

## Upgrade to Version 1.104.0

The following settings have been added to restrict requests to only allowed domains in the `stripe-html-cleaner-service` via the `/compress` method:

- `app.cors.allowedOrigins` = *

## Upgrade to Version 1.97.0

Docker images have been moved to the **stripo** organization on Docker Hub.

### Action Required

1. Run `update_all.sh` to update the Helm repository.

## Upgrade to Version 1.95.0

### Action Required

1. Verify the `jwt.secret.apiKeyV3` property of the `stripo-plugin-api-gateway`. Ensure the value is at least 64 symbols.

## Upgrade to Version 1.84.0

Support for different metrics has been added on port 8081:

- Liveness probe: [http://localhost:8081/actuator/health/liveness](http://localhost:8081/actuator/health/liveness)
- Readiness probes: [http://localhost:8081/actuator/health/readiness](http://localhost:8081/actuator/health/readiness)
- Prometheus metrics: [http://localhost:8081/actuator/prometheus](http://localhost:8081/actuator/prometheus)

### Action Required

1. Run `update_all.sh` to update the Helm repository.

## Upgrade to Version 1.83.0

### Redis Service

A new microservice, **redis**, has been added to support the Rate Limits feature.

### Action Required

1. Use `redis.yaml` as an example of the service configuration and create your own configuration.
2. Run the `install_all.sh` script to deploy the microservice.

### Rate Limit Feature

Settings have been added to limit the number of requests from a single IP in the `plugin-api-gateway` settings:

- `rate.limit.publicRules` = [{"limit":10000,"durationSecond":60},{"limit":100000,"durationSecond":3600}] - rules for limiting the number of requests within specified periods. Example: 10,000 requests per minute and 100,000 requests per hour.
- `rate.limit.enabled` = true - a flag indicating whether the limitations should be applied.
- `redisson.url` = redis://redis:6379 - the path to Redis if `rate.limit.enabled=true`.
- `redisson.password` = test - the password for the Redis database.
- `redisson.authorized` = true - indicates whether authorization to Redis is required.

### Action Required

Update your config map section in `stripo-plugin-api-gateway.yaml` to enable this feature.

## Upgrade to Version 1.81.0

### AI Feature

A new microservice, **ai-service**, has been added to support the AI assistant feature.

### Action Required

1. Modify the `configmap` section of `stripo-plugin-api-gateway.yaml`.
2. Add the property: `service.ai.url=http://ai-service:8080`.
3. Use `ai-service.yaml` as an example of the service configuration and create your own configuration.
4. Run `install_all.sh` script to deploy the microservice.

To enable AI feature, modify the `stripo_plugin_local_plugin_details` database, `plugins` table, `config` cell. This cell contains JSON with the plugin configuration; you need to add:

```json
{
  ...,
  "ai": {
    "openAiApiKey": "YOUR_OPEN_AI_API_KEY",
    "textBlockAiEnabled": true,
    "smartModuleAiEnabled": true
  }
}
```

### Speed Up Microservice Startup Time

### Action Required

1. Remove the environment variables `LOGSTASH_HOST` and `LOGSTASH_PORT` from the env section in your `.yaml` files.
  This is relevant if you do not use Logstash as a logs collector.

