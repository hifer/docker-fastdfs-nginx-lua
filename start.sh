#!/usr/bin/env sh

# nginx端口默认值
NGINX_PORT=$1
# 网卡
NETWORK_CARD=eth0
# fastdfs端口默认值
FDFS_PORT=$2
# group分组个数,如有多个分组设置此项
GROUP_COUNT=1
# 存储目录
STORAGE_PATH=/data/fastdfs/storage

# 创建存储目录和软连接
mkdir -p /data/fastdfs/storage/data /data/fastdfs/tracker;
ln -s /data/fastdfs/storage/data/ /data/fastdfs/storage/data/M00;

# 动态修改NGINX监听端口
sed -i "s/listen .*$/listen $NGINX_PORT;/g" /usr/local/nginx/conf/nginx.conf; 

# fdfs配置
sed -i "s/http.server_port.*$/http.server_port = $NGINX_PORT/g" /etc/fdfs/storage.conf; 
if [ "$HOST_IP" = "" ]; then 
    HOST_IP=$(ifconfig $NETWORK_CARD | grep "inet" | grep -v "inet6" | awk '{print $2}' | awk -F: '{print $2}')
fi 

sed -i "s+^tracker_server.*$+tracker_server = $HOST_IP:$FDFS_PORT+g" /etc/fdfs/storage.conf;
sed -i "s+^tracker_server.*$+tracker_server = $HOST_IP:$FDFS_PORT+g" /etc/fdfs/client.conf;
sed -i "s+^tracker_server.*$+tracker_server = $HOST_IP:$FDFS_PORT+g" /etc/fdfs/mod_fastdfs.conf;
#sed -i "s+^group_count =.*$+group_count = $GROUP_COUNT+g" /etc/fdfs/mod_fastdfs.conf;
sed -i "s+^store_path0.*$+store_path0 = $STORAGE_PATH+g" /etc/fdfs/mod_fastdfs.conf;
sed -i "s+^url_have_group_name =.*$+url_have_group_name = true+g" /etc/fdfs/mod_fastdfs.conf;

# 启动
/etc/init.d/fdfs_trackerd start; 
/etc/init.d/fdfs_storaged start; 
/usr/local/nginx/sbin/nginx -g 'daemon off;';
