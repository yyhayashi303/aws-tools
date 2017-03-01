#!/bin/sh
while getopts ":l:c:p:n:" OPT ; do
  case $OPT in
    l)
      elbName=$OPTARG
      ;;
    c)
      ec2Name=$OPTARG
      ;;
    p)
      profile=$OPTARG
      ;;
    n)
      limit=$OPTARG
      ;;
    \? )
      echo nothing matched
      ;;
    esac
done

[[ -z "$profile" ]] && exit 1

if [[ ! -z "$elbName" ]]; then
  instanceIds=`aws --profile $profile elb describe-load-balancers --load-balancer-name $elbName | jq -r '.LoadBalancerDescriptions[] | .Instances[] | .InstanceId' | tr '\n' ' '`
fi
if [[ ! -z "$ec2Name"  ]]; then
  instanceIds=`aws ec2 --profile $profile describe-instances --filter "Name=tag:Name,Values=$ec2Name" | jq -r '.Reservations[] | .Instances[] | select(.State.Name == "running") | .InstanceId' | tr '\n' ' '`
fi

if [ -z "$instanceIds" ]; then
  echo "Instance not found"
  exit 1
fi
instanceIps=`aws --profile $profile ec2 describe-instances --instance-ids $instanceIds | jq -r '.Reservations[] | .Instances[] | select(.State.Name == "running") | .PrivateIpAddress' | tr '\n' ','`

if [ -z $limit ]; then
  targetIps=$instanceIps
else
  targetIps=`echo $instanceIps | cut -d "," -f 1-$limit`
fi

multi-ssh-with-tmux.sh $profile-$elbName $profile $targetIps
