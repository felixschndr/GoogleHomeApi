#!/bin/bash

#https://rithvikvibhu.github.io/GHLocalApi/

send(){
    OHIP="localhost"
    item="Wecker_NestHub"
    curl -X PUT --header "Content-Type: text/plain" --header "Accept: application/json" -d "$state" "http://$OHIP:8080/rest/items/$item/state"
}

#In das Verzeichnis des Script wechseln
cd $(dirname "$(readlink -f "$BASH_SOURCE")")


#Access Token holen; wechselt circa stündlich
access_token=$(python ./get_master_and_access_tokens.py | grep "ya29" )
#echo "Access Token von Nest Hub: $access_token"


#Lokalen Auth Token holen
local_auth_token=$(./get_local_auth_tokens.go -H "authorization: Bearer $access_token" \
  -import-path . \
  -proto ./proto_helper \
  googlehomefoyer-pa.googleapis.com:443 \
  google.internal.home.foyer.v1.StructuresService/GetHomeGraph | \
jq '.home.devices[] | {deviceName, localAuthToken} | select(.localAuthToken != null) | select(.deviceName == "Nest Hub")' | jq '.localAuthToken' | sed 's/"//g')
#echo "Lokaler Auth Token von Nest Hub: $local_auth_token"


#Abfrage der Wecker von der API von Nest Hub
alle_wecker=$(curl -H "cast-local-authorization-token: $local_auth_token" --insecure https://192.168.178.35:8443/setup/assistant/alarms 2>/dev/null | jq '.alarm' | grep "fire_time")
if [[ -z $alle_wecker ]]; then
    echo -e "Es sind keine Wecker gestellt"
    state="UNDEF"
    send
    exit 0
fi
echo -e "Alle Wecker:\n$alle_wecker"


#Die Zahlen extrahieren und den ersten Wecker finden
naechster_wecker=$(echo $alle_wecker | grep -oE '[0-9]{1,}' | sort -n | head -1)
echo "Nächster Wecker: $naechster_wecker"


#Millis des nächsten Wecker zu leserlichem String konvertieren
naechster_wecker_formatiert_menschlich=$(date -d @$( echo "($naechster_wecker + 500) / 1000" | bc) +"%H:%M Uhr, %d.%m.")
echo -e "Nächster Wecker formatiert für Menschen: $naechster_wecker_formatiert_menschlich"


#Millis des nächsten Wecker zu String für OpenHAB konvertieren
naechster_wecker_formatiert_openhab=$(date -d @$( echo "($naechster_wecker + 500) / 1000" | bc) +"%Y-%m-%dT%H:%M:%S")
echo -e "Nächster Wecker formatiert für OpenHAB:\t $naechster_wecker_formatiert_openhab"


#Wecker an OpenHAB senden
state=$naechster_wecker_formatiert_openhab
send


exit 0
