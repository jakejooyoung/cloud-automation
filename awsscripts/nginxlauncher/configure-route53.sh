#!/bin/bash -eo pipefail
#
## Initializes HOSTED ZONE w/ standard A, CNAME records.
## WARNING! this code deletes all zones related to given domain.
## ONLY use when setting up for the first time. 
export RED=`tput setaf 1`
export GREEN=`tput setaf 2`
export YELLOW=`tput setaf 3`
export RESET=`tput sgr0`

function missingarg(){
	echo "${RED}[ERROR] MISSING ARGS${RESET} ${0##*/}"
	exit 1
}
function cleanup(){
	echo "${RED}[ERROR]${RESET} ${0##*/}:$1"
	echo "Reversing any changes made..."
	delete_all_zones_and_records_for_domain 
  exit 1
}
function success(){
	echo "${GREEN}[SUCCESS]${RESET} ${0##*/}"
	exit 0
}
####
trap '[[ -z $1 || -z $2 ]] && missingarg' EXIT
if [[ -z $1 || -z $2 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] && success || cleanup $LINENO' EXIT

function create_hosted_zone_for_domain(){
	echo "Creating a hosted zone for domain"
	created_hosted_zone=$(aws route53 create-hosted-zone \
		--name $dn --caller-reference $(date +%Y-%m-%d:%H:%M:%S)\
		| jq -r '.HostedZone .Id')
}
function delete_all_zones_and_records_for_domain() {
	sh $(dirname $0)/delete-all-zones-and-records.sh $dn
}
function prepare_upsert_for_a_and_cname(){
	# Make A and CNAME record sets rqst in JSON
	arec_cname_upsert_rqst=$(sh \
	$(dirname $0)/prepare-upsert-for-a-and-cname.sh \
	$dn $eip_public_ip)	
}
function update_record_set(){
	sh $(dirname $0)/update-record-set.sh $1 $2
}
function initialize_zone_with_a_and_cname_records(){
	delete_all_zones_and_records_for_domain 
	create_hosted_zone_for_domain
	prepare_upsert_for_a_and_cname
	update_record_set \
	$created_hosted_zone $arec_cname_upsert_rqst
}

dn=$1; eip_public_ip=$2
initialize_zone_with_a_and_cname_records \
$dn $eip_public_ip

exit 0


