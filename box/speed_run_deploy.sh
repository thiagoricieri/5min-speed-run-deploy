#!/bin/bash

# Copy the script using:
# scp speed_run_deploy.sh USER@SERVER_UP:~/speed_run_deploy.sh
# then log into your server and run:
# bash ~/.speed_run_deploy.sh

# Prompt for required information
echo "😃 WELCOME TO SPEED RUN DEPLOY v1.0!"
read -p "  - Enter domain name: " DOMAIN_NAME
read -p "  - Enter server IP: " SERVER_IP
read -p "  - Enter deploy user name (default: deployer): " DEPLOY_USER
DEPLOY_USER=${DEPLOY_USER:-deployer}
read -p "  - Enter deploy branch (default: main): " DEPLOY_BRANCH
DEPLOY_BRANCH=${DEPLOY_BRANCH:-main}
read -p "  - Enter Node port number (default: 3000): " NODE_PORT
NODE_PORT=${NODE_PORT:-3000}

# Check if DEPLOYER_USER is root
if [[ "$DEPLOYER_USER" == "root" ]]; then
    echo "❌ ERROR: DEPLOYER_USER cannot be 'root'."
    exit 1
fi

# Check if the domain argument is provided
if [[ -z "$DOMAIN_NAME" ]]; then
    echo "❌ ERROR: No domain provided."
    exit 1
fi

# Check if the domain is reachable (DNS resolution)
if ! nslookup "$DOMAIN_NAME" > /dev/null 2>&1; then
    echo "❌ ERROR: The domain '$DOMAIN_NAME' is unreachable (DNS not updated)."
    exit 1
fi

# Update system and install dependencies
echo "📦 Updating and installing dependencies..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install -y nginx nodejs npm certbot python3-certbot-nginx git curl

# Install PM2 globally
sudo npm install -g pm2

# Create site directory
echo "🗂️ Creating site directory..."
sudo mkdir -p /var/www/$DOMAIN_NAME
sudo chown -R $USER:$USER /var/www/$DOMAIN_NAME

# Create deploy user
echo "👨‍🔧 Creating deploy user: $DEPLOY_USER..."
sudo adduser --disabled-password --gecos "" $DEPLOY_USER
sudo mkdir -p /home/$DEPLOY_USER/.ssh

# Create key for deployment
sudo ssh-keygen -t rsa -b 4096 -C "$DEPLOY_USER@$SERVER_IP" -f /home/$DEPLOY_USER/.ssh/deployer -N ""
sudo cat /home/$DEPLOY_USER/.ssh/deployer.pub > /home/$DEPLOY_USER/.ssh/authorized_keys
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh

# Manage directory permissions
sudo chmod 700 /home/$DEPLOY_USER/.ssh
sudo chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
sudo mv /home/$DEPLOY_USER/.ssh/deployer /home/$DEPLOY_USER/deployer
sudo mv /home/$DEPLOY_USER/.ssh/deployer.pub /home/$DEPLOY_USER/deployer.pub

# Set permissions
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /var/www/$DOMAIN_NAME

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Configure Nginx
echo "🗄️ Configuring Nginx..."
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
echo "server {
    listen 80;
    server_name $DOMAIN_NAME;
    location / {
        proxy_pass http://localhost:$NODE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" | sudo tee $NGINX_CONF

sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Obtain SSL certificate
echo "🔐 Obtaining SSL certificate..."
sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME

# Create deploy script
echo "🏃‍♂️ Creating deploy script..."
DEPLOY_SCRIPT="/home/$DEPLOY_USER/deploy.sh"
echo "#!/bin/bash
cd /var/www/$DOMAIN_NAME
echo \"🗂️ List & pull files in /var/www/$DOMAIN_NAME...\"
ls -lah .
git pull origin $DEPLOY_BRANCH
echo \"📦 Install and build...\"
npm install
npm run build
echo \"⚙️ Starting the Next.js '$DOMAIN_NAME' app...\"
npm run start -- -p $NODE_PORT &
pm2 restart $DOMAIN_NAME || pm2 start npm --name \"$DOMAIN_NAME\" -- run start -- -p $NODE_PORT
pm2 save
pm2 list
" | sudo tee $DEPLOY_SCRIPT

sudo chmod +x $DEPLOY_SCRIPT
sudo chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_SCRIPT

# Everything's good:
echo "✅ Setup complete! Now, do this:"
echo " - Copy your SSH key to your local machine with (run from your local machine):"
echo "scp root@$SERVER_IP:/home/$DEPLOY_USER/deployer ~/.ssh/deployer"
echo "scp root@$SERVER_IP:/home/$DEPLOY_USER/deployer.pub ~/.ssh/deployer.pub"
echo " - Now try accessing SSH to the box using the deployer key (run from your local machine):"
echo "ssh -i ~/.ssh/deployer deployer@$SERVER_IP"
echo " - Setup Github Actions:"
echo "1. Run the commands above so you have the keys in your machine"
echo "2. Copy the private key contents (it was created in ~/.ssh/deployer in your machine):"
echo "cat ~/.ssh/deploy | pbcopy"
echo "3. Add the private key to GitHub → Repo Settings → Secrets and Variables → Actions"
echo "4. Name it SSH_PRIVATE_KEY"
echo "5. Create another secret: SERVER_IP as $SERVER_IP"
echo "5. Create another secret: SERVER_USER as $DEPLOY_USER"
echo "These instructions are also in maintain.sh"
echo "--------------"
echo "👉 To do later:"
echo " - To deploy, SSH into the server and run:"
echo "sudo -u $DEPLOY_USER /home/$DEPLOY_USER/deploy.sh"
echo "- Configure your DNS A record to point $DOMAIN_NAME to $SERVER_IP."
