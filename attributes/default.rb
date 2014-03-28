case platform
when "debian"

  if platform_version.to_f == 5.0
    default[:postbooks][:version] = "8.3"
  elsif platform_version =~ /squeeze/
    default[:postbooks][:version] = "8.4"
  end

  set[:postbooks][:dir] = "/etc/postgresql/#{node[:postbooks][:version]}/main"

when "ubuntu"

  case
  when platform_version.to_f <= 9.04
    default[:postbooks][:version] = "8.3"
  else
    default[:postbooks][:version] = "9.1"
  end

  set[:postbooks][:dir] = "/etc/postgresql/#{node[:postbooks][:version]}/main"

when "fedora"

  if platform_version.to_f <= 12
    default[:postbooks][:version] = "8.3"
  else
    default[:postbooks][:version] = "8.4"
  end

  set[:postbooks][:dir] = "/var/lib/pgsql/data"

when "redhat","centos","scientific","amazon"

  default[:postbooks][:version] = "8.4"
  set[:postbooks][:dir] = "/var/lib/pgsql/data"

when "suse"

  if platform_version.to_f <= 11.1
    default[:postbooks][:version] = "8.3"
  else
    default[:postbooks][:version] = "8.4"
  end

  set[:postbooks][:dir] = "/var/lib/pgsql/data"

else
  default[:postbooks][:version] = "8.4"
  set[:postbooks][:dir]         = "/etc/postgresql/#{node[:postbooks][:version]}/main"
end


default[:postbooks][:default_statistics_target]=100
default[:postbooks][:max_fsm_pages]=500000
default[:postbooks][:max_fsm_relations]=10000 
default[:postbooks][:logging_collector]="on"
default[:postbooks][:log_rotation_age]="1d"
default[:postbooks][:log_rotation_size]="100MB"
default[:postbooks][:checkpoint_timeout]="5min"
default[:postbooks][:checkpoint_completion_target]=0.5
default[:postbooks][:checkpoint_warning]="30s"
default[:postbooks][:checkpoint_segments]=100
default[:postbooks][:wal_buffers]="8MB"
default[:postbooks][:wal_writer_delay]="200ms"
default[:postbooks][:max_stack_depth]="7MB"
default[:postbooks][:total_memory]=node[:memory][:total].to_i * 1024
default[:postbooks][:total_memory_mb]=(node[:memory][:total].to_i * 1024) / 1024 / 1024
default[:postbooks][:shared_memory_percentage]=0.25
default[:postbooks][:effective_cache_size_percentage]=0.80
default[:postbooks][:shared_buffers]=((node[:memory][:total].to_i * 1024) / 1024 / 1024 * 0.25).to_i
default[:sysctl][:shared_buffers]=node[:memory][:total].to_i * 1024
default[:postbooks][:effective_cache_size]=((node[:memory][:total].to_i * 1024) * 0.80).to_i / 1024 / 1024
if node[:memory][:total].to_i < 5147483648
  default[:postbooks][:maintenance_work_mem]="128MB"
  default[:postbooks][:work_mem]="32MB"
else
  default[:postbooks][:maintenance_work_mem]="256MB"
  default[:postbooks][:work_mem]="64MB"
end

# Server Settings
default[:postbooks][:data_path]="/var/lib/postgresql"
default[:postbooks][:data_directory]="#{node[:postbooks][:data_path]}/#{node[:postbooks][:version]}/main"
default[:postbooks][:wal_directory]="#{node[:postbooks][:data_path]}/#{node[:postbooks][:version]}/pg_xlog"
default[:postbooks][:hba_file]="#{node[:postbooks][:data_path]}/#{node[:postbooks][:version]}/main/pg_hba.conf"
default[:postbooks][:ident_file]="#{node[:postbooks][:data_path]}/pg_ident.conf"
default[:postbooks][:external_pid_file]="#{node[:postbooks][:data_path]}/#{node[:postbooks][:version]}/postgresql.pid"
default[:postbooks][:temp_tablespaces]="/var/tmp/postgresql"
default[:postbooks][:local_authentication]="md5"
default[:postbooks][:encoding]="UTF8"
default[:postbooks][:locale]="en_US.UTF-8"
default[:postbooks][:max_connections]="65535"
# Hot standby Settings
default[:postbooks][:wal_level]="hot_standby"
default[:postbooks][:hot_standby]="off"
default[:postbooks][:hot_standby_feedback]="off"
default[:postbooks][:replicas]=["10.0.0.0/8"]

# Misc Settings
default[:postbooks][:swappiness]="15"
default[:postbooks][:kernel_sem]="4096 6553555 1600 65535"

default[:postbooks][:custom_variable_classes]="plv8"
