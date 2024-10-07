#!/bin/bash

# Connection parameters
HOST="localhost"
PORT="5432"
USER="postgres"

# Array with database and user information
databases_users=(
  "stripo_plugin_local_bank_images user_bank_images password_bank_images"
  "stripo_plugin_local_custom_blocks user_custom_blocks password_custom_blocks"
  "stripo_plugin_local_documents user_documents password_documents"
  "stripo_plugin_local_drafts user_drafts password_drafts"
  "stripo_plugin_local_html_gen user_html_gen password_html_gen"
  "stripo_plugin_local_plugin_details user_plugin_details password_plugin_details"
  "stripo_plugin_local_plugin_stats user_plugin_stats password_plugin_stats"
  "stripo_plugin_local_securitydb user_securitydb password_securitydb"
  "stripo_plugin_local_timers user_timers password_timers"
  "countdowntimer user_countdowntimer password_countdowntimer"
  "ai_service user_ai_service password_ai_service"
)

# Step 1: Create databases, users, and assign privileges
for entry in "${databases_users[@]}"; do
  IFS=' ' read -r db user password <<< "$entry"

  echo "Creating database: $db and user: $user"

  # Create the database
  psql -h $HOST -p $PORT -U $USER -c "CREATE DATABASE $db;"

  # Create the user
  psql -h $HOST -p $PORT -U $USER -c "CREATE USER $user WITH PASSWORD '$password';"

  # Grant all privileges to the user on the database
  psql -h $HOST -p $PORT -U $USER -c "GRANT ALL PRIVILEGES ON DATABASE $db TO $user;"

  echo "Database $db and user $user created with privileges."
done

# Step 2: Apply privileges for all existing and future tables in the public schema for all databases
databases=$(psql -h $HOST -p $PORT -U $USER -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

# Execute commands for each database
for db in $databases; do
  echo "Applying privileges to database: $db"

  # Grant all privileges on all existing tables in the public schema
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;"

  # Allow object creation in the public schema
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT CREATE ON SCHEMA public TO PUBLIC;"

  # Set default privileges for all future tables
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO PUBLIC;"

  echo "Privileges applied to $db"
done

# Also execute commands for the postgres database
psql -h $HOST -p $PORT -U $USER -d postgres -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;"
psql -h $HOST -p $PORT -U $USER -d postgres -c "GRANT CREATE ON SCHEMA public TO PUBLIC;"
psql -h $HOST -p $PORT -U $USER -d postgres -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO PUBLIC;"

echo "Privileges applied to database: postgres"
