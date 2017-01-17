#!/bin/bash -eo pipefail
#
# Creates json for a basic upsert requests
# for both A_RECORD and CNAME  
#######################################
function missingarg(){
	echo "${RED}[ERROR] MISSING ARGS${RESET} ${0##*/}:$1"
	exit 1
}
function err_report(){
	echo "${RED}[ERROR]${RESET} ${0##*/}:$1"
	exit 1
}
function success(){
	echo "${GREEN}[PASS]${RESET} There are no zones associated with domain."
	exit 0
}
####
trap '[[ -z $1 ]] && missingarg' EXIT
if [[ -z $1 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] && success || err_report $LINENO' EXIT
function list_all_zones_for_domain(){
	zone_list="$(aws route53 list-hosted-zones \
		--output text \
		--query 'HostedZones[?Name==`'$1'.`].Id')"
	count=$(echo $zone_list | wc -w)
	if [[ $count -eq 0 ]]; then exit 0; fi
}
function delete_all_zones_for_this_domain(){
	local dn=$1
	list_all_zones_for_domain $dn
	echo "Found zones for this domain."
	echo "Recursively deleting all zones for domain: $dn..."
	for zid in $(echo $zone_list | sed 's/,/ /g' | sed 's'@'/hostedzone/'@' '@'g')
	do
		echo "Deleting hosted zone $zid..." 
		delete_all_records_for_zone $zid
    deletion_id=$(aws route53 delete-hosted-zone \
	  	--id $zid \
	 	 	--output text \
	 	 	--query 'ChangeInfo.Id')\
		&& aws route53 wait resource-record-sets-changed \
			--id "$deletion_id"
		echo "Deleted zone $zid."
		echo "Change id: $deletion_id"
	done
}
function 	delete_all_records_for_zone(){
	local zid=$1
	echo "Recursively deleting all record sets for zone: $zid..."
	aws route53 list-resource-record-sets \
		--hosted-zone-id $zid \
		| jq -c '.ResourceRecordSets[]' \
		| while read -r resourcerecordset; do
			read -r name type <<< \
				$(jq -r '.Name,.Type' <<<"$resourcerecordset")
			  if [ $type != "NS" -a $type != "SOA" ]; then
	  	    aws route53 change-resource-record-sets \
			      --hosted-zone-id $zid \
			      --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":
			          '"$resourcerecordset"'
			        }]}' \
			      --output text --query 'ChangeInfo.Id'
			  	echo "Deleting record set $resourserecordset"
			  	# local rqst='{"Changes":[{"Action":"DELETE","ResourceRecordSet":'"$resourcerecordset"'}]}'
			   #  sh submit-rec.sh $z $rqst
		  	fi
			done
}

delete_all_zones_for_this_domain $1

exit 0