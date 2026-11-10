#!/usr/bin/env bash

docker compose  exec -u 0 -it guacamole bash -c 'keytool -importcert -noprompt -trustcacerts -alias ldap-ca -file /cacerts/icat-intra-ca.crt -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit'
