# Migration Guide
***
This document is meant to help you migrate your Stripo environment to the latest release version.


## Upgrade to the 1.81.0 Version

### AI feature
New microservice **ai-service** was added to support AI assistant feature.
1. Modify configmap section of stripo-plugin-api-gateway.yaml. 
   1. Add `service.ai.url=http://ai-service:8080 property`
1. Use ai-service.yaml file as an example of service configuration and create your own config
1. Run install_all.sh script to deploy the microservice


### Speed up microservice startup time
1. Remove env vars LOGSTASH_HOST and LOGSTASH_PORT from env section in your *.yaml files

This is relevant in case you do not use logstash as a logs collector.

