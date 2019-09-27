# docker-fastdfs-nginx-lua

```
docker run -d -p 80:80 -p 22122:22122 \
    --name=fastdfs\
    -e TZ=Asia/Shanghai \
    -e HOST_IP=10.3.78.164 \
    -v /data/fastdfs:/data/fastdfs \
    fastdfs:2.0
```
