### Requirements local tools
```
kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
helm  (https://helm.sh/docs/intro/install/)
```

### Create database on postgresql
``` sql
CREATE DATABASE stripo_plugin_local_custom_blocks;
CREATE DATABASE stripo_plugin_local_plugin_details;
CREATE DATABASE stripo_plugin_local_documents;
CREATE DATABASE stripo_plugin_local_drafts;
CREATE DATABASE stripo_plugin_local_bank_images;
CREATE DATABASE stripo_plugin_local_plugin_stats;
CREATE DATABASE stripo_plugin_local_securitydb;
```

### Create s3 bucket
https://support.stripo.email/en/articles/3726140-configuration-of-aws-s3-storage

### Change application.properties postgres connections in yaml file. 
File need to change:

```stripo-plugin-custom-blocks-service.yaml``` 

```stripo-plugin-details-service```

```stripo-plugin-documents-service.yaml```

```stripo-plugin-drafts-service.yaml```

```stripo-plugin-image-bank-service.yaml```

``` stripo-plugin-statistics-service.yaml ```

``` stripo-security-service.yaml ```

Example stripo-security-service.yaml:
``` yml
configmap:
  enabled: true
  extraScrapeConfigs:
    application.properties: |
      management.endpoint.health.enabled=true
      management.endpoints.web.exposure.include=metrics
      spring.datasource.url=jdbc:postgresql://YOU_POSTGRES_ADDRESS:5432/stripo_plugin_local_securitydb
      spring.datasource.username=YOU_POSTGRES_USERNAME
      spring.datasource.password=YOU_POSTGRES_PASSWORD
      auth.username=security-service
      auth.password=secret
      server.port=8080
      #=================== Updated passwords ======================
      auth.passwordV2=secret
```
### Change aws credentials stripo-plugin-documents-service.yaml
``` yml
      storage.internal.aws.accessKey=
      storage.internal.aws.secretKey=
      storage.internal.aws.bucketName=
      storage.internal.aws.region=
```

### How to add private repo
```
helm repo add --username GitHubUser --password githubToken stripo 'https://raw.githubusercontent.com/stripoinc/stripo-plugins-charts/main/'
```

### Update repo
```
helm repo update
```

## Install all plugins
```
mkdir -p secrets
# add file to secrets docker-hub-secret.yaml
./install_all.sh
```

#### On database stripo_plugin_local_plugin_details
``` sql
INSERT INTO plugins(name, plugin_id, secret_key, created_on, website, email, status, config, subscription_type, subscription_updated_on, subscription_next_payment_on, individual_limits_id, sub_domain)
    VALUES ('demoplugin', '7a4b7b4092e011eba8b30242ac130004', 'e55c869d9e2846879c2e8eba1bf1b41b', '2024-04-01 00:00:00+00', '', '', 'ACTIVE', '{"theme":{"type":"CUSTOM","params":{"primary-color":"#32cb4b","secondary-color":"#ffffff","border-radius-base":"17px","customFontLink":"","font-size":"14px","font-family":"-apple-system, BlinkMacSystemFont, \"Segoe UI\", Oxygen-Sans, Ubuntu, Cantarell, \"Helvetica Neue\", sans-serif","option-panel-background-color":"#f6f6f6","default-font-color":"#555555","panels-border-color":"#dddddd"},"removePluginBranding":true},"imageGallery":{"type":"PLUGIN","awsRegion":"ap-south-1","tabs":[{"label":{"en":"Email"},"key":"email_${emailId}"}],"maxFileSizeInKBytes":2048,"imagesBankEnabled":false,"imagesBankLabel":{"en":"Stock"},"pexelsEnabled":false,"pixabayEnabled":false,"iconFinderEnabled":false,"imageSearchEnabled":false,"iconSearchEnabled":false,"skipChunkedTransferEncoding":true},"blocksLibrary":{"enabled":true,"tabs":[{"viewOrder":0,"label":{"en":"Email"},"key":"email_${emailId}"}],"view":"FULL_WIDTH"},"baseBlocks":{"imageEnabled":true,"textEnabled":true,"buttonEnabled":true,"spacerEnabled":true,"videoEnabled":true,"socialNetEnabled":true,"bannerEnabled":true,"menuEnabled":true,"htmlEnabled":true,"timerEnabled":false,"ampCarouselEnabled":true,"ampAccordionEnabled":true,"ampFormControlsEnabled":true},"blockControls":{"blockVisibilityEnabled":true,"mobileIndentPluginEnabled":true,"mobileInversionEnabled":true,"mobileAlignmentEnabled":true,"stripePaddingEnabled":true,"containerBackgroundEnabled":true,"structureBackgroundImageEnabled":true,"containerBackgroundImageEnabled":true,"dynamicStructuresEnabled":true,"imageSrcLinkEnabled":true,"ampVisibilityEnabled":true,"smartBlocksEnabled":true,"imageEditorPluginEnabled":true,"synchronizableModulesEnabled":false,"rolloverEffectEnabled":true},"permissionsApi":{},"mergeTagsEnabled":true,"specialLinksEnabled":false,"customFontsEnabled":true,"ownControls":true,"autoSaveApi":{"enabled":false,"username":"username","password":"password"},"undoEnabled":true,"versionHistoryEnabled":true}', 'ENTERPRISE', '2021-04-01 00:00:00+00', '2024-04-01 00:00:00+00', null, 'cope')
```

### Change nginx config replase ``` plugins.conf ```
``` conf
{{ public_domain }}
{{ emple-loadbalancer-ingress }}
{{ S3_BUCKET_URI }}
```

## Manual install
### Create namespace if not exist
```
kubectl create namespace stripo
```

### Add secret for dockerhub pull images
```
kubectl apply -f secrets/docker-hub-secret.yaml -n stripo
```

1
### Install stripo-security-service
```
helm install stripo-security-service stripo/stripo-security-service -f stripo-security-service.yaml --namespace stripo
```

2
### Install  stripo-plugin-proxy-service
```
helm install stripo-plugin-proxy-service stripo/stripo-plugin-proxy-service -f stripo-plugin-proxy-service.yaml --namespace stripo
```

3
### Install  stripo-plugin-statistics-service
```
helm install stripo-plugin-statistics-service stripo/stripo-plugin-statistics-service -f stripo-plugin-statistics-service.yaml --namespace stripo
```

4
### Install stripo-plugin-details-service
```
helm install stripo-plugin-details-service stripo/stripo-plugin-details-service -f stripo-plugin-details-service.yaml --namespace stripo
```

5
### Install screenshot-service
```
helm install screenshot-service stripo/screenshot-service -f screenshot-service.yaml --namespace stripo
```

6
### Install stripo-plugin-documents-service
```
helm install stripo-plugin-documents-service stripo/stripo-plugin-documents-service -f stripo-plugin-documents-service.yaml --namespace stripo
```

7
### Install stripo-plugin-image-bank-service
```
helm install stripo-plugin-image-bank-service stripo/stripo-plugin-image-bank-service -f stripo-plugin-image-bank-service.yaml --namespace stripo
```

8
### Install stripo-plugin-custom-blocks-service
```
helm install stripo-plugin-custom-blocks-service stripo/stripo-plugin-custom-blocks-service -f stripo-plugin-custom-blocks-service.yaml --namespace stripo
```

9
### Install stripe-html-gen-service
```
helm install stripe-html-gen-service stripo/stripe-html-gen-service -f stripe-html-gen-service.yaml --namespace stripo
```

10
### Install patches-service
```
helm install patches-service stripo/patches-service -f patches-service.yaml --namespace stripo
```

11
### Install amp-validator-service
```
helm install amp-validator-service stripo/amp-validator-service -f amp-validator-service.yaml --namespace stripo
```

12
### Install stripe-html-cleaner-service
```
helm install stripe-html-cleaner-service stripo/stripe-html-cleaner-service -f stripe-html-cleaner-service.yaml --namespace stripo
```

13
### Install stripo-plugin-api-gateway
```
helm install stripo-plugin-api-gateway stripo/stripo-plugin-api-gateway -f stripo-plugin-api-gateway.yaml --namespace stripo
```

14
### Install stripo-plugin-drafts-service
```
helm install stripo-plugin-drafts-service stripo/stripo-plugin-drafts-service -f stripo-plugin-drafts-service.yaml --namespace stripo
```

15
### Install emple-ui
```
helm install emple-ui stripo/emple-ui -f emple-ui.yaml --namespace stripo
```

16
### Install emple-loadbalancer
```
helm install emple-loadbalancer stripo/emple-loadbalancer -f emple-loadbalancer.yaml --namespace stripo
```