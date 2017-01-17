#!/bin/bash -eo pipefail
## Initialize HOSTED ZONE w/ standard A, CNAME records
# set -v

#----------------------------------------------------------
function tear_down() {
  echo "Cleaning stuff up..."
	delete_all_zones_for_this_domain
	echo "Listing zones:"
	aws route53 list-hosted-zones
	echo "exiting"
}
#----------------------------------------------------------
trap EXIT

local dn=$1
local eip=$2

create_hosted_zone
trap tear_down EXIT

local hosted_zone_id=$(aws route53 list-hosted-zones --output text --query 'HostedZones[?Name==`'$1'.`].Id')
local arec_cname=$(source $(dirname $0)/make-arec-cname-json.sh "" "" "" $dn $eip)
update_record_set

trap EXIT

function create_hosted_zone(){
	aws route53 create-hosted-zone --name $dn --caller-reference 'date +%Y-%m-%d:%H:%M:%S' | exit 1
}
function update_record_set(){
	local change_id=$(aws route53 change-resource-record-sets \
		--hosted-zone-id $hosted_zone_id \
		--change-batch $arec_cname \
		| jq -r '.ChangeInfo.Id' \
		| cut -d'/' -f3)
	if [[ -z $change_id ]]; then
		echo "Change did not go through."
	else 
		echo "Record change submitted! Change Id: $change_id..."
		echo -n "Waiting for all Route53 DNS to be in sync..."
		until [[ $(aws route53 get-change \
			--id $change_id \
			| jq -r '.ChangeInfo.Status') \
			== "INSYNC" ]]; do
		 	echo -n "."
		 	sleep 5
		done
		echo "!"
		echo "Your record change has now propagated."
	fi
}

function delete_all_zones_for_this_domain(){
	for i in $($hosted_zone_id | sed 's/,/ /g' | sed 's'@'/hostedzone/'@' '@'g')
	do
		recurively_delete_record_sets $i \
		&& echo "Deleting hosted zone with id $i..." \
    && deletion_id=$(aws route53 delete-hosted-zone \
	  	--id "$i" \
	 	 	--output text \
	 	 	--query 'ChangeInfo.Id')\
		&& deletion_status=$(aws route53 wait resource-record-sets-changed --id "$deletion_id")\
		&& echo "Deleted with change id: $(echo $deletion_id | sed 's'@'/change/'@' '@'g')" 
	done
}
function 	recurively_delete_record_sets(){
	echo "Deleting record sets recursively for given hosted zone"
	local zone_id=$1
	aws route53 list-resource-record-sets \
		--hosted-zone-id $hosted_zone_id \
		| jq -c '.ResourceRecordSets[]' \
		| while read -r resourcerecordset; do
			read -r name type <<< $(jq -r '.Name,.Type' <<<"$resourcerecordset")
			  if [ $type != "NS" -a $type != "SOA" ]; then
			  	echo "Deleting record set $resourserecordset"
			  	local delete_rqst='{"Changes":[{"Action":"DELETE","ResourceRecordSet":'"$resourcerecordset"'}]}'
			    update_record_set $delete_rqst
		  	fi
			done
}

exit 0




