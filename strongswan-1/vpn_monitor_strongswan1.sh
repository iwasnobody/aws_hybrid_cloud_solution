#!/bin/bash
litterbin=$(ip link add tunnel1 type vti local 172.16.1.100 remote 52.50.130.77 key 100)
litterbin=$(ip add add 169.254.100.2/24 remote 169.254.100.1/24 dev tunnel1)
litterbin=$(ip link set tunnel1 up mtu 1436)

litterbin=$(ip rule add priority 10 from all lookup 10)

ip route add 169.254.100.0/24 via 169.254.100.1 table 10
ip route add 10.10.0.0/16 via 169.254.100.1 table 10
