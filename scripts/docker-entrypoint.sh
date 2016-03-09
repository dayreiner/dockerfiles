#!/bin/bash
set -e
#set -x

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

attn () {
    echo
    echo "======================================="
    echo
}

preflight () {
    if [[ -z ${CLUSTER_NAME+x} ]]; then
        attn
        echo >&2 "CLUSTER_NAME variable must be set."
        exit 1
    elif [[ -z ${SST_USER+x} || -z ${SST_PASS+x} ]]; then
        attn
        echo >&2 "SST_USER and SST_PASS variables must be set in order to start the cluster."
        exit 1
    fi 
}

cluster_conf () {
    attn
    echo "Configuring /etc/my.cnf.d/server.cnf with cluster variables"
    echo "wsrep_sst_auth                 = ${SST_USER}:${SST_PASS}" >> /etc/my.cnf.d/server.cnf
    echo "wsrep_on                       = ON" >> /etc/my.cnf.d/server.cnf
    # Set mysql log and slow query log to /dev/stdout for container logging
    sed -i 's/NULL/\/dev\/stdout/g' /etc/my.cnf.d/server.cnf
}

if [ "$1" = 'mysqld' ]; then
	# Get config
	#DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
	DATADIR="/var/lib/mysql"

	if [ ! -d "$DATADIR/mysql" ]; then
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
			echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
			exit 1
		fi

		mkdir -p "$DATADIR"
		chown -R mysql:mysql "$DATADIR"

		echo 'Initializing database'
		mysql_install_db --user=mysql --datadir="$DATADIR" --rpm
		echo 'Database initialized'

		"$@" --skip-networking &
		pid="$!"

		mysql=( mysql --protocol=socket -uroot )

		for i in {30..0}; do
			if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
			# sed is for https://bugs.mysql.com/bug.php?id=20545
			mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
		fi


		if [ ${DBMODE} = "BOOTSTRAP" ]; then
			preflight
			echo "Creating SST User for cluster state transfer..."
			"${mysql[@]}" <<-EOSQL
				--  Set up sst user for galera
				SET @@SESSION.SQL_LOG_BIN=0;
	
				CREATE USER '${SST_USER}'@'%' IDENTIFIED BY '${SST_PASS}' ;
				GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO '${SST_USER}'@'%' ;
				FLUSH PRIVILEGES ;
			EOSQL
		fi	

		"${mysql[@]}" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;

			DELETE FROM mysql.user ;
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			DROP DATABASE IF EXISTS test ;
			FLUSH PRIVILEGES ;
		EOSQL

		if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
			mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
		fi

		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
			mysql+=( "$MYSQL_DATABASE" )
		fi

		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | "${mysql[@]}"

			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
			fi

			echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
		fi

		echo
		for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)  echo "$0: running $f"; . "$f" ;;
				*.sql) echo "$0: running $f"; "${mysql[@]}" < "$f" && echo ;;
				*)     echo "$0: ignoring $f" ;;
			esac
			echo
		done

		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		echo
		echo 'MySQL init process done. Ready for start up.'
		echo
	fi

	chown -R mysql:mysql "/var/lib/mysql"
fi

if [ -z ${DBMODE+x} ]; then
    attn
    echo >&2 "DBMODE variable must be defined as STANDALONE, BOOTSTRAP or a comma-separated list of container names."
    exit 1
elif [ ${DBMODE} = "STANDALONE" ]; then
    attn
    echo "Starting MariaDB in STANDALONE mode..."
    # Set mysql log and slow query log to /dev/stdout for container logging
    sed -i 's/NULL/\/dev\/stdout/g' /etc/my.cnf.d/server.cnf
    exec "$@" 
elif [ ${DBMODE} = "BOOTSTRAP" ]; then
    attn
    echo "Bootstrapping MariaDB cluster ${CLUSTER_NAME} with primary node ${HOSTNAME}..."
    preflight
    cluster_conf
    exec $@ --wsrep_node_address="${HOSTNAME}" \
	--wsrep_cluster_name="${CLUSTER_NAME}" \
        --wsrep_new_cluster --wsrep_cluster_address="gcomm://" \
	--wsrep_node_name="${HOSTNAME}" 
else
    attn
    echo "Joining MariaDB cluster ${CLUSTER_NAME} on nodes ${DBMODE}..."
    preflight
    cluster_conf
    exec $@ --wsrep_node_address="${HOSTNAME}" \
	--wsrep_cluster_name="${CLUSTER_NAME}" \
        --wsrep_cluster_address=gcomm://${DBMODE}
	--wsrep_node_name="${HOSTNAME}"
fi
