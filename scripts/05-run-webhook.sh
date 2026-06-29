#!/bin/bash
CRUMB=$(curl -s -u admin:admin 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
curl -s -u admin:admin -H "$CRUMB" --data-urlencode "script=$(cat /vagrant/scripts/05-enable-webhook.groovy)" http://localhost:8080/scriptText
