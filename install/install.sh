#!/bin/bash
NODE_PATH=`command -v node`
SYSTEMCTL_PATH=`command -v systemctl`

SRS_SECRET=`pwgen 12 -1`
DKIM_SECRET=`pwgen 12 -1`
ZONEMTA_SECRET=`pwgen 12 -1`
DKIM_SELECTOR=`$NODE_PATH -e 'console.log(Date().toString().substr(4, 3).toLowerCase() + new Date().getFullYear())'`

$(which npm) i -g npm-check-updates
$(which npm) install -g npm

echo "Installing Haraka"
$(which npm) install -g Haraka

echo "Fetching wildduck from git..."
mkdir -p /opt
git clone git://github.com/nodemailer/wildduck.git /opt/wildduck
cd /opt/wildduck
echo "Installing WildDuck Dependencies"
ncu -u
$(which npm) install --production --progress=false
echo "Configuring"
mkdir -p /etc/wildduck/config
for $file in ./config/*.toml
do
	#little hack to parse BASH environment variables within a file!
	eval "echo $(<$file)" > "/etc/wildduck/${file##*/}"
done

echo "Initializing Haraka..."
haraka -i /opt/haraka
echo $HOST > /opt/haraka/config/host_list
echo localhost > /opt/haraka/config/host_list


echo "Installing Haraka WildDuck Plugin..."
git clone git://github.com/nodemailer/haraka-plugin-wildduck.git /opt/haraka/plugins/wildduck
cd /opt/haraka/plugins/wildduck
rm -rf package-lock.json
npm install --production --progress=false
cd /opt/haraka
ncu -u
npm install --unsafe-perm --save haraka-plugin-rspamd Haraka
eval $PLUGINS_ADDITIONAL_INSTALL
echo "spf
dkim_verify
clamd
rspamd
tls
$PLUGINS
wildduck" > /opt/haraka/config/plugins

echo "Setting up Haraka Plugins..."
echo 'host = localhost
port = 11333
add_headers = always
[dkim]
enabled = true
[header]
bar = X-Rspamd-Bar
report = X-Rspamd-Report
score = X-Rspamd-Score
spam = X-Rspamd-Spam
[check]
authenticated=true
private_ip=true
[reject]
spam = false
[soft_reject]
enabled = true
[rmilter_headers]
enabled = true
[spambar]
positive = +
negative = -
neutral = /' > config/rspamd.ini

echo 'clamd_socket = /var/run/clamav/clamd.ctl
[reject]
virus=true
error=false' > config/clamd.ini

cp plugins/wildduck/config/wildduck.yaml config/wildduck.yaml
sed -i -e "s/secret value/$SRS_SECRET/g" config/wildduck.yaml


mkdir -p /opt/zone-mta
git clone git://github.com/zone-eu/zone-mta-template.git /opt/zone-mta
mkdir -p /opt/zone-mta/plugins/wildduck
git clone git://github.com/nodemailer/zonemta-wildduck.git /opt/zone-mta/plugins/wildduck

mkdir -p /etc/zone-mta
cp -r /opt/zone-mta/config /etc/zone-mta
sed -i -e 's/port=2525/port=587/g;s/host="127.0.0.1"/host="0.0.0.0"/g;s/authentication=false/authentication=true/g' /etc/zone-mta/interfaces/feeder.toml
rm -rf /etc/zone-mta/plugins/dkim.toml
echo '# @include "/etc/wildduck/dbs.toml"' > /etc/zone-mta/dbs-production.toml
echo 'user="wildduck"
group="wildduck"' | cat - /etc/zone-mta/zonemta.toml > temp && mv temp /etc/zone-mta/zonemta.toml

echo "[[default]]
address=\"0.0.0.0\"
name=\"$HOSTNAME\"" > /etc/zone-mta/pools.toml

echo "[\"modules/zonemta-loop-breaker\"]
enabled=\"sender\"
secret=\"$ZONEMTA_SECRET\"
algo=\"md5\"" > /etc/zone-mta/plugins/loop-breaker.toml

echo "[wildduck]
enabled=[\"receiver\", \"sender\"]
# which interfaces this plugin applies to
interfaces=[\"feeder\"]
# optional hostname to be used in headers
# defaults to os.hostname()
hostname=\"$HOST\"
# How long to keep auth records in log
authlogExpireDays=30
# SRS settings for forwarded emails
[wildduck.srs]
    # Handle rewriting of forwarded emails
    enabled=true
    # SRS secret value. Must be the same as in the MX side
    secret=\"$SRS_SECRET\"
    # SRS domain, must resolve back to MX
    rewriteDomain=\"$HOST\"
[wildduck.dkim]
# share config with WildDuck installation
# @include \"/etc/wildduck/dkim.toml\"
" > /etc/zone-mta/plugins/wildduck.toml

cd /opt/zone-mta/keys
# Many registrar limits dns TXT fields to 255 char. 1024bit is almost too long:-\
openssl genrsa -out "$MAILDOMAIN-dkim.pem" 1024
chmod 400 "$MAILDOMAIN-dkim.pem"
openssl rsa -in "$MAILDOMAIN-dkim.pem" -out "$MAILDOMAIN-dkim.cert" -pubout
DKIM_DNS="v=DKIM1;k=rsa;p=$(grep -v -e '^-' $MAILDOMAIN-dkim.cert | tr -d "\n")"

DKIM_JSON=`DOMAIN="$MAILDOMAIN" SELECTOR="$DKIM_SELECTOR" node -e 'console.log(JSON.stringify({
  domain: process.env.DOMAIN,
  selector: process.env.SELECTOR,
  description: "Default DKIM key for "+process.env.DOMAIN,
  privateKey: fs.readFileSync("/opt/zone-mta/keys/"+process.env.DOMAIN+"-dkim.pem", "UTF-8")
}))'`

cd /opt/zone-mta
ncu -u
npm install --unsafe-perm --production

cd /opt/zone-mta/plugins/wildduck
ncu -u
npm install --unsafe-perm --production


