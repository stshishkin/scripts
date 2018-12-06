#!/bin/bash

# script for compairing CDR files (csv - format) in case of dusputes between VoIP providers
#
# USAGE:
# $1 - our CDR file
# $2 - delimeter
# $3 - №-column with destination number
# $4 - №-column with duration
#
# $5 - partner's CDR file
# $6 - delimeter
# $7 - №-column with destination number
# $8 - №-column with duration
#
# EXAMPLE: ./our.csv \; 5 6 ./partner.csv \",\" 6 7
#

OUR_FILE=$1
OUR_DEL=$2
OUR_BNUM=$3
OUR_DUR=$4

PART_FILE=$5
PART_DEL=$6
PART_BNUM=$7
PART_DUR=$8

OUT_DIFF="diff.file"

check () {
    for i in OUR PART; do
	FILE=${i}_FILE
    	DEL=${i}_DEL
    	BNUM=${i}_BNUM
    	DUR=${i}_DUR

    	most_value=$(awk -F${!DEL} 'FNR>1{if($'${!DUR}' ~ /^[0-9]+$/ && $'${!BNUM}' ~ /^[0-9]+$/){print $'${!DUR}'}else{print "NO"}}' ${!FILE} |\
    	sort | uniq -c | sort -rn | head -1)
    	if [[ "$most_value" =~ "NO" ]]; then
    	    echo "too much incorrect values in ${!FILE} : ("$(echo $most_value | awk '{print $1}')"/"$(count_calls ${!FILE})")"
    	    exit
    	fi
    done
}

sum_time () { 
    FILE=${1}_FILE
    DEL=${1}_DEL
    DUR=${1}_DUR
    awk -F${!DEL} 'BEGIN{s=0}FNR>1{s+=$'${!DUR}'}END{print s}' ${!FILE}
}

count_calls () { 
    cat $1 | wc -l
}

diff_file () {
	diff -y --suppress-common-lines <(cat $OUR_FILE | awk -F$OUR_DEL 'FNR>1{print $'$OUR_BNUM'";"$'$OUR_DUR'}' | sort)\
	 <(cat $PART_FILE | awk -F$PART_DEL 'FNR>1{print $'$PART_BNUM'";"$'$PART_DUR'}' | sort)
}

new_calls () {
	if [[ $2 == "OUR" ]];then
		local DIR='>'
	else
		local DIR='<'
	fi
	new=$(cat $1 | grep $DIR | grep -oE '[0-9]+;[0-9]+')

	if [[ $2 == "OUR" ]];then
		local FIELDS='$1";"$2'
	else
		local FIELDS='$3";"$4'
	fi
	new=$new"\n"$(cat $1 | grep '|' | sed 's/\s//g;s/|/;/' | awk -F';' '{if($1!=$3) print '$FIELDS'}')
	#echo $new >> ./check
	our=0
	part=0
	if [[ $3 == "check" ]]; then
	    printf '%s\n' "$new" | while IFS= read -r line; do
		num=$(echo $line | awk -F\; '{print $1}')
		#echo "$num $(grep -c $num $OUR_FILE) $(grep -c $num $PART_FILE)" >> ./check
		if [[ $(grep -c $num $OUR_FILE) != $(grep -c $num $PART_FILE) ]]; then 
		    echo $line; 
		else
		    if [[ $2 == "OUR" ]];then
			echo our >> ./check
		    else
			echo part >> ./check
		    fi
		fi 
	    done
	    #echo "$our $part" > ./check
	else
	    echo $new
	fi
}

round_calls () {
	cat $1 | grep '|' | sed 's/\s//g;s/|/;/' | awk -F';' '{if(($2-$4)**2==1 && $1==$3) print $0}'
}

diff_calls () {
	cat $1 | grep '|' | sed 's/\s//g;s/|/;/' | awk -F';' '{if(($2-$4)**2!=1 && $1==$3) print $0}'
}

example () {
	for line in $(cat $1); do

		res=$(echo $line | awk -F';' '{print NF}')
		if [[ "$res" -gt "2" ]]; then
			OUR_PART=$(echo $line | awk -F';' '{print $1";"$2}' )
			PART_PART=$(echo $line | awk -F';' '{print $3";"$4}' )

			for i in OUR PART; do
				BNUM=${i}_BNUM
				DUR=${i}_DUR
				DEL=${i}_DEL
				FILE=${i}_FILE
				PART=${i}_PART
				if [[ ${!BNUM} -lt ${!DUR} ]];then
					regexp=$(echo ${!PART} | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL}|^)\1(${!DEL})?.*${!DEL}\2(${!DEL}|$)/")
				else
					regexp=$(echo ${!PART} | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL}|^)\2(${!DEL})?.*${!DEL}\1(${!DEL}|$)/") 
				fi
				grep -E "$regexp" ${!FILE}
			done
		else
			DEL=${2}_DEL
			FILE=${2}_FILE
			BNUM=${2}_BNUM
			DUR=${2}_DUR
			if [[ ${!BNUM} -lt ${!DUR} ]];then
				regexp=$(echo $line | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL}|^)\1(${!DEL})?.*${!DEL}\2(${!DEL}|$)/")
			else
				regexp=$(echo $line | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL}|^)\2(${!DEL})?.*${!DEL}\1(${!DEL}|$)/") 
			fi
			grep -E "$regexp" ${!FILE}
		fi
	done
}

check
our_time=$(sum_time OUR)
part_time=$(sum_time PART)
echo -n "difference by time:" $(((our_time - part_time) / 60)) "мин. ("\
$(bc <<< "scale=2;($our_time - $part_time) * 100 / $our_time" | sed -E 's/^(-)?\./\1 0./') "% of our total time)"
echo
our_calls=$(count_calls $OUR_FILE)
part_calls=$(count_calls $PART_FILE)
echo "difference by calls:" $((our_calls - part_calls)) "шт"

diff_file > $OUT_DIFF

round_num=$(round_calls <(diff_file) | wc -l)
if [[ $round_num -ne 0 ]]; then
    echo "calls with round missmatch:" $round_num  "шт," $(($round_num / 60)) "мин"
fi

missmatch_num=$(diff_calls <(diff_file) | wc -l)
if [[ $missmatch_num -ne 0 ]]; then
    echo "calls with duration missmatch:" $missmatch_num  "шт," \
    $(( $(diff_calls <(diff_file) | awk -F';' '{our+=$2; part+=$4}END{print our-part}') / 60)) "мин"
    echo "examples:" 
    printf "$(example <(diff_calls <(diff_file) | head )) \n"
    #example <(diff_calls <(diff_file)) PART > missmatch.csv
fi

our_missed_num=$(new_calls <(diff_file) OUR check | wc -l)
if [[ $our_missed_num -ne 0 ]]; then
    echo "calls, which missed in our CDR:" $our_missed_num "шт," \
    $(( $(new_calls <(diff_file) OUR check | awk -F';' 'BEGIN {s=0} {s+=$2} END {print s}') / 60 )) "мин"
#new_calls <(diff_file) OUR | sort -t\; -k2nr | head
    echo "examples:" 
    printf "$(example <(new_calls <(diff_file) OUR check | sort -t\; -k2nr | head ) PART) \n"
    example <(new_calls <(diff_file) OUR | sort -t\; -k2nr) PART > ourmiss.csv
fi

part_missed_num=$(new_calls <(diff_file) PART check | wc -l)
if [[ $part_missed_num -ne 0 ]]; then
    echo "calls, which missed in partner's CDR:" $part_missed_num "шт," \
    $(( $(new_calls <(diff_file) PART check | awk -F';' 'BEGIN {s=0} {s+=$2} END {print s}') / 60 )) "мин"
    echo "examples:" 
    #printf "$(example <(new_calls <(diff_file) PART check | sort -t\; -k2nr | head ) OUR) \n"
    #example <(new_calls <(diff_file) PART check | sort -t\; -k2nr) OUR > partmiss.csv
fi

