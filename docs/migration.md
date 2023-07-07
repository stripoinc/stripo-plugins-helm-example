# Migration Guide
***
This document is meant to help you migrate your Stripo environment to the latest release version.

## Upgrade to the 1.84.0 Version
1. Modify ai-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

2. Modify stripe-html-cleaner-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}
      auth.swaggerUsername=html-cleaner-service
      auth.swaggerPassword=secret'

3. Modify stripe-html-gen-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

4. Modify stripo-plugin-api-gateway.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}
      service.plugindetails.url=http://stripo-plugin-details-service:8080
      service.customblocks.url=http://stripo-plugin-custom-blocks-service:8080
      service.drafts.url=http://stripo-plugin-drafts-service:8080
      service.documents.url=http://stripo-plugin-documents-service:8080
      service.imagesbank.url=http://stripo-plugin-image-bank-service:8080
      service.htmlgen.url=http://stripe-html-gen-service:8080
      service.htmlcleaner.url=http://stripe-html-cleaner-service:8080
      service.statistics.url=http://stripo-plugin-statistics-service:8080
      service.ai.url=http://ai-service:8080
      service.timer.url=http://stripo-timer-api:8080`

5. Modify stripo-plugin-custom-blocks-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

6. Modify stripo-plugin-details-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

7. Modify stripo-plugin-documents-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

8. Modify stripo-plugin-drafts-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}
      draft.autoSave.maxRetries=3
      draft.autoSave.timeoutSeconds=5`

9. Modify stripo-plugin-image-bank-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

10. Modify stripo-plugin-proxy-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

11. Modify stripo-plugin-statistics-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

12. Modify stripo-security-service.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}
      auth.username=security-service
      auth.password=secret
      auth.passwordV2=secret`

13. Modify stripo-timer-api.yaml, add block 'base.properties' to configmap:
    `base.properties: |
      management.server.port=8081
      management.endpoints.web.exposure.include=health,prometheus,metrics
      management.endpoint.health.probes.enabled=true
      management.metrics.tags.application=${spring.application.name}`

14. Run 









New microservice **redis** was added.
1. Use redis.yaml file as an example of service configuration and create your own config
2. Run install_all.sh script to deploy the microservice


## Upgrade to the 1.83.0 Version
New microservice **redis** was added.
1. Use redis.yaml file as an example of service configuration and create your own config
2. Run install_all.sh script to deploy the microservice

## Upgrade to the 1.81.0 Version

### AI feature
New microservice **ai-service** was added to support AI assistant feature.
1. Modify configmap section of stripo-plugin-api-gateway.yaml. 
   1. Add `service.ai.url=http://ai-service:8080 property`
2. Use ai-service.yaml file as an example of service configuration and create your own config
3. Run install_all.sh script to deploy the microservice


### Speed up microservice startup time
1. Remove env vars LOGSTASH_HOST and LOGSTASH_PORT from env section in your *.yaml files

This is relevant in case you do not use logstash as a logs collector.

