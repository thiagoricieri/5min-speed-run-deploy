#!/bin/bash
# MAINTAIN BOX

# Usage:
# bash ./maintain.sh

# ====================================================
# RIGHT AFTER SETTING UP THE BOX
# ====================================================

# After running the speed_run_deploy.sh script, do this:
# Setup Github Actions:"
# 1. Copy the public key to your GitHub account: GitHub → Settings → SSH and GPG Keys
# cat ~/.ssh/deployer.pub | pbcopy
# 2. Add new SSH Key and paste the contents in "Key"
# 3. Copy the private key contents (it was created in ~/.ssh/deployer in your machine):
# cat ~/.ssh/deployer | pbcopy
# 4. Go to GitHub → Repo Settings → Secrets and Variables → Actions
# 5. Create secret SSH_PRIVATE_KEY and paste the private key contents
# 6. Create secret: SERVER_IP and paste <your server IP>"
# 7. Create secret: SERVER_USER and paste <your deployer user (default is 'deployer')>

# ====================================================
# CHECKING LOGS
# ====================================================

# NGINX ----------------------------------------------

# Monitor
tail /var/log/nginx/access.log
tail /var/log/nginx/error.log

# Clear
sudo truncate -s 0 /var/log/nginx/access.log
sudo truncate -s 0 /var/log/nginx/error.log

# PM2 ------------------------------------------------

# Monitor
pm2 logs

# Clear
pm2 flush

# Automated log maintainance
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M # Set max log size to 10 MB
pm2 set pm2-logrotate:retain 7 # Retain logs for 7 days

# NPM ------------------------------------------------

# Schedule system and dependency updates to patch vulnerabilities:
sudo apt update && sudo apt upgrade -y
npm outdated

# JOURNAL --------------------------------------------

# To view logs in real-time (similar to tail -f):
journalctl -f

# Check Log Size
journalctl --disk-usage

# Limit usage
sudo vim /etc/systemd/journald.conf

# SystemMaxUse=500M
# SystemKeepFree=1G
sudo systemctl restart systemd-journald

# Clear old logs
journalctl --vacuum-size=100M
journalctl --vacuum-time=7d

# ====================================================
# BACKUPS
# ====================================================

# Automate backups for your data and configurations using cron jobs or tools like rsync.

# ====================================================
# ALERTING
# ====================================================

# Configure server alerting for downtimes using UptimeRobot or similar tools.