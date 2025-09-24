#!/bin/bash
# This script creates databases, users, assigns privileges, and configures access for a specific user to their database only.

# Connection parameters
HOST="localhost"
PORT="5432"
USER="postgres"
PASSWORD="your_postgres_password"  # Password for the PostgreSQL superuser.

# Export the password to avoid prompting for it during execution
export PGPASSWORD=$PASSWORD  # This exports the password into the environment variable `PGPASSWORD`, which `psql` will use automatically when connecting.

# Array with database and user information
databases_users=(
  # The format is: "database_name user_name user_password"
  # Each line represents a database with a user and password for that specific database.
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
# The loop iterates over the list of databases and users, creating each database and user in PostgreSQL.
for entry in "${databases_users[@]}"; do
  # Splitting each entry into database, user, and password.
  IFS=' ' read -r db user password <<< "$entry"

  echo "Creating database: $db and user: $user"  # Informative message to indicate which database and user are being created.

  # Create the database
  psql -h $HOST -p $PORT -U $USER -c "CREATE DATABASE $db;"  # This creates the database using `psql`. The `-c` flag allows executing SQL commands.

  # Create the user
  psql -h $HOST -p $PORT -U $USER -c "CREATE USER $user WITH PASSWORD '$password';"  # This creates the user and assigns a password.

  # Grant all privileges to the user on the newly created database
  psql -h $HOST -p $PORT -U $USER -c "GRANT ALL PRIVILEGES ON DATABASE $db TO $user;"  # This gives the user full access (read, write, modify) to the database.

  echo "Database $db and user $user created with privileges."  # Confirmation message after the database and user are set up.
done

# Step 2: Apply privileges for all existing and future tables in the public schema for the specific user in their own database only
# This section ensures that proper privileges are set for all current and future tables in the databases.
for entry in "${databases_users[@]}"; do
  IFS=' ' read -r db user password <<< "$entry"

  echo "Applying privileges to database: $db for user: $user"

  # Grant all privileges on all existing tables in the public schema for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;"
  # This grants full privileges on all existing tables in the schema `public` to the specific user only in their own database.

  # Allow the specific user to create objects in the public schema of their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT CREATE ON SCHEMA public TO $user;"
  # This allows the specific user to create new tables and objects in the schema `public` of their own database.

  # Set default privileges for future tables for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $user;"
  # This sets default privileges, so any future tables created in the schema `public` will automatically have full privileges for the specific user in their own database.

  # Grant privileges to sequences for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $user;"
  # This grants usage and select privileges on all sequences in the public schema to the specific user in their own database.

  # Set default privileges for future sequences for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO $user;"
  # This sets default privileges, so any future sequences created in the schema `public` will automatically have usage and select privileges for the specific user in their own database.

  echo "Privileges applied to $db for user: $user"  # Confirmation message indicating that privileges have been applied to the current database for the specific user.
done

echo "Privileges applied to all databases for their respective users"
