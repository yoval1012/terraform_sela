#!/bin/bash

# Update package lists
sudo apt-get update

# Install PostgreSQL
sudo apt-get install -y postgresql

# Start the PostgreSQL service
sudo systemctl start postgresql

# Enable PostgreSQL to start on system boot
sudo systemctl enable postgresql

# Create a PostgreSQL user and a database
sudo -u postgres psql -c "CREATE USER yuval WITH PASSWORD '1234567';"
sudo -u postgres psql -c "CREATE DATABASE db OWNER yuval;"

# Grant all privileges on the database to the user
sudo -u postgres psql -d db -c "GRANT ALL PRIVILEGES ON DATABASE db TO yuval;"
echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf

# Allow connections to PostgreSQL from all IP addresses (for development purposes)
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Reload PostgreSQL for changes to take effect
sudo systemctl reload postgresql

