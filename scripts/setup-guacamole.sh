#!/usr/bin/env bash
 # TODO: write a script to run this command for all the certificates in the directory
 # It is better to use a loop or something to import all the certificates
 # The command is: 
 # keytool -importcert -noprompt -trustcacerts -alias ldap-ca -file /cacerts/icat-intra-ca.crt -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit
 
docker compose  exec -u 0 -it guacamole bash -c 'keytool -importcert -noprompt -trustcacerts -alias ldap-ca -file /cacerts/icat-intra-ca.crt -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit'
