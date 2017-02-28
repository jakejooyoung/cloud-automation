#!/bin/bash -eo pipefail

# launch.sh 
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
function rollback(){
	sh $(dirname $0)/rollback.sh "$domain_name" "$alloc_id" "$ec2_id" "$assoc_id"
}
function cleanup(){
	echo "${RED}Nginx instance launch failed.${RESET}"
	echo "${RED}ERROR]${RESET} ${0##*/}:$1"
	echo "Rolling back components..."
	rollback
	exit 1
}
function success(){
	printf "${GREEN}[SUCCESS]${RESET}${0##*/}\
	\nNginx launch & configuration\
	\nwere successful.\
	\nEC2 Id     : '$ec2_id'\
	\nAlloc Id   : '$alloc_id'\
	\nAssoc Id   : '$assoc_id'\
	\nEIP Public : '$eip_public_ip'\
	\nDomain Name: '$domain_name'\
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

function allocate_eip(){
	echo 'Allocating EIP...'
	allocation=$(aws ec2 allocate-address --domain vpc) \
	&&alloc_id=$(echo $allocation | jq -r '.AllocationId')
}
function parse_public_ip(){
	eip_public_ip=$(aws ec2 describe-addresses \
		--allocation-ids $alloc_id | jq -r ".Addresses | .[] | .PublicIp") 
}
function configure_route53(){
	sh $(dirname $0)/configure-route53.sh \
		$domain_name $eip_public_ip
}

function launch_instance(){
	echo "Launching & Configuring Nginx..."
	launch_response=$(aws ec2 run-instances \
		--image-id ami-6e165d0e \
		--count 1 --instance-type t2.micro \
		--iam-instance-profile Name="ssl-profile" \
		--key-name FounderKey \
		--security-groups nginx-full jkmba-ssh \
		--user-data "$(aws s3 cp s3://npgains.userdata/nginx.sh - \
			| sed "s/domain_placeholder/$domain_name/g")")\
	&&ec2_id=$(echo $launch_response | jq -r ".Instances[] | .InstanceId")
}
function wait_for_instance(){
	aws ec2 wait instance-running --instance-ids $ec2_id \
	&&echo "${GREEN}EC2 $ec2_id is running.${RESET}"
}
function create_tag(){
	aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=$1
}

function associate_eip(){
	echo "Associating EIP with $ec2_id"
	association=$(aws ec2 associate-address --instance-id $ec2_id --allocation-id $alloc_id) \
	&&assoc_id=$(echo $association | jq -r '.AssociationId')
}
function launch (){
	allocate_eip && parse_public_ip && configure_route53 \
	&&launch_instance && wait_for_instance && create_tag "$domain_name-nginx"\
	&&associate_eip 
}
domain_name=$1
launch

exit 0
