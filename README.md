# Set up system properties on Ubuntu 20.04
1. Set timezone and locale
2. Move sshd to listen port 3322 instead 22
3. Deny remote login as root user
4. Add user 'support' for support service
5. Grant sudo rights to the 'support'
6. Limit 'support' sudo rights to start|stop|restart services
7. Deploy Nginx and Monit and make them autostart on reboot
8. Set Nginx to proxy requests to the Monit server with the basic auth using monit/tinom credentials.
