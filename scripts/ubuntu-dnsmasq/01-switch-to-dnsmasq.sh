#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#!/bin/bash

# Function to test DNS resolution
test_dns_resolution() {
    echo "Testing DNS resolution for apple.com and nyt.com..."

    if ! nslookup apple.com &> /dev/null; then
        echo "DNS resolution for apple.com failed."
        exit 1
    fi

    if ! nslookup nyt.com &> /dev/null; then
        echo "DNS resolution for nyt.com failed."
        exit 1
    fi

    echo "DNS resolution succeeded for both apple.com and nyt.com."
}

# Step 1: Temporarily set Google's DNS in /etc/resolv.conf to allow apt-get update
echo "Temporarily setting Google's DNS to allow apt-get update..."
sudo bash -c "cat > /etc/resolv.conf" <<EOL
nameserver 8.8.8.8
nameserver 8.8.4.4
EOL

# Step 2: Install dnsmasq if not installed
echo "Installing dnsmasq..."
sudo apt-get update
sudo apt-get install -y dnsmasq

# Step 3: Configure dnsmasq
echo "Configuring dnsmasq..."

DNSMASQ_CONF="/etc/dnsmasq.conf"
if [ -f "$DNSMASQ_CONF" ]; then
    sudo mv "$DNSMASQ_CONF" "$DNSMASQ_CONF.bak"
    echo "Backed up original dnsmasq.conf to dnsmasq.conf.bak"
fi

# Write new dnsmasq configuration
sudo bash -c "cat > $DNSMASQ_CONF" <<EOL
# Set Google's DNS servers
server=8.8.8.8
server=8.8.4.4

# Listen on the loopback interface
listen-address=127.0.0.1

# Enable DNS caching
cache-size=150

# Log queries (optional)
log-queries
EOL

# Step 4: Stop and disable systemd-resolved at the last possible moment
echo "Stopping and disabling systemd-resolved to free up port 53..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Step 5: Remove the symbolic link to /etc/resolv.conf if it exists
if [ -L /etc/resolv.conf ]; then
    echo "Removing /etc/resolv.conf symlink..."
    sudo rm -f /etc/resolv.conf
fi

# Step 6: Restart and enable dnsmasq
echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# Step 7: Configure NetworkManager to stop managing DNS (optional, if using NetworkManager)
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
if [ -f "$NM_CONF" ]; then
    echo "Configuring NetworkManager to stop managing DNS..."
    sudo bash -c "echo -e '[main]\ndns=none' >> $NM_CONF"
    sudo systemctl restart NetworkManager
fi

# Step 8: Recreate /etc/resolv.conf to point to dnsmasq
echo "Creating /etc/resolv.conf to point to dnsmasq..."
sudo bash -c "cat > /etc/resolv.conf" <<EOL
nameserver 127.0.0.1
EOL

# Step 9: Make /etc/resolv.conf immutable to prevent overwrites
echo "Making /etc/resolv.conf immutable..."
sudo chattr +i /etc/resolv.conf

# Step 10: Test DNS resolution for apple.com and nyt.com
test_dns_resolution

echo "dnsmasq setup complete. Google's DNS (8.8.8.8, 8.8.4.4) is now configured."