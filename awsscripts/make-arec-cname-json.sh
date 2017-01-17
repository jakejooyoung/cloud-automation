#!/bin/bash -eou	 pipefail
#
# Creates json for a basic upsert requests
# for both A_RECORD and CNAME  
#######################################
function err_report(){
	echo >&2 "
		Failed to make JSON for 
		A&CNAME rec requests
		for this domain.

		Error on line $1.
		Now exiting...
	"
	exit 1
}
trap '[ "$?" -eq 0 ] || err_report $LINENO' EXIT

function fill_json(){
	message=$(
	  tr "\n" " " <<- END
	    {
				"Action":"$1",
				"ResourceRecordSet":{
					"Name":"$2",
					"Type":"$3",
					"TTL":$4, 
					"ResourceRecords":[{
						"Value":"$5"
					}]
				}
			}
	END)
	echo $message
}
function make_json(){
	arec=$(fill_json "UPSERT" $name "A" 300 $value)	
	cnamerec=$(fill_json "UPSERT" "www.$name" "CNAME" 300 $name)
	arec_cname_json=$(jq -C -n "{\"Changes\": [$arec, $cnamerec]}")
	echo $arec_cname_json
}
function missingarg(){
	echo >&2 '
	 	ERROR! Missing Args:
	 	Provide Record Name 
	 	and IP value.
	'
	exit 1
}
if [[ -z $1 || -z $2 ]]; then
	missingarg
fi
name=$1
value=$2
make_json

exit 0