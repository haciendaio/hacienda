sudo apt-get update
sudo apt-get install -y git ruby-dev g++ cmake pkg-config
gem install bundler
echo "export GITHUB_OAUTH_TOKEN=$1" >> /home/vagrant/.bashrc
