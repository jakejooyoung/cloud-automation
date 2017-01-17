#!/bin/bash -eo pipefail
#
# Creates json for a basic upsert requests
# for both A_RECORD and CNAME  
#######################################
function err_report(){
	echo "${RED}[ERROR]${RESET} ${0##*/}:$1"
	exit 1
}
function missingarg(){
	echo "${RED}[ERROR] MISSING ARGS${RESET} ${0##*/}:$1"
	exit 1
}
####
trap '[[ -z $1 || -z $2 ]] && missingarg' EXIT
if [[ -z $1 || -z $2 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] || err_report $LINENO' EXIT
function fill_json(){
	json='{"Action":"'$1'","ResourceRecordSet":{"Name":"'$2'","Type":"'$3'","TTL":'$4',"ResourceRecords":[{"Value":"'$5'"}]}}'
	echo $json
}
function make_json(){
	local name=$1
	local value=$2
	arec=$(fill_json "UPSERT" $name "A" 300 $value)
	cnamerec=$(fill_json "UPSERT" "www.$name" "CNAME" 300 $name)
	arec_cname_json=$(echo '{"Changes":['$arec','$cnamerec']}')
	echo $arec_cname_json
}

make_json $1 $2

exit 0