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
function rollback(){
	local ec2=$1
	local alloc=$2
	local assoc=$3
	local dn=$4
	echo 'Tearing down nginx service...'
	if [[ -n $assoc ]]; then
		echo "EIP association found. Dissociating..."
		aws ec2 disassociate-address --association-id $assoc
	fi
	if [[ -n $alloc ]]; then
		echo "EIP Allocation found. Releasing..."
		aws ec2 release-address --allocation-id $alloc 
	fi
	if [[ -n $ec2 ]]; then
		echo "EC2 instance found. Terminating..."
		success=$(echo $(aws ec2 terminate-instances --instance-ids $ec2))
	fi
	delete_all_zones_and_records_for_domain $dn
}
function delete_all_zones_and_records_for_domain() {
	sh $(dirname $0)/delete-all-zones-and-records.sh $1
}
rollback $1 $2 $3 $4
exit 0