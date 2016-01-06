#!/bin/bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

function shutdown()
{
    date
    echo "Shutting down Tomcat"
    ${CATALINA_HOME}/bin/catalina.sh stop
}

# Allow any signal which would kill a process to stop Tomcat
trap shutdown HUP INT QUIT ABRT KILL ALRM TERM TSTP

if [ ! -f ${CATALINA_HOME}/scripts/.tomcat_admin_created ]; then
	${CATALINA_HOME}/scripts/create_admin.sh
fi

date
echo "Starting Tomcat"
export CATALINA_PID=/tmp/$$

exec ${CATALINA_HOME}/bin/catalina.sh run

echo "Waiting for `cat $CATALINA_PID`"
wait `cat $CATALINA_PID
