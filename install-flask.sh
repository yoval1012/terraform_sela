#!/bin/bash

# Update system and install required packages
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install Flask psycopg2-binary

# Create your Flask app (app.py)
cat <<EOL > app.py
from flask import Flask
import psycopg2

# Database configuration
db_host = "10.0.2.5"
db_port = 5432
db_user = "yuval"
db_password = "1234567"
db_name = "db"

# Create a PostgreSQL connection
try:
    conn = psycopg2.connect(
        host="10.0.2.5",
        port="5432",
        user="yuval",
        password="1234567",
        database="db"
    )
    cursor = conn.cursor()
    print("Connected to PostgreSQL")
except Exception as e:
    print(f"Error: {e}")

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, Flask on VM1!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOL

# Run the Flask app
nohup python3 app.py > /dev/null 2>&1 &

