FROM ubuntu:21.04 as builder
LABEL stage=builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN truncate -s0 /tmp/preseed.cfg && \
    apt-get update && \
    echo "tzdata tzdata/Areas select Europe" >> /tmp/preseed.cfg && \
    echo "tzdata tzdata/Zones/Europe select Berlin" >> /tmp/preseed.cfg && \
    debconf-set-selections /tmp/preseed.cfg && \
    rm -f /etc/timezone /etc/localtime && \
    apt-get install -y git scons gcc g++ openssl check cmake bison \
                       libboost-all-dev libasio-dev libaio-dev libncurses5-dev libreadline-dev \
                       libpam-dev socat libcurl4-openssl-dev pkg-config patchelf && \
    apt-get clean all

RUN git clone https://github.com/percona/percona-xtradb-cluster.git /tmp/percona_src \
    && cd /tmp/percona_src \
    && git checkout 5.7 \
    && git submodule init wsrep/src \
    && git submodule update wsrep/src \
    && git submodule init percona-xtradb-cluster-galera \
    && git submodule update percona-xtradb-cluster-galera \
    && git submodule init extra/coredumper \
    && git submodule update extra/coredumper \
    && cd  percona-xtradb-cluster-galera \
    && git submodule init wsrep/src  \
    && git submodule update wsrep/src \
    && git submodule init  \
    && git submodule update

RUN cd /tmp/percona_src && \
    mkdir pxc-build && \
    ./build-ps/build-binary.sh ./pxc-build

RUN mv /tmp/percona_src/pxc-build/*.aarch64.tar.gz /tmp/percona_server.tar.gz

FROM ubuntu:21.04
COPY --from=builder /tmp/percona_server.tar.gz /tmp/percona_server.tar.gz

RUN cd /tmp && \
    tar -xf percona_server.tar.gz \
    && mv /tmp/Percona-XtraDB-Cluster-*.Linux.aarch64 /usr/local/ \
    && cd /usr/local  \
    && mv Percona-XtraDB-Cluster-*.Linux.aarch64 mysql \
    && mkdir -p /usr/share/mysql/ \
    && cp -r /usr/local/mysql/lib/* /usr/lib/ \
    && cp -r /usr/local/mysql/share/english/* /usr/share/mysql

ENV PATH=$PATH:/usr/local/mysql/bin

RUN apt-get update && apt-get install -y libaio1 libaio-dev libnuma1

ADD my.cnf /etc/mysql/my.cnf
ADD cluster.cnf /etc/mysql/conf.d/cluster.cnf

RUN useradd mysql \
    && rm -rf /var/lib/mysql/ \
    && mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql \
    && chown -R mysql /var/lib/mysql /var/run/mysqld /var/log/mysql


ADD start.sh /start.sh

ENTRYPOINT ["/start.sh"]