#!/bin/sh
while getopts ":l:c:p:" OPT ; do
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
    \? )
      echo nothing matched
      ;;
    esac
done

[[ -z "$profile" ]] && exit 1

if [[ ! -z "$elbName" ]]; then
  instanceIds=`aws --profile $profile --region ap-northeast-1 elb describe-load-balancers --load-balancer-name $elbName | jq -r '.LoadBalancerDescriptions[] | .Instances[] | .InstanceId' | tr '\n' ' '`
fi
if [[ ! -z "$ec2Name"  ]]; then
  instanceIds=`aws --profile $profile --region ap-northeast-1 ec2 describe-instances --filter "Name=tag:Name,Values=$ec2Name" | jq -r '.Reservations[] | .Instances[] | select(.State.Name == "running") | .InstanceId' | tr '\n' ' '`
fi

if [ -z "$instanceIds" ]; then
  echo "Instance not found"
  exit 1
fi
ips=`aws --profile $profile --region ap-northeast-1 ec2 describe-instances --instance-ids $instanceIds | jq -r '.Reservations[] | .Instances[] | select(.State.Name == "running") | .PrivateIpAddress' | tr '\n' ','`

echo "ログインするホストを指定してください。"
select ip in `echo ${ips} | sed 's/,/ /g'`
do
  if [ "$ip" = "" ]; then
    echo "番号を指定してください。"
    continue
  fi
  if [ "$ip" = "exit" ]; then
    exit 0
  fi
  break
done

ssh -o StrictHostKeyChecking=no ${ip}
