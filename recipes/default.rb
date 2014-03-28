#
# Cookbook Name:: postbooks
# Recipe:: default
#
# Copyright 2014, xTuple
#
# All rights reserved - Do Not Redistribute
#

package "wget" do
   action :install
end

execute "get pg key" do
 command 'wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -'
end

execute "add repository" do
  command 'echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
end

apt_repository 'nginx' do
  uri          'http://ppa.launchpad.net/nginx/stable/ubuntu'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          'C300EE8C'
  action :add
end

apt_repository 'node.js-legacy' do
  uri          'http://ppa.launchpad.net/chris-lea/node.js-legacy/ubuntu'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          'C300EE8C'
  action :add
end

## sudo add-apt-repository ppa:chris-lea/node.js -y
apt_repository 'node.js' do
  uri          'http://ppa.launchpad.net/chris-lea/node.js/ubuntu'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          'C7917B12'
  action :add
end

## sudo add-apt-repository ppa:git-core/ppa -y
apt_repository 'git-core' do
  uri          'http://ppa.launchpad.net/git-core/ppa/ubuntu'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          'E1DF1F24'
  action :add
end

execute "apt-get update"
execute "apt-get install pgdg-keyring"

%w{curl build-essential libssl-dev openssh-server cups ncurses-term}.each do |pkg|
apt_package pkg do
   action :install
   end
end

%w{postgresql-9.1 postgresql-server-dev-9.1 postgresql-contrib-9.1}.each do |pgpkg|
package pgpkg do
   action :install
   end
end

apt_package "git"  do
  version "1:1.9.1-0ppa1~precise1"
  action :install
end

apt_package "postgresql-9.1-plv8" do
   version "1.4.0.ds-2.pgdg12.4+1"
   action :install
end

apt_package "nginx-full" do
   version "1.4.6-1+precise0"
   action :install
end

apt_package "nginx-extras" do
   version "1.4.6-1+precise0"
   action :install
end

apt_package "nodejs"  do
  version "0.8.26-1chl1~precise1"
  action :install
end

apt_package "npm" do
   version "1.3.0-1chl1~precise1"
   action :install
end

remote_file "#{Chef::Config[:file_cache_path]}/postbooks_empty-4.3.1.backup" do
  source "http://monitor.xtuple.com/download/4.3.1/postbooks_empty-4.3.1.backup"
  mode "0644"
end

remote_file "#{Chef::Config[:file_cache_path]}/postbooks_quickstart-4.3.1.backup" do
  source "http://monitor.xtuple.com/download/4.3.1/postbooks_quickstart-4.3.1.backup"
  mode "0644"
end

remote_file "#{Chef::Config[:file_cache_path]}/postbooks_demo-4.3.1.backup" do
  source "http://monitor.xtuple.com/download/4.3.1/postbooks_demo-4.3.1.backup"
  mode "0644"
end

group "xtuple" do
  action :create
end

user "xtuple" do
  supports :manage_home => true
  comment "xtuple User"
  gid "users"
  home "/home/xtuple"
  shell "/bin/bash"
  system true
end

group "xtuple" do
  action :modify
  members "xtuple"
  append true
end


# PostgreSQL Server Config Tasks
# postgresql.conf add plv8
# pg-hba.conf rules

execute "init-postgres" do
  command "/usr/bin/pg_createcluster 9.1 main -e=#{node[:postbooks][:encoding]} --locale=#{node[:postbooks][:locale]}"
  action :run
  user "root"
end

=begin
template "/etc/postgresql/9.1/main/postgresql.conf" do
  source 'xt_postgresql.conf.erb'
  mode 0640
  owner 'postgres'
  group 'postgres'
  variables(
            :custom_variable_classes => node[:postbooks][:custom_variable_classes]
            )
end
=end

template "/etc/postgresql/9.1/main/pg_hba.conf" do
  source 'pg_hba.conf.erb'
  owner 'postgres'
  group 'postgres' 
  mode 0640
end

#sysctl "Raise kernel.shmmax" do
#//  variables 'kernel.shmmax' => node[:postbooks][:total_memory]
#//end

#//sysctl "Raise kernel.shmall" do
#//  variables 'kernel.shmall' => node[:postbooks][:total_memory] / 4096
#//  not_if { node[:postbooks][:total_memory]/4096 < 2097152 }
#//end

#//sysctl "Modify kernel.sem" do
#//  variables 'kernel.sem' => node[:postbooks][:kernel_sem]
#//end

#//sysctl "Swappiness of 15" do
#//  variables 'vm.swappiness' => node[:postbooks][:swappiness]
#//end

execute "start postgresql" do
  command "/bin/bash --login -c 'LC_ALL="" /etc/init.d/postgresql start'"
  not_if 'ps aux | grep -v bash | grep [p]ostgres'
end

service "postgresql" do
  action :enable
end

bash "appendplv8" do
 user "root"
 cwd "/tmp"
 code <<-EOH
 echo "custom_variable_classes = 'plv8'" >> /etc/postgresql/9.1/main/postgresql.conf
 EOH
end

bash "createroles" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  psql -U postgres -p 5432 -c "CREATE ROLE xtrole;"
  psql -U postgres -p 5432 -c "CREATE USER admin SUPERUSER IN GROUP xtrole;"
  psql -U postgres -p 5432 -c "CREATE USER monitor IN GROUP xtrole;"
  EOH
end

bash "createdbs" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  createdb -U admin -p 5432 demo
  createdb -U admin -p 5432 quickstart
  createdb -U admin -p 5432 empty
  EOH
end

bash "restoredbs" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  droplang -U admin -p 5432 -d demo plpgsql
  pg_restore -U admin -p 5432 -d demo #{Chef::Config[:file_cache_path]}/postbooks_demo-4.3.1.backup
  createlang -U admin -p 5432 -d demo plv8

  droplang -U admin -p 5432 -d empty plpgsql
  pg_restore -U admin -p 5432 -d empty #{Chef::Config[:file_cache_path]}/postbooks_empty-4.3.1.backup
  createlang -U admin -p 5432 -d empty plv8

  droplang -U admin -p 5432 -d quickstart plpgsql
  pg_restore -U admin -p 5432 -d quickstart #{Chef::Config[:file_cache_path]}/postbooks_quickstart-4.3.1.backup
  createlang -U admin -p 5432 -d quickstart plv8

  EOH
end


# run init.sql - 
# CREATE EXTENSION plv8;
# CREATE ROLE xtrole;
# CREATE USER admin SUPERUSER IN GROUP xtrole;
# CREATE USER node SUPERUSER IN GROUP xtrole;
# CREATE USER monitor;

# create db as owner admin
# CREATE DATABASE postbooks OWNER admin;

# download postbooks db from sourceforge, or other.
# too bad we don't have a symlink to 'latest'
 
directory "/usr/local/xtuple" do
  owner "root"
  group "root"
  mode 00644
  action :create
end

git "/usr/local/xtuple/xtuple" do
  repository "git://github.com/xtuple/xtuple.git"
  reference "master"
  enable_submodules true
  action :sync
end

git "/usr/local/xtuple/xtuple-extensions" do
  repository "git://github.com/xtuple/xtuple-extensions.git"
  reference "master"
  enable_submodules true
  action :sync
end

execute "npm-install-xt" do
  cwd "/usr/local/xtuple/xtuple"
  command "npm  install 2>&1"
  action :run
end

execute "npm-install-xtext" do
  cwd "/usr/local/xtuple/xtuple-extensions"
  command "npm  install 2>&1"
  action :run
end

=begin
git "/usr/local/xtuple/private-extensions" do
  repository "git://github.com/xtuple/private-extensions.git"
  reference "master"
  enable_submodules true
  action :sync
end

git "/usr/local/xtuple/bi" do
  repository "git://github.com/xtuple/bi.git"
  reference "master"
  enable_submodules true
  action :sync
end

npm_package do
  path "/usr/local/xtuple/xtuple"
  action :install_from_json
end

npm_package do
  path "/usr/local/xtuple/xtuple-extensions"
  action :install_from_json
end
=end
