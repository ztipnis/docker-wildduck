# fresh install
echo "Installing ZoneMTA"
cd /var/opt
git clone --bare git://github.com/zone-eu/zone-mta-template.git zone-mta.git
git clone --bare git://github.com/nodemailer/zonemta-wildduck.git

# checkout files from git to working directory
mkdir -p /opt/zone-mta
git --git-dir=/var/opt/zone-mta.git --work-tree=/opt/zone-mta checkout master

mkdir -p /opt/zone-mta/plugins/wildduck
git --git-dir=/var/opt/zonemta-wildduck.git --work-tree=/opt/zone-mta/plugins/wildduck checkout master


cp -r /opt/zone-mta/config /etc/zone-mta
sed -i -e 's/port=2525/port=587/g;s/host="127.0.0.1"/host="0.0.0.0"/g;s/authentication=false/authentication=true/g' /etc/zone-mta/interfaces/feeder.toml

rm -rf /etc/zone-mta/plugins/dkim.toml
echo '# @include "/etc/wildduck/dbs.toml"' > /etc/zone-mta/dbs-production.toml
rm /etc/zone-mta/dbs-development.toml
cp /etc/zone-mta/dbs-production.toml /etc/zone-mta/dbs-development.toml
echo 'user="wildduck"
group="wildduck"' | cat - /etc/zone-mta/zonemta.toml > temp && mv temp /etc/zone-mta/zonemta.toml


cd /opt/zone-mta
ncu -u
npm install --loglevel=error --progress=false --unsafe-perm --production

cd /opt/zone-mta/plugins/wildduck
ncu -u
npm install --loglevel=error --progress=false --unsafe-perm --production

