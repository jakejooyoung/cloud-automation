#!/bin/bash -eo pipefail

# launch_go.sh 
# 1. Launches EC2 with Go Server userdata + presigned url for bitbucket repo ssh key
# 2. Using presigned url, userdata script downloads ssh key
# 3. Git clone Go server barebone then cleanup all ssh related variables and files
# 4. Finish up configuration and return success code.

# TRAP stuff START ##########################################################
export RED=`tput setaf 1`
export GREEN=`tput setaf 2`
export YELLOW=`tput setaf 3`
export RESET=`tput sgr0`
# function rollback(){
# 	# To-Do: Add rollback feature into this code.
# 	# sh $(dirname $0)/rollback.sh "$domain_name" "$alloc_id" "$ec2_id" "$assoc_id"
# }
function missingarg(){
	echo "${RED}[ERROR] MISSING ARGS${RESET} ${0##*/}:$1 \n"
	exit 1
}
function cleanup(){
	echo "${RED}Go Server instance launch failed.${RESET}"
	echo "${RED}ERROR]${RESET} ${0##*/}:$1"
	echo "Rolling back components..."
	# rollback
	exit 1
}
function success(){
	printf "${GREEN}[SUCCESS]${RESET}${0##*/}"
}
# TRAP stuff END ##################################################################

trap '[[ -z $1 ]] && missingarg $LINENO' EXIT
if [[ -z $1 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] && success || cleanup $LINENO' SIGINT EXIT

function launch_go(){
	local presigned=$(aws s3 presign s3://npgains.keys/bitbucket_rsa --expires-in 360 | sed s#'\&'#'\\&'#g)
	echo $presigned 

	echo "Launching & Configuring Go Server..."
	launch_response=$(aws ec2 run-instances \
		--image-id ami-6e165d0e \
		--count 1 --instance-type t2.micro \
		--iam-instance-profile Name="go-launcher" \
		--key-name FounderKey \
		--security-groups webserver jkmba-ssh \
		--user-data "$(aws s3 cp s3://npgains.userdata/go.sh - | sed "s#PRESIGNED_URL#$presigned#g")")\
	&&ec2_id=$(echo $launch_response | jq -r ".Instances[] | .InstanceId")
}
function wait_for_instance(){
	aws ec2 wait instance-running --instance-ids $ec2_id \
	&&echo "${GREEN}EC2 $ec2_id is running.${RESET}"
}
function create_tag(){
	aws ec2 create-tags --resources $ec2_id --tags Key=$1,Value=$2
}
domain_name=$1
launch_go && wait_for_instance && 
create_tag Name "$domain_name" &&
create_tag "Role" "WebServer" &&
create_tag "Type" "Go" &&
create_tag "Plan" "Startup"

echo "Launched go instance: $ec2_id"
exit 0