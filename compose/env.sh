#!/bin/bash

# Source this file before running docker-compose in order to define
# the environment variables required for the build environment
#
# source ./setenv.sh [ dev | qa | uat | prod ]

export COMPOSE_PROJECT_NAME=k2

export build_number=${BUILD_NUMBER:-nobuild}
export build_url=${BUILD_URL:-nobuild}
export build_tag=${BUILD_TAG:-$(date -u +"%Y%m%dT%H%M%SZ")}
export git_commit=${GIT_COMMIT:-$(git rev-parse HEAD)}

if [[ $1 = prod ]] ; then

elif [[ $1 = qa ]] ; then
elif [[ $1 = dev ]] ; then
export mariadb_volume_db1=/Users/jdreiner/mysql/db1:/var/lib/mysql
export mariadb_volume_db2=/Users/jdreiner/mysql/db2:/var/lib/mysql
export mariadb_volume_db3=/Users/jdreiner/mysql/db3:/var/lib/mysql
export db1_sql_port="3306:3306"
export db2_sql_port="3307:3306"
export db3_sql_port="3308:3306"
else
  echo "Unable to determine environment, please specifiy qa/prod/dev"
fi

