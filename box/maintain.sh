#!/bin/bash
# MAINTAIN BOX

# Usage:
# bash ./maintain.sh

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