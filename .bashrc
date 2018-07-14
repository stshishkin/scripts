alias qrpass="qrencode -s 7 -o - -t UTF8 'WIFI:S:<SSID>;T:WPA2;P:<password>;;'"
alias wifipass="qrpass"
alias generate='echo $(cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c32)'
function wan(){
    if ping -c 1 ns2.google.com &> /dev/null ; then
        echo $(dig TXT +short o-o.myaddr.l.google.com @ns2.google.com | sed "s/\"//g" )
    else 
        echo offline
    fi
}
function online (){
    if [[ -z $1 ]]; then
        test_host=8.8.8.8
    else
        test_host=$1
    fi

    while true
        do
            sleep 0.5
            ping -c 1 $test_host &> /dev/null 2>&1
            exitcode=$?
            if [[ $exitcode -eq 0 ]]; then
                echo online;
                break
            elif [[ $exitcode -gt 128 ]]; then
                echo stop;
                break
            fi
        done
}
function ripe () {
    link="http://rest.db.ripe.net/search?source=ripe&query-string="
    echo $(curl -s "${link}$1" | xmlstarlet sel -t -c 'string(//*[@name="netname"]/@value)')
}
