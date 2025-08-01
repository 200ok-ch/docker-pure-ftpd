#!/bin/bash

set -euo pipefail

# TODO
# - logs should go into /home/ftpuser/logs and be rotated
# - /etc/pure-ftpd should go into /home/ftpuser/config

# Validate required environment variables
if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
  echo "Error: FTP_USER and FTP_PASSWORD environment variables must be set"
  exit 1
fi

echo "Setting up FTP user: $FTP_USER"

# CHECK: not sure this is acutally needed
# Create virtual user database directory
mkdir -p /etc/pure-ftpd/passwd

# Ensure uploads and scripts directories exist
mkdir -p /home/ftpuser/uploads /home/ftpuser/scripts

# Create the FTP user with pure-pw, pointing to uploads directory
printf "$FTP_PASSWORD\n$FTP_PASSWORD\n" | \
  pure-pw useradd "$FTP_USER" \
          -u "$FTP_UID" \
          -g "$FTP_GID" \
          -d /home/ftpuser/uploads \
          -m

# CHECK: not sure this	is acutally needed, the -m might already be enough
# Generate the user database
pure-pw mkdb

# Configure pure-ftpd settings
echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
echo "yes" > /etc/pure-ftpd/conf/CreateHomeDir
echo "30000 30009" > /etc/pure-ftpd/conf/PassivePortRange
echo "no" > /etc/pure-ftpd/conf/PAMAuthentication
echo "no" > /etc/pure-ftpd/conf/UnixAuthentication
# CHECK: this might be the default
echo "/etc/pure-ftpd/pureftpd.pdb" > /etc/pure-ftpd/conf/PureDB

# Configure upload script
UPLOAD_SCRIPT_ARGS=""
if [ -f "$FTP_UPLOADSCRIPT" ]; then
  echo "Configuring upload script: $FTP_UPLOADSCRIPT"

  if [ ! -x "$FTP_UPLOADSCRIPT" ]; then
    echo "Making upload script executable: $FTP_UPLOADSCRIPT"
    chmod +x "$FTP_UPLOADSCRIPT"
  fi

  UPLOAD_SCRIPT_ARGS="-o $FTP_UPLOADSCRIPT"
else
  echo "Warning: Upload script $FTP_UPLOADSCRIPT not found - continuing without"
fi

# Set ownership of home directory and subdirectories
chown -R "$FTP_UID:$FTP_GID" /home/ftpuser

# Configure logging for Fail2Ban
mkdir -p /var/log/pure-ftpd
touch /var/log/pure-ftpd/pure-ftpd.log

# TODO: fix the rsyslog/fail2ban setup
# Start rsyslog for proper logging
# service rsyslog start

# # Configure and start Fail2Ban if enabled
# if [ "$FAIL2BAN_ENABLED" = "true" ]; then
#   echo "Configuring Fail2Ban..."
#
#   # Update Fail2Ban configuration with environment variables
#   sed -i "s/maxretry = .*/maxretry = $FAIL2BAN_MAXRETRY/" /etc/fail2ban/jail.d/pure-ftpd.local
#   sed -i "s/bantime = .*/bantime = $FAIL2BAN_BANTIME/" /etc/fail2ban/jail.d/pure-ftpd.local
#
#   # Start Fail2Ban
#   service fail2ban start
#   echo "Fail2Ban started"
# fi

echo "Starting pure-ftpd..."
echo "Upload directory: /home/ftpuser/uploads"
echo "Scripts directory: /home/ftpuser/scripts"
if [ -f "$FTP_UPLOADSCRIPT" ]; then
  echo "Upload script: $FTP_UPLOADSCRIPT"
else
  echo "No upload script configured"
fi

# Start pure-ftpd in foreground
exec /usr/sbin/pure-ftpd \
     -c $FTP_MAXCLIENTSNUMBER \
     -C $FTP_MAXCLIENTSPERIP \
     -l puredb:/etc/pure-ftpd/pureftpd.pdb \
     -E \
     -j \
     -R \
     -P $FTP_PASSIVE_IP \
     -p 30000:30009 \
     $UPLOAD_SCRIPT_ARGS 2>&1 | tee -a /var/log/pure-ftpd/pure-ftpd.log
