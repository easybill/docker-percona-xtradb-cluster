#!/bin/bash

sed -i "s~ENV_SQL_MODE~$SQL_MODE~" /etc/mysql/my.cnf

touch /var/log/mysql/error.log
chmod -R 777 /var/lib/mysql
chmod -R 777 /var/log/mysql
mysqld --initialize-insecure --datadir=/var/lib/mysql --user=mysql
chmod -R 777 /var/lib/mysql
chmod -R 777 /var/log/mysql

asyncRun() {
    "$@" &
    pid="$!"
    trap "echo 'Stopping PID $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

    # A signal emitted while waiting will make the wait command return code > 128
    # Let's wrap it in a loop that doesn't end before the process is indeed stopped
    while kill -0 $pid > /dev/null 2>&1; do
        wait
    done
}

mv /etc/mysql/conf.d/cluster.cnf /_cluster.cnf

mysqld --user=mysql --datadir=/var/lib/mysql &
pid="$!"

mysql=( mysql -uroot --port=3306 )

for i in {3000..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" ; then
                break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
done
if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
fi

"${mysql[@]}" <<-EOSQL
    -- What's done in this file shouldn't be replicated
    --  or products like mysql-fabric won't work
    SET @@SESSION.SQL_LOG_BIN=0;
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' ;
    GRANT ALL ON *.* to root@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

    CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL ON *.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

    FLUSH PRIVILEGES ;
EOSQL

if ! kill -s TERM "$pid" || ! wait "$pid"; then
    echo >&2 'MySQL init process failed.'
    exit 1
fi

echo
echo 'MySQL init process done. Ready for start up.'
echo

echo "safe_to_bootstrap: 0" > /var/lib/mysql/grastate.dat
if [ "$BOOTSTRAP" == "1" ]; then
    echo "safe_to_bootstrap: 1" > /var/lib/mysql/grastate.dat
fi
chmod 777 /var/lib/mysql/grastate.dat


mv /_cluster.cnf /etc/mysql/conf.d/cluster.cnf


sed -i "s~ENV_WSREP_CLUSTER_ADDRESS~$WSREP_CLUSTER_ADDRESS~" /etc/mysql/conf.d/cluster.cnf
sed -i "s~ENV_WSREP_CLUSTER_NAME~$WSREP_CLUSTER_NAME~" /etc/mysql/conf.d/cluster.cnf
sed -i "s~ENV_WSREP_NODE_NAME~$WSREP_NODE_NAME~" /etc/mysql/conf.d/cluster.cnf

if [ "$*" == "" ]; then
    cd /var/lib/mysql
    if [ "$BOOTSTRAP" == "1" ]; then
        asyncRun mysqld --wsrep-new-cluster --datadir=/var/lib/mysql --user=mysql
    else
        asyncRun mysqld --datadir=/var/lib/mysql --user=mysql
    fi

    mysql=( mysql -uroot -p"${MYSQL_PASSWORD}" --host=127.0.0.1 --port=3306 )
    for i in {3000..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" ; then
                break
        fi
        echo 'wait for mysql ready'
        sleep 1
    done

else
    /bin/bash -l -c "$*"
fi