#!/bin/bash -eo pipefail
#
## Initialize HOSTED ZONE w/ standard A, CNAME records
cleanup() {
  echo "Cleaning stuff up..."
  if [[ -n $hosted_zone_id ]];then 
  	tear_down
  fi
  exit 1
}
trap cleanup EXIT
set -v
#----------------------------------------------------------
eip dn hosted_zone_id arec_cname
function initialize_domain() {
	dn=$1
	eip=$2
	arec_cname=$(source $(dirname $0)/make-arec-cname-json.sh "" "" "" $dn $eip)\
	&& create_hosted_zone $dn\
	&& update_record_set $eip
	echo $arec_cname
}
function create_hosted_zone(){
	aws route53 create-hosted-zone --name $1 --caller-reference +%Y-%m-%d:%H:%M:%S 
	hosted_zone_id=$(aws route53 list-hosted-zones --output text --query 'HostedZones[?Name==`'$1'.`].Id')
	echo "Created hosted zone: $hosted_zone_id"
}
function update_record_set(){
	change_id=$(aws route53 change-resource-record-sets \
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
		exit 0
	fi
}

#######################################
## Tear down if something goes wrong.
####################################### 
#TO-DO: put tear down functions in separate file
function tear_down(){
	echo "Down it goes..."
	delete_all_zones_for_this_domain
	aws route53 list-hosted-zones
}
function delete_all_zones_for_this_domain(){
	for i in $(echo $hosted_zone_id | sed 's/,/ /g' | sed 's'@'/hostedzone/'@' '@'g')
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

initialize_domain $1 $2
trap : 0

exit 0





