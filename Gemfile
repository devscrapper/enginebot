#referentiels
source "http://rubygems.org"
source "http://gems.github.com"
# utiliser en dev net-ssh 2.6.x et pas > sinon capistrano n'arrive plus à se connecter à la machine distante. Si nécessire en prod alors utiliser les groupes

gem 'eventmachine', '~> 1.0.8'
gem 'json', '~> 1.8'
gem 'ruby-progressbar', '~> 1.7.5'
gem 'rufus-scheduler', '~> 2.0.24'
gem 'ice_cube', '~> 0.13.3'
gem 'logging', '~> 2.0.0'
gem 'logging-email', '~> 1.0.0'
gem 'uuid', '~> 2.3.8'
gem 'pony', '~> 1.11.0'
gem 'rest-client', '~> 1.6.7'
gem 'tzinfo', '~> 1.0.0'
gem 'addressable', '2.3.8'
gem 'em-http-server', '~> 0.1.8'
gem 'em-http-request', '~> 1.0.3'
gem 'htmlentities', '~> 4.3', '>= 4.3.4'
# fin new gem

#group :development
group :development do
  gem 'capistrano', '~> 2.15.5'
  gem 'rvm-capistrano', '~> 1.5.3'
  gem 'tzinfo-data', '~>1.2014.5'
  gem "bundler"
end

group :production      do
 # gem "bundler", '~> 1.11.2'
  gem 'i18n', '~> 0.7.0'
end