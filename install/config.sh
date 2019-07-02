echo "Configuring"
set +e
addgroup -S wildduck
adduser -S -H -D wildduck -G wildduck
set -e
mkdir -p /etc/wildduck/config
IMAP_PORT=143
if [[ $SECURE = true ]]; then
	IMAP_PORT=993;
	export IMAP_PORT;
else
	IMAP_PORT=143;
	export IMAP_PORT;
fi
export IMAP_PORT
OPENSSL_PATH=$(which openssl)
export OPENSSL_PATH
for file in /src/config/*.toml
do
	#parse BASH environment variables
	echo "$(envsubst < $file)" > "/etc/wildduck/${file##*/}"
done

cp /src/config/roles.json /etc/wildduck/roles.json
mv /etc/wildduck/default.toml /etc/wildduck/wildduck.toml
eval $PLUGINS_ADDITIONAL_INSTALL
if [[ $SECURE = true ]]; then
	echo "tls
	spf
	dkim_verify
	rspamd
	$PLUGINS
	wildduck" > /opt/haraka/config/plugins
else
	echo "spf
	dkim_verify
	rspamd
	$PLUGINS
	wildduck" > /opt/haraka/config/plugins
fi


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



echo "$(envsubst < /src/config/wd-haraka/wildduck.yaml)" > /opt/haraka/config/wildduck.yaml


if [[ $SECURE = true ]]; then
cat "$TLS_CERTPATH" "$TLS_CAPATH" > /opt/haraka/config/tls_cert.pem
cat "$TLS_KEYPATH" > /opt/haraka/config/tls_key.pem
fi
export NODE_PATH=`command -v node`
export SRS_SECRET=`pwgen 12 -1`
apk --update add --no-cache gettext
echo "$(export DKIM_SECRET=`pwgen 12 -1` && envsubst < /src/config/dkim.toml)" > "/etc/wildduck/dkim.toml"
apk del gettext

export ZONEMTA_SECRET=`pwgen 12 -1`
echo "[\"modules/zonemta-loop-breaker\"]
enabled=\"sender\"
secret=\"$ZONEMTA_SECRET\"
algo=\"md5\"" > /etc/zone-mta/plugins/loop-breaker.toml
echo "[[default]]
address=\"0.0.0.0\"
name=\"$HOST\"" > /etc/zone-mta/pools.toml
echo "
[feeder]
enabled=true
processes=1
maxSize=31457280
host=\"0.0.0.0\"
port=587
authentication=true
maxRecipients=1000
starttls=true
secure=false
" > /etc/zone-mta/interfaces/feeder.toml
echo "# @include \"/etc/wildduck/tls.toml\"" >> /etc/zone-mta/interfaces/feeder.toml
if [[ $SECURE = true ]]; then
	echo "
	[feeder_s]
	enabled=true
	processes=1
	maxSize=31457280
	host=\"0.0.0.0\"
	port=465
	authentication=true
	maxRecipients=1000
	starttls=true
	secure=true
	" > /etc/zone-mta/interfaces/feeder_s.toml
	echo "# @include \"/etc/wildduck/tls.toml\"" >> /etc/zone-mta/interfaces/feeder_s.toml
fi
if [[ $SECURE = true ]]; then
echo "[wildduck]
enabled=[\"receiver\", \"sender\"]
# which interfaces this plugin applies to
interfaces=[\"feeder\", \"feeder_s\"]
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
else
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
fi
cd /opt/zone-mta/keys
# Many registrar limits dns TXT fields to 255 char. 1024bit is almost too long:-\
openssl genrsa -out "$HOST-dkim.pem" 1024
chmod 400 "$HOST-dkim.pem"
openssl rsa -in "$HOST-dkim.pem" -out "$HOST-dkim.cert" -pubout
if [[ "$MMONIT_ENABLED" = "true" ]]; then
	echo "set mmonit http://$MMONIT_USER:$MMONIT_PASS@$MMONIT_HOST:$MMONIT_PORT/collector" > /etc/monitrc
else
	echo "" > /etc/monitrc
fi
echo '
set daemon 5
set httpd port 2812
  allow 0.0.0.0/0.0.0.0
check process rspamd with pidfile /var/run/rspamd.pid
   start = "/bin/bash -c '"'"'/src/rspamd.sh start'"'"'"
   stop = "/bin/bash -c '"""'/src/rspamd.sh stop'"""'"
   if 3 restarts within 5 cycles then alert
check process haraka with pidfile /var/run/haraka.pid
   start = "/bin/bash -c '"'"'/src/haraka.sh start'"'"'"
   stop = "/bin/bash -c '"""'/src/haraka.sh stop'"""'"
   if 3 restarts within 5 cycles then alert
check process zonemta with pidfile /var/run/zonemta.pid
   start = "/bin/bash -c '"'"'/src/zonemta.sh start'"'"'"
   stop = "/bin/bash -c '"'"'/src/zonemta.sh stop'"'"'"
   if 3 restarts within 5 cycles then alert
check process wildduck with pidfile /var/run/wildduck.pid
   start = "/bin/bash -c '"'"'/src/wildduck.sh start'"'"'"
   stop = "/bin/bash -c '"'"'/src/wildduck.sh stop'"'"'"
   if 3 restarts within 5 cycles then alert
' >> /etc/monitrc

