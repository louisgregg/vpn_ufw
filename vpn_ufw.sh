#!/bin/bash

# Check for root priviliges
if [[ $EUID -ne 0 ]]; then
   printf "Please run as root:\nsudo %s\n" "${0}"
   exit 1
fi

#In order to obtain data from the config file (located in the same directory as this script)
#the following code returns the exact directory in which THIS script is located. 
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

#Obtain values from the config file. 
source $DIR/vpn_ufw_config.cfg

#Stop all processes with the keyword specified in config file. 
killall -9 $process_to_kill

#shut down firewall if running
ufw disable

#disable VPN (if running)
sudo -u $username nmcli con down $vpn_name

#connect to vpn (run as user)
sudo -u $username nmcli con up $vpn_name

#reset firewall. Set rules (DNS queries blocked). Bring the firewall up.

# Reset the ufw config
ufw --force reset

# let all incoming traffic pass
ufw default allow incoming
# and block outgoing by default
ufw default deny outgoing

# Every communiction via VPN is considered to be safe
ufw allow out on tun0

#Don't block the creation of the VPN tunnel
#I've disabled this, to ensure that connections cannot be made through this port, bypassing the VPN.
#Therefore the initial connection TO the VPN server must be made before the firewall is enabled.  
#ufw allow out $VPN_DST_PORT

#Block / Don't block DNS queries
#By default, DNS querues are blocked (unless going through VPN) to prevent against potential DNS leaks.
#Uncomment the following line if you wish to allow DNS queries to bypass your VPN.
#ufw allow out 53

# Allow local IPv4 connections
ufw allow out to 10.0.0.0/8
ufw allow out to 172.16.0.0/12
ufw allow out to 192.168.0.0/16
# Allow IPv4 local multicasts
ufw allow out to 224.0.0.0/24
ufw allow out to 239.0.0.0/8

# Allow local IPv6 connections
ufw allow out to fe80::/64
# Allow IPv6 link-local multicasts
ufw allow out to ff01::/16
# Allow IPv6 site-local multicasts
ufw allow out to ff02::/16
ufw allow out to ff05::/16

# Enable the firewall
ufw enable

#Get firewall status and outfacing IP address. 
ufw_status=$(ufw status | sed -n '1 p')
ip_temp=$(sudo -u $username curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
#Print the firewall status.
echo "the ufw_status variable is" 
echo $ufw_status
#Print our outfacing ip address.
echo "the ip_temp variable is"
echo $ip_temp

ufw_on_status='Status: active'
#Check that the firewall status and ip address are correct.
if [ "$ip_temp" = "$correct_vpn_ip" ] && [ "$ufw_status" = "$ufw_on_status" ];
then
	echo "Our outfacing IP is "$ip_temp" (the correct address) and ufw reports "$ufw_status"."
	echo "Executing Command."
	sudo -u $username $command_to_execute	
else 
	echo "Our outfacing IP is "$ip_temp" and ufw reports "$ufw_status
	echo "Either our outfacing IP is wrong, the ufw status is wrong, or both."
	echo "NOT executing commmand."
fi
