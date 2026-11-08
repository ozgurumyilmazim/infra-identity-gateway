#!/bin/sh
set -e
exec traefik \
  --api.dashboard=true \
  --api.insecure=false \
  --providers.docker=true \
  --providers.docker.exposedbydefault=false \
  --providers.file.directory=/etc/traefik/dynamic \
  --providers.file.watch=true \
  --entrypoints.web.address=:80 \
  --entrypoints.web.http.redirections.entrypoint.to=websecure \
  --entrypoints.web.http.redirections.entrypoint.scheme=https \
  --entrypoints.web.forwardedheaders.trustedips=127.0.0.1/32,${TRUSTED_SUBNET} \
  --entrypoints.websecure.address=:443 \
  --entrypoints.websecure.forwardedheaders.trustedips=127.0.0.1/32,${TRUSTED_SUBNET} \
  --entrypoints.webexternalsecure.address=:444 \
  --entrypoints.webexternalsecure.forwardedheaders.trustedips=127.0.0.1/32,${TRUSTED_SUBNET} \
  --entrypoints.webexternalunsecure.address=:88 \
  --entrypoints.webexternalunsecure.forwardedheaders.trustedips=127.0.0-1/32,${TRUSTED_SUBNET} \
  --accesslog=true \
  --accesslog.filepath=/var/log/traefik/access.log \
  --accesslog.bufferingsize=100 \
  --experimental.localplugins.crowdsec.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin \
  --certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL} \
  --certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json \
  --certificatesresolvers.letsencrypt.acme.dnschallenge=true \
  --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare \
  --certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53