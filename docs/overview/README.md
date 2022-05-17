# Stripo Plugin Infrastructure Overview
On the high level Stripo plugin infrastructure looks like:

<img src="general_overview.png" alt="High level infrastructure scheme" style="width: 50%"/>

Plugin infrastructure consists of 19 microservices that are wrapped into the docker
containers/images. These images are hosted in the Stripo Docker Hub Repository to
which partners can get the read-only access (just to be able to download the images with
needed particular versions) once they’re on Enterprise pricing plan and intend to host Plugin
Backend on their server.
Some microservices have their own Databases (PostgreSQL) that may be deployed
in any place. The connection between services and their DB are specified via properties.
Infrastructure also provides you with the ability to send logs from every microservice to ELK
stack. ELK stack can be also deployed in any place. The url to ELK can be specified via properties.

The list of actual microservices and their responsibilities are described in the table below:

| Service name | Description | Is public for web |
| ----------- | ----------- | ----------- | 
| Header      | Title       || 
| Paragraph   | Text        || 


MICROSERVICES SCHEMA
