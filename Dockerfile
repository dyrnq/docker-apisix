FROM centos:7

ARG APISIX_VERSION=2.9
LABEL apisix_version="${APISIX_VERSION}"



RUN set -eux && \
    yum clean all && \
    yum makecache && \
    yum update -y && \
    yum install git -y && \
    git clone --depth 1 https://github.com/api7/apisix-build-tools && \
    groupadd --system --gid 1001 nginx && \
    adduser --system --gid 1001 --no-create-home --home /nonexistent --comment "nginx user" --shell /bin/false --uid 1001 nginx && \
    cd apisix-build-tools && \
    sed -i "s@--with-compat@--with-compat --user=nginx --group=nginx@g" build-apisix-openresty.sh && \
    bash build-apisix-openresty-centos7.sh


RUN yum install -y pcre which tzdata ca-certificates \
    && curl -fsSL -o /tmp/apisix.rpm https://github.com/apache/apisix/releases/download/$APISIX_VERSION/apisix-$APISIX_VERSION-0.el7.x86_64.rpm \
	&& rpm -ivh --nodeps /tmp/apisix.rpm \
	&& yum clean all \
	&& sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t60/g' /etc/login.defs

WORKDIR /usr/local/apisix

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/apisix/logs/access.log \
    && ln -sf /dev/stderr /usr/local/apisix/logs/error.log

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

EXPOSE 9080 9443

CMD ["sh", "-c", "/usr/bin/apisix init && /usr/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]