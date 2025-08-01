FROM debian:bookworm-slim

# Install pure-ftpd and fail2ban
RUN apt-get update && \
    apt-get install -y pure-ftpd fail2ban iptables rsyslog && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /home/ftpuser/uploads /home/ftpuser/scripts \
             /var/log/pure-ftpd /etc/fail2ban/jail.d && \
    useradd -d /home/ftpuser -s /bin/false ftpuser && \
    chown -R ftpuser:ftpuser /home/ftpuser

# Copy configuration files
COPY entrypoint.sh /entrypoint.sh
COPY fail2ban-pure-ftpd.conf /etc/fail2ban/jail.d/pure-ftpd.local
RUN chmod +x /entrypoint.sh

# Expose FTP ports
EXPOSE 21 30000-30009

# Environment variables
ENV FTP_USER=ftpuser
ENV FTP_PASSWORD=changeme
ENV FTP_PASSIVE_IP=localhost
ENV FTP_UID=1000
ENV FTP_GID=1000
ENV FTP_UPLOADSCRIPT=/home/ftpuser/scripts/upload
ENV FAIL2BAN_ENABLED=true
ENV FAIL2BAN_MAXRETRY=3
ENV FAIL2BAN_BANTIME=3600

ENTRYPOINT ["/entrypoint.sh"]
