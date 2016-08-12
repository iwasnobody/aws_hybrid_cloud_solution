#!/bin/bash

#Strongwan-1 healthy; Strongswan-2 healthy; Tunnel1 healthy; Tunnel2 healthy
#Status=0
#Strongwan-1 healthy; Strongswan-2 healthy; Tunnel1 unhealthy; Tunnel2 healthy
#Status=1
#Strongwan-1 healthy; Strongswan-2 healthy; Tunnel1 healthy; Tunnel2 unhealthy
#Status=2
#Strongwan-1 healthy; Strongswan-2 healthy; Tunnel1 unhealthy; Tunnel2 unhealthy
#Status=3
#Strongwan-1 unhealthy; Strongswan-2 healthy; Tunnel2 healthy
#Status=4
#Strongwan-1 unhealthy; Strongswan-2 healthy; Tunnel2 unhealthy
#Status=5
#Strongwan-1 healthy; Strongswan-2 unhealthy; Tunnel1 healthy
#Status=6
#Strongwan-1 healthy; Strongswan-2 unhealthy; Tunnel1 unhealthy
#Status=7
#Strongwan-1 unhealthy; Strongswan-2 unhealthy
#Status=8

# Strongswan-1 instance id
VPN_ID1="i-0e1466e8a5dd4892c"
# Strongswan-2 instance id
VPN_ID2="i-0430fe110cdec5835"
# VGW id
VGW_ID="vgw-078bcc55"
# RT of Private-1
VPN_RT_ID1="rtb-468f5222"
# RT of Private-2
VPN_RT_ID2="rtb-4b8f522f"

# Remote site IP to ping, two tunnel ip and one dx vgw ip
DX_IP="10.10.3.100"
Remote_IP1="169.254.100.1"
Remote_IP2="169.254.200.1"

# Get EC2 region
EC2_REGION=$(wget -qO - http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep region | sed 's/\(.*\)region.*"\(.*\)"\(,*\)/\2/g')

# Get IP of Strongswan-1 and Strongswan-2
Strongswan1_IP=$(aws ec2 describe-instances --region=$EC2_REGION --instance-ids=$VPN_ID1 --query 'Reservations[0].Instances[0].PrivateIpAddress' | sed 's/"\(.*\)"/\1/g')
Strongswan2_IP=$(aws ec2 describe-instances --region=$EC2_REGION --instance-ids=$VPN_ID2 --query 'Reservations[0].Instances[0].PrivateIpAddress' | sed 's/"\(.*\)"/\1/g')

# Health Check variables
Num_Pings=3
Ping_Timeout=1
Wait_Between_Pings=2
Wait_for_Instance_Stop=60
Wait_for_Instance_Start=60

#Initialize Status
DX_Status=2
Status=10
Logfile=0

#logstash parameter
logstash_site="Singapore"
#if Strongswan instance need to stop and start
Strongswan1_reboot=0
Strongswan2_reboot=0

# Get this instance's ID
Instance_ID=$(wget -qO - http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep instanceId | sed 's/\(.*\)instanceId.*"\(.*\)"\(,*\)/\2/g')

echo `date` "-- Starting VPN monitor"

while [ 1 ]; do
  # Check health of DX
  pingresult_dx=$(ping -c $Num_Pings -W $Ping_Timeout $DX_IP | grep time= | wc -l)
  # DX link down
  if [ "$pingresult_dx" == "0" ]; then
    #Private-1 to Strongswan-1, Private-2 to Strongswan-2
    if [[ "$DX_Status" != "0" ]]; then
      echo `date` "-- DX link down, changing route to VPN" | tee -a logfile
      let logstash_time=($(date +%s)*1000)
      echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"DX link down\",\"action\":\"Change route to VPN\"}]" >> /tmp/logstash.txt
      Logfile=1
  #    litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
  #    litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
      Status=10
      DX_Status=0
    fi
    pingresult_tunnel1=$(ping -c $Num_Pings -W $Ping_Timeout $Remote_IP1 | grep time= | wc -l)
    if [ "$pingresult_tunnel1" == "0" ]; then
      Tunnel1_HEALTH=0
    else
      Tunnel1_HEALTH=1
    fi
    pingresult_tunnel2=$(ping -c $Num_Pings -W $Ping_Timeout $Remote_IP2 | grep time= | wc -l)
    if [ "$pingresult_tunnel2" == "0" ]; then
      Tunnel2_HEALTH=0
    else
      Tunnel2_HEALTH=1
    fi
    pingresult_strongswan1=$(ping -c $Num_Pings -W $Ping_Timeout $Strongswan1_IP | grep time= | wc -l)
    if [ "$pingresult_strongswan1" == "0" ]; then
      Strongswan1_HEALTH=0
    else
      Strongswan1_HEALTH=1
    fi
    pingresult_strongswan2=$(ping -c $Num_Pings -W $Ping_Timeout $Strongswan2_IP | grep time= | wc -l)
    if [ "$pingresult_strongswan2" == "0" ]; then
      Strongswan2_HEALTH=0
    else
      Strongswan2_HEALTH=1
    fi
    if [[ "$Strongswan1_HEALTH" == "1" && "$Strongswan2_HEALTH" == "1" ]]; then
      if [[ "$Tunnel1_HEALTH" == "1" && "$Tunnel2_HEALTH" == "1" ]]; then
        if [[ "$Status" != "0" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: healthy\nTunnel1: healthy\nTunnel2: healthy" | tee -a logfile
          echo "-- Private-1 route to Strongswan-1; Private-2 route to Strongswan-2" | tee -a logfile
          Logfile=1
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
          Status=0
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1: healthy; Strongswan-2: healthy; Tunnel1: healthy; Tunnel2: healthy; Private-1 route to Strongswan-1; Private-2 route to Strongswan-2\"}]" >> /tmp/logstash.txt
        fi
      elif [[ "$Tunnel1_HEALTH" == "0" && "$Tunnel2_HEALTH" == "1" ]]; then
        if [[ "$Status" != "1" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: healthy\nTunnel1: unhealthy\nTunnel2: healthy" | tee -a logfile
          echo "-- Private-1 route to Strongswan-2; Private-2 route to Strongswan-2" | tee -a logfile
          Logfile=1
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
          Status=1
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1: healthy; Strongswan-2: healthy; Tunnel1: unhealthy; Tunnel2: healthy; Private-1 route to Strongswan-2; Private-2 route to Strongswan-2\"}]" >> /tmp/logstash.txt
        fi
      elif [[ "$Tunnel1_HEALTH" == "1" && "$Tunnel2_HEALTH" == "0" ]]; then
        if [[ "$Status" != "2" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: healthy\nTunnel1: healthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Private-1 route to Strongswan-1; Private-2 route to Strongswan-1" | tee -a logfile
          Logfile=1
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
          Status=2
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1: healthy; Strongswan-2: healthy; Tunnel1: healthy; Tunnel2: unhealthy; Private-1 route to Strongswan-1; Private-2 route to Strongswan-1\"}]" >> /tmp/logstash.txt
        fi
      elif [[ "$Tunnel1_HEALTH" == "0" && "$Tunnel2_HEALTH" == "0" ]]; then
        if [[ "$Status" != "3" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: healthy\nTunnel1: unhealthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Both Tunnel down, traffic lost!" | tee -a logfile
          Logfile=1
          Status=3
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Both Tunnel down, traffic lost!\"}]" >> /tmp/logstash.txt
        fi
      fi
    elif [[ "$Strongswan2_HEALTH" == "1" ]]; then
      if [[ "$Tunnel2_HEALTH" == "1" ]]; then
        if [[ "$Status" != "4" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: unhealthy\nStrongswan-2: healthy\nTunnel1: unhealthy\nTunnel2: healthy" | tee -a logfile
          echo "-- Private-1 route to Strongswan-2; Private-2 route to Strongswan-2" | tee -a logfile
          Logfile=1
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID2)
          Status=4
          Strongswan1_reboot=1
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1: unhealthy; Strongswan-2: healthy; Tunnel1: unhealthy; Tunnel2: healthy; Private-1 route to Strongswan-2; Private-2 route to Strongswan-2; Stop Start Strongswan-1\"}]" >> /tmp/logstash.txt
        fi
      else
        if [[ "$Status" != "5" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: unhealthy\nStrongswan-2: healthy\nTunnel1: unhealthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Strongswan-1 down, Tunnel2 down, traffic lost!" | tee -a logfile
          echo "-- Strongswan-1 need stop and start" | tee -a logfile
          Logfile=1
          Strongswan1_reboot=1
          Status=5
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1 down, Tunnel2 down, traffic lost!; Stop Start Strongswan-1\"}]" >> /tmp/logstash.txt
        fi
      fi
    elif [[ "$Strongswan1_HEALTH" == "1" ]]; then
      if [[ "$Tunnel1_HEALTH" == "1" ]]; then
        if [[ "$Status" != "6" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: unhealthy\nTunnel1: healthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Private-1 route to Strongswan-1; Private-2 route to Strongswan-1" | tee -a logfile
          Logfile=1
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
          litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --instance-id $VPN_ID1)
          Strongswan2_reboot=1
          Status=6
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Strongswan-1: healthy; Strongswan-2: unhealthy; Tunnel1: healthy; Tunnel2: unhealthy; Private-1 route to Strongswan-1; Private-2 route to Strongswan-1; Stop Start Strongswan-2\"}]" >> /tmp/logstash.txt
        fi
      else
        if [[ "$Status" != "7" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: healthy\nStrongswan-2: unhealthy\nTunnel1: unhealthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Tunnel1 down, Strongswan-2 down, traffic lost!" | tee -a logfile
          echo "-- Strongswan-2 need stop and start" | tee -a logfile
          Logfile=1
          Strongswan2_reboot=1
          Status=7
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Tunnel1 down, Strongswan-2 down, traffic lost!; Stop Start Strongswan-2\"}]" >> /tmp/logstash.txt
        fi
      fi
    else
      if [[ "$Status" != "8" ]]; then
          echo -e `date` "\nStatus change:\nStrongswan-1: unhealthy\nStrongswan-2: unhealthy\nTunnel1: unhealthy\nTunnel2: unhealthy" | tee -a logfile
          echo "-- Both Strongswan down, traffic lost!" | tee -a logfile
          echo "-- Strongswan-1 and Strongswan-2 need stop and start" | tee -a logfile
          Logfile=1
          Strongswan1_reboot=1
          Strongswan2_reboot=1
          Status=8
          let logstash_time=($(date +%s)*1000)
          echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"VPN Status Change\",\"action\":\"Both Strongswan down, traffic lost!; Stop Start Strongswan-1 and Strongswan-2\"}]" >> /tmp/logstash.txt
      fi
    fi
    #stop and start instance
    if [[ "$Strongswan1_reboot" == "1" && "$Strongswan2_reboot" == "1" ]]; then
      Instance_HEALTHY=0
      STOPPING_Instance=0
      #instance is unhealthy, loop while we try to fix it
      while [ "$Instance_HEALTHY" == "0" ]; do
        # Check instance state to see if we should stop it or start it again
        Strongswan1_STATE=`aws ec2 describe-instances --instance-ids $VPN_ID1 --region $EC2_REGION --output text --query 'Reservations[*].Instances[*].State.Name'`
        Strongswan2_STATE=`aws ec2 describe-instances --instance-ids $VPN_ID2 --region $EC2_REGION --output text --query 'Reservations[*].Instances[*].State.Name'`
        if [[ "$Strongswan1_STATE" == "stopped" && "$Strongswan2_STATE" == "stopped" ]]; then
          echo `date` "-- Both Strongswan stopped, starting them back up" | tee -a logfile
          litterbin=$(aws ec2 start-instances --instance-ids $VPN_ID1 --region=$EC2_REGION)
          litterbin=$(aws ec2 start-instances --instance-ids $VPN_ID2 --region=$EC2_REGION)
          Instance_HEALTHY=1
          Strongswan1_reboot=0
          Strongswan2_reboot=0
          sleep $Wait_for_Instance_Start
        elif [ "$STOPPING_Instance" == "0" ]; then
          echo `date` "-- Attempting to stop both Strongswan for reboot" | tee -a logfile
          litterbin=$(aws ec2 stop-instances --instance-ids $VPN_ID1 --region=$EC2_REGION)
          litterbin=$(aws ec2 stop-instances --instance-ids $VPN_ID2 --region=$EC2_REGION)
          STOPPING_Instance=1
        fi
        sleep $Wait_for_Instance_Stop
      done
    elif [[ "$Strongswan1_reboot" == "1" ]]; then
      Instance_HEALTHY=0
      STOPPING_Instance=0
      #instance is unhealthy, loop while we try to fix it
      while [ "$Instance_HEALTHY" == "0" ]; do
        # Check instance state to see if we should stop it or start it again
        Strongswan1_STATE=`aws ec2 describe-instances --instance-ids $VPN_ID1 --region $EC2_REGION --output text --query 'Reservations[*].Instances[*].State.Name'`
        if [[ "$Strongswan1_STATE" == "stopped" ]]; then
          echo `date` "-- Strongswan-1 stopped, starting it back up" | tee -a logfile
          litterbin=$(aws ec2 start-instances --instance-ids $VPN_ID1 --region=$EC2_REGION)
          Instance_HEALTHY=1
          Strongswan1_reboot=0
          sleep $Wait_for_Instance_Start
        elif [ "$STOPPING_Instance" == "0" ]; then
          echo `date` "-- Attempting to stop Strongswan-1 for reboot" | tee -a logfile
          litterbin=$(aws ec2 stop-instances --instance-ids $VPN_ID1 --region=$EC2_REGION)
          STOPPING_Instance=1
        fi
        sleep $Wait_for_Instance_Stop
      done
    elif [[ "$Strongswan2_reboot" == "1" ]]; then
      Instance_HEALTHY=0
      STOPPING_Instance=0
      #instance is unhealthy, loop while we try to fix it
      while [ "$Instance_HEALTHY" == "0" ]; do
        # Check instance state to see if we should stop it or start it again
        Strongswan2_STATE=`aws ec2 describe-instances --instance-ids $VPN_ID2 --region $EC2_REGION --output text --query 'Reservations[*].Instances[*].State.Name'`
        if [[ "$Strongswan2_STATE" == "stopped" ]]; then
          echo `date` "-- Strongswan-2 stopped, starting it back up" | tee -a logfile
          litterbin=$(aws ec2 start-instances --instance-ids $VPN_ID2 --region=$EC2_REGION)
          Instance_HEALTHY=1
          Strongswan2_reboot=0
          sleep $Wait_for_Instance_Start
        elif [ "$STOPPING_Instance" == "0" ]; then
          echo `date` "-- Attempting to stop Strongswan-2 for reboot" | tee -a logfile
          litterbin=$(aws ec2 stop-instances --instance-ids $VPN_ID2 --region=$EC2_REGION)
          STOPPING_Instance=1
        fi
        sleep $Wait_for_Instance_Stop
      done
    fi
  # DX link up
  else
    if [[ "$DX_Status" != "1" ]]; then
      echo `date` "-- DX link up, changing route to DX" | tee -a logfile
      Logfile=1
      litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID1 --destination-cidr-block 0.0.0.0/0 --gateway-id $VGW_ID)
      litterbin=$(aws ec2 replace-route --region=$EC2_REGION --route-table-id=$VPN_RT_ID2 --destination-cidr-block 0.0.0.0/0 --gateway-id $VGW_ID)
      DX_Status=1
      let logstash_time=($(date +%s)*1000)
      echo "[{\"time\":\"$logstash_time\",\"site\":\"$logstash_site\",\"event\":\"DX link up\",\"action\":\"Change route to DX\"}]" >> /tmp/logstash.txt
    fi
  fi
  if [[ "$Logfile" == "1" ]]; then
    litterbin=$(aws sns publish --region ap-southeast-1 --topic-arn "arn:aws:sns:ap-southeast-1:938706647508:DCI-Status" --subject "Status of DCI between Singapore and Ireland Changed!" --message file://logfile)
    litterbin=$(aws sns publish --region ap-southeast-1 --phone-number "+8613916244719" --message file://logfile)
    echo > logfile
    Logfile=0
  fi
done
