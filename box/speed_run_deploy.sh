#!/bin/bash

# ====================================================
# 5MIN SPEED RUN DEPLOY SCRIPT
# ====================================================

# Usage:
# scp speed_run_deploy.sh USER@SERVER_UP:~/speed_run_deploy.sh
# then log into your server and run:
# bash ~/.speed_run_deploy.sh
# Warning: You must have added your server IP to your domain A registry first

# ====================================================
# THE FOLLOWING MUST BE EXECUTED IN YOUR SERVER:
# ====================================================

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

# UPDATE & UPGRADE -----------------------------------
# Update system and install dependencies
echo "📦 Updating and installing dependencies..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install -y nginx nodejs npm certbot python3-certbot-nginx git curl

# PM2 ------------------------------------------------

# Install PM2 globally
sudo npm install -g pm2

# DIRECTORIES ----------------------------------------

# Create site directory
echo "🗂️ Creating site directory..."
sudo mkdir -p /var/www/$DOMAIN_NAME
sudo chown -R $USER:$USER /var/www/$DOMAIN_NAME

# DEPLOYER -------------------------------------------

# Create deploy user
echo "👨‍🔧 Creating deploy user: $DEPLOY_USER..."
sudo adduser --disabled-password --gecos "" $DEPLOY_USER
sudo mkdir -p /home/$DEPLOY_USER/.ssh

# Create key for deployment
sudo ssh-keygen -t rsa -b 4096 -C "$DEPLOY_USER@$SERVER_IP" -f /home/$DEPLOY_USER/.ssh/deployer -N ""
sudo cat /home/$DEPLOY_USER/.ssh/deployer.pub > /home/$DEPLOY_USER/.ssh/authorized_keys
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh

# PERMISSIONS ----------------------------------------

# Manage directory permissions
sudo chmod 700 /home/$DEPLOY_USER/.ssh
sudo chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
sudo mv /home/$DEPLOY_USER/.ssh/deployer /home/$DEPLOY_USER/deployer
sudo mv /home/$DEPLOY_USER/.ssh/deployer.pub /home/$DEPLOY_USER/deployer.pub

# Set permissions
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /var/www/$DOMAIN_NAME

# FIREWALL -------------------------------------------

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

# SSL CERT -------------------------------------------

# Obtain SSL certificate
echo "🔐 Obtaining SSL certificate..."
sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME

# DEPLOY SCRIPT --------------------------------------

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
pm2 list | grep -wq "$DOMAIN_NAME" && pm2 delete $DOMAIN_NAME
pm2 start "npm run start" --name "$DOMAIN_NAME"
pm2 save
pm2 list
" | sudo tee $DEPLOY_SCRIPT

sudo chmod +x $DEPLOY_SCRIPT
sudo chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_SCRIPT

# ====================================================
# WRAPPING UP...
# ====================================================

echo "✅ Setup complete! Now, do this:"
echo " - Copy your SSH key to your local machine with (run from your local machine):"
echo "scp root@$SERVER_IP:/home/$DEPLOY_USER/deployer ~/.ssh/deployer"
echo "scp root@$SERVER_IP:/home/$DEPLOY_USER/deployer.pub ~/.ssh/deployer.pub"
echo " - Setup Github Actions:"
echo "1. Run the commands above so you have the keys in your machine"
echo "2. Copy the public key to your"
echo "cat ~/.ssh/deployer.pub | pbcopy"
echo "3. Go to https://github.com/settings/keys"
echo "4. Click 'Add new SSH' Key and paste the contents in public key field"
echo "5. Copy the private key contents (it was created in ~/.ssh/deployer in your machine):"
echo "cat ~/.ssh/deployer | pbcopy"
echo "6. Push your code to Github"
echo "7. Copy the repository URL"
echo "8. Go to https://github.com/<YOUR GITHUB USER>/<YOUR REPO NAME>/settings/secrets/actions"
echo "9. Create secret SSH_PRIVATE_KEY and paste the private key contents"
echo "10. Create secret: SERVER_IP as $SERVER_IP"
echo "11. Create secret: SERVER_USER as $DEPLOY_USER"
echo "12. SSH into your server using the deployer user:"
echo "ssh -i ~/.ssh/deployer deployer@$SERVER_IP"
echo "13. Clone your repository into /var/www/$DOMAIN_NAME"
echo "git clone https://github.com/<YOUR GITHUB USER>/<YOUR REPO NAME>.git /var/www/$DOMAIN_NAME"
echo "Done! Every merge to main branch will be deployed."
echo "These instructions are also in maintain.sh"
echo "--------------"
echo "👉 To do later:"
echo " - To deploy, SSH into the server and run:"
echo "sudo -u $DEPLOY_USER /home/$DEPLOY_USER/deploy.sh"
echo "- Configure your DNS A record to point $DOMAIN_NAME to $SERVER_IP."
