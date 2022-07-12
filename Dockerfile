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
    sed \
    -e "s@--with-compat@--with-compat --user=nginx --group=nginx@g" \
    -e "/set -x/aversion=\"master\"" \
    -i.bak \
    build-apisix-base.sh && \
    utils/build-common.sh build_apisix_base_rpm


RUN yum install -y pcre which tzdata ca-certificates && \
    yum install -y https://repos.apiseven.com/packages/centos/apache-apisix-repo-1.0-1.noarch.rpm && \
    yum clean all && \
    yum makecache -y && \
    yum install -y --downloadonly --downloaddir=/tmp apisix-$APISIX_VERSION-0.el7 && \
    rpm -ivh --nodeps /tmp/apisix-$APISIX_VERSION-*.rpm && \
    yum clean all && \
    rm -rf /tmp/*.rpm && \
    sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t60/g' /etc/login.defs && \
    curl -fsL -o /usr/bin/apisix https://raw.githubusercontent.com/apache/apisix/250db3b28fc6e43e6d97f8512ca5c4d3ca83eead/bin/apisix

WORKDIR /usr/local/apisix

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/apisix/logs/access.log \
    && ln -sf /dev/stderr /usr/local/apisix/logs/error.log

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

EXPOSE 9080 9443

CMD ["sh", "-c", "/usr/bin/apisix init && /usr/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]
