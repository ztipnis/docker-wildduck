#! /bin/bash
echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"
OURNAME=deploy.sh
export DKIM_SELECTOR=`node -e 'console.log(Date().toString().substr(4, 3).toLowerCase() + new Date().getFullYear())'`
export DKIM_JSON=`DOMAIN="$HOST" SELECTOR="$DKIM_SELECTOR" node -e 'console.log(JSON.stringify({
  domain: process.env.DOMAIN,
  selector: process.env.SELECTOR,
  description: "Default DKIM key for "+process.env.DOMAIN,
  privateKey: fs.readFileSync("/opt/zone-mta/keys/"+process.env.DOMAIN+"-dkim.pem", "UTF-8")
}))'`
export DKIM_DNS="v=DKIM1;k=rsa;p=$(grep -v -e '^-' /opt/zone-mta/keys/$HOST-dkim.cert | tr -d "\n")"

printf "Waiting for the server to start up.."
sleep 60
until $(curl --output /dev/null --silent --fail $(echo http://127.0.0.1:8080/users?accessToken=$WD_ACCESS_TOKEN)); do
    printf '.'
    sleep 2
done
echo "."

# Ensure DKIM key
echo "Registering DKIM key for $HOST"
eval "curl -i -XPOST http://localhost:8080/dkim?accessToken=$WD_ACCESS_TOKEN \
    -H 'Content-type: application/json' \
    -d '$DKIM_JSON'"
echo "
Add this TXT record to the $HOST DNS zone:
$DKIM_SELECTOR._domainkey.$HOST. IN TXT \"$DKIM_DNS\"
"
echo "WildDuck is running.
Please remember
to set up MX and SPF
DNS records as required"