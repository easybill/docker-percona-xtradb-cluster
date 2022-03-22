# Percona XtraDB Cluster Container (from source)
This image comes with **arm64** and **amd64** support.
do not use this image in production it's for development only.

We built the image because there are no official arm64 packages.

Image is available at [Dockerhub](https://hub.docker.com/r/easybill/percona_xtradb_cluster).

## Percona XtraDB Cluster 5.7

plain docker:
```
docker run --rm \ 
    -e "WSREP_CLUSTER_ADDRESS=gcomm://" 
    -e "WSREP_CLUSTER_NAME=eb1" \ 
    -e "MYSQL_USER=username" \ 
    -e "MYSQL_PASSWORD=password" \
    -e "BOOTSTRAP=1" \
    -e "SQL_MODE=NO_ENGINE_SUBSTITUTION" \
    -e "WSREP_NODE_NAME=master" \
    -p "3306:3306" \
    --mount type=tmpfs,destination=/var/lib/mysql \ 
    --mount type=tmpfs,destination=/var/log/mysql \
    easybill/percona_xtradb_cluster:57_latest
```

docker compose:

```yml
version: '3.3'
services:
  db:
    security_opt:
      - seccomp:unconfined
    image: easybill/percona_xtradb_cluster:57_latest
    tmpfs:
      - /var/lib/mysql:exec,mode=777,size=2G
      - /var/log/mysql:exec,mode=777,size=2G
    environment:
        MYSQL_PASSWORD: username
        MYSQL_USER: password
        WSREP_CLUSTER_ADDRESS: 'gcomm://'
        WSREP_CLUSTER_NAME: eb1
        BOOTSTRAP: 1
        WSREP_NODE_NAME: master
        SQL_MODE: NO_ENGINE_SUBSTITUTION
```
