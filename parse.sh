#!/usr/bin/env bash

exec 2>/dev/null

site="https://#########/private"
#example of making safely POST request with login/password authentication
#prepairing massage with POST parameter includind secret password
#echo -n "numfile=my_secret_login&pass=my_sercet_password&formseen=y" | gpg -e --armor -r script
#decrypting message into runtime file to use it in curl command
#grabing session id for following requests
PHPSESSID=$(curl -i -s -X POST $site/auth.php --data @<(gpg --batch -d --armor -r script <<'TXT'
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1

hQEMA5H0+5MDZB8LAQf+LxatSrlmhKUNxdHngTCIGz1uy0sxMLy9ArDnxh8+2X8R
wvXXO6PRGfEHV0P+j+JaAuzKIbylGK8rT3q68qlUh0CSvTbfIch2BALvf1GRPiZT
lMQQ8Onhx53lnaywfnAY8nrX1O52BXLAKc2J/IDvoHisXegyYwyB/FQ3DhKLHrIK
56xonbDCJYSmQSgFjBO4X2kPNDJ/WjfjSxrGlrg0cpYMX+N6WChcM3bNjl+E/ei/
EvkxFA8d3hdmwMJjOdBT5xp768Euoq1icfbxkPmTUikgno15GMrLeVvKOJu7u4rm
X01VuOIMxi1dsdvQvITZFJ8clLsJA9mHwG3lbTFuE9JtAY0u5zc0q2Bnm+2u3BNl
Bq/CO0u1jT7W2Kac+dka6zaqyyK50Tf0avy7M99hxjjHCyG6w5k9KkHCcuJYOuMJ
8ofDUftJxIgu2qfdpp9eFZu67D5lO4XVxAV5L8kCy4GONUHw/K0fJyntaZiCow==
=mO0n
-----END PGP MESSAGE-----
TXT
) | grep -oP '(?<=PHPSESSID=)[^;]+' )

curl -s -b "PHPSESSID=$PHPSESSID" $site/privatePage.php > /dev/null
cmn_id=$(curl -s -b "PHPSESSID=$PHPSESSID" $site/add_flat.php | xmlstarlet fo --html --dropdtd | xmlstarlet sel -t -c '//*[@name="cmn_id"]' | grep -oP '(?<=value=")[^"]+(?=".*Верхнеуслонский)')
rty_id=$(curl -s -b "PHPSESSID=$PHPSESSID" -X POST --data "cmn_id=$cmn_id" $site/add_flat.php | xmlstarlet fo --html --dropdtd | xmlstarlet sel -t -c '//*[@name="rty_id"]' | grep -oP '(?<=value=")[^"]+')
for id in $rty_id; do
    curl -s -b "PHPSESSID=$PHPSESSID" -X POST --data "cmn_id=$cmn_id&rty_id=$id" $site/add_flat.php | xmlstarlet fo --html --dropdtd | xmlstarlet sel -t -v '//*[@id="addFlat"]/ul/li/table/tr/td/a'
done
