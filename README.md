<img src="https://stripo-cdn.stripo.email/img/front/press-kit/logo-horizontal.svg" alt="Stripo Logo" style="width: 198px"/>
<br/>

# Stripo plugin deployment manual

## Table of Contents
- [Overview](#overview)
- [System Architecture](#architecture)
- [Microservices and Their Responsibilities](#microservices)
- [Prerequisites](#prerequisites)

- [Deployment Process](#deployment-process)
- [Step 1: Setting Up Kubernetes Cluster](#step-1-setting-up-kubernetes-cluster)
- [Step 2: Installing Postgres Database](#step-2-installing-postgres-database)
- [Step 3: Setting Up NATS Messaging](#step-3-setting-up-nats-messaging)
- [Step 4: Configuring CockroachDB](#step-4-configuring-cockroachdb)
- [Step 5: Installing Redis](#step-5-installing-redis)
- [Step 6: Deploying Helm Charts](#step-6-deploying-helm-charts)
- [Maintenance](#maintenance)
- [Contributing](#contributing)
- [License](#license)

---

## Overview
This repository contains the web application built using microservices architecture. The services are deployed on a Kubernetes cluster using Helm charts. Below, you will find detailed instructions on how to set up the environment, configure the necessary components, and deploy the services.

## System Architecture

The Stripo ecosystem consists of several key components, each playing a crucial role in ensuring seamless operations and communication between services. Below is a breakdown of the main parts of the architecture:

- **Kubernetes Cluster with Microservices**:  
  All services are containerized and deployed as Docker images within a Kubernetes cluster, enabling a scalable and distributed microservices architecture.

- **PostgreSQL**:  
  Serves as the primary relational database for microservices that require structured data storage.

- **Redis**:  
  Used for managing rate-limiting information, ensuring efficient access control across microservices.

- **Amazon S3**:  
  Provides a scalable storage solution for media assets, such as images and files, with high availability and durability.

### Additional Components for Stripo Editor V2:

- **NATS**:  
  Facilitates messaging and communication between microservices, allowing them to interact in a decoupled manner.

- **CockroachDB**:  
  A distributed database that stores email templates and patch information, providing scalability and consistency for critical data.

- **Amazon ElastiCache**:  
  Used to store co-editing session information, enabling real-time collaboration by efficiently caching session data.

![Architecture Diagram](docs/system_architecture.png)

## Microservices Architecture Overview

The Plugin infrastructure is composed of 20 microservices, each containerized using Docker. These Docker images are hosted in Stripo's Docker Hub repository. Enterprise plan partners are granted read-only access to this repository, allowing them to download the required images with specific versions when they choose to host the Plugin Backend on their own servers.

### Microservice Dependencies

Several microservices rely on external services such as **PostgreSQL**, **CockroachDB**, and **Redis**. These dependencies can be deployed on any infrastructure. The connection between each microservice and its dependencies is defined within the properties in these Helm charts, ensuring smooth and customizable deployments.

### Logging and Monitoring

Each microservice has the option to send its logs to an **ELK stack** (Elasticsearch, Logstash, and Kibana) for monitoring and analysis. Like the dependencies, the ELK stack can be deployed anywhere, and its URL can be specified via properties. This ensures flexible monitoring setups for partners hosting the Plugin Backend on their servers.

### Microservice Responsibilities

The table below outlines the current microservices, their roles, and their requirements for different plugin versions (V1 and V2). It also specifies which services are public-facing for web access.

| Service Name                            | Responsibility                                                                                         | Public (Web) | Required for V1 | Required for V2 |
|-----------------------------------------|--------------------------------------------------------------------------------------------------------|--------------|-----------------|-----------------|
| **stripo-plugin-api-gateway**           | Handles user authentication, authorization, and request routing.                                       | true         | true            | true            |
| **stripo-plugin-proxy-service**         | Proxies Stripo editor JS requests to avoid CORS errors when accessing different domains.               | true         | true            | true            |
| **countdowntimer**                      | Generates timer GIFs for countdown elements.                                                           | true         | true            | true            |
| **stripo-plugin-details-service**       | Manages CRUD operations for plugin configuration.                                                      | false        | true            | true            |
| **stripo-plugin-statistics-service**    | Stores user session statistics.                                                                        | false        | true            | true            |
| **stripo-plugin-drafts-service**        | Stores email changes (patches) on autosave.                                                            | false        | true            | false           |
| **patches-service**                     | Reconstructs full emails from autosave patches.                                                        | false        | true            | false           |
| **ai-service**                          | Supports AI-based features within the Stripo editor.                                                   | false        | true            | false           |
| **stripo-plugin-documents-service**     | Handles document (image) read/upload operations.                                                       | false        | true            | true            |
| **stripo-plugin-custom-blocks-service** | Manages CRUD operations for custom blocks (modules).                                                   | false        | true            | true            |
| **stripo-timer-api**                    | Interacts with timers and stores usage statistics for timers.                                          | false        | true            | true            |
| **screenshot-service**                  | Generates image previews from HTML for module previews.                                                | false        | true            | true            |
| **stripo-plugin-image-bank-service**    | Integrates with external services like Pixabay, Pexels, and IconFinder for image handling.             | false        | true            | true            |
| **stripe-html-gen-service**             | Parses external websites and extracts information for smart-modules.                                   | false        | true            | true            |
| **stripo-security-service**             | Verifies external URLs for security, ensuring compliance with protocols and blocking internal AWS IPs. | false        | true            | true            |
| **stripe-html-cleaner-service**         | Compiles and cleans HTML/CSS from the Stripo editor to produce optimized, compressed HTML for sending. | false        | true            | true            |
| **amp-validator-service**               | Validates AMP HTML code for correctness and compliance.                                                | false        | true            | true            |
| **coediting-core-service**              | Acts as a coediting API gateway and stores email templates and autosave patches.                       | true         | false           | true            |
| **env-adapter-service**                 | Manages coediting user authentication and checks editor permissions.                                   | false        | false           | true            |
| **merge-service**                       | Applies autosave patches to email templates.                                                           | false        | false           | true            |

### Notes:
- **Public (Web)**: Indicates whether the service is accessible via the web.
- **Required for V1/V2**: Specifies if the service is mandatory for plugin versions 1 or 2.

![Microservices Diagram](docs/microservices.png)

## Prerequisites

Before deploying the web application, ensure that the following prerequisites are met. Each of these components needs to be installed and properly configured.

1. **Kubernetes Cluster**
 - Ensure that a running Kubernetes cluster is available.
 - You can install Kubernetes by following the official guide: [Kubernetes Installation](https://kubernetes.io/docs/setup/)

2. **Helm**: Version 3.x or higher
 - Helm is a package manager for Kubernetes. Install it by following the official guide: [Helm Installation](https://helm.sh/docs/intro/install/)

3. **PostgreSQL**: Version 15.x or higher
 - PostgreSQL is required for the database. Install PostgreSQL by following the guide: [PostgreSQL Installation](https://www.postgresql.org/download/)

4. **Redis**: Version 6.x or higher
 - Redis is an in-memory data structure store, widely used for caching, real-time analytics, message brokering, and more. To deploy Redis in your Kubernetes cluster, follow the official installation guide: [Redis Installation](https://redis.io/docs/getting-started/installation/)

Additionally, these prerequisites must be met if you want to deploy Stripo V2 microservices:

5. **NATS**: Version 2.x
 - NATS is a messaging system required for the application. Install NATS using the official documentation: [NATS Installation](https://docs.nats.io/nats-server/installation)

   **Additional NATS configuration:**
   ```yaml
   server_name: “your_server_name”
   port: 4222
   max_payload: 16777216
   jetstream {
       store_dir: /var/lib/nats/data
       max_mem: 1GB
       max_file: 10GB
   }
   cluster {
       name: “your_cluster_name”
       listen: 0.0.0.0:6222
       routes = [
           nats-route://your_server_route1:6222
           nats-route://your_server_route2:6222
           nats-route://your_server_route3:6222
       ]
   }
   ```
6. **CockroachDB**: Version 23.x or higher
 - CockroachDB is a distributed SQL database that offers scalability and strong consistency. You can install CockroachDB by following the official guide: [CockroachDB Installation](https://www.cockroachlabs.com/docs/stable/install-cockroachdb.html)

   **Additional CockroachDB Parameters:**
      ```bash
   --cache=.10          # Cache size set to 10% of available memory
   --max-sql-memory=.70  # SQL memory limited to 70% of available memory
   --max-tsdb-memory=.1  # Timeseries database memory limited to 10% of available memory
   ```

7. **Amazon ElastiCache**
 - AWS ElastiCache for Redis official documentation:  [AWS ElastiCache doc](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html)


## Deployment Process

### Step 1: Create PostgreSQL Databases

Below is a list of microservices that require individual PostgreSQL databases:

- `stripo-plugin-api-gateway`
- `countdowntimer`
- `stripo-plugin-details-service`
- `stripo-plugin-statistics-service`
- `stripo-plugin-drafts-service`
- `ai-service`
- `stripo-plugin-documents-service`
- `stripo-plugin-custom-blocks-service`
- `stripo-timer-api`
- `stripo-plugin-image-bank-service`
- `stripe-html-gen-service`
- `stripo-security-service`

#### SQL Script Template for Database Creation:

```sql
-- Step 1: Create the database
CREATE DATABASE your_database_name;

-- Step 2: Create the user with a password
CREATE USER your_username WITH PASSWORD 'your_password';

-- Step 3: Grant the user read/write access to the database
GRANT ALL PRIVILEGES ON DATABASE your_database_name TO your_username;
```

For an example SQL script, refer to this file (./resourses/postgres/01_create_databases.sql)

### Step 2: Insert Required Data into the PostgreSQL Database

To start using the String editor in plugin mode, you first need to register a plugin in the `stripo-plugin-details-service` database. This database contains a table named `plugins`.

For an example on how to register the first plugin, refer to the following SQL script: [02_register_plugin.sql](./resources/postgres/02_register_plugin.sql).

| Column            | Description                                                                                                                                                              |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name              | The name of your application. It will not be displayed elsewhere but may be used for your convenience to distinguish the records within table                            |
| plugin_id         | A unique GUID of your application without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one |
| secret_key        | A unique GUID of your secret key without hyphens. You are welcome to use [this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one  |
| status            | The status of the application. It always should be "ACTIVE"                                                                                                              |
| config            | The JSON config of this application. Described below in[Plugin Configuration Parameters](#plugin-configuration-parameters) section.                                      |
| subscription_type | The pricing plan of the application. In your case, it is always "ENTERPRISE"                                                                                             |
| sub_domain        | Create any string value here that will be used as a subdomain for the links with uploaded images. Works only if you have configured Plugin storage for image hosting     |



#### Plugin Configuration Parameters

This section provides an overview of the configuration parameters for the plugin setup.

| Parameter                                    | Type         | Description                                                                                                                                       |
|----------------------------------------------|--------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `theme.type`                                 | String       | Set to `"DEFAULT"` to use Stripo theme, or `"CUSTOM"` to apply custom theme parameters.                                                           |
| `theme.params.primary-color`                 | String (Hex) | Sets the primary color (e.g., `#93c47d`).                                                                                                         |
| `theme.params.secondary-color`               | String (Hex) | Sets the secondary color (e.g., `#ffffff`).                                                                                                       |
| `theme.params.border-radius-base`            | String (px)  | Defines the base border radius for elements (e.g., `5px`).                                                                                        |
| `theme.params.customFontLink`                | String (URL) | Link to your public custom font. [More info](https://support.stripo.email/en/articles/3174076-how-to-add-manage-custom-fonts-to-email-templates). |
| `theme.params.font-size`                     | String (px)  | Sets the font size (e.g., `9px`).                                                                                                                 |
| `theme.params.font-family`                   | String       | Specifies the font family to use (e.g., `"Segoe UI", Roboto, etc.`).                                                                              |
| `theme.params.option-panel-background-color` | String (Hex) | Background color of the option panel (e.g., `#cfe2f3`).                                                                                           |
| `theme.params.default-font-color`            | String (Hex) | Default font color (e.g., `#38761d`).                                                                                                             |
| `theme.params.panels-border-color`           | String (Hex) | Border color of the panels (e.g., `#0004cc`).                                                                                                     |
| `theme.removePluginBranding`                 | Boolean      | Set to `true` to hide the Stripo logo within the editor, `false` to display it.                                                                   |
| `imageGallery.type`                          | String       | Type of storage for uploaded images: `PLUGIN`, `AWS_S3`, `AZURE`, or `API`  (e.g., `PLUGIN`).                                                     |
| `imageGallery.baseDownloadUrl`               | String (URL) | Base download URL for images (optional).                                                                                                          |
| `imageGallery.awsBucketName`                 | String       | AWS bucket name for image storage (if using AWS).                                                                                                 |
| `imageGallery.awsAccessKey`                  | String       | AWS access key (if using AWS).                                                                                                                    |
| `imageGallery.awsSecretKey`                  | String       | AWS secret key (if using AWS).                                                                                                                    |
| `imageGallery.awsRegion`                     | String       | AWS region (e.g., `eu-central-1`).                                                                                                                |
| `imageGallery.azureToken`                    | String       | Azure storage token (if using Azure).                                                                                                             |
| `imageGallery.api.enabled`                   | Boolean      | Enables custom API for image storage (set to `true`).                                                                                             |
| `imageGallery.api.url`                       | String (URL) | URL for custom image storage API.                                                                                                                 |
| `imageGallery.api.username`                  | String       | Username for custom image storage API.                                                                                                            |
| `imageGallery.api.password`                  | String       | Password for custom image storage API.                                                                                                            |
| `imageGallery.tabs`                          | Array        | Tabs (folders) displayed in the image gallery UI.                                                                                                 |
| `imageGallery.maxFileSizeInKBytes`           | Number       | Maximum file size for uploaded images (e.g., `8192` KB).                                                                                          |
| `imageGallery.imagesBankEnabled`             | Boolean      | Enables the stock image library.                                                                                                                  |
| `imageGallery.pexelsEnabled`                 | Boolean      | Enables searching stock images from Pexels.                                                                                                       |
| `imageGallery.pixabayEnabled`                | Boolean      | Enables searching stock images from Pixabay.                                                                                                      |
| `imageGallery.iconFinderEnabled`             | Boolean      | Enables searching stock icons from Iconfinder.                                                                                                    |
| `imageGallery.skipChunkedTransferEncoding`   | Boolean      | Set `false` to use chunked transfer encoding for image uploads.                                                                                   |
| `blocksLibrary.enabled`                      | Boolean      | Enables the Modules section in the editor (true/false).                                                                                           |
| `blocksLibrary.tabs`                         | Array        | Folders displayed in the Modules section of the editor.                                                                                           |
| `blocksLibrary.view`                         | String       | Defines the view type for modules (`GRID` or `FULL_WIDTH`).                                                                                       |
| `baseBlocks`                                 | Object       | Enables/disables individual base blocks like image, text, button, etc.                                                                            |
| `blockControls`                              | Object       | Enables/disables advanced controls for blocks in the editor.                                                                                      |
| `permissionsApi.enabled`                     | Boolean      | Enables the Permissions Checker API.                                                                                                              |
| `ai.openAiApiKey`                            | String       | OpenAI API key for AI features.                                                                                                                   |
| `ai.textBlockAiEnabled`                      | Boolean      | Enables AI for text block suggestions.                                                                                                            |
| `ai.smartModuleAiEnabled`                    | Boolean      | Enables AI for Smart modules suggestions.                                                                                                         |
| `mergeTagsEnabled`                           | Boolean      | Enables merge tags within the editor.                                                                                                             |
| `specialLinksEnabled`                        | Boolean      | Enables special links (e.g., unsubscribe, profile update) within the editor.                                                                      |
| `customFontsEnabled`                         | Boolean      | Enables custom fonts within the editor.                                                                                                           |
| `autoSaveApi.enabled`                        | Boolean      | Enables auto-saving of progress in the editor.                                                                                                    |
| `autoSaveApiV2.enabled`                      | Boolean      | Enables notifications of changes in the editor V2.                                                                                                |
| `autoSaveEnabled`                            | Boolean      | Enables auto-saving in the editor V2.                                                                                                             |
| `undoEnabled`                                | Boolean      | Enables undo/redo actions within the editor.                                                                                                      |
| `versionHistoryEnabled`                      | Boolean      | Enables version history feature within the editor.                                                                                                |

### Step 3: Configure Countdown Timer

1. **Generate password hash**  
   Use the following commands to install the required Python dependencies and generate a password hash. Replace `${YOUR_PASSWORD}` with your actual password.

    ```shell
    pip3 install bcrypt  # Install Python dependencies
    python3 ./resources/countdowntimer/encode.py ${YOUR_PASSWORD}  # Generate password hash
    ```

2. **Set the generated password in the `countdowntimer` service database**  
   Run the following SQL query to update the password in the `system_user` table. Replace `${YOUR_PASSWORD_HASH}` with the generated password hash from the previous step.

    ```sql
    UPDATE system_user SET password = '${YOUR_PASSWORD_HASH}' WHERE username = 'Admin';
    ```

3. **Update the `stripo-timer-api.yaml` file**  
   Set the newly generated password in the `stripo-timer-api.yaml` file under the `configmap`. Replace `${YOUR_PASSWORD}` with the actual password used to generate the hash.

    ```bash
    timer.username=Admin
    timer.password=${YOUR_PASSWORD}
    ```

### Example

If your password is `secret`, follow the steps below:

```bash
Generate password hash:
-> python3 encode.py secret
<- $2b$12$QNSzmdqZB/MkTZSkiI/RlOn0n0dQABAjZFVYIeIjnvF2pz19vWmfq

Run the following SQL query to update the password hash in the database:
UPDATE system_user SET password = '$2b$12$QNSzmdqZB/MkTZSkiI/RlOn0n0dQABAjZFVYIeIjnvF2pz19vWmfq' WHERE username = 'Admin';

Update the stripo-timer-api.yaml file:
timer.username=Admin
timer.password=secret
```

### Step 4: Configure Amazon S3 Bucket

1. **Set Up AWS S3 Bucket and Permissions**

   Follow the instructions provided in [this documentation](https://stripo.email/ru/plugin-api/#configuration-of-aws-s3-storage) to configure your AWS S3 bucket and account permissions properly.

2. **Update Configuration File**

   Modify the `stripo-plugin-documents-service.yaml` file under the `configmap`. Ensure you provide the necessary values for the following parameters:

   ```yaml
   storage.internal.aws.accessKey=
   storage.internal.aws.secretKey=
   storage.internal.aws.bucketName=
   storage.internal.aws.region=
   storage.internal.aws.baseDownloadUrl=
   ```

### Step 5: Update Helm Chart Configurations

Enhance the `configmap` sections of the Helm charts for each microservice located in `./charts/*.yaml`. Add the necessary properties to include the actual database settings and secret keys.

### Step 6: Configure Stripo docker hub access

???

### Step 7: Configure Logging

Stripo logs can be collected using the ELK stack. Follow these steps to configure logging:

1. **Deploy the ELK Stack**

   Ensure that the ELK stack (Elasticsearch, Logstash, Kibana) is properly deployed in your environment.

2. **Set Environment Variables**

   Define the environment variables `LOGSTASH_HOST` and `LOGSTASH_PORT` in your YAML configuration files to direct log data to Logstash.

3. **Configure Log Levels**

   The default log level is set to `INFO`. You can customize the log level for each microservice within the YAML file settings under the `config map` section:

   ```yaml
   log.properties: |
     logging.level.root=DEBUG
   ```

   Replace `DEBUG` with the desired log level (e.g., `INFO`, `WARN`, `ERROR`) as needed for your use case.


### Step 8: Deploy microservices

#### Add Stripo helm repo with command
```shell
helm repo add stripo 'https://raw.githubusercontent.com/stripoinc/stripo-plugins-charts/main/'
```

#### Update Helm Charts with Specific Tag Versions

1. **Identify the Correct Tag Version:**
    - For **Stripo Editor V1**, refer to the [Stripo Plugin V1 Releases](https://github.com/ardas/stripo-plugin/tree/master/Versions).
    - For **Stripo Editor V2**, refer to the [Stripo Plugin V2 Releases](https://github.com/stripoinc/stripo-plugin-releases).

2. **Update the Helm Chart:**
    - In your Helm chart files, locate instances of the image tag set to `latest`.
    - Replace `latest` with the specific version tag you identified in the previous step.

Example:
```yaml
image:
  tag: "X.Y.Z"  # Replace X.Y.Z with the actual version tag.
```

#### Execute Bash Script for Installing or Upgrading Helm Charts in Your Kubernetes Namespace:
```shell
sh ./resources/helm/manage_charts.sh <namespace>
```

### Additional steps to configure Stripo Editor V2
#### Step 1: Create CockroachDB Database
To create a CockroachDB database, please refer to the official documentation:

[Official CockroachDB Documentation](https://www.cockroachlabs.com/docs/stable/)

Follow the step-by-step instructions to set up your database correctly.

#### Step 2: Create NATS account
To create a NATS account, please follow the official documentation provided by NATS. The official guide will walk you through the process step-by-step to ensure your account is set up correctly.

#### Step 3. Create an AWS ElastiCache Cluster
To create an AWS ElastiCache cluster, please refer to the official AWS documentation for detailed instructions and best practices.

<div style="border: 1px solid red; padding: 10px; border-left-width: 10px; background-color: #fff2f2;">
<strong>Warning:</strong>
Stripo is not responsible for the system's functionality if this instruction is not followed and the system is deployed in a manner different from the suggested method. However, our specialists are available to assist you on an individual basis according to specific agreements.
</div>

## Testing

### Stripo Editor V1

1. [Download the index.html file](https://github.com/ardas/stripo-plugin-samples/tree/master/client-side-code-sample).
2. Replace the following line:
    ```js
    script.src = 'https://plugins.stripo.email/static/latest/stripo.js';
    ```
   with:
    ```js
    script.src = '{SERVICE_ADDRESS}/static/stripo.js';
    ```
3. Add these additional parameters to the plugin configuration:
    ```js
    apiBaseUrl: '{SERVICE_ADDRESS}/api/v1',
    proxyUrl: '{SERVICE_ADDRESS}/proxy/v1/proxy',
    ```
4. Replace the `getAuthToken` function:
    ```js
    getAuthToken: function (callback) {
        request('POST', 'https://plugins.stripo.email/api/v1/auth', JSON.stringify({ 
          pluginId: 'YOUR_PLUGIN_ID',
          secretKey: 'YOUR_SECRET_KEY'
        }), function(data) {
            callback(JSON.parse(data).token);
        });
    }
    ```
   with:
    ```js
    getAuthToken: function (callback) {
        request('POST', '{SERVICE_ADDRESS}/api/v1/auth', JSON.stringify({ 
          pluginId: '{YOUR_PLUGIN_ID}',
          secretKey: '{YOUR_SECRET_KEY}'
        }), function(data) {
            callback(JSON.parse(data).token);
        });
    }
    ```
5. Open `index.html` in your browser.

### Stripo Editor V2

1. [Download the index.html file](https://github.com/stripoinc/stripo-plugin-samples/tree/main/quick-start-guide).
2. Replace the following line:
    ```js
    script.src = 'https://plugins.stripo.email/resources/uieditor/latest/UIEditor.js';
    ```
   with:
    ```js
    script.src = '{SERVICE_ADDRESS}/resources/uieditor/latest/UIEditor.js';
    ```
3. Add these additional parameters to the plugin configuration:
    ```js
    apiBaseUrl: '{SERVICE_ADDRESS}/api/v1',
    coeditingBasePath: '{SERVICE_ADDRESS}/coediting',
    ```
4. Replace the `onTokenRefreshRequest` function:
    ```js
    onTokenRefreshRequest: function (callback) {
        request('POST', 'https://plugins.stripo.email/api/v1/auth', JSON.stringify({ 
          pluginId: 'YOUR_PLUGIN_ID',
          secretKey: 'YOUR_SECRET_KEY',
          userId: '1',
          role: 'user'
        }), function(data) {
            callback(JSON.parse(data).token);
        });
    }
    ```
   with:
    ```js
    onTokenRefreshRequest: function (callback) {
        request('POST', '{SERVICE_ADDRESS}/api/v1/auth', JSON.stringify({ 
          pluginId: '{YOUR_PLUGIN_ID}',
          secretKey: '{YOUR_SECRET_KEY}',
          userId: '1',
          role: 'user'
        }), function(data) {
            callback(JSON.parse(data).token);
        });
    }
    ```
5. Open `index.html` in your browser.

## Migration Guide
See docs [here](https://github.com/stripoinc/stripo-plugins-helm-example/blob/main/docs/migration.md).
