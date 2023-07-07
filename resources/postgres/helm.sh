#helm -n stripo install postgres oci://registry-1.docker.io/bitnamicharts/postgresql --set global.postgresql.auth.postgresPassword=secret --set global.postgresql.auth.username=example --set global.postgresql.auth.password=secret --set image.tag=14
helm -n stripo upgrade --install postgres oci://registry-1.docker.io/bitnamicharts/postgresql -f values.yaml
