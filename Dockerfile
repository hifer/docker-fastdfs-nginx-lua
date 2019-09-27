FROM alpine:3.10.2

MAINTAINER lvhfa <lvhfa@yonyou.com>

ENV SETUP_HOME=/root/fastdfs \
    NGINX_VERSION=1.16.1 \
    LUAJIT_VERSION=2.0.5 \
    NGX_DEVEL_KIT_VERSION=0.3.1 \
    LUA_NGINX_MODULE_VERSION=0.10.13 \
    NGINX_PORT=80 \
    FDFS_PORT=22122
    
RUN mkdir -p ${SETUP_HOME}

# 修改安装源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# nginx配置
ADD ./nginx.conf ${SETUP_HOME}/

# 启动脚本
ADD ./start.sh ${SETUP_HOME}/

# 安装依赖包
RUN apk add --no-cache --virtual .build-deps \
	gcc \
	make \
	linux-headers \
	curl \
	gnupg \
	libc-dev \
	libxslt-dev \
	openssl-dev \
	perl-dev \
    && apk add --no-cache \
	bash \
        gd-dev \
        pcre-dev \
        geoip-dev \
        lua-dev \
	zlib-dev \
	tzdata \
    && cd ${SETUP_HOME}/ \
    && curl -fSL  https://github.com/happyfish100/libfastcommon/archive/master.tar.gz -o fastcommon.tar.gz \
    && tar zxf fastcommon.tar.gz \
    && cd ${SETUP_HOME}/libfastcommon-master/ \
    && ./make.sh \
    && ./make.sh install \
# 下载、编译fastdfs
    && cd ${SETUP_HOME}/ \
    && curl -fSL  https://github.com/happyfish100/fastdfs/archive/master.tar.gz -o fastfs.tar.gz \
    && tar zxf fastfs.tar.gz \
    && cd ${SETUP_HOME}/fastdfs-master/ \
    && ./make.sh \
    && ./make.sh install \
# 配置fastdfs
    && cd /etc/fdfs/ \
    && cp storage.conf.sample storage.conf \
    && sed -i "s|/home/yuqing/fastdfs|/data/fastdfs/storage|g" /etc/fdfs/storage.conf \
    && cp tracker.conf.sample tracker.conf \
    && sed -i "s|/home/yuqing/fastdfs|/data/fastdfs/tracker|g" /etc/fdfs/tracker.conf \
    && cp client.conf.sample client.conf \
    && sed -i "s|/home/yuqing/fastdfs|/data/fastdfs/storage|g" /etc/fdfs/client.conf \
# 下载nginx-fastdfs插件
    && cd ${SETUP_HOME}/ \
    && curl -fSL  https://github.com/happyfish100/fastdfs-nginx-module/archive/master.tar.gz -o nginx-module.tar.gz \
    && tar zxf nginx-module.tar.gz \
# 下载nginx
    && cd ${SETUP_HOME}/ \
    && curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz \
# 下载、安装LuaJIT
    && cd ${SETUP_HOME}/ \
    && curl -fSL http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz -o LuaJIT-${LUAJIT_VERSION}.tar.gz \
    && tar zxf LuaJIT-${LUAJIT_VERSION}.tar.gz \
    && cd ${SETUP_HOME}/LuaJIT-${LUAJIT_VERSION} \
    && make PREFIX=/usr/local/luajit \
    && make install PREFIX=/usr/local/luajit \
    && export LUAJIT_LIB=/usr/local/luajit/lib \
    && export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0 \
    && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/luajit/lib \
# 下载NDK
    && cd ${SETUP_HOME}/ \
    && mkdir -p /usr/local \
    && curl -fSL https://github.com/simplresty/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz -o v${NGX_DEVEL_KIT_VERSION}.tar.gz \
    && tar zxf v${NGX_DEVEL_KIT_VERSION}.tar.gz -C /usr/local \
# 下载lua-nginx-module
    && cd ${SETUP_HOME}/ \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.tar.gz -o v${LUA_NGINX_MODULE_VERSION}.tar.gz \
    && tar zxf v${LUA_NGINX_MODULE_VERSION}.tar.gz -C /usr/local \
# nginx编译安装
    && cd ${SETUP_HOME} \
    && sed -i "s+char uri[256]+char uri[2048]+g" ${SETUP_HOME}/fastdfs-nginx-module-master/src/common.c \
    && cd nginx-${NGINX_VERSION} \
    && export CFLAGS="-Wno-error" \
    && export CXXFLAGS="-Wno-error" \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && ./configure \
	--add-module=${SETUP_HOME}/fastdfs-nginx-module-master/src \
	--add-module=/usr/local/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
	--add-module=/usr/local/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
	--with-ld-opt=-Wl,-rpath,${LUAJIT_LIB} \
	--with-http_image_filter_module \
	--with-http_v2_module \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_geoip_module \
	--with-http_perl_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-stream_geoip_module=dynamic \
	--with-http_slice_module \
	--with-file-aio \
	--with-ipv6 \
	--user=nginx \
	--group=nginx \
    && make && make install \
# 配置nginx和fastdfs环境，配置nginx
    && cp ${SETUP_HOME}/fastdfs-nginx-module-master/src/mod_fastdfs.conf /etc/fdfs/ \
    && cd ${SETUP_HOME}/fastdfs-master/conf/ \
    && cp http.conf mime.types anti-steal.jpg /etc/fdfs/ \
    && rm -rf /usr/local/nginx/conf/nginx.conf \
    && cp ${SETUP_HOME}/nginx.conf /usr/local/nginx/conf/nginx.conf \
    && apk del .build-deps \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# 启动脚本执行权限
    && cp ${SETUP_HOME}/start.sh / \
    && chmod u+x /start.sh \
    && rm -rf ${SETUP_HOME}/*


# 暴露端口
EXPOSE ${NGINX_PORT} ${FDFS_PORT}

ENTRYPOINT ["/bin/sh","-c","/start.sh ${NGINX_PORT} ${FDFS_PORT}"]

