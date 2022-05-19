<img src="https://my.stripo.email/cabinet/nav-brand.8b487c2de1ab15c17b62.svg" alt="Stripo Logo" style="width: 50%"/>
<br/>

# Stripo plugin deployment manual

## Infrastructure Overview
On the high level Stripo plugin infrastructure looks like:

<img src="docs/general_overview.png" alt="High level infrastructure scheme" style="width: 80%"/>

Plugin infrastructure consists of 17 microservices that are wrapped into the docker
containers/images. These images are hosted in the Stripo Docker Hub Repository to
which partners can get the read-only access (just to be able to download the images with
needed particular versions) once they’re on Enterprise pricing plan and intend to host Plugin
Backend on their server.
Some microservices have their own Databases (PostgreSQL) that may be deployed
in any place. The connection between services and their DB are specified via properties.
Infrastructure also provides you with the ability to send logs from every microservice to ELK
stack. ELK stack can be also deployed in any place. The url to ELK can be specified via properties.

The list of actual microservices and their responsibilities are described in the table below:

| Service name | Responsibility | Is public for web |
| ----------- | ----------- | ----------- | 
| stripo-plugin-api-gateway | Used for user’s authentication, authorization and requests routing  | true |
| emple-ui | Used to serve Stripo editor static files: js, css, fonts, icons | true |
| stripo-plugin-proxy-service | Used to proxy Stripo editor JS requests to different domains to avoid CORS error | true |
| countdowntimer | Used to create timer gif | true |
| stripo-plugin-details-service | Used for CRUD operations with plugin configuration | false |
| stripo-plugin-statistics-service | Used to store user sessions statistic | false |
| stripo-plugin-drafts-service | Used to store patches (email changes) on autosave| false |
| patches-service | Used to recreate complete email from autosave patches| false |
| stripo-plugin-documents-service | Used to handle documents (images) read/upload| false |
| stripo-plugin-custom-blocks-service | Used for CRUD operations with modules | false |
| stripo-timer-api | Used for interaction with timer and store timer usage statistic | false |
| screenshot-service | Used to generate images by HTML for modules preview | false |
| stripo-plugin-image-bank-service | Used to interact with external services like pixabay, pexels, iconFinder | false |
| stripe-html-gen-service | Used to parse external sites and extract information for smart-modules | false |
| stripo-security-service | Used to check external URLs for security (protocol, internal AWS IPs) | false |
| stripe-html-cleaner-service | Used to compile HTML and CSS from Stripo editor to clean compressed HTML ready to be sent to customers | false |
| amp-validator-service | Used to check is AMP HTML code valid | false |

## Communication between microservices
<img src="docs/microservices_overview.png" alt="Microservices communication scheme" style="width: 80%"/>

## Environment configuration

### Required local tools
```
kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
helm  (https://helm.sh/docs/intro/install/)
```

### Video manual to create Stripo environment with Amazon EKS

| # | Description | Link | Resources |
| ----------- | ----------- | ----------- | ----------- | 
| 1 | Create Amazon EKS cluster | [Video](https://drive.google.com/file/d/1zDo-TOQVKDr3v2II3N_3eiULL9iG390P/view?usp=sharing) | ./resources/cluster.yaml |
| 2 | Install Nginx ingress controller | [Video](https://drive.google.com/file/d/1COfkeV70c1gl9SeCs5JeDvKgpW1LI8AM/view?usp=sharing) | <https://kubernetes.github.io/ingress-nginx/deploy/#aws> |
| 3 | Create DNS record in Route 53 | [Video](https://drive.google.com/file/d/1o_ozrML9zHxCvt5DyxRxLRMMgJ_qVraB/view?usp=sharing) | |
| 4 | Create PostgreSQL databases | --- | ./resources/postgres/01_create_databases.sql |
| 5 | Create S3 bucket | [Video](https://drive.google.com/file/d/1cneCKGVKpeOoaJ_hSXD_TeV2aCyXyin7/view?usp=sharing) | <https://stripo.email/ru/plugin-api/#configuration-of-aws-s3-storage> |
| 6 | Enrich yaml properties with actual DB and AWS S3 settings | --- | |
| 7 | Add helm repository | --- | ./resources/helm_repo.sh |
| 8 | Add ingress configuration | -?- | |
| 9 | Run kubernetes cluster | [Video](https://drive.google.com/file/d/1Jkk7Jpg3jx0huUtSC-XTeiQaI1PcsNgU/view?usp=sharing) | ./install_all.sh |
| 10 | Apply database scripts | --- | ./resources/postgres/02_register_plugin.sql |
| 11 | Configure Nginx | --- | ./resources/nginx/plugins.conf |
| 12 | Configure countdown timer | --- |  |
| 13 | Test your configuration | [Video](https://drive.google.com/file/d/1LYncj3u15BTSWacXKUxH_oVNJ9Dy3qlY/view?usp=sharing) |

### Personal secret key
Personal secret key is used to download docker images from Stripo docker hub.
Put secret key (docker-hub-secret.yaml) to ```./secrets``` folder

### Logging
#### ELK stack
Stripo logs can be collected with ELK stack. To configure logging do the following steps: 
1. Deploy ELK stack
2. Set env variables LOGSTASH_HOST and LOGSTASH_PORT in yaml files.
   Files to change:
- ```amp-validator-service.yaml```
- ```patches-service.yaml```
- ```screenshot-service.yaml```
- ```stripe-html-cleaner-service.yaml```
- ```stripe-html-gen-service.yaml```
- ```stripo-plugin-api-gateway.yaml```
- ```stripo-plugin-custom-blocks-service.yaml```
- ```stripo-plugin-details-service```
- ```stripo-plugin-documents-service.yaml```
- ```stripo-plugin-drafts-service.yaml```
- ```stripo-plugin-image-bank-service.yaml```
- ```stripo-plugin-proxy-service.yaml```
- ```stripo-plugin-statistics-service.yaml ```
- ```stripo-security-service.yaml ```
- ```stripo-timer-api.yaml ```

#### Log level
Default log level is INFO.
You can change the log level for each microservice in yaml file settings:
```
log.properties: |
  logging.level.root=DEBUG
```

### Docker images tags
Stripo continuously releases new features and bug fixes.
You will be regularly notified with the list of release image tags and release notes.
To apply new docker images you need to replace
```
tag: "latest"
```
with the actual tag version in yaml files.

Files to change:
- ```amp-validator-service.yaml```
- ```countdowntimer.yaml```
- ```emple-ui.yaml```
- ```patches-service.yaml```
- ```screenshot-service.yaml```
- ```stripe-html-cleaner-service.yaml```
- ```stripe-html-gen-service.yaml```
- ```stripo-plugin-api-gateway.yaml```
- ```stripo-plugin-custom-blocks-service.yaml```
- ```stripo-plugin-details-service```
- ```stripo-plugin-documents-service.yaml```
- ```stripo-plugin-drafts-service.yaml```
- ```stripo-plugin-image-bank-service.yaml```
- ```stripo-plugin-proxy-service.yaml```
- ```stripo-plugin-statistics-service.yaml ```
- ```stripo-security-service.yaml ```
- ```stripo-timer-api.yaml ```

To apply the new tag version run the following command:
```
./update.sh amp-validator-service
./update.sh patches-service
./update.sh screenshot-service
./update.sh stripe-html-cleaner-service
./update.sh stripe-html-gen-service
./update.sh stripo-plugin-api-gateway
./update.sh stripo-plugin-custom-blocks-service
./update.sh stripo-plugin-details-service
./update.sh stripo-plugin-documents-service
./update.sh stripo-plugin-drafts-service
./update.sh stripo-plugin-image-bank-service
./update.sh stripo-plugin-proxy-service
./update.sh stripo-plugin-statistics-service
./update.sh stripo-security-service
./update.sh emple-loadbalancer
```

### Plugin registration DB script description

```./resources/postgres/02_register_plugin.sql```

| Column | Description |
| ----------- | ----------- | 
| name | The name of your application. It will not be displayed elsewhere, but may be used for your convenience to distinguish the records within table |
| plugin_id | A unique GUID of your application without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one |
| secret_key | A unique GUID of your secret key without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one |
| status | The status of the application. It always should be "ACTIVE" |
| config | The JSON config of this application. Described in ```./resources/plugin_config.json``` |
| subscription_type | The pricing plan of the application. In your case, it is always "ENTERPRISE" |
| sub_domain | Create here any string value that will be used as a subdomain for the links with uploaded images. Works only if you have configured Stripo storage for image hosting |
