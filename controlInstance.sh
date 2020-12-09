#!/bin/bash

function usage {
  echo "Usage: ./controlInstance.sh <EC2 Instance Name> [OPT] [profile]"
  echo "Options: start, stop"
  echo "Profile: [default], .."
  echo "Start will create an entry in .ssh/config for given"
  echo "instance name. If entry already exists, it will"
  echo "replace the hostname with the new Public Hostname."
  exit
}

function checkReqPackage {
  echo "Checking awscli and jq packages"
  pkgs="awscli jq"
  configure=0
  for pkg in $pkgs; do
    dpkg -s $pkg &> /dev/null
    if [ $? -eq 1 ]
    then
      sudo apt install -y $pkg
      if [ $pkg == "awscli" ]
      then
        configure=1
      fi
    fi
  done
  if [ $configure -eq 1 ]
  then
    echo "Configuring AWS CLI"
    aws --profile $prof configure
  fi
}

function str_to_val {
  temp=$1
  temp="${temp%\"}"
  temp="${temp#\"}"
  echo $temp
}

function addHost {
  key=$(str_to_val $(aws --profile $prof ec2 describe-instances --filters "Name=tag-value,Values=$ec2" | jq .Reservations[].Instances[].KeyName))
  echo "" >> ~/.ssh/config
  read -p "User: " user
  read -p "Complete Path to .pem file: " path
  echo "Host $1" >> ~/.ssh/config
  echo "    HostName $2" >> ~/.ssh/config
  echo "    User $user" >> ~/.ssh/config
  echo "    Port 22" >> ~/.ssh/config
  echo "    IdentityFile $path/$key.pem" >> ~/.ssh/config
}

function configEntry {
  hn=$(ssh -G $ec2 | grep hostname)
  for h in $hn; do
    if [[ $h == *"amazonaws.com"* ]]; then
      echo $h
    elif [[ $h == $ec2 ]]; then
      echo ""
    fi
  done
}

if [ -z "$1" ]
then
  usage
fi

checkReqPackage

ec2=$1
control=$2
prof=$3
if [ -z "$3" ]
then
  prof=default
fi

id=$(str_to_val $(aws --profile $prof ec2 describe-instances --filters "Name=tag-value,Values=$ec2" | jq .Reservations[].Instances[].InstanceId))

if [ $control == "start" ]
then
  state=$(aws --profile $prof ec2 describe-instances --filters "Name=tag-value,Values=$ec2" | jq .Reservations[].Instances[].State.Name)
  echo "Current state: $state"
  if [ $state != "\"stopped\"" ]
  then
    echo "Instance already running."
  else
    echo "Starting ID: $id ($ec2)"
    aws --profile $prof ec2 start-instances --instance-ids $id
  fi
  host=""
  while [ -z $host ]
  do
    host=$(str_to_val $(aws --profile $prof ec2 describe-instances --filters "Name=tag-value,Values=$ec2" | jq .Reservations[].Instances[].PublicDnsName))
    sleep 1
  done
  echo "Instance hostname: $host"
  echo "Checking hostname configuration for Host $ec2 in .ssh/config..."
  hostname_old=$(configEntry $ec2)
  echo $hostname_old
  if [ ! -z "$hostname_old" ]
  then
    if [ $hostname_old == $host ]
    then
      echo "Configuration up-to-date. Proceed to: ssh $ec2"
    else
      echo "replacing $hostname_old with $host"
      sed -i "s/$hostname_old/$host/g" ~/.ssh/config
    fi
  else
    echo "No existing entry for host $ec2."
    echo "Adding new entry in ~/.ssh/config. This is done for the first time."
    addHost $ec2 $host
  fi
elif [ $control == "stop" ]
then
  echo "Stopping ID: $id ($ec2)"
  aws --profile $prof ec2 stop-instances --instance-ids $id
elif [ $control == "modify" ]
then
  echo "Modifying ID: $id ($ec2)"
  attribute=$4
  value=$5
  #echo "aws --profile $prof ec2 modify-instance-attribute --instance-id $id --$attribute \"{\\\"Value\\\": \\\"$value\\\"}\""
  aws --profile $prof ec2 modify-instance-attribute --instance-id $id --$attribute "{\"Value\": \"$value\"}"
fi
