### Requirements local tools
```
kubectl  (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
helm     (https://helm.sh/docs/intro/install/)
minikube (https://minikube.sigs.k8s.io/docs/start/)

NOTE! For mac users. Docker daemon should be runned
```

### Minikube video manual
[Video](https://kub.stripocdn.email/content/materials/git/minikube.mp4)

### Minikube text manual

NOTE: You can skip deployment of some microservices. Minimal working set consists of the following microservices:
```
stripo-plugin-api-gateway
stripo-plugin-details-service
stripo-plugin-statistics-service
stripo-security-service
emple-ui
```

#### Create postgres databases
``` sql
CREATE DATABASE stripo_plugin_local_custom_blocks;
CREATE DATABASE stripo_plugin_local_plugin_details;
CREATE DATABASE stripo_plugin_local_documents;
CREATE DATABASE stripo_plugin_local_drafts;
CREATE DATABASE stripo_plugin_local_bank_images;
CREATE DATABASE stripo_plugin_local_plugin_stats;
CREATE DATABASE stripo_plugin_local_securitydb;
```

#### Create s3 bucket
https://stripo.email/ru/plugin-api/#configuration-of-aws-s3-storage

#### Change DB connection and S3 bucket settings in yaml files. 
```
stripo-plugin-custom-blocks-service.yaml 
stripo-plugin-details-service
stripo-plugin-documents-service.yaml
stripo-plugin-drafts-service.yaml
tripo-plugin-image-bank-service.yaml
stripo-plugin-statistics-service.yaml
stripo-security-service.yaml
```

#### Add helm repo
```
helm repo add stripo 'https://raw.githubusercontent.com/stripoinc/stripo-plugins-charts/main/'
helm repo update
```

#### Install all services
```
mkdir -p secrets
# add file to secrets docker-hub-secret.yaml
./minikube/install_on_minikube.sh
```

NOTE. If in the console you see the message
```
Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

press Ctrl+C and run the command
```
minikube service emple-loadbalancer -n stripo --url
SERVICE_ADDRESS_LB=http://127.0.0.1:56528 //set your URL value
sed "s|{SERVICE_ADDRESS}|$SERVICE_ADDRESS_LB|g" minikube/index-minikube.tmpl > minikube/index-minikube.html
```

#### On database stripo_plugin_local_plugin_details
``` sql
INSERT INTO plugins(name, plugin_id, secret_key, created_on, website, email, status, config, subscription_type, subscription_updated_on, subscription_next_payment_on, individual_limits_id, sub_domain)
    VALUES ('demoplugin', '7a4b7b4092e011eba8b30242ac130004', 'e55c869d9e2846879c2e8eba1bf1b41b', '2024-04-01 00:00:00+00', '', '', 'ACTIVE', '{"theme":{"type":"CUSTOM","params":{"primary-color":"#32cb4b","secondary-color":"#ffffff","border-radius-base":"17px","customFontLink":"","font-size":"14px","font-family":"-apple-system, BlinkMacSystemFont, \"Segoe UI\", Oxygen-Sans, Ubuntu, Cantarell, \"Helvetica Neue\", sans-serif","option-panel-background-color":"#f6f6f6","default-font-color":"#555555","panels-border-color":"#dddddd"},"removePluginBranding":true},"imageGallery":{"type":"PLUGIN","awsRegion":"ap-south-1","tabs":[{"label":{"en":"Email"},"key":"email_${emailId}"}],"maxFileSizeInKBytes":2048,"imagesBankEnabled":false,"imagesBankLabel":{"en":"Stock"},"pexelsEnabled":false,"pixabayEnabled":false,"iconFinderEnabled":false,"imageSearchEnabled":false,"iconSearchEnabled":false,"skipChunkedTransferEncoding":true},"blocksLibrary":{"enabled":true,"tabs":[{"viewOrder":0,"label":{"en":"Email"},"key":"email_${emailId}"}],"view":"FULL_WIDTH"},"baseBlocks":{"imageEnabled":true,"textEnabled":true,"buttonEnabled":true,"spacerEnabled":true,"videoEnabled":true,"socialNetEnabled":true,"bannerEnabled":true,"menuEnabled":true,"htmlEnabled":true,"timerEnabled":false,"ampCarouselEnabled":true,"ampAccordionEnabled":true,"ampFormControlsEnabled":true},"blockControls":{"blockVisibilityEnabled":true,"mobileIndentPluginEnabled":true,"mobileInversionEnabled":true,"mobileAlignmentEnabled":true,"stripePaddingEnabled":true,"containerBackgroundEnabled":true,"structureBackgroundImageEnabled":true,"containerBackgroundImageEnabled":true,"dynamicStructuresEnabled":true,"imageSrcLinkEnabled":true,"ampVisibilityEnabled":true,"smartBlocksEnabled":true,"imageEditorPluginEnabled":true,"synchronizableModulesEnabled":false,"rolloverEffectEnabled":true},"permissionsApi":{},"mergeTagsEnabled":true,"specialLinksEnabled":false,"customFontsEnabled":true,"ownControls":true,"autoSaveApi":{"enabled":false,"username":"username","password":"password"},"undoEnabled":true,"versionHistoryEnabled":true}', 'ENTERPRISE', '2021-04-01 00:00:00+00', '2024-04-01 00:00:00+00', null, 'cope')
```

#### Open on browser for check plugins install 
``` minikube/index-minikube.html ```


#### For check status deployment use dashboard
```
minikube dashboard
```

#### Delete cluster
```
minikube delete
```
