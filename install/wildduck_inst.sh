echo "Fetching wildduck from git..."
git clone git://github.com/nodemailer/wildduck.git /opt/wildduck
rm -rf /opt/wildduck/config
cd /opt/wildduck
echo "Installing WildDuck Dependencies..."
ncu -u
$(which npm) install --production --progress=false
echo "Configuring"
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

echo "Installing Haraka WildDuck Plugin..."
git clone git://github.com/nodemailer/haraka-plugin-wildduck.git /opt/haraka/plugins/wildduck
cd /opt/haraka/plugins/wildduck
rm -rf config
rm -rf package-lock.json
ncu -u
npm install --production --progress=false --loglevel=error
cd /opt/haraka
npm install --production --unsafe-perm --loglevel=error --progress=false --save haraka-plugin-rspamd 
eval $PLUGINS_ADDITIONAL_INSTALL
if [[ $SECURE = true ]]; then
	echo "spf
	dkim_verify
	rspamd
	tls
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

echo "key=$TLS_KEYPATH
cert=$TLS_CERTPATH" > config/tls.ini
