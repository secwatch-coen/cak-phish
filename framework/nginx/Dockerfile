FROM nginx:stable

# Create a place to store certs
RUN mkdir -p /etc/nginx/certs

# Add our startup hook (anything in /docker-entrypoint.d runs at startup)
COPY 99-gen-self-signed-cert.sh /docker-entrypoint.d/99-gen-self-signed-cert.sh
RUN chmod +x /docker-entrypoint.d/99-gen-self-signed-cert.sh