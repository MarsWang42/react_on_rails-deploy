# Create new user called deploy
sudo adduser deploy
sudo adduser deploy sudo
su deploy


# Install Ruby 2.4.0 via rbenv
sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.4.0
rbenv global 2.4.0
ruby -v

gem install bundler
rbenv rehash


# Install Nodejs 7.x
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo apt-get install -y nodejs


# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn


# Install Nginx and Passenger
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates

sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update

sudo apt-get install -y nginx-extras passenger
sudo service nginx start


# Update mgomx.conf
sudo vim /etc/nginx/nginx.conf
uncomment "include /etc/nginx/passenger.conf;"

sudo vim /etc/nginx/passenger.conf
add "passenger_ruby /home/deploy/.rbenv/shims/ruby;"

sudo service nginx restart


# Install PostgreSQL and setup
sudo apt-get install postgresql postgresql-contrib libpq-dev

sudo su - postgres
createuser --pwprompt deploy
createdb -O deploy my_app_name_production # change "my_app_name" to your app's name which we'll also use later on
exit


# Add the Nginx Host
sudo vim /etc/nginx/sites-enabled/default

server {
        listen 80;
        listen [::]:80 ipv6only=on;

        server_name mydomain.com;
        passenger_enabled on;
        rails_env    production;
        root         /home/deploy/my_app_name/current/public;

        # redirect server error pages to the static page /50x.html
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
}


# Update database.yml and secrets.yml
sudo vim /home/deploy/my_app_name/shared/config/database.yml # replace my_app_name with your app name.

production:
  adapter: postgresql
  host: 127.0.0.1
  database: my_app_name_production
  username: deploy
  password: YOUR_POSTGRES_PASSWORD
  encoding: unicode
  pool: 5

sudo vim /home/deploy/my_app_name/shared/config/secrets.yml

production:
  secret_key_base: YOUR_SECRET_KEY


# Restart the server and deploy
cap production deploy
touch my_app_name/current/tmp/restart.txt
