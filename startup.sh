#!/bin/bash

DHCLIENT=$(which dhclient 2>&1)
IP=$(which ip 2>&1)
GREP=$(which grep 2>&1)
REBOOT=$(which reboot 2>&1)
PING=$(which ping 2>&1)
RESET=$(which reset 2>&1)
IPTABLES=$(which iptables 2>&1)

save(){
    echo -en "\033[s"
}

undo(){
    echo -en "\033[u"
    echo -en "\033[0J"
}

err(){
    echo -en "\033[1;31m$1\033[0m"    
}

ok(){
    echo -en "\033[1;32m$1\033[0m"    
}

get_info(){
	auto_iface="$($IP route get 8.8.8.8 2>/dev/null | $GREP -Po '(?<=dev )[^ ]+')"
	if [[ -z $auto_iface ]]; then
		auto_iface='none'
		auto_ip='none'
	else
		auto_ip="$($IP addr show dev $auto_iface | $GREP -Po '(?<=inet )[^/ ]+' )"
		if [[ -z $auto_ip ]]; then
			auto_ip='none'
		fi
	fi
	ip_output=$($IP address show)
	i=j=k=1
	while read line ; do
	    regex1='[0-9]+: ([^:]+): <([^>]*BROADCAST[^>]*)> .*state ([^ ]+) .*'
	    regex2='ether ([0-9a-f:]+)'
	    regex3='inet ([0-9./]+)'
	    if [[ $line =~ $regex1 ]]; then
		ifaces[$i]=${BASH_REMATCH[1]}
		state[$i]=${BASH_REMATCH[3]}
		statuses=${BASH_REMATCH[2]}
		act[$i]='off'
		l2[$i]='unplugged'
		for flag in $(echo $statuses | tr ',' ' ' ); do
		    if [[ $flag = 'UP' ]]; then
			act[$i]='on'
		    elif [[ $flag = 'LOWER_UP' ]]; then
			l2[$i]='plugged'
		    fi
		done
		i=$i+1
	    elif [[ $line =~ $regex2 ]]; then
		mac[$j]=${BASH_REMATCH[1]}
		j=$j+1
	    elif [[ $line =~ $regex3 ]]; then
		ip[$k]=${BASH_REMATCH[1]}
		k=$k+1
	    fi
	done <<< "$ip_output"
}

menu(){

	$RESET
	
	echo "Actual IP on default interface ($auto_iface) : $auto_ip"
	echo
	echo
	echo "Console  setup"
	echo 
	echo "1) Change IP on LAN interface"
	echo "2) Ping host"
	echo "3) Clear Firewall"
	echo "4) Reboot"
	echo

	echo -n "Enter a number:"
	read number

	case ${number} in
	1) 
		menu_ip
		;;
	2) 
		menu_ping
		;;
	3) 
		clear_iptables
		;;
	4) 
		menu_reboot
		;;
	65535)
		exit
		;;
	*)
		err "Wrong number"
		sleep 1
		menu
		;;
	esac
}

menu_ip(){
	i=1
	save
	echo "Network interfaces:"
	for (( a=1 ; a<${#ifaces[@]}+1 ; a++ )); do
		echo -ne "$a) ${ifaces[$a]}\t"
		if [[ ${l2[$a]} =~ unplugged ]]; then
		    err "${l2[$a]}\t"
		else
		    ok " ${l2[$a]} \t"
		fi
		if [[ ${act[$a]} =~ off ]]; then
		    err "${act[$a]}\t"
		else
		    ok " ${act[$a]} \t"
		fi
		if [[ ${state[$a]} =~ UP ]]; then
		    ok " ${state[$a]} \t"
		else
		    err "${state[$a]}\t"
		fi
		if [[ -z "${mac[$a]}" ]]; then
		    echo -ne "none\t"
		else
		    echo -ne "${mac[$a]}\t"
		fi
		if [[ -z "${ip[$a]}" ]]; then
		    echo -ne "none\t"
		else
		    echo -ne "${ip[$a]}\t"
		fi
		echo
	done
	echo -n "Select a number of default interface (0 for cancel): "
	read n
	if [[ $n =~ ^[0-9]+$ ]]; then
	    if [[ $n -ge 1 ]] && [[ $n -le ${#ifaces[@]} ]]; then
		change_ip $n
	    elif [[ $n -eq 0 ]]; then
		err "Cancelled."
		sleep 1
		menu
	    else
		err "Number is not correct. Please enter a number of interface."
		sleep 1
		undo
		menu_ip
	    fi
	else
	    err "Not a number. Please enter a number of interface."
	    sleep 1
	    undo
	    menu_ip
	fi
}

check_ip(){
	if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)(/([0-9]+))?$ ]]; then
	    for (( i=1; i<5; i++)); do
		if ! [[ ${BASH_REMATCH[$i]} -ge 0 ]] || ! [[ ${BASH_REMATCH[$i]} -le 255 ]]; then
		    return 1
		fi
	    done
	    if [[ -n ${BASH_REMATCH[6]} ]] && [[ ${BASH_REMATCH[6]} -gt 32 ]]; then
		return 1
	    fi
	    return 0
	else
	    return 1
	fi
}

change_ip(){
	save
	echo -n "Do you want to use DHCP for (${ifaces[$n]}) interface(y/n):"
        read ok
        if [ $ok = "y" ] || [ $ok = "Y" ]; then
		if [[ -n "$(ps ax | $GREP dhclient)" ]]; then
			killall -9 dhclient	
		fi
		$DHCLIENT
		get_info
		echo "IP (${ip[$n]}) was assigned to interface ${ifaces[$n]} by DHCP."
		echo -n "Press ENTER to continue."
		read
	else
	    echo -n "Please enter a new IP for (${ifaces[$n]}) interface:"
	   	read ip
	   	if check_ip $ip; then
	   	    mask=""
	   	    if [[ -z ${ip##*/} ]]; then
	   		mask="/24"
	   	    fi
	   	    $($IP address flush dev ${ifaces[$n]})
	   	    if [[ $? -ne 0 ]]; then
	   		err "failed"
	   		sleep 1
	   		return
	   	    fi
	   	    $($IP address add ${ip}${mask} dev ${ifaces[$n]})
	   	    if [[ $? -ne 0 ]]; then
	   		err "failed"
	   		sleep 1
	   		return
	   	    fi
	   	    $($IP link set ${ifaces[$n]} up)
	   	    if [[ $? -ne 0 ]]; then
	   		err "failed"
	   		sleep 1
	   		return
	   	    fi
	   	    ok "success"
	   	    sleep 1
	   	    return
	   	else
	   	    err "IP is not correct."
	       	    sleep 1
	       	    undo
	       	    change_ip $n
	   	fi
	fi
}

clear_iptables(){
	echo -n "All your network defense will be erased."
	echo -n "Are you sure? (y/n)"
	read ok
	if [ $ok = "y" ] || [ $ok = "Y" ]; then
		echo -n "Flush all rules... "
		$IPTABLES -F
		$IPTABLES -F -t nat
		$IPTABLES -F -t mangle
		$IPTABLES -X
		$IPTABLES -X -t nat
		$IPTABLES -X -t mangle
		ok "done."
	else
		err "Canceled."
	fi
	echo
	echo -n "Press ENTER to continue."
	read
}

menu_ping(){
    save
    echo -n "Enter IP:"
    read ip
    if check_ip $ip; then
	$PING -c4 $ip
	echo -n "Press ENTER to continue."
	read
    else
        err "IP is not correct."
        sleep 1
        undo
        menu_ping
    fi
}

menu_reboot(){
    echo -n "Are you sure? (y/n)"
    read ok
    if [ $ok = "y" ] || [ $ok = "Y" ]; then
    	$REBOOT
    else
    	err "Canceled."
    fi
}

trap '' 2 3 15 9

$DHCLIENT

while true
do
    get_info
    menu
done
