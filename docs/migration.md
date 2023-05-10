# Migration Guide
## Upgrade to the Latest 2.x Version
1. Remove env vars LOGSTASH_HOST and LOGSTASH_PORT from values files
2. Get lastest versions values file ai-service.yaml and install_all.sh from this repo
3. Deploy new microservice by running install_all.sh
4. Upgrade your infrastructure by running update.sh
