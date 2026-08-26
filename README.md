<img src="https://stripo-cdn.stripo.email/img/front/press-kit/logo-horizontal.svg" alt="Stripo Logo" style="width: 198px"/>
<br/>

# Stripo plugin deployment manual

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
   - [Kubernetes Cluster with Microservices](#kubernetes-cluster-with-microservices)
   - [PostgreSQL](#postgresql)
   - [Redis](#redis)
   - [Amazon S3](#amazon-s3)
   - [Additional Components for Stripo Editor V2](#additional-components-for-stripo-editor-v2)
3. [Microservices Architecture Overview](#microservices-architecture-overview)
   - [Microservice Dependencies](#microservice-dependencies)
   - [Logging and Monitoring](#logging-and-monitoring)
   - [Microservice Responsibilities](#microservice-responsibilities)
4. [Prerequisites](#prerequisites)
5. [Deployment Process](#deployment-process)
   - [Step 1: Create PostgreSQL Databases](#step-1-create-postgresql-databases)
   - [Step 2: Insert Required Data into the PostgreSQL Database](#step-2-insert-required-data-into-the-postgresql-database)
     - [Plugin Configuration Parameters](#plugin-configuration-parameters)
   - [Step 3: Additional steps to configure Stripo Editor V2 (for V2 only)](#step-3-additional-steps-to-configure-stripo-editor-v2-for-v2-only)
     - [Create TiDB Database](#create-tidb-database)
     - [Use AWS Aurora MySQL instead of TiDB (optional)](#use-aws-aurora-mysql-instead-of-tidb-optional)
     - [Create NATS Account](#create-nats-account)
     - [Create an AWS ElastiCache Cluster](#create-an-aws-elasticache-cluster)
   - [Step 4: Configure Amazon S3 Bucket](#step-4-configure-amazon-s3-bucket)
   - [Step 5: Update Helm Chart Configurations](#step-5-update-helm-chart-configurations)
   - [Step 6: Configure Docker Image Access](#step-6-configure-docker-image-access)
     - [Configure Stripo Docker Hub Access](#configure-stripo-docker-hub-access)
     - [Configure Amazon ECR Access (Alternative to Docker Hub)](#configure-amazon-ecr-access-alternative-to-docker-hub)
   - [Step 7: Configure Logging](#step-7-configure-logging)
   - [Step 8: Deploy Microservices](#step-8-deploy-microservices)
   - [Step 9: Configure Countdown Timer](#step-9-configure-countdown-timer)
   - [Step 10: Configure CDN for Static Resources](#step-10-configure-cdn-for-static-resources)
   - [Step 11: Configure AI Widgets (for V2 only)](#step-11-configure-ai-widgets-for-v2-only)
     - [Create the Databases](#create-the-databases)
     - [Configure the Widgets Registry Service](#configure-the-widgets-registry-service)
     - [Configure the Chat Server](#configure-the-chat-server)
     - [Route the API Gateway to Both Services](#route-the-api-gateway-to-both-services)
     - [Enable the Shared Widget Catalog](#enable-the-shared-widget-catalog)
     - [Enable Widgets for Your Plugin](#enable-widgets-for-your-plugin)
     - [Allow Long-Lived Streaming Responses](#allow-long-lived-streaming-responses)
     - [Host the Widgets Panel Bundle](#host-the-widgets-panel-bundle)
     - [Verify the Setup](#verify-the-setup)
6. [Testing](#testing)
   - [Stripo Editor V1](#stripo-editor-v1)
   - [Stripo Editor V2](#stripo-editor-v2)
7. [Migration Guide](#migration-guide)

---

## Overview

This repository contains the web application built using microservices architecture. The services are deployed on a Kubernetes cluster using Helm charts. Below, you will find detailed instructions on how to set up the environment, configure the necessary components, and deploy the services.

## System Architecture

The Stripo ecosystem consists of several key components, each playing a crucial role in ensuring seamless operations and communication between services. Below is a breakdown of the main parts of the architecture:

- **Kubernetes Cluster with Microservices**:All services are containerized and deployed as Docker images within a Kubernetes cluster, enabling a scalable and distributed microservices architecture.
- **PostgreSQL**:Serves as the primary relational database for microservices that require structured data storage.
- **Redis**:Used for managing rate-limiting information, ensuring efficient access control across microservices.
- **Amazon S3**:
  Provides a scalable storage solution for media assets, such as images and files, with high availability and durability.

### Additional Components for Stripo Editor V2:

- **NATS**:Facilitates messaging and communication between microservices, allowing them to interact in a decoupled manner.
- **TiDB**:A distributed database that stores email templates and patch information, providing scalability and consistency for critical data.
- **Amazon ElastiCache**:
  Used to store co-editing session information, enabling real-time collaboration by efficiently caching session data.

![Architecture Diagram](docs/assets/system_architecture.png)

## Microservices Architecture Overview

The Plugin infrastructure is composed of 22 microservices, each containerized using Docker. These Docker images are hosted in Stripo's Docker Hub repository. Enterprise plan partners are granted read-only access to this repository, allowing them to download the required images with specific versions when they choose to host the Plugin Backend on their own servers.

### Microservice Dependencies

Several microservices rely on external services such as **PostgreSQL**, **TiDB**, and **Redis**. These dependencies can be deployed on any infrastructure. The connection between each microservice and its dependencies is defined within the properties in these Helm charts, ensuring smooth and customizable deployments.

### Logging and Monitoring

Each microservice has the option to send its logs to an **ELK stack** (Elasticsearch, Logstash, and Kibana) for monitoring and analysis. Like the dependencies, the ELK stack can be deployed anywhere, and its URL can be specified via properties. This ensures flexible monitoring setups for partners hosting the Plugin Backend on their servers.

### Microservice Responsibilities

The table below outlines the current microservices, their roles, and their requirements for different plugin versions (V1 and V2). It also specifies which services are public-facing for web access.

| Service Name                                  | Responsibility                                                                                         | Public (Web) | Required for V1 | Required for V2 |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------ | --------------- | --------------- |
| **stripo-plugin-api-gateway**           | Handles user authentication, authorization, and request routing.                                       | true         | true            | true            |
| **stripo-plugin-proxy-service**         | Proxies Stripo editor JS requests to avoid CORS errors when accessing different domains.               | true         | true            | true            |
| **countdowntimer**                      | Generates timer GIFs for countdown elements.                                                           | true         | true            | true            |
| **stripo-plugin-details-service**       | Manages CRUD operations for plugin configuration.                                                      | false        | true            | true            |
| **stripo-plugin-statistics-service**    | Stores user session statistics.                                                                        | false        | true            | true            |
| **stripo-plugin-drafts-service**        | Stores email changes (patches) on autosave.                                                            | false        | true            | false           |
| **patches-service**                     | Reconstructs full emails from autosave patches.                                                        | false        | true            | false           |
| **ai-service**                          | Supports AI-based features within the Stripo editor.                                                   | false        | true            | true            |
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
| **ui-editor-widgets-registry-service**  | Stores AI widget definitions and syncs the shared widget catalog from Stripo.                          | false        | false           | true            |
| **convo-core-chat-server**              | Runs the AI conversation that generates and edits widget content.                                      | false        | false           | true            |

### Notes:

- **Public (Web)**: Indicates whether the service is accessible via the web.
- **Required for V1/V2**: Specifies if the service is mandatory for plugin versions 1 or 2.

![Microservices Diagram](docs/assets/microservices.png)

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
  max_payload: 33554432
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

  If you deploy NATS using the [official NATS Helm chart](https://github.com/nats-io/k8s/tree/main/helm/charts/nats), set `max_payload` via `config.merge` in `values.yaml` and apply with `helm upgrade`:

  ```yaml
  config:
    merge:
      max_payload: 33554432 # 32 MiB
  ```

  After the change, restart or force a reconnect of `merge-service` and `coediting-core-service` — NATS clients cache `max_payload` from the initial connection handshake, so already-open connections keep enforcing the old limit until they reconnect.

  With a higher `max_payload`, `merge-service` may process larger patch payloads in memory — increase its `resources.limits.memory` / `resources.requests.memory` to **6000Mi** and scale `NODE_OPTIONS --max-old-space-size` accordingly (~90% of the memory limit, i.e. `5400`) in `./charts/merge-service.yaml` (see [Step 5](#step-5-update-helm-chart-configurations)).

  In addition to `max_payload`, set `settings.nats.maxPayloadSizeToIncludeInMsg: "31457280"` (30 MiB) on **both** `merge-service` and `coediting-core-service` (see `./charts/merge-service.yaml` and `./charts/coediting-core-service.yaml`; rendered as the `NATS_MAX_PAYLOAD_SIZE_TO_INCLUDE_IN_MSG` environment variable). It enables offloading of messages larger than this size through Object Storage instead of sending them inline over NATS. The value must be identical on both services and slightly lower than the NATS `max_payload` (the 32 MiB / 30 MiB pair). This setting takes effect starting from the release that enables reading it from the environment; on earlier versions it is ignored and `merge-service` logs `object store is not configured, skipping initialization` at startup.

  To keep large emails opening fast, also consider lowering `settings.numberOfPatchesToStartCompaction` on `coediting-core-service` (service default `100`, recommended `10`–`20`; rendered as the `NUMBER_OF_PATCHES_TO_START_COMPACTION` environment variable) — the number of accumulated patches that triggers server-side model compaction. A lower value means more frequent compaction and faster email opening. See the [Migration Guide](docs/migration.md#editor-performance-for-large-emails) for details.

6. **TiDB**: Version 7.5.0 or higher

- TiDB is a distributed SQL database that offers scalability and strong consistency. You can install TiDB by following the official guide: [TiDB Installation](https://docs.pingcap.com/tidb/stable/quick-start-with-tidb/)

  **Important Note**: When configuring TiDB connection parameters in your application configuration, ensure that the port value is specified as an integer (e.g., `4000`) rather than a string (e.g., `"4000"`). Some applications may require the port to be specified as a numeric value to avoid type conversion errors.

  **Additional TiDB Parameters:**

```
  tidb:
      performance.txn-entry-size-limit: 125829120    # The maximum size of a single entry in a transaction (in bytes).
      performance.txn-total-size-limit: 1000000000   # The maximum total size of all entries in a single transaction (in bytes).
  tikv:
      raftstore.raft-entry-max-size: 64MB            #  The maximum size of a single Raft log entry in TiKV.    
```

  > **Note:** TiDB is required for Stripo Editor V2 only, and it is not the only option. `coediting-core-service` can use an **AWS Aurora MySQL** cluster instead — see [Use AWS Aurora MySQL instead of TiDB](#use-aws-aurora-mysql-instead-of-tidb-optional). If you choose Aurora, you do not need to deploy a TiDB cluster at all.

7. **Amazon ElastiCache**

- AWS ElastiCache for Redis official documentation:  [AWS ElastiCache doc](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html)

## Deployment Process

### Step 1: Create PostgreSQL Databases

Below is a list of microservices that require individual PostgreSQL databases:

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
- `ui-editor-widgets-registry-service` (AI Widgets, V2 only — see [Step 11](#step-11-configure-ai-widgets-for-v2-only))
- `convo-core-chat-server` (AI Widgets, V2 only — see [Step 11](#step-11-configure-ai-widgets-for-v2-only))

You can find the script template for database creation at: `./resources/postgres/01_create_databases.sh`.

> **Note:** You can use **AWS RDS Aurora PostgreSQL** instead of local PostgreSQL. See the [Migration Guide](./docs/migration.md) for Aurora setup with IAM authentication.

### Step 2: Insert Required Data into the PostgreSQL Database

To start using the String editor in plugin mode, you first need to register a plugin in the database of `stripo-plugin-details-service`. This database contains a table named `plugins`.

For an example on how to register the first plugin, refer to the following SQL script: [02_register_plugin.sql](./resources/postgres/02_register_plugin.sql).

| Column            | Description                                                                                                                                                          |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name              | The name of your application. It will not be displayed elsewhere but may be used for your convenience to distinguish the records within table                        |
| plugin_id         | A unique GUID of your application without hyphens. You are welcome to use[this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one |
| secret_key        | A unique GUID of your secret key without hyphens. You are welcome to use[this](https://www.guidgenerator.com/online-guid-generator.aspx) service to generate a new one  |
| status            | The status of the application. It always should be "ACTIVE"                                                                                                          |
| config            | The JSON config of this application. Described below in[Plugin Configuration Parameters](#plugin-configuration-parameters) section.                                     |
| subscription_type | The pricing plan of the application. In your case, it is always "ENTERPRISE"                                                                                         |
| sub_domain        | Create any string value here that will be used as a subdomain for the links with uploaded images. Works only if you have configured Plugin storage for image hosting |

#### Plugin Configuration Parameters

This section provides an overview of the configuration parameters for the plugin setup.

| Parameter                                         | Type         | Description                                                                                                                                   |
| ------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `theme.type`                                    | String       | Set to `"DEFAULT"` to use Stripo theme, or `"CUSTOM"` to apply custom theme parameters.                                                   |
| `theme.params.primary-color`                    | String (Hex) | Sets the primary color (e.g.,`#93c47d`).                                                                                                    |
| `theme.params.secondary-color`                  | String (Hex) | Sets the secondary color (e.g.,`#ffffff`).                                                                                                  |
| `theme.params.border-radius-base`               | String (px)  | Defines the base border radius for elements (e.g.,`5px`).                                                                                   |
| `theme.params.customFontLink`                   | String (URL) | Link to your public custom font.[More info](https://support.stripo.email/en/articles/3174076-how-to-add-manage-custom-fonts-to-email-templates). |
| `theme.params.font-size`                        | String (px)  | Sets the font size (e.g.,`9px`).                                                                                                            |
| `theme.params.font-family`                      | String       | Specifies the font family to use (e.g.,`"Segoe UI", Roboto, etc.`).                                                                         |
| `theme.params.option-panel-background-color`    | String (Hex) | Background color of the option panel (e.g.,`#cfe2f3`).                                                                                      |
| `theme.params.default-font-color`               | String (Hex) | Default font color (e.g.,`#38761d`).                                                                                                        |
| `theme.params.panels-border-color`              | String (Hex) | Border color of the panels (e.g.,`#0004cc`).                                                                                                |
| `theme.removePluginBranding`                    | Boolean      | Set to `true` to hide the Stripo logo within the editor, `false` to display it.                                                           |
| `imageGallery.type`                             | String       | Type of storage for uploaded images:`PLUGIN`, `AWS_S3`, `AZURE`, `CLOUDINARY`, `GOOGLE_CLOUD`, or `API` (e.g., `PLUGIN`).       |
| `imageGallery.baseDownloadUrl`                  | String (URL) | Base download URL for images (optional).                                                                                                      |
| `imageGallery.awsBucketName`                    | String       | AWS bucket name for image storage (if using AWS).                                                                                             |
| `imageGallery.awsAccessKey`                     | String       | AWS access key (if using AWS).                                                                                                                |
| `imageGallery.awsSecretKey`                     | String       | AWS secret key (if using AWS).                                                                                                                |
| `imageGallery.awsRegion`                        | String       | AWS region (e.g.,`eu-central-1`).                                                                                                           |
| `imageGallery.azureToken`                       | String       | Azure storage token (if using Azure).                                                                                                         |
| `imageGallery.azureBaseDownloadUrl`             | String (URL) | Azure base download URL for images (if using Azure).                                                                                          |
| `imageGallery.cloudinaryCloudName`              | String       | Cloudinary cloud name (if using Cloudinary).                                                                                                  |
| `imageGallery.cloudinaryApiKey`                 | String       | Cloudinary API key (if using Cloudinary).                                                                                                     |
| `imageGallery.cloudinaryApiSecret`              | String       | Cloudinary API secret (if using Cloudinary).                                                                                                  |
| `imageGallery.googleCloudBucketName`            | String       | Google Cloud Storage bucket name (if using Google Cloud).                                                                                     |
| `imageGallery.googleCloudProjectId`             | String       | Google Cloud project ID (if using Google Cloud).                                                                                              |
| `imageGallery.googleCloudKey`                   | String       | Google Cloud authentication key (if using Google Cloud).                                                                                      |
| `imageGallery.api.enabled`                      | Boolean      | Enables custom API for image storage (set to `true`).                                                                                       |
| `imageGallery.api.url`                          | String (URL) | URL for custom image storage API.                                                                                                             |
| `imageGallery.api.username`                     | String       | Username for custom image storage API.                                                                                                        |
| `imageGallery.api.password`                     | String       | Password for custom image storage API.                                                                                                        |
| `imageGallery.tabs`                             | Array        | Tabs (folders) displayed in the image gallery UI.                                                                                             |
| `imageGallery.tabs[].label`                     | Object       | Localized labels for the tab (e.g.,`{"en": "Photos", "es": "Fotos"}`).                                                                      |
| `imageGallery.tabs[].key`                       | String       | Unique key identifier for the tab.                                                                                                            |
| `imageGallery.tabs[].canWrite`                  | Boolean      | Whether users can upload/write to this tab (default:`false`).                                                                               |
| `imageGallery.tabs[].role`                      | String       | Required role to access this tab (`ADMIN` or `USER`).                                                                                     |
| `imageGallery.maxFileSizeInKBytes`              | Number       | Maximum file size for uploaded images (e.g.,`8192` KB).                                                                                     |
| `imageGallery.imagesBankEnabled`                | Boolean      | Enables the stock image library.                                                                                                              |
| `imageGallery.pexelsEnabled`                    | Boolean      | Enables searching stock images from Pexels.                                                                                                   |
| `imageGallery.pixabayEnabled`                   | Boolean      | Enables searching stock images from Pixabay.                                                                                                  |
| `imageGallery.iconFinderEnabled`                | Boolean      | Enables searching stock icons from Iconfinder.                                                                                                |
| `imageGallery.pexelsKey`                        | String       | Pexels API key for stock image search.                                                                                                        |
| `imageGallery.pixabayKey`                       | String       | Pixabay API key for stock image search.                                                                                                       |
| `imageGallery.iconFinderKey`                    | String       | Iconfinder API key for stock icon search.                                                                                                     |
| `imageGallery.imageSearchEnabled`               | Boolean      | Enables image search functionality.                                                                                                           |
| `imageGallery.iconSearchEnabled`                | Boolean      | Enables icon search functionality.                                                                                                            |
| `imageGallery.imagesBankLabel`                  | Object       | Localized labels for the images bank (e.g.,`{"en": "Stock", "es": "Banco"}`).                                                               |
| `imageGallery.skipChunkedTransferEncoding`      | Boolean      | Set `false` to use chunked transfer encoding for image uploads.                                                                             |
| `blocksLibrary.enabled`                         | Boolean      | Enables the Modules section in the editor (true/false).                                                                                       |
| `blocksLibrary.tabs`                            | Array        | Folders displayed in the Modules section of the editor.                                                                                       |
| `blocksLibrary.tabs[].viewOrder`                | Number       | Display order of the tab in the UI.                                                                                                           |
| `blocksLibrary.tabs[].label`                    | Object       | Localized labels for the tab (e.g.,`{"en": "Email", "es": "Correo"}`).                                                                      |
| `blocksLibrary.tabs[].key`                      | String       | Unique key identifier for the tab.                                                                                                            |
| `blocksLibrary.tabs[].canWrite`                 | Boolean      | Whether users can save modules to this tab (default:`false`).                                                                               |
| `blocksLibrary.tabs[].role`                     | String       | Required role to access this tab (`ADMIN` or `USER`).                                                                                     |
| `blocksLibrary.view`                            | String       | Defines the view type for modules (`NET` or `FULL_WIDTH`, default: `FULL_WIDTH`).                                                       |
| `baseBlocks`                                    | Object       | Enables/disables individual base blocks like image, text, button, etc.                                                                        |
| `baseBlocks.imageEnabled`                       | Boolean      | Enables the Image block (default:`true`).                                                                                                   |
| `baseBlocks.textEnabled`                        | Boolean      | Enables the Text block (default:`true`).                                                                                                    |
| `baseBlocks.buttonEnabled`                      | Boolean      | Enables the Button block (default:`true`).                                                                                                  |
| `baseBlocks.spacerEnabled`                      | Boolean      | Enables the Spacer block (default:`true`).                                                                                                  |
| `baseBlocks.videoEnabled`                       | Boolean      | Enables the Video block (default:`true`).                                                                                                   |
| `baseBlocks.socialNetEnabled`                   | Boolean      | Enables the Social Networks block (default:`true`).                                                                                         |
| `baseBlocks.bannerEnabled`                      | Boolean      | Enables the Banner block (default:`true`).                                                                                                  |
| `baseBlocks.menuEnabled`                        | Boolean      | Enables the Menu block (default:`true`).                                                                                                    |
| `baseBlocks.htmlEnabled`                        | Boolean      | Enables the HTML block (default:`true`).                                                                                                    |
| `baseBlocks.timerEnabled`                       | Boolean      | Enables the Timer block (default:`false`).                                                                                                  |
| `baseBlocks.ampCarouselEnabled`                 | Boolean      | Enables the AMP Carousel block (default:`true`).                                                                                            |
| `baseBlocks.ampAccordionEnabled`                | Boolean      | Enables the AMP Accordion block (default:`true`).                                                                                           |
| `baseBlocks.ampFormControlsEnabled`             | Boolean      | Enables the AMP Form block (default:`true`).                                                                                                |
| `blockControls`                                 | Object       | Enables/disables advanced controls for blocks in the editor.                                                                                  |
| `blockControls.blockVisibilityEnabled`          | Boolean      | Enables block visibility controls (default:`true`).                                                                                         |
| `blockControls.mobileInversionEnabled`          | Boolean      | Enables mobile inversion controls (default:`true`).                                                                                         |
| `blockControls.mobileAlignmentEnabled`          | Boolean      | Enables mobile alignment controls (default:`true`).                                                                                         |
| `blockControls.stripePaddingEnabled`            | Boolean      | Enables stripe padding controls (default:`true`).                                                                                           |
| `blockControls.containerBackgroundEnabled`      | Boolean      | Enables container background controls (default:`true`).                                                                                     |
| `blockControls.structureBackgroundImageEnabled` | Boolean      | Enables structure background image controls (default:`true`).                                                                               |
| `blockControls.containerBackgroundImageEnabled` | Boolean      | Enables container background image controls (default:`true`).                                                                               |
| `blockControls.dynamicStructuresEnabled`        | Boolean      | Enables dynamic structures controls (default:`true`).                                                                                       |
| `blockControls.imageSrcLinkEnabled`             | Boolean      | Enables image source link controls (default:`true`).                                                                                        |
| `blockControls.ampVisibilityEnabled`            | Boolean      | Enables AMP visibility controls (default:`true`).                                                                                           |
| `blockControls.smartBlocksEnabled`              | Boolean      | Enables smart blocks functionality (default:`true`).                                                                                        |
| `blockControls.imageEditorPluginEnabled`        | Boolean      | Enables built-in image editor plugin (default:`true`).                                                                                      |
| `blockControls.mobileIndentPluginEnabled`       | Boolean      | Enables mobile indent plugin (default:`true`).                                                                                              |
| `blockControls.rolloverEffectEnabled`           | Boolean      | Enables rollover effect controls (default:`true`).                                                                                          |
| `blockControls.synchronizableModulesEnabled`    | Boolean      | Enables synchronizable modules functionality (default:`false`).                                                                             |
| `blockControls.compressionEnabled`              | Boolean      | Enables image compression functionality (default:`false`).                                                                                  |
| `blockControls.compressionRate`                 | Number       | Image compression rate (1-100, where 100 is best quality).                                                                                    |
| `permissionsApi.enabled`                        | Boolean      | Enables the Permissions Checker API.                                                                                                          |
| `permissionsApi.url`                            | String (URL) | URL for the Permissions API endpoint.                                                                                                         |
| `permissionsApi.username`                       | String       | Username for Permissions API authentication.                                                                                                  |
| `permissionsApi.password`                       | String       | Password for Permissions API authentication.                                                                                                  |
| `ai.openAiApiKey`                               | String       | OpenAI API key for AI features.                                                                                                               |
| `ai.textBlockAiEnabled`                         | Boolean      | Enables AI for text block suggestions.                                                                                                        |
| `ai.smartModuleAiEnabled`                       | Boolean      | Enables AI for Smart modules suggestions.                                                                                                     |
| `ai.openAiModel`                                | String       | OpenAI model to use for AI features (e.g.,`gpt-4`).                                                                                         |
| `ai.geminiProjectId`                            | String       | Google Gemini project ID for AI features.                                                                                                     |
| `ai.geminiServiceAccountKey`                    | String       | Google Gemini service account key for authentication.                                                                                         |
| `ai.stabilityBearerToken`                       | String       | Stability AI bearer token for image generation.                                                                                               |
| `ai.geminiEnabled`                              | Boolean      | Enables Google Gemini AI features.                                                                                                            |
| `ai.stabilityEnabled`                           | Boolean      | Enables Stability AI for image generation.                                                                                                    |
| `ai.dallEEnabled`                               | Boolean      | Enables DALL-E for AI image generation.                                                                                                       |
| `ai.gpt4oEnabled`                               | Boolean      | Enables GPT-4 model features.                                                                                                                 |
| `ai.subjectAiEnabled`                           | Boolean      | Enables AI for email subject line suggestions.                                                                                                |
| `ai.altTextEnabled`                             | Boolean      | Enables AI for generating image alt text.                                                                                                     |
| `mergeTagsEnabled`                              | Boolean      | Enables merge tags within the editor.                                                                                                         |
| `specialLinksEnabled`                           | Boolean      | Enables special links (e.g., unsubscribe, profile update) within the editor.                                                                  |
| `customFontsEnabled`                            | Boolean      | Enables custom fonts within the editor.                                                                                                       |
| `autoSaveApi.enabled`                           | Boolean      | Enables auto-saving of progress in the editor.                                                                                                |
| `autoSaveApi.url`                               | String (URL) | URL for the Auto-Save API endpoint.                                                                                                           |
| `autoSaveApi.username`                          | String       | Username for Auto-Save API authentication.                                                                                                    |
| `autoSaveApi.password`                          | String       | Password for Auto-Save API authentication.                                                                                                    |
| `autoSaveApiV2.enabled`                         | Boolean      | Enables notifications of changes in the editor V2.                                                                                            |
| `autoSaveApiV2.url`                             | String (URL) | URL for the Auto-Save API V2 endpoint.                                                                                                        |
| `autoSaveApiV2.username`                        | String       | Username for Auto-Save API V2 authentication.                                                                                                 |
| `autoSaveApiV2.password`                        | String       | Password for Auto-Save API V2 authentication.                                                                                                 |
| `autoSaveEnabled`                               | Boolean      | Enables auto-saving in the editor V2.                                                                                                         |
| `undoEnabled`                                   | Boolean      | Enables undo/redo actions within the editor.                                                                                                  |
| `versionHistoryEnabled`                         | Boolean      | Enables version history feature within the editor.                                                                                            |
| `baseSubDomainSourcePath`                       | String       | Base subdomain source path for resources.                                                                                                     |
| `editorPermissionsApi.enabled`                  | Boolean      | Enables the Editor Permissions API.                                                                                                           |
| `editorPermissionsApi.url`                      | String (URL) | URL for the Editor Permissions API endpoint.                                                                                                  |
| `editorPermissionsApi.username`                 | String       | Username for Editor Permissions API authentication.                                                                                           |
| `editorPermissionsApi.password`                 | String       | Password for Editor Permissions API authentication.                                                                                           |
| `firstPartyExtensions.widgetsEnabled`           | Boolean      | Enables the AI Widgets panel in the editor V2 (default:`false`). See[Step 11](#step-11-configure-ai-widgets-for-v2-only).                  |
| `firstPartyExtensions.openaiApiKey`             | String       | OpenAI API key used by the AI Widgets chat. Never sent to the browser.                                                                         |
| `firstPartyExtensions.chatkitDomainPublicKey`   | String       | Public key from your OpenAI domain allowlist; lets ChatKit run on the domains where the editor is embedded. Used in the browser, not a secret.  |

### Step 3: Additional steps to configure Stripo Editor V2 (for V2 only)

#### Create TiDB Database

To create a TiDB database, please refer to the official documentation:

[Official TiDB Documentation](https://docs.pingcap.com/tidb/stable/quick-start-with-tidb/)

Or follow these steps for configuration after instances created for it:

##### Introduction

All IP addresses used in the TiDB section of this document are examples. Please use the internal addresses of your EC2 instances or virtual machines.

##### System Architecture

The TiDB cluster includes the following components:

- TiDB Server — processes SQL queries
- PD (Placement Driver) — metadata management
- TiKV — distributed key-value storage
- TiFlash — optional columnar storage for OLAP
- Monitoring Stack — Prometheus, Grafana, AlertManager

Current Configuration example:

- Number of nodes: 5
- IP addresses:
  - 172.31.12.1 (primary node + monitoring)
  - 172.31.12.2
  - 172.31.12.3
  - 172.31.12.4
  - 172.31.12.5
- Component distribution:
  - PD Servers: all 5 nodes
  - TiDB Servers: all 5 nodes
  - TiKV Servers: all 5 nodes
  - Monitoring: 172.31.12.1

##### Prerequisites and Preparation

System Requirements:

- OS: Linux (recommended Ubuntu 16.04+ / CentOS 7+)
- CPU: 4+ cores
- RAM: 8GB+
- Disk: SSD, 100GB minimum
- Network: Gigabit Ethernet

##### Required Software

```
# Install TiUP (TiDB deployment tool)
curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
source ~/.bashrc
# Install cluster component
tiup cluster
```

##### Server Setup:

- Create the tidb user
- Grant sudo privileges:

```
echo 'tidb ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tidb
```

- Generate SSH keys and copy to each server
- Disable SELinux and firewalld
- Set timezone to UTC
- Enable and start chronyd

##### System Parameters:

```
# /etc/sysctl.conf
net.core.somaxconn = 32768  
net.ipv4.tcp_syncookies = 0  
vm.swappiness = 0
```

```
# /etc/security/limits.conf
tidb soft nofile 1000000  
tidb hard nofile 1000000  
tidb soft stack 32768
```

##### Cluster Configuration

**topology.yaml**
(Contains full role distribution across nodes — PD, TiDB, TiKV, monitoring, Grafana, AlertManager)

This is an example of a working topology.yaml. You may only need to replace the example addresses with the actual internal addresses of your instances.

```yaml
global:
  user: tidb
  ssh_port: 22
  deploy_dir: /tidb-deploy
  data_dir: /DATA
  os: linux
  arch: amd64

monitored:
  node_exporter_port: 9100
  blackbox_exporter_port: 9115
  deploy_dir: /tidb-deploy/monitor-9100
  data_dir: /DATA/monitor-9100
  log_dir: /tidb-deploy/monitor-9100/log

server_configs:
  tidb:
    performance.txn-entry-size-limit: 125829120
    performance.txn-total-size-limit: 1000000000
  tikv:
    raftstore.raft-entry-max-size: 64MB
  pd: {}
  grafana: {}

pd_servers:
  - host: 172.31.12.1
    name: pd-1
  - host: 172.31.12.2
    name: pd-2
  - host: 172.31.12.3
    name: pd-3
  - host: 172.31.12.4
    name: pd-4
  - host: 172.31.12.5
    name: pd-5

tidb_servers:
  - host: 172.31.12.1
  - host: 172.31.12.2
  - host: 172.31.12.3
  - host: 172.31.12.4
  - host: 172.31.12.5

tikv_servers:
  - host: 172.31.12.1
  - host: 172.31.12.2
  - host: 172.31.12.3
  - host: 172.31.12.4
  - host: 172.31.12.5

monitoring_servers:
  - host: 172.31.12.1
    port: 9090
    ng_port: 12020

grafana_servers:
  - host: 172.31.12.1
    port: 3000
    username: admin
    password: admin

alertmanager_servers:
  - host: 172.31.12.1
    web_port: 9093
    cluster_port: 9094
```

##### Deployment

- Availability check:

```
tiup cluster check topology.yaml --user tidb  
tiup cluster check topology.yaml --apply --user tidb
```

- Deploy the cluster:

```
tiup cluster deploy tidb-cluster v7.1.0 topology.yaml --user tidb  
tiup cluster start tidb-cluster  
tiup cluster display tidb-cluster
```

```
mysql -h 172.31.12.101 -P 4000 -u root  
SHOW DATABASES;  
SELECT tidb_version();
```

##### Backup

- Using BR (Backup & Restore):

```
tiup br backup full --pd "172.31.12.1:2379" --storage "local:///backup/full-$(date +%Y%m%d-%H%M%S)"
```

- Restore from backup:

```
tiup br restore full --pd "172.31.12.1:2379" --storage "local:///backup/full-yyyyMMdd-HHmmss"
```

Follow the step-by-step instructions to set up your database correctly.

#### Use AWS Aurora MySQL instead of TiDB (optional)

`coediting-core-service` stores email templates and patches. By default it uses TiDB, but it can use an **AWS Aurora MySQL** cluster instead. This is optional and affects only this one microservice — nothing else in your deployment changes.

Choose Aurora if you already run on AWS and prefer a managed database over maintaining a multi-node TiDB cluster yourself. If you pick Aurora, you can skip the whole [Create TiDB Database](#create-tidb-database) section above.

> **Note for existing installations:** this switch only changes where the service reads and writes. The Helm chart does not copy any data, so templates already stored in TiDB will not appear in Aurora. If you are switching a live installation rather than setting up a new one, contact the Stripo team to plan the data migration first.

**Requirements**

- Aurora MySQL **8.0 or higher** (Stripo tests on 8.4), reachable from your Kubernetes cluster
- The cluster security group must allow inbound TCP `3306` from your Kubernetes nodes
- TLS is enabled by the `tls` block shown in Step D. Keep that block: without it the service connects **without encryption** and does so silently, with no error in the logs

##### Step A. Configure the cluster parameters

Aurora defaults are not suitable for email templates: templates can be large, and the editor requires case-insensitive UTF-8. Create custom parameter groups with the values below — otherwise you may hit `Packet for query is too large` errors or incorrect sorting.

| Parameter | Value | Set in |
| ---------------------- | --------------------- | ------------------------------ |
| `character_set_server` | `utf8mb4` | DB **cluster** parameter group |
| `collation_server` | `utf8mb4_unicode_ci` | DB **cluster** parameter group |
| `time_zone` | `UTC` | DB **cluster** parameter group |
| `max_allowed_packet` | `268435456` (256 MB) | DB **instance** parameter group |

> MySQL 8 defaults `collation_server` to `utf8mb4_0900_ai_ci`, so it must be overridden explicitly.

##### Step B. Create the database and the user

Connect to the cluster **writer** endpoint and run:

```sql
CREATE DATABASE stripo_coediting_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'coediting_user'@'%' IDENTIFIED BY '<strong-password>' REQUIRE SSL;
GRANT CREATE, DROP, ALTER, INDEX, REFERENCES,
      INSERT, SELECT, UPDATE, DELETE,
      CREATE TEMPORARY TABLES, LOCK TABLES,
      CREATE VIEW, SHOW VIEW, EXECUTE, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER
  ON stripo_coediting_db.* TO 'coediting_user'@'%';
FLUSH PRIVILEGES;
```

Schema-level privileges (`CREATE`, `ALTER`, `INDEX`) are required — the service manages its own tables.

##### Step C. Create the CA certificate ConfigMap

The service verifies the Aurora server certificate, so it needs the Amazon RDS root CA bundle. Download it and create a ConfigMap in the **same namespace** as your Stripo services:

```shell
curl -o global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
kubectl create configmap coediting-core-service-rds-ca -n <namespace> --from-file=global-bundle.pem
```

The key inside the ConfigMap must be named exactly `global-bundle.pem` — the command above does that for you. The Helm chart mounts it into the pod at `/etc/ssl/rds/global-bundle.pem`; you do not need to configure that path anywhere.

> This is the official public AWS RDS root CA bundle. It contains no secrets and is the same file for every AWS account and region.

##### Step D. Switch the service to Aurora

In `charts/coediting-core-service.yaml`, set `dbType` to `AuroraMySQL` and fill in the `auroraMysql` block:

```yaml
settings:
  dbType: AuroraMySQL

  auroraMysql:
    host: <cluster-writer-endpoint>   # e.g. my-cluster.cluster-ab12cd.eu-west-1.rds.amazonaws.com
    port: 3306
    username: coediting_user
    password: <strong-password>
    databaseName: stripo_coediting_db
    tls:
      mode: verify_identity
      caBundleConfigMap: coediting-core-service-rds-ca   # ConfigMap name from Step C
```

Notes:

- `dbType` is **case-sensitive**: it must be exactly `AuroraMySQL` or `TiDB`. It is the only switch you need — the chart puts the matching connection settings into the pod and sets the service level `DB_READ_TARGET` and `DB_WRITE_TARGETS` variables for you.
- You can leave the existing `tiDb` block in the file. While `dbType` is `AuroraMySQL` it is ignored, which makes switching back a one-line change.
- The `auroraMysql` block also accepts optional connection pool settings — `openConnections`, `idleConnections`, `connMaxLifetime`, `reconnectInterval` and `connectTimeout`. Leave them out unless you have a reason to tune the pool: the service defaults to 100 open and 25 idle connections, the same values it uses for TiDB.

##### Step E. Apply and verify

Deploy as usual with the script from [Step 8](#step-8-deploy-microservices), or directly:

```shell
helm upgrade --install coediting-core-service stripo/go-template-service \
  -f charts/coediting-core-service.yaml --namespace <namespace>
kubectl rollout status deploy/coediting-core-service --namespace <namespace>
```

Confirm the pod really received the Aurora settings:

```shell
kubectl exec deploy/coediting-core-service -n <namespace> -- \
  env | grep -E 'DB_READ_TARGET|DB_WRITE_TARGETS|AURORA_MYSQL_HOST|AURORA_MYSQL_TLS_CA_FILE'
```

Expected output — and **no** `TIDB_*` variables at all:

```
DB_READ_TARGET=AuroraMySQL
DB_WRITE_TARGETS=AuroraMySQL
AURORA_MYSQL_HOST=<your cluster endpoint>
AURORA_MYSQL_TLS_CA_FILE=/etc/ssl/rds/global-bundle.pem
```

##### Switching back to TiDB

Set `dbType` back to `TiDB`, keep the `tiDb` block filled in, and run the same upgrade command. The `auroraMysql` block and the CA ConfigMap can stay in place — they are ignored.

##### Troubleshooting

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| Pod stuck in `ContainerCreating`, event `configmap "coediting-core-service-rds-ca" not found` | ConfigMap from Step C is missing, misspelled, or in another namespace | Create it in the same namespace as the service |
| TLS errors such as `x509: certificate signed by unknown authority` | The key inside the ConfigMap is not `global-bundle.pem`, or the file was truncated on download | Recreate the ConfigMap with `--from-file=global-bundle.pem` |
| `helm upgrade` fails with `settings.dbType must be "TiDB" or "AuroraMySQL"` | `dbType` is misspelled — the value is case-sensitive | Set it to exactly `AuroraMySQL` and upgrade again |
| `helm upgrade` fails with `settings.auroraMysql is not set` | `dbType` is `AuroraMySQL` but the `auroraMysql` block is missing | Fill in the block from Step D |
| No `AURORA_MYSQL_*` variables in the pod and `TIDB_*` variables are still present, upgrade reported no error | An old cached chart version (before 1.3.0) was installed | Run `helm repo update stripo` and upgrade again |
| `Access denied for user 'coediting_user'` | Grants are missing, or the user was created without `REQUIRE SSL` while TLS is enforced | Re-run Step B |
| `Packet for query is too large` | `max_allowed_packet` left at its default value | Apply Step A and reboot the instance |

#### Create NATS Account

To create a NATS account, please follow the official documentation provided by NATS. The official guide will walk you through the process step-by-step to ensure your account is set up correctly.

#### Create an AWS ElastiCache Cluster

To create an AWS ElastiCache cluster, please refer to the official AWS documentation for detailed instructions and best practices.

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

### Step 6: Configure Docker Image Access

#### Configure Stripo Docker Hub Access

1. **Request Access to Stripo Docker Hub Repository**: Contact the Stripo team and request them to add your Docker Hub account to the Stripo Docker Hub repository.
2. **Login to Docker Hub**: Ensure you are logged into your Docker Hub account.
3. **Generate Base64 Hash from Docker Configuration**:

   - Navigate to your Docker configuration directory:
     ```shell
     cd ~/.docker
     ```
   - Create a Base64 hash of your `config.json` file:
     ```shell
     cat config.json | base64
     ```
4. **Update Secret Token**:

   - Replace `{{ YOUR_SECRET_TOKEN_SHOULD_BE_HERE }}` inside `./resources/secrets/docker-hub-secret.yaml` with the Base64 hash obtained from the previous step.

#### Configure Amazon ECR Access (Alternative to Docker Hub)

If you prefer to use Amazon ECR instead of Docker Hub for hosting Docker images, you can configure cross-account access to your ECR repository. This section provides instructions for both the ECR repository owner and the client account.

##### 1: Account EKS Configuration

**a. Create IAM Role with ECR Access**

In the client account, create an IAM role with a policy that allows access to your ECR repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

**b. Bind Role to Kubernetes ServiceAccount (IRSA)**

1. Create an IAM role and bind it to the Kubernetes service account using IRSA:

```bash
eksctl create iamserviceaccount \
  --name <SERVICE_ACCOUNT_NAME> \
  --namespace <NAMESPACE> \
  --cluster <EKS_CLUSTER_NAME> \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/<POLICY_NAME> \
  --approve \
  --role-name <IAM_ROLE_NAME>
```

2. Specify this serviceAccount in your deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: <SERVICE_ACCOUNT_NAME>
```

##### 2: Using ECR Images

In your deployment, the client can reference your ECR image as follows:

```yaml
containers:
  - name: app
    image: <YOUR_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<REPO_NAME>:<TAG>
```

**Important**: Ensure that kubectl and eksctl are configured to work with the correct cluster and context.

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

### Step 8: Deploy Microservices

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

To enable Stripo editor v2, please uncomment the corresponding section in the `manage_charts.sh` file.

```
# Uncomment to run Stripo editor V2 microservices
```

### Step 9: Configure Countdown Timer

1. **Retrieve Timer Password**

   Begin by obtaining the timer password from the `stripo-timer-api.yaml` file:

   ```bash
   timer.password=${TAKE_THIS_PASSWORD_STRING}
   ```
2. **Generate Password Hash**

   To generate a password hash, follow the steps below. First, install the necessary Python dependencies, then use them to create the password hash. Make sure to replace `${YOUR_PASSWORD}` with the actual password retrieved from `stripo-timer-api.yaml`:

   ```shell
   # Install Python dependencies
   pip3 install bcrypt 

   # Generate password hash
   python3 ./resources/countdowntimer/encode.py ${YOUR_PASSWORD}

   ```
3. **Update the `countdowntimer` Service Database**

   With the generated password hash, update the `system_user` table in your database by executing the following SQL query. Replace `${YOUR_PASSWORD_HASH}` with the hash generated in the previous step:

   ```sql
   UPDATE "system_user" 
   SET password = '${YOUR_PASSWORD_HASH}'
   WHERE username = 'Admin';
   ```

### Example

If your password is `secret`, follow the steps below:

```bash
Generate password hash:
-> python3 encode.py secret
<- $2b$12$QNSzmdqZB/MkTZSkiI/RlOn0n0dQABAjZFVYIeIjnvF2pz19vWmfq

Run the following SQL query to update the password hash in the database:
UPDATE "system_user" SET password = '$2b$12$QNSzmdqZB/MkTZSkiI/RlOn0n0dQABAjZFVYIeIjnvF2pz19vWmfq' WHERE username = 'Admin';

Update the stripo-timer-api.yaml file:
timer.username=Admin
timer.password=secret
```

### Step 10: Configure CDN for Static Resources

#### Stripo Editor V1

Stripo's static files are hosted on their servers and can be accessed via the following URL: [https://plugins.stripo.email/static/latest/stripo.js](https://plugins.stripo.email/static/latest/stripo.js). To boost the loading speed of these source files, you have the option to set up your own Content Delivery Network (CDN) and host the editor's static files there.

The necessary static files for the Stripo Editor are available in Stripo's GitHub repository: [GitHub Repository](https://github.com/ardas/stripo-plugin/tree/master/Versions). To access the latest release, navigate to the folder containing the most recent editor version. This folder houses the latest release of static files. You may copy these files and save them on your server.

Ensure you maintain the same directory structure as found in the repository, meaning the organization and encapsulation of the files should remain unchanged. Once you've transferred the files to your server, you need to update the URL for the `stripo.js` script from the Stripo-hosted version to your server's location. For example: `https://your-server.com/path-to-static/stripo.js`.

Please note while caching these files on your server is beneficial, the `stripo.js` script itself should not be cached. This practice ensures you are always using the latest version of the script.

#### Stripo Editor V2

You can find detailed instructions [here](https://plugin.stripo.email/hosting-stripo-editor-files-on-your-own-cdn).

### Step 11: Configure AI Widgets (for V2 only)

**AI Widgets** add an assistant panel to the Stripo Editor V2. Instead of filling in a form, the user picks a widget — an interactive block such as a scratcher or a poll — and configures it in a chat conversation. The feature is available in **Stripo Editor V2 only** and requires two additional microservices:

| Service                              | Responsibility                                                                                                    |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `ui-editor-widgets-registry-service` | Stores widget definitions (markup, icons, translations, AI prompts) and syncs the shared widget catalog from Stripo. |
| `convo-core-chat-server`             | Runs the AI conversation that generates and edits the widget content.                                             |

Neither service is public. The editor reaches both through `stripo-plugin-api-gateway`, which also checks that the feature is enabled for your plugin and injects the OpenAI key and the chat authentication token.

Both services are already listed in `./resources/helm/manage_charts.sh` and are installed together with the rest of the stack in [Step 8](#step-8-deploy-microservices).

#### Create the Databases

Each service needs its own PostgreSQL database. Both are already included in `./resources/postgres/01_create_databases.sh` (see [Step 1](#step-1-create-postgresql-databases)):

| Service                              | Database                                   | User                       |
| ------------------------------------ | ------------------------------------------ | -------------------------- |
| `ui-editor-widgets-registry-service` | `stripo_plugin_local_widgets_registry`     | `user_widgets_registry`    |
| `convo-core-chat-server`             | `stripo_plugin_local_widgets_chat_history` | `user_widgets_chat_history` |

Both services create and upgrade their own schema on startup — Flyway for the registry service, Alembic for the chat server — so the database user needs `CREATE` on the `public` schema. The script from Step 1 already grants it. PostgreSQL 13 or higher is required: the registry service uses `gen_random_uuid()`.

#### Configure the Widgets Registry Service

Set the database connection and the shared catalog sync in `charts/ui-editor-widgets-registry-service.yaml`:

```yaml
configmap:
  enabled: true
  extraScrapeConfigs:
    application.properties: |
      logging.level.root=INFO
      spring.datasource.url=jdbc:postgresql://postgres:5432/stripo_plugin_local_widgets_registry
      spring.datasource.username=user_widgets_registry
      spring.datasource.password=password_widgets_registry
      shared.modules.auth.client.api-key=my-api-key
```

| Property                             | Description                                                                                                                                                     |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `shared.modules.auth.client.api-key` | The key issued by the Stripo team (see [Enable the Shared Widget Catalog](#enable-the-shared-widget-catalog)).                                                    |
| `shared.modules.sync.interval`       | Optional. How often to poll the owner, default `60m`. Either leave it out or give a valid duration — an empty value breaks the sync scheduler.                    |

The service listens on port `8080` and exposes health probes on `8081`, like the other Java microservices.

#### Configure the Chat Server

`convo-core-chat-server` is a Python service and is configured **through environment variables only** — it does not read the properties file that the chart mounts. Set them in the `env` section of `charts/convo-core-chat-server.yaml`:

```yaml
env:
  - name: AUTH_PROVIDER_HOST
    value: http://stripo-plugin-api-gateway:8080/api/v1/convo/inner/
  - name: DATABASE_URL
    value: postgresql://user_widgets_chat_history:password_widgets_chat_history@postgres:5432/stripo_plugin_local_widgets_chat_history
  - name: STRIPO_WIDGET_PROMPT_ENDPOINT
    value: http://ui-editor-widgets-registry-service:8080/api/v1/widgets/{widgetId}/prompt
```

| Variable                        | Description                                                                                                                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AUTH_PROVIDER_HOST`            | Where the chat server validates the token issued by the api-gateway. It appends `v1/auth/{token}/user-info` to this value, so keep the `/api/v1/convo/inner/` path and the trailing slash. |
| `DATABASE_URL`                  | Chat history database. **Verify this one carefully:** if it is missing the service still starts and reports healthy, but keeps conversations in memory and loses them on every restart.  |
| `STRIPO_WIDGET_PROMPT_ENDPOINT` | Where the chat server loads the AI prompt of a widget. Keep the literal `{widgetId}` placeholder — the service substitutes it per request.                                                |

The remaining settings (`CONSOLE_LOG_AS_JSON`, `CONFIG_SERVICE_REQUIRED`, `AUTH_PROVIDER_USE_MOCK`, `USE_PERSISTED_STORE`, `AUTO_MIGRATE`, `LANGFUSE_ENABLED`) come from the chart defaults and are already correct for a self-hosted installation. Override them through `settings.*` only if you have a reason to:

```yaml
settings:
  profile: PLUGINS
  autoMigrate: true          # run Alembic migrations on startup
```

> **Do not set `OPENAI_API_KEY` on this service.** The key is taken from the plugin configuration and forwarded per request by the api-gateway, which keeps every plugin on its own key. A key left in the environment is used as a fallback and, if you also enable Langfuse tracing, can send conversation content to the wrong OpenAI account.

The service listens on port `8000` and answers health probes at `/api/v1/health`.

#### Route the API Gateway to Both Services

The gateway does not discover the new services on its own. Add both URLs to the `configmap` section of `charts/stripo-plugin-api-gateway.yaml` — without them every widget request fails, even though both pods are running:

```yaml
      service.widgetsregistry.url=http://ui-editor-widgets-registry-service:8080
      service.convo.url=http://convo-core-chat-server:8000
```

Note the different ports: `8080` for the registry service, `8000` for the chat server.

The gateway signs the chat authentication token with `jwt.secret.apiKeyV3`, which is already part of your gateway configuration. No additional secret is needed.

#### Enable the Shared Widget Catalog

The widgets themselves are built and published by Stripo, then pulled into your installation by a background sync: your registry service runs in **follower** mode and polls the Stripo-hosted registry (the **owner**) for the published catalog. Without this sync the widgets panel opens with an empty list.

1. **Request an API key from the Stripo team**, giving them a name for your installation. Stripo registers your installation as a follower on their side and sends you the key.
2. Put the key into `shared.modules.auth.client.api-key` as shown in [Configure the Widgets Registry Service](#configure-the-widgets-registry-service) and upgrade the service.
3. The first sync runs as soon as the service is ready, and then repeats every `shared.modules.sync.interval` (default 60 minutes). A successful run logs `Synchronizing shared widgets` followed by `Shared widgets synchronized`. When nothing has changed on the owner side, the request returns `204 No Content` and the log stays quiet.

Synced widgets are managed entirely by the sync — a widget removed from the Stripo catalog is removed from your installation on the next run.

#### Enable Widgets for Your Plugin

Widgets are disabled by default. Enable them in the `config` JSON of the `plugins` table in the `stripo-plugin-details-service` database (see [Step 2](#step-2-insert-required-data-into-the-postgresql-database)):

```json
{
  ...,
  "firstPartyExtensions": {
    "widgetsEnabled": true,
    "openaiApiKey": "YOUR_OPEN_AI_API_KEY",
    "chatkitDomainPublicKey": "YOUR_DOMAIN_PUBLIC_KEY"
  }
}
```

- `widgetsEnabled` — the main switch. While it is `false`, the api-gateway answers `403` to every widget and chat request and the panel never appears in the editor.
- `openaiApiKey` — your OpenAI API key. The gateway reads it per request and passes it to the chat server as a header; it is never exposed to the browser. Without it the conversation fails with `400 OpenAI Api Key is missing`.
- `chatkitDomainPublicKey` — the OpenAI **domain public key** that lets the AI Assistant open on your domains (how to get it — below). Unlike `openaiApiKey` it is not a secret: it is used in the browser only to verify the domain and gives no access to your OpenAI account.

**How to get the domain public key.** The AI Assistant in the widgets panel is powered by OpenAI ChatKit. For security reasons, ChatKit runs only on domains verified by OpenAI, so every domain where you embed the editor with the plugin must be added to the domain allowlist of your OpenAI organization:

1. Open the [Domain allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist) page in your OpenAI organization settings (Settings → Security → Domain allowlist).
2. Add every domain where the editor with the plugin is embedded, including test and staging domains.
3. Copy the generated public key — it starts with `domain_pk_` — and set it as `chatkitDomainPublicKey`.

> **Warning:** without a valid key, the AI Assistant won't open in the widgets panel on your domain. Widgets already added to sent emails keep working.

You can apply all three values to an already registered plugin with the following SQL (the `config` column stores JSON as text, so it is cast to `jsonb` and back; existing `firstPartyExtensions` keys are preserved):

```sql
UPDATE plugins
SET config = (
    config::jsonb || jsonb_build_object(
        'firstPartyExtensions',
        COALESCE(config::jsonb -> 'firstPartyExtensions', '{}'::jsonb) || jsonb_build_object(
            'widgetsEnabled', true,
            'openaiApiKey', 'YOUR_OPEN_AI_API_KEY',
            'chatkitDomainPublicKey', 'YOUR_DOMAIN_PUBLIC_KEY'
        )
    )
)::text
WHERE plugin_id = 'YOUR_PLUGIN_ID';
```

The change takes effect immediately: the gateway reads the plugin configuration on every request, so no restart is needed.

#### Allow Long-Lived Streaming Responses

The AI answer is streamed to the browser as Server-Sent Events through the api-gateway. A single answer can take several minutes, and the gateway keeps the stream open for up to 300 seconds. Default NGINX Ingress settings break this in two ways: the response is buffered, so nothing appears until the answer is complete, and the connection is closed after 60 seconds.

Add these annotations to the `stripo-plugin-api-gateway` ingress in `charts/stripo-plugin-api-gateway.yaml`:

```yaml
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "310"
```

If you terminate traffic on another proxy, load balancer or CDN in front of the cluster, apply the equivalent settings there as well.

#### Host the Widgets Panel Bundle

If you host the editor static files on your own CDN ([Step 10](#step-10-configure-cdn-for-static-resources)), the widgets panel bundle must be copied together with the rest of the release and keep its relative path:

```
{YOUR_CDN_ADDRESS}/UIEditor.js
{YOUR_CDN_ADDRESS}/fpe/widgets/loader.js   <-- must be present
```

The editor derives the loader address from the location of `UIEditor.js`, so `fpe/widgets/` has to sit next to it. If the file is missing, the panel silently fails to load.

The chat interface is loaded at runtime from the OpenAI CDN (`https://cdn.platform.openai.com`). If the page that embeds the editor enforces a Content Security Policy, allow that host in `script-src` and `connect-src`. ChatKit also runs only on domains verified by OpenAI — every domain where the editor is embedded must be in your OpenAI domain allowlist and the generated key must be set as `chatkitDomainPublicKey` (see [Enable Widgets for Your Plugin](#enable-widgets-for-your-plugin)), otherwise the chat area stays blank while the rest of the panel works.

#### Verify the Setup

Open an email in the editor and check that the widgets panel lists widgets and that a message in the chat produces a streamed answer. If something is wrong:

| Symptom                                                                | Cause                                                                                         | Fix                                                                                       |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| The widgets panel does not appear in the editor at all                 | `firstPartyExtensions.widgetsEnabled` is not set in the plugin configuration                | Update the plugin `config` JSON                                                           |
| Widget requests return `403`                                         | Same as above — the gateway rejects the request before it reaches the registry service        | Update the plugin `config` JSON                                                           |
| Widget requests return `503` or time out                             | `service.widgetsregistry.url` / `service.convo.url` are empty in the gateway configuration    | Add both URLs and upgrade the gateway                                                     |
| The panel loads but the widget list is empty                           | The shared catalog has not been synced                                                        | Check `shared.modules.*`, look for `Shared widgets synchronized` in the registry service logs |
| Registry logs `Owner shared widgets request failed with status 401`  | The API key does not match the one registered on the Stripo side                              | Re-check `shared.modules.auth.client.api-key` with the Stripo team                         |
| The chat replies `400 OpenAI Api Key is missing`                     | `firstPartyExtensions.openaiApiKey` is empty in the plugin config                            | Add the key to the plugin `config` JSON                                                   |
| The panel and the widget list work, but the AI Assistant does not open | The embedding domain is not verified by OpenAI: `chatkitDomainPublicKey` is missing, or the domain is not in the allowlist | Add the domain to your OpenAI domain allowlist and set the generated key in the plugin `config` JSON |
| Every chat request fails with `503`, although the pod is healthy     | `AUTH_PROVIDER_HOST` is not set or unreachable — the chat server cannot validate the token     | Check the variable and that the gateway is reachable from the chat server pod              |
| The answer arrives all at once at the end, or the stream breaks off    | The ingress buffers the response or closes the connection too early                           | Apply the annotations from [Allow Long-Lived Streaming Responses](#allow-long-lived-streaming-responses) |
| Chat history disappears after a restart                                | `DATABASE_URL` is not set — the chat server fell back to in-memory storage                    | Set `DATABASE_URL` and restart the service                                                |

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
   script.src = '{YOUR_CDN_ADDRESS}/stripo/stripo.js';
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
   script.src = '{STATIC_HOSTING_ADDRESS}/static/UIEditor.js';
   ```
3. Add these additional parameters to the plugin configuration:

   ```js
   window.Stripo.init({
       ..., // your initialization params
       apiBaseUrl: 'https://{SERVICE_ADDRESS}/api/v1',
       coeditingBasePath: 'https://{SERVICE_ADDRESS}/coediting',
       coeditingWsUrl: 'wss://{SERVICE_ADDRESS}/coediting/ws/coediting',
       ...
   });
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

   You need to retrieve {YOUR_PLUGIN_ID} and {YOUR_SECRET_KEY} from the 'plugins' table within the `stripo-plugin-details-service` microservice database. These values are located in the 'plugin_id' and 'secret_key' columns.
5. Open `index.html` in your browser.

## Migration Guide

See docs [here](https://github.com/stripoinc/stripo-plugins-helm-example/blob/main/docs/migration.md).
