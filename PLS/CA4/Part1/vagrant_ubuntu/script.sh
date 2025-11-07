# Update package list

# Speed up apt: use a faster mirror (e.g., Portugal or nearest country)
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://pt.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

# Update package list only if it's older than 1 day (avoids redundant downloads)
if [ $(find /var/lib/apt/lists -name "*_Packages" -mtime +1 | wc -l) -gt 0 ]; then
  sudo apt-get update --quiet
fi


# Upgrade all packages
sudo apt-get upgrade -y

# Install git
sudo apt-get install git -y