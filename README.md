# docker-fastdfs-nginx-lua

# 构建镜像
```
git clone https://github.com/hifer/docker-fastdfs-nginx-lua.git
cd docker-fastdfs-nginx-lua
docker build -t fastdfs:2.0 .
```

# 运行
```
docker run -d --net=host --restart=always \
    --name=fastdfs\
    -e TZ=Asia/Shanghai \
    -e HOST_IP=10.3.78.164 \
    -v /data/fastdfs:/data/fastdfs \
    fastdfs:2.0
```

ps:HOST_IP默认取eth0网卡，如网卡非eth0,请添加-e HOST_IP=x.x.x.x配置
如果需要更爱nginx端口：添加-e NGINX_PORT=8888
