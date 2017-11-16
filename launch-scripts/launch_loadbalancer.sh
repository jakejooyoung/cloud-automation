#!/bin/bash -eo pipefail

# launch_api_loadbalancer.sh 
# 1. Allocates Elastic IP, gets eip's public IP, then configures Route53 to point domain to public IP of eip
# 2. Launches EC2 with NginX userdata, waits until its up and running, then tags it
# 3. Associates newly launched EC2 with allocated Elastic IP.

# TRAP stuff START ##########################################################
export RED=`tput setaf 1`
export GREEN=`tput setaf 2`
export YELLOW=`tput setaf 3`
export RESET=`tput sgr0`
function missingarg(){
	echo "${RED}[ERROR] MISSING ARGS${RESET} ${0##*/}:$1"
	exit 1
}
function cleanup(){
	echo "${RED}Nginx Load Balancer instance launch failed.${RESET}"
	echo "${RED}ERROR]${RESET} ${0##*/}:$1"
	exit 1
}
function success(){
	printf "${GREEN}[SUCCESS]${RESET}${0##*/}\
	\nNginx Load Balancer launch & configuration\
	\nwere successful.\
	\nEC2 Id     : '$ec2_id'\
	\n"
	#Debug 
	#rollsback changes after test
	# rollback \	
	# && echo 'Success!'
}
# TRAP stuff END ##################################################################

trap '[[ -z $1 ]] && missingarg $LINENO' EXIT
if [[ -z $1 ]]; then exit 1; fi
trap '[ "$?" -eq 0 ] && success || cleanup $LINENO' SIGINT EXIT

function launch_instance(){
	echo "Launching & Configuring Nginx Load Balancer..."
	launch_response=$(aws ec2 run-instances \
		--image-id ami-6e165d0e \
		--count 1 --instance-type t2.micro \
		--iam-instance-profile Name="nginx-launcher" \
		--key-name FounderKey \
		--security-groups loadbalancer jkmba-ssh \
		--user-data "$(aws s3 cp s3://npgains.userdata/loadbalancer.sh -)")\
	&&ec2_id=$(echo $launch_response | jq -r ".Instances[] | .InstanceId")
}
function wait_for_instance(){
	aws ec2 wait instance-running --instance-ids $ec2_id \
	&&echo "${GREEN}EC2 $ec2_id is running.${RESET}"
}
function create_tag(){
	aws ec2 create-tags --resources $ec2_id --tags Key=$1,Value=$2
}
function launch (){
	launch_instance && wait_for_instance && 
	create_tag Name "$domain_name-api-loadbalancer" &&
	create_tag "Role" "ApiLoadBalancer" &&
	create_tag "Type" "Nginx" &&
	create_tag "Plan" "Startup" &&
	create_tag "Owner" "npgains"
}
domain_name=$1
launch

exit 0
