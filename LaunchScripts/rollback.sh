#!/bin/bash -eo pipefail
#
# Rollback on Error
function success(){
	echo "${GREEN}[SUCCESS]${RESET} ${0##*/}"
	echo "${GREEN}$success${RESET}"
	exit 0
}	
function error_exit(){
	echo "${RED}[ERROR]${RESET} ${0##*/}:$1"
	exit 1
}
####
trap '[ "$?" -eq 0 ] && success || error_exit $LINENO' EXIT
function tearDown(){
	local alloc=$1 ec2=$2 assoc=$3
	echo 'Tearing down nginx service...'
	if [[ -n $alloc ]]; then
		echo "EIP Allocation found. Releasing..."
		aws ec2 release-address --allocation-id $alloc 
	fi
	if [[ -n $ec2 ]]; then
		echo "EC2 instance found. Terminating..."
		success=$(echo $(aws ec2 terminate-instances --instance-ids $ec2))
	fi
	if [[ -n $assoc ]]; then
		echo "EIP association found. Dissociating..."
		aws ec2 disassociate-address --association-id $assoc
	fi
}
function delete_all_zones_and_records_for_domain() {
	local dn=$1
	sh $(dirname $0)/delete-all-zones-and-records.sh $dn
}
tearDown $2 $3 $4
delete_all_zones_and_records_for_domain $1
exit 0