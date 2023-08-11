#!/bin/sh

# readonly user
psql -c "CREATE USER readonly WITH PASSWORD 'password';"
# revoke
psql -c "REVOKE CREATE ON SCHEMA public FROM PUBLIC;"

# Gitlab
echo "- Gitlab"
psql -c "CREATE USER gitlab WITH PASSWORD 'password';"
psql -c "GRANT gitlab TO postgres;"
psql -c "CREATE DATABASE gitlab OWNER=gitlab;"
psql -c "CREATE EXTENSION pg_trgm;" -d gitlab
psql -c "CREATE EXTENSION btree_gist;;" -d gitlab
psql -c "CREATE SCHEMA gitlab;" -U gitlab -d gitlab
psql -c "GRANT CONNECT ON DATABASE gitlab TO readonly;" -U gitlab -d gitlab
psql -c "GRANT USAGE ON SCHEMA gitlab TO readonly;" -U gitlab -d gitlab
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA gitlab TO readonly;" -U gitlab -d gitlab
psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA gitlab GRANT SELECT ON TABLES TO readonly;" -U gitlab -d gitlab
psql -c "REVOKE CREATE ON SCHEMA gitlab FROM PUBLIC;" -U gitlab -d gitlab

