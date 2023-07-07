# Migration Guide
***
This document is meant to help you migrate your Stripo environment to the latest release version.

## Upgrade to the 1.84.0 Version
1. Download update_all.sh from this repo
2. Run bash update_all.sh for update charts

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

