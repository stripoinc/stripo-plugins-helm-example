<img src="https://stripo-cdn.stripo.email/img/front/press-kit/logo-horizontal.svg" alt="Stripo Logo" style="width: 198px"/>
<br/>

# Stripo plugin deployment manual

## Infrastructure Overview
On the high level, the Stripo plugin infrastructure looks like this:

<img src="docs/general_overview.png" alt="High level infrastructure scheme" style="width: 80%"/>

Plugin infrastructure consists of 17 microservices that are wrapped into the docker
containers/images. These images are hosted in the Stripo Docker Hub Repository to
which partners can get the read-only access (just to be able to download the images with
needed particular versions) once they’re on the Enterprise pricing plan and intend to host Plugin
Backend on their server.
Some microservices have their own databases (PostgreSQL) that can be deployed
anywhere. The connection between services and their DB is specified via properties.
Infrastructure also provides you with the ability to send logs from every microservice to the ELK
stack. The ELK stack can also be deployed anywhere. The URL to ELK can be specified via properties.

The list of actual microservices and their responsibilities are described in the table below:

| Service name                        | Responsibility                                                                                         | Is public for web |
|-------------------------------------|--------------------------------------------------------------------------------------------------------|-------------------|
 | stripo-plugin-api-gateway           | Used for user’s authentication, authorization and requests routing                                     | true              | 
 | emple-ui                            | Used to serve Stripo editor static files: js, css, fonts, icons                                        | true              |
 | stripo-plugin-proxy-service         | Used to proxy Stripo editor JS requests to different domains to avoid CORS error                       | true              |
 | countdowntimer                      | Used to create timer gif                                                                               | true              |
 | stripo-plugin-details-service       | Used for CRUD operations with plugin configuration                                                     | false             |
 | stripo-plugin-statistics-service    | Used to store user sessions statistic                                                                  | false             |
 | stripo-plugin-drafts-service        | Used to store patches (email changes) on autosave                                                      | false             |
 | patches-service                     | Used to recreate complete email from autosave patches                                                  | false             |
 | stripo-plugin-documents-service     | Used to handle documents (images) read/upload                                                          | false             |
 | stripo-plugin-custom-blocks-service | Used for CRUD operations with modules                                                                  | false             |
 | stripo-timer-api                    | Used for interaction with timer and store timer usage statistic                                        | false             |
 | screenshot-service                  | Used to generate images by HTML for modules preview                                                    | false             |
 | stripo-plugin-image-bank-service    | Used to interact with external services like pixabay, pexels, iconFinder                               | false             |
 | stripe-html-gen-service             | Used to parse external sites and extract information for smart-modules                                 | false             |
 | stripo-security-service             | Used to check external URLs for security (protocol, internal AWS IPs)                                  | false             |
 | stripe-html-cleaner-service         | Used to compile HTML and CSS from Stripo editor to clean compressed HTML ready to be sent to customers | false             |
 | amp-validator-service               | Used to check if AMP HTML code is valid                                                                   | false             |

## Communication between microservices
<img src="docs/microservices_overview.png" alt="Microservices communication scheme" style="width: 80%"/>

## Environment configuration

### Required local tools
```
kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
helm  (https://helm.sh/docs/intro/install/)
```

### Manual to create Stripo environment with Amazon EKS

| #   | Description                                                          | Link                                                                                  | Resources                                                             |
|-----|----------------------------------------------------------------------|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
 | 1   | Create Amazon EKS cluster                                            | [Video](https://kub.stripocdn.email/content/materials/git/aws_eks_cluster.mp4)        | [eksctl](https://eksctl.io/) <br> ./resources/cluster.yaml            |
 | 2   | Install Nginx ingress controller                                     | [Video](https://kub.stripocdn.email/content/materials/git/install-nginx-ingress.mp4)  | <https://kubernetes.github.io/ingress-nginx/deploy/#aws>              |
 | 3   | Create DNS record in Route 53                                        | [Video](https://kub.stripocdn.email/content/materials/git/dns_route_53.mp4)           |                                                                       |
 | 4   | Create PostgreSQL databases                                          | [Video](https://kub.stripocdn.email/content/materials/git/create_dbs.mp4)             | ./resources/postgres/01_create_databases.sql                          |
 | 5   | Create S3 bucket                                                     | [Video](https://kub.stripocdn.email/content/materials/git/s3_bucket.mp4)              | <https://stripo.email/ru/plugin-api/#configuration-of-aws-s3-storage> |
 | 6   | Enrich yaml properties with actual DB and AWS S3 settings            | [Video](https://kub.stripocdn.email/content/materials/git/yaml_config.mp4)            |                                                                       |
 | 7   | Add helm repository                                                  |                                                                                       | ```bash ./resources/helm_repo.sh```                                   |
 | 8   | Run kubernetes cluster                                               | [Video](https://kub.stripocdn.email/content/materials/git/run_kubernetes_cluster.mp4) | ./install_all.sh                                                      |
 | 9   | Apply database script to ```stripo_plugin_local_plugin_details``` DB |                                                                                       | ./resources/postgres/02_register_plugin.sql                           |
 | 10  | Configure Nginx                                                      | [Video](https://kub.stripocdn.email/content/materials/git/nginx_config.mp4)           | ./resources/nginx/plugins.conf                                        |
 | 11  | Configure countdown timer                                            | [Video](https://kub.stripocdn.email/content/materials/git/countdowntimer.mp4)         |                                                                       |
 | 12  | Test your configuration                                              | [Video](https://kub.stripocdn.email/content/materials/git/configuration_testing.mp4)  |
 | 13  | Run on minikube                                                      | [Video](https://kub.stripocdn.email/content/materials/git/minikube.mp4)               |

### Personal secret key
A personal secret key is used to download docker images from the Stripo docker hub.
Put secret key (docker-hub-secret.yaml) to ```./secrets``` folder

### Logging
#### ELK stack
Stripo logs can be collected with ELK stack. To configure logging, do the following steps: 
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
The default log level is INFO.
You can change the log level for each microservice in yaml file settings:
```
log.properties: |
  logging.level.root=DEBUG
```

### Docker images tags
Stripo continuously releases new features and bug fixes.
You will be regularly notified with the list of release image tags and release notes.
To apply new docker images, you need to replace
```
tag: "latest"
```
With the actual tag version in yaml files.

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

To apply the new tag version, run the following command:
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

| Column            | Description                                                                                                                                                              |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name              | The name of your application. It will not be displayed elsewhere but may be used for your convenience to distinguish the records within table                           |
| plugin_id         | A unique GUID of your application without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one |
| secret_key        | A unique GUID of your secret key without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one  |
| status            | The status of the application. It always should be "ACTIVE"                                                                                                              |
| config            | The JSON config of this application. Described in ```./resources/plugin_config.json```                                                                                   |
| subscription_type | The pricing plan of the application. In your case, it is always "ENTERPRISE"                                                                                             |
| sub_domain        | Create any string value here that will be used as a subdomain for the links with uploaded images. Works only if you have configured Stripo storage for image hosting     |


### Migration Guide
See docs [here](https://github.com/stripoinc/stripo-plugins-helm-example/blob/main/docs/migration.md).
