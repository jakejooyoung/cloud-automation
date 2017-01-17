#!/bin/bash -o pipefail
#
# Launch NGINX EC2
# Alloc&assign ELASTIC IP.
# Setup ROUTE53
cleanup()
{
	echo "Dissociating & releasing elastic ip address"
	aws ec2 disassociate-address --association-id $elip_assoc_id\
	&& aws ec2 release-address --allocation-id $elip_alloc_id
  echo $(aws ec2 terminate-instances --instance-ids $ec2_id)
	echo >&2 '
	***************
	*** ABORTED ***
	***************
	'
  echo "An error occurred. Exiting..." >&2
  exit 1
}
trap cleanup EXIT

function launch(){
	domain_name=$1
	echo "Launching ec2 instance with nginx userdata..."
	ec2_res=$(aws ec2 run-instances \
	--image-id ami-6e165d0e \
	--count 1 \
	--instance-type t2.micro \
	--iam-instance-profile Name="ssl-profile" \
	--key-name FounderKey \
	--security-groups nginx-full jkmba-ssh \
	--user-data "$(aws s3 cp s3://npgains.userdata/nginx.sh -)") \
	&& ec2_id=$(echo $ec2_res | jq -r ".Instances[] | .InstanceId") \
	&& $(aws ec2 create-tags \
			--resources $ec2_id \
			--tags Key=Name,Value=nginxReverseProxy) \
	&& $(aws ec2 wait instance-running --instance-ids $ec2_id)
	echo "EC (Id: $ec2_id) is up and running."
	get_elastic_ip 
	source $(dirname $0)/route53-setup.sh $domain_name $elip & 
	wait $! || cleanup
}
function get_elastic_ip {
	echo "Getting Elastic IP for nginx instance"
	elip_alloc_id=$(aws ec2 allocate-address \
		--domain vpc \
		| jq -r '.AllocationId')\
	&& elip_assoc_id=$(aws ec2 associate-address \
		--instance-id $ec2_id \
		--allocation-id $elip_alloc_id \
		| jq -r '.AssociationId') \
	&& elip=$(aws ec2 describe-addresses --allocation-ids $elip_alloc_id | jq -r ".Addresses | .[] | .PublicIp")\
	&& echo >&2 "
		AssocId : '$elip_assoc_id'
		AllocId : '$elip_alloc_id'
		Elip_id : '$elip'	
	"
}

if [[ -z $1 ]]; then
	echo >&2 '
  Please provide domain_name
 	domain.com      [o]
 	www.domain_name [x]
 	'
	exit 1
fi
trap : 0

launch $1
exit 0

