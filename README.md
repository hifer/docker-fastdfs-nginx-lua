# docker-fastdfs-nginx-lua

```
docker run -d --net=host --restart=always \
    --name=fastdfs\
    -e TZ=Asia/Shanghai \
    -e HOST_IP=10.3.78.164 \
    -v /data/fastdfs:/data/fastdfs \
    fastdfs:2.0
```
