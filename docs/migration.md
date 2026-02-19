# Migration Guide

This document is designed to assist you in migrating your Stripo environment to the latest release version.

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

