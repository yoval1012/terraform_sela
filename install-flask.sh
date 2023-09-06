#!/bin/bash

# Install Flask
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install Flask

# Create your Flask app (app.py)
cat <<EOL > app.py
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, Flask on VM1!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOL

# Run the Flask app
python3 app.py


