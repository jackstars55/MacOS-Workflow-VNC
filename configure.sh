#!/bin/bash
# configure.sh VNC_USER_PASSWORD VNC_PASSWORD NGROK_AUTH_TOKEN

# Navigate to home to avoid getcwd permission errors
cd ~

# 1. Identify the current user (in GitHub Actions, this is usually 'runner')
USER_NAME=$(whoami)
echo "Setting password for user: $USER_NAME"

# 2. Set the password for the current user using the VNC_PASSWORD ($2)
sudo dscl . -passwd /Users/$USER_NAME "$2"

# 3. Enable SSH (Remote Login)
echo "Starting SSH service..."
sudo systemsetup -setremotelogin on || sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# 4. Install ngrok
echo "Installing ngrok..."
brew install ngrok

# 5. Configure ngrok using NGROK_AUTH_TOKEN ($3)
ngrok config add-authtoken "$3"

# 6. Start ngrok in the background forwarding port 22 (SSH)
echo "Starting ngrok tunnel..."
ngrok tcp 22 > /dev/null &

# Give ngrok a few seconds to establish the connection
sleep 3

# 7. Fetch the public URL from ngrok's local API and print the exact SSH command
echo "==================================================================="
curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    url = data['tunnels'][0]['public_url'].replace('tcp://', '')
    host, port = url.split(':')
    print(f'✅ SSH TUNNEL READY!')
    print(f'Run this command on your local machine:')
    print(f'ssh $USER_NAME@{host} -p {port}')
    print(f'(Use your VNC_PASSWORD when prompted)')
except Exception as e:
    print('Error fetching ngrok URL. Is the token correct?')
"
echo "==================================================================="

# 8. Keep the script running so the runner doesn't exit and kill the tunnel
wait
