echo "Fetching wildduck from git..."
git clone git://github.com/nodemailer/wildduck.git /opt/wildduck
rm -rf /opt/wildduck/config
cd /opt/wildduck
echo "Installing WildDuck Dependencies..."
ncu -u
$(which npm) install --production --progress=false

echo "Installing Haraka WildDuck Plugin..."
git clone git://github.com/nodemailer/haraka-plugin-wildduck.git /opt/haraka/plugins/wildduck
cd /opt/haraka/plugins/wildduck
rm -rf config
rm -rf package-lock.json
ncu -u
npm install --production --progress=false --loglevel=error
cd /opt/haraka
npm install --production --unsafe-perm --loglevel=error --progress=false --save haraka-plugin-rspamd 