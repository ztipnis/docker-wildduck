#! /bin/bash

OURNAME=deploy.sh

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

cd "$INSTALLDIR"

echo "DEPLOY SETUP

1. Add your ssh key to /home/deploy/.ssh/authorized_keys

2. Clone application code
\$ git clone deploy@$HOST:/var/opt/wildduck.git
\$ git clone deploy@$HOST:/var/opt/zone-mta.git
\$ git clone deploy@$HOST:/var/opt/wildduck-webmail.git
\$ git clone deploy@$HOST:/var/opt/haraka-plugin-wildduck.git
\$ git clone deploy@$HOST:/var/opt/zonemta-wildduck.git

3. After making a change in local copy deploy to server
\$ git push origin master
(you might need to use -f when pushing first time)

NAMESERVER SETUP
================

MX
--
Add this MX record to the $HOST DNS zone:

$HOST. IN MX 5 $HOST.

SPF
---
Add this TXT record to the $HOST DNS zone:

$HOST. IN TXT \"v=spf1 a:$HOST a:$HOST ip4:$PUBLIC_IP ~all\"

Or:
$HOST. IN TXT \"v=spf1 a:$HOST ip4:$PUBLIC_IP ~all\"
$HOST. IN TXT \"v=spf1 ip4:$PUBLIC_IP ~all\"

Some explanation:
SPF is basically a DNS entry (TXT), where you can define,
which server hosts (a:[HOST]) or ip address (ip4:[IP_ADDRESS])
are allowed to send emails.
So the receiver server (eg. gmail's server) can look up this entry
and decide if you(as a sender server) is allowed to send emails as
this email address.

If you are unsure, list more a:, ip4 entries, rather then fewer.

Example:
company website: awesome.com
company's email server: mail.awesome.com
company's reverse dns entry for this email server: mail.awesome.com -> 11.22.33.44

SPF record in this case would be:
awesome.com. IN TXT \"v=spf1 a:mail.awesome.com a:awesome.com ip4:11.22.33.44 ~all\"

The following servers can send emails for *@awesome.com email addresses:
awesome.com (company's website handling server)
mail.awesome.com (company's mail server)
11.22.33.44 (company's mail server's ip address)

Please note, that a:mail.awesome.com is the same as ip4:11.22.33.44, so it is
redundant. But better safe than sorry.
And in this example, the company's website handling server can also send
emails and in general it is an outbound only server.
If a website handles email sending (confirmation emails, contact form, etc).

DKIM
----
Add this TXT record to the $HOST DNS zone:

$DKIM_SELECTOR._domainkey.$HOST. IN TXT \"$DKIM_DNS\"

The DKIM .json text we added to wildduck server:
    curl -i -XPOST http://localhost:8080/dkim \\
    -H 'Content-type: application/json' \\
    -d '$DKIM_JSON'


Please refer to the manual how to change/delete/update DKIM keys
via the REST api (with curl on localhost) for the newest version.

List DKIM keys:
    curl -i http://localhost:8080/dkim
Delete DKIM:
    curl -i -XDELETE http://localhost:8080/dkim/59ef21aef255ed1d9d790e81

Move DKIM keys to another machine:

Save the above curl command and dns entry.
Also copy the following two files too:
/opt/zone-mta/keys/[HOST]-dkim.cert
/opt/zone-mta/keys/[HOST]-dkim.pem

pem: private key (guard it well)
cert: public key


PTR
---
Make sure that your public IP has a PTR record set to $HOST.
If your hosting provider does not allow you to set PTR records but has
assigned their own hostname, then edit /etc/zone-mta/pools.toml and replace
the hostname $HOST with the actual hostname of this server.

(this text is also stored to $INSTALLDIR/$HOST-nameserver.txt)" > "$INSTALLDIR/$HOST-nameserver.txt"

printf "Waiting for the server to start up.."

until $(curl --output /dev/null --silent --fail $(echo http://127.0.0.1:8080/users?accessToken=$WD_ACCESS_TOKEN)); do
    printf '.'
    sleep 2
done
echo "."

# Ensure DKIM key
echo "Registering DKIM key for $HOST"
echo $DKIM_JSON

curl -i -XPOST http://localhost:8080/dkim \
-H 'Content-type: application/json' \
-d "$DKIM_JSON"

echo ""
cat "$INSTALLDIR/$HOST-nameserver.txt"
echo ""
echo "All done, open https://$HOST/ in your browser"