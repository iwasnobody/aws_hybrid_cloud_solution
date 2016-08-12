#!/bin/bash

RX_packets_old=0
TX_packets_old=0
RX_bytes_old=0
TX_bytes_old=0

while [[ 1 ]]; do
RX_packets_new=$(ifconfig tunnel1 | grep "RX packets" | awk '{print $2}' | sed 's/.*:\(.*\)/\1/g' | awk '{printf "%s",$0}')
TX_packets_new=$(ifconfig tunnel1 | grep "TX packets" | awk '{print $2}' | sed 's/.*:\(.*\)/\1/g' | awk '{printf "%s",$0}')
RX_bytes_new=$(ifconfig tunnel1 | grep "RX bytes" | awk '{print $2}' | sed 's/.*:\(.*\)/\1/g' | awk '{printf "%s",$0}')
TX_bytes_new=$(ifconfig tunnel1 | grep "RX bytes" | awk '{print $6}' | sed 's/.*:\(.*\)/\1/g' | awk '{printf "%s",$0}')

let RX_packets=($RX_packets_new-$RX_packets_old)
let TX_packets=($TX_packets_new-$TX_packets_old)
let RX_bytes=($RX_bytes_new-$RX_bytes_old)
let TX_bytes=($TX_bytes_new-$TX_bytes_old)

RX_packets_old=$RX_packets_new
TX_packets_old=$TX_packets_new
RX_bytes_old=$RX_bytes_new
TX_bytes_old=$TX_bytes_new

#sleep 60

#echo $RX_packets
#echo $RX_bytes
#echo $TX_packets
#echo $TX_bytes

aws cloudwatch put-metric-data --region ap-southeast-1 --metric-name VPN2_RX_Packets --namespace "VPN Traffic Statistics" --value $RX_packets
aws cloudwatch put-metric-data --region ap-southeast-1 --metric-name VPN2_RX_Bytes --namespace "VPN Traffic Statistics" --value $RX_bytes
aws cloudwatch put-metric-data --region ap-southeast-1 --metric-name VPN2_TX_Packets --namespace "VPN Traffic Statistics" --value $TX_packets
aws cloudwatch put-metric-data --region ap-southeast-1 --metric-name VPN2_TX_Bytes --namespace "VPN Traffic Statistics" --value $TX_bytes
sleep 30
done
