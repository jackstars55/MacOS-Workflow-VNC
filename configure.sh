#!/bin/bash
# configure.sh VNC_USER_PASSWORD VNC_PASSWORD NGROK_AUTH_TOKEN

# Navigate to home to avoid getcwd permission errors
cd ~

# 1. Identify the current user 
USER_NAME=$(whoami)
echo "Setting up environment for user: $USER_NAME"

# 2. Force-reset the system password using VNC_PASSWORD ($2) just in case you need sudo access later
sudo sysadminctl -resetPasswordFor "$USER_NAME" -newPassword "$2"

# 3. Setup SSH directory and inject the HARDCODED public key
echo "Injecting hardcoded SSH public key..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKc//Nge5z8h9ak9Inflgfmi9qcn4dr8QBoMumygAhK @" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 4. Enable SSH (Remote Login)
echo "Starting SSH service..."
sudo systemsetup -setremotelogin on || sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# 5. Install ngrok
echo "Installing ngrok..."
brew install ngrok

# 6. Configure ngrok using NGROK_AUTH_TOKEN ($3)
ngrok config add-authtoken "$3"

# 7. Start ngrok in the background forwarding port 22 (SSH)
echo "Starting ngrok tunnel..."
ngrok tcp 22 > /dev/null &

# Give ngrok a few seconds to establish the connection
sleep 3

# 8. Fetch the public URL from ngrok's local API and print the exact SSH command
echo "==================================================================="
curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    url = data['tunnels'][0]['public_url'].replace('tcp://', '')
    host, port = url.split(':')
    print(f'✅ SSH TUNNEL READY (Key Auth)!')
    print(f'Run this command on your local machine:')
    print(f'ssh $USER_NAME@{host} -p {port}')
except Exception as e:
    print('Error fetching ngrok URL. Is the token correct?')
"
echo "==================================================================="

# 9. Keep the script running so the runner doesn't exit and kill the tunnel
wait
