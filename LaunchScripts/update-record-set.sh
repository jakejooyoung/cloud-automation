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
	echo "${GREEN}[SUCCESS]${RESET} ${0##*/}"
	exit 0
}	
####
trap '[[ -z $1  ||  -z $2 ]] && missingarg' EXIT
if [[ -z $1 || -z $2 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] && success || err_report $LINENO' EXIT
function submit_record_change(){
	local zid=$1; 
	local req=$2; 
	local submission;
	submission=$(aws route53 change-resource-record-sets \
		--hosted-zone-id $zid --change-batch $req) || exit $?
	change_id=$(echo $submission \
		| jq -r '.ChangeInfo.Id' | cut -d'/' -f3) 
	printf "\e[?25l${YELLOW}"
	echo "Waiting for all Route53 DNS to be in sync..." 
	until [ $(aws route53 get-change --id $change_id \
		| jq -r '.ChangeInfo.Status')=="INSYNC" ]; do
	 	echo "Trying..."
		sleep 0.5
	done
	printf "\e[?25h ${RESET}\n"
	echo "${GREEN}Change id: $change_id${RESET}"
}
submit_record_change $1 $2
exit 0