#!/bin/bash
su - ec2-user -c "kong stop"
export IP_ADDR=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
wget https://bintray.com/kong/kong-community-edition-aws/download_file\?file_path\=dists/kong-community-edition-0.11.1.aws.rpm -O kong.rpm
yum install -y epel-release
yum install -y kong.rpm --nogpgcheck

#Increase limits
cat << 'EOF' > /etc/security/limits.d/90-nginx.conf
*	soft nofile 4096
*	hard nofile 4096
EOF

cat << 'EOF' > /etc/sysctl.d/90-nginx.conf
net.core.somaxconn = 65536
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_max_syn_backlog = 3240000
EOF

/sbin/sysctl -p

#Install the Kong config
mkdir -p /etc/kong/
cat << 'EOF' > /etc/kong/kong.conf
database = kong
pg_host = ${pg_host}
pg_port = 5432
pg_password = ${pg_pass}
pg_database = ${pg_db}
pg_user = ${pg_user}
cluster_listen = 0.0.0.0:7946
server_tokens = off
EOF

cat << 'EOF' > /etc/kong/nginx.template
# ---------------------
# custom_nginx.template
# ---------------------

worker_processes $${{NGINX_WORKER_PROCESSES}}; # can be set by kong.conf
daemon $${{NGINX_DAEMON}};                     # can be set by kong.conf

pid pids/nginx.pid;                      # this setting is mandatory
error_log logs/error.log $${{LOG_LEVEL}}; # can be set by kong.conf
worker_rlimit_nofile    20000; 
events {
    use epoll; # custom setting
    multi_accept on;
    worker_connections 20000;
}

http {
    # include default Kong Nginx config
    include 'nginx-kong.conf';
    keepalive_timeout 65;
    keepalive_requests 100000;
    sendfile         on;
    tcp_nopush       on;
    tcp_nodelay      on;

    client_body_buffer_size      128k;
    client_header_buffer_size    1k;
    large_client_header_buffers  4 64k;
    output_buffers               1 64k;
    postpone_output              1460;

    client_header_timeout  3m;
    client_body_timeout    3m;
    send_timeout           3m;

    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 5;
    open_file_cache_errors off;


}
EOF

echo "cluster_advertise = $IP_ADDR:7946" >> /etc/kong/kong.conf
service cassandra stop
rm /usr/local/kong/serf/serf.id
su - ec2-user -c "kong start -c /etc/kong/kong.conf --nginx-conf /etc/kong/nginx.template"