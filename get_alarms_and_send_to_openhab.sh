#!/bin/bash

#Source https://rithvikvibhu.github.io/GHLocalApi/

NestHubIP="192.168.XXX.XXX"

send_to_openhab(){
    OHIP="localhost"
    item="Wecker_NestHub"
    curl -X PUT --header "Content-Type: text/plain" --header "Accept: application/json" -d "$state" "http://$OHIP:8080/rest/items/$item/state"
}

#Change to the source directory
cd $(dirname "$(readlink -f "$BASH_SOURCE")")


#get access_token
access_token=$(python ./get_master_and_access_tokens.py | grep "ya29" )
echo "Access Token: $access_token"


#get auth token of NestHub
local_auth_token=$(./get_local_auth_token.go -H "authorization: Bearer $access_token" \
  -import-path . \
  -proto ./proto_helper \
  googlehomefoyer-pa.googleapis.com:443 \
  google.internal.home.foyer.v1.StructuresService/GetHomeGraph | \
jq '.home.devices[] | {deviceName, localAuthToken} | select(.localAuthToken != null) | select(.deviceName == "Nest Hub")' | jq '.localAuthToken' | sed 's/"//g')
echo "Local Auth Token of Nest Hub: $local_auth_token"


#Abfrage der Wecker von der API von Nest Hub
all_alarms=$(curl -H "cast-local-authorization-token: $local_auth_token" --insecure https://$NestHubIP:8443/setup/assistant/alarms 2>/dev/null | jq '.alarm' | grep "fire_time")
if [[ -z $all_alarms ]]; then
    echo -e "There are no alarms"
    state="UNDEF"
    send_to_openhab
    exit 0
fi
echo -e "All Alarms:\n$all_alarms"


#Die Zahlen extrahieren und den ersten Wecker finden
next_alarm=$(echo $all_alarms | grep -oE '[0-9]{1,}' | sort -n | head -1)
echo "Next Alarm: $next_alarm"


#Millis des nächsten Wecker zu leserlichem String konvertieren
naechster_wecker_formatted_for_humans=$(date -d @$( echo "($next_alarm + 500) / 1000" | bc) +"%H:%M Uhr, %d.%m.")
echo -e "Next Alarms headable: $naechster_wecker_formatted_for_humans"


#Millis des nächsten Wecker zu String für OpenHAB konvertieren
naechster_wecker_formatted_for_openhab=$(date -d @$( echo "($next_alarm + 500) / 1000" | bc) +"%Y-%m-%dT%H:%M:%S")
echo -e "Next Alarm headble by openHAB:\t $naechster_wecker_formatted_for_openhab"


#Send alarm to openHAB
state=$naechster_wecker_formatted_for_openhab
send_to_openhab


exit 0
