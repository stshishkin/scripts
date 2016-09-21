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

sum_time () { 
    cat $1 | awk -F$2 'FNR>1{s+=$'$3'}END{print s}'
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
	cat $1 | grep $DIR | grep -oE '[0-9]+;[0-9]+'
}

round_calls () {
	cat $1 | grep '|' | sed 's/\s//g;s/|/;/' | awk -F';' '{if(($2-$4)**2==1) print $0}'
}

diff_calls () {
	cat $1 | grep '|' | sed 's/\s//g;s/|/;/' | awk -F';' '{if(($2-$4)**2!=1) print $0}'
}

new_calls_ext () {
	BNUM=${2}_BNUM
	DUR=${2}_DUR
	DEL=${2}_DEL
	FILE=${2}_FILE

	if [[ $2 == "OUR" ]];then
		local DIR='<'
	else
		local DIR='>'
	fi

	if [[ ${!BNUM} -lt ${!DUR} ]];then
		grep -Ef <(cat $1 | grep $DIR | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/${!DEL}\1(${!DEL})?.*${!DEL}\2${!DEL}/") ${!FILE}
	else
		grep -Ef <(cat $1 | grep $DIR | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/${!DEL}\2(${!DEL})?.*${!DEL}\1${!DEL}/") ${!FILE}
	fi
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
					regexp=$(echo ${!PART} | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/${!DEL}\1(${!DEL})?.*${!DEL}\2${!DEL}/")
				else
					regexp=$(echo ${!PART} | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/${!DEL}\2(${!DEL})?.*${!DEL}\1${!DEL}/") 
				fi

				grep -E "$regexp" ${!FILE}
			done
		else
			DEL=${2}_DEL
			FILE=${2}_FILE
			BNUM=${2}_BNUM
			DUR=${2}_DUR
			if [[ ${!BNUM} -lt ${!DUR} ]];then
				regexp=$(echo $line | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL})?\1(${!DEL})?.*${!DEL}\2(${!DEL})?/")
			else
				regexp=$(echo $line | sed -E "s/[^0-9]*([0-9]+);([0-9]+)[^0-9]*/(${!DEL})?\2(${!DEL})?.*${!DEL}\1(${!DEL})?/") 
			fi

			grep -E "$regexp" ${!FILE}
		fi
	done
}

our_time=$(sum_time $OUR_FILE $OUR_DEL $OUR_DUR)
part_time=$(sum_time $PART_FILE $PART_DEL $PART_DUR)
echo "difference by time:" $(((our_time - part_time) / 60)) "мин"

our_calls=$(count_calls $OUR_FILE)
part_calls=$(count_calls $PART_FILE)
echo "difference by calls:" $((our_calls - part_calls)) "шт"

diff_file > $OUT_DIFF

echo "calls with round missmatch:" $(round_calls <(diff_file) | wc -l) "шт,"\
 $(($(round_calls <(diff_file) | wc -l) / 60)) "мин"
echo "calls with duration missmatch:" $(diff_calls <(diff_file) | wc -l) "шт,"\
 $(( $(diff_calls <(diff_file) | awk -F';' '{our+=$2; part+=$4}END{print our-part}') / 60)) "мин"
echo "examples:" 
printf "$(example <(diff_calls <(diff_file) | head )) \n"

echo "calls, which missed in our CDR:" $(new_calls <(diff_file) OUR | wc -l) "шт,"\
 $(( $(new_calls <(diff_file) OUR | awk -F';' '{s+=$2} END {print s}') / 60 )) "мин"
echo "examples:" 
printf "$(example <(new_calls <(diff_file) OUR | head ) PART) \n"

echo "calls, which missed in partner's CDR:" $(new_calls <(diff_file) PART | wc -l) "шт,"\
 $(( $(new_calls <(diff_file) PART | awk -F';' '{s+=$2} END {print s}') / 60 )) "мин"

