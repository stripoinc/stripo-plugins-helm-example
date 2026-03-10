# Migration Guide

This document is designed to assist you in migrating your Stripo environment to the latest release version.

## Update as of March 06, 2026

### Key Changes

- Added support for **AWS Aurora PostgreSQL** with **IAM authentication** as an alternative to the default local PostgreSQL.
  - All plugin microservices can now connect to Aurora PostgreSQL using IAM-based authentication (no passwords required).
  - A new database initialization script `01_create_databases_iam.sh` has been added to automate the setup of databases, users, and IAM roles on Aurora.
  - The `stripo-aurora-datasource-spring-boot-starter` library handles IAM token generation and SSL configuration automatically.

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
     Database and user mapping (from `01_create_databases_iam.sh`):

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

     ConfigMap properties for each Java/Spring service:
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

