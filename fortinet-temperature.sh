#!/bin/sh
SNMPSTRING=public

for HOSTNAME in `grep -E "fw" /etc/xymon/hosts.cfg | awk '{print $2}'`; do
	STATUS=$($BB $BBDISP "query $HOSTNAME.conn" | awk '{print $1}')
 	echo "STATUS = $STATUS"
 	if [ "$STATUS" = "clear" ]; then
		echo "Clear Status on $HOSTNAME"
    		continue
    	fi
	echo "\tSensor Name\t\tCelsius\tFahrenheit" > /tmp/$HOSTNAME.temp
	for TARGET in $(snmpwalk -Oq -v2c -c $SNMPSTRING $HOSTNAME 1.3.6.1.4.1.12356.101.4.3 2>/dev/null | grep -i tempera | awk '{print $1}' ); do
		SENSOR=$(snmpget -Oqv -v2c -c $SNMPSTRING $HOSTNAME $TARGET | sed 's/"//g' | sed 's/ /_/g')
		TARGET2=$(echo $TARGET | sed 's/.101.4.3.2.1.2./.101.4.3.2.1.3./g')
		TEMPERATURE=$(snmpget -Oqv -v2c -c $SNMPSTRING $HOSTNAME $TARGET2 | sed 's/"//g')
		TEMPERATURE2=$(echo "scale=1; $TEMPERATURE/1" | bc)
		TEMPERATUREF=$(echo "scale=1; $TEMPERATURE2*1.8+32" | bc)
		echo "&green\t$SENSOR\t$TEMPERATURE2\t$TEMPERATUREF" >> /tmp/$HOSTNAME.temp
	done
	$BB $BBDISP "status $HOSTNAME.temperature green `date`
`cat /tmp/$HOSTNAME.temp`
"
	rm /tmp/$HOSTNAME.temp
done
