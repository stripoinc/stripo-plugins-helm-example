#!/bin/bash
# This script creates databases, IAM-authenticated users, assigns privileges, and configures access for Aurora PostgreSQL.
# All users use rds_iam role - no passwords, auth via AWS IAM token.
#
# Prerequisites:
# - IAM auth enabled on Aurora cluster
# - PGSSLMODE=require (Aurora enforces SSL via rds.force_ssl=1)
# - IAM policy with rds-db:connect for each user (printed at the end)

# Connection parameters
HOST="${PGHOST:?PGHOST required (Aurora cluster endpoint)}"
PORT="${PGPORT:-5432}"
USER="${PGUSER:-postgres}"
PASSWORD="${PGPASSWORD:?PGPASSWORD required}"

# Export the password and SSL mode to avoid prompting during execution
export PGPASSWORD=$PASSWORD
export PGSSLMODE="${PGSSLMODE:-require}"

# Array with database and user information
databases_users=(
  # The format is: "database_name user_name"
  # Each line represents a database with a user for that specific database.
  # All users authenticate via IAM token (rds_iam role) - no passwords needed.
  "ai_service user_ai_service"
  "countdowntimer user_countdowntimer"
  "stripo_plugin_local_bank_images user_bank_images"
  "stripo_plugin_local_custom_blocks user_custom_blocks"
  "stripo_plugin_local_documents user_documents"
  "stripo_plugin_local_drafts user_drafts"
  "stripo_plugin_local_html_gen user_html_gen"
  "stripo_plugin_local_plugin_details user_plugin_details"
  "stripo_plugin_local_plugin_stats user_plugin_stats"
  "stripo_plugin_local_securitydb user_securitydb"
  "stripo_plugin_local_timers user_timers"
)

# Step 1: Create databases, users, grant rds_iam role, and assign privileges
# The loop iterates over the list of databases and users, creating each database and user in PostgreSQL.
for entry in "${databases_users[@]}"; do
  # Splitting each entry into database and user.
  IFS=' ' read -r db user <<< "$entry"

  echo "Creating database: $db and user: $user (IAM auth)"

  # Create the database (each CREATE DATABASE must be a separate psql call - cannot run inside a transaction)
  psql -h $HOST -p $PORT -U $USER -c "CREATE DATABASE $db;" 2>/dev/null || true

  # Create the user with LOGIN capability (no password - IAM token will be used)
  psql -h $HOST -p $PORT -U $USER -c "CREATE USER $user WITH LOGIN;" 2>/dev/null || true

  # Grant rds_iam role to enable IAM token authentication
  # IMPORTANT: Once rds_iam is granted, regular password auth will NOT work for this user.
  # Aurora uses PAM auth for rds_iam users - they MUST authenticate with an IAM token.
  psql -h $HOST -p $PORT -U $USER -c "GRANT rds_iam TO $user;" 2>/dev/null || true

  # Grant all privileges to the user on the newly created database
  psql -h $HOST -p $PORT -U $USER -c "GRANT ALL PRIVILEGES ON DATABASE $db TO $user;"

  echo "Database $db and user $user created with IAM auth privileges."
done

# Step 2: Apply privileges for all existing and future tables in the public schema for the specific user in their own database only
# This section ensures that proper privileges are set for all current and future tables in the databases.
for entry in "${databases_users[@]}"; do
  IFS=' ' read -r db user <<< "$entry"

  echo "Applying privileges to database: $db for user: $user"

  # Grant usage and create on schema public for the specific user
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT USAGE, CREATE ON SCHEMA public TO $user;"

  # Grant all privileges on all existing tables in the public schema for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;"

  # Grant all privileges on all existing sequences in the public schema for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $user;"

  # Set default privileges for future tables for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $user;"

  # Set default privileges for future sequences for the specific user in their own database
  psql -h $HOST -p $PORT -U $USER -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $user;"

  echo "Privileges applied to $db for user: $user"
done

# Step 3: Print IAM policy resources for reference
# These ARNs must be added to the IAM policy with rds-db:connect action.
CLUSTER_RESOURCE_ID="${CLUSTER_RESOURCE_ID:-<YOUR_CLUSTER_RESOURCE_ID>}"
AWS_ACCOUNT="${AWS_ACCOUNT:-<YOUR_AWS_ACCOUNT>}"
AWS_REGION="${AWS_REGION:-eu-west-1}"

echo ""
echo "Privileges applied to all databases for their respective users"
echo ""
echo "IAM policy resources (add to rds-db:connect policy):"
for entry in "${databases_users[@]}"; do
  IFS=' ' read -r db user <<< "$entry"
  echo "  arn:aws:rds-db:${AWS_REGION}:${AWS_ACCOUNT}:dbuser:${CLUSTER_RESOURCE_ID}/$user"
done
echo ""
echo "Get CLUSTER_RESOURCE_ID:"
echo "  aws rds describe-db-clusters --db-cluster-identifier <name> --query 'DBClusters[0].DbClusterResourceId' --output text"
