$(which npm) i -g npm-check-updates
$(which npm) install -g npm

echo "Installing Haraka"
mkdir -p /root/.node-gyp
chmod -R 777 /root
chmod -R 777 /opt
$(which npm) install -g Haraka

echo "Initializing Haraka..."
haraka -i /opt/haraka
echo $HOST > /opt/haraka/config/host_list
echo localhost > /opt/haraka/config/host_list
