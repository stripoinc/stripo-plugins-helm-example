# Migration Guide
***
This document is meant to help you migrate your Stripo environment to the latest release version.

## Upgrade to the 1.83.0 Version

### Redis service
New microservice **redis** was added to support Rate Limits feature.
1. Use redis.yaml file as an example of service configuration and create your own config
2. Run install_all.sh script to deploy the microservice

### Rate limit feature
The following settings have been added to limit the number of requests from a single IP to the plugin-api-gateway settings:

* **rate.limit.publicRules**=[{"limit":10000,"durationSecond":60},{"limit":100000,"durationSecond":3600}] - rules for limiting the number of requests within specified periods. Example: 10,000 requests per minute and 100,000 requests per hour.
* **rate.limit.enabled=true** - a flag indicating whether the limitations should be applied.
* **redisson.url=redis://redis:6379** - the path to Redis if rate.limit.enabled=true.
* **redisson.password=test** - the password for the Redis database.
* **redisson.authorized=true** - indicates whether authorization to Redis is required.


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

