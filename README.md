This script  provides a way to ensure that your traffic is being routed through a vpn connection (as enforced by a firewall) before executing the command of your choice - like starting a torrent client for example. 


It does the following tasks in the following order, based on parameters stored in the config file **vpn_ufw_config.cfg**:

1. Kills tasks which include a keyword (to shut down your torrent client, for example). 
2. Disable ufw (if running).
3. Disable a VPN connection (if connected) using nmcli.
4. Enables the same VPN connection. 
5. Sets a series of ufw firewall rules. 
	* These rules allow all incoming connections and forbid all outgoing connections. 
	* Outgoing local connections and outgoing connections through tun0 (the VPN) are allowed.
6. Enables ufw. 
6. Our outfacing IP address is retrieved from dyndns.org. 
7. Finally, if the firewall status and our outfacing ip address are correct, then a command (from the config file) is executed.

Step 5, the section which configures ufw, was taken from a script by **Thomas Butz**. You can find the origional script in his post here: https://community.hide.me/threads/internetverbindung-auf-vpn-beschraenken-ufw-firewall.571/

An example config file is provided. Edit this file to match your needs and save it as **vpn_ufw_config.cfg**.

This script was tested on Ubuntu and Debian systems. Your VPN connection must be correctly configured in NetworkManager and you need ufw installed to enfore the firewall rules. **nmcli** is used to enable / disable the VPN. This script must be run with sudo or as root.  
