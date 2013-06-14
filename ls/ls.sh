#!/bin/bash

###################
# Petr Bělohlávek #
###################

# Pozn.:
# místo expanzí by byl podstatně lepší a rychlejší find :)


# vars
stack="/tmp/.ls/stack"
stackSize="0"

a="0"
A="0"
d="0"
R="0"
r="0"
t="0"

defaultIFS="$IFS"
tmpStat="/tmp/.ls/stat.tmp"
output="/tmp/.ls/output"
tmpPop="/tmp/.ls/pop.tmp"

depth="2"

clean () {
	rm -Rf "/tmp/.ls"
}

# na stdout, nesnižuje stackSize
pop () {
	tail -n 1 < $stack

	ed -s $stack <<END
.d
w
q
END
}

# $1 = process
push () {
	echo $1 >> $stack
	stackSize=$(($stackSize+1))
}

# $1 = file
writeFile () { #TODO pouze jméno, ne cesta
	#echo $1
	IFS=" "
	stat -t -c "%A %h %U %G %s %z %N" "$1" | tr -d '„' | tr -d '“' > $tmpStat
	read perm links owner group size date time area fullName arrow symlink < $tmpStat
	# date = 2013-02-09
	# time = 10:08:54.869001741
	#TODO parse

	name=$(echo $fullName | sed "s|^.*/\(.*\)$|\1|")
	fileType=$(echo $perm | sed 's|^\(.\).*$|\1|')

	# chtělo by to case
	if [ "$fileType" = "-" ]; then #file
		echo $perm $links $owner $group $size $date $time $name
	else
		if [ "$fileType" = "d" ]; then #dir
			if [ "$d" = "1" ]; then # projeď pouze současný adresář
				echo $perm $links $owner $group $size $date $time $name
			fi
		else #symlink
			echo $perm $links $owner $group $size $date $time $name $arrow $symlink
		fi
	fi
	IFS="$defaultIFS"
}

clean
mkdir "/tmp/.ls"
# param
while [ $# -ne 0 ]; do
	case $1 in 
		-a )
			a="1"
			shift 1
			;;
		-A )
			A="1"
			shift 1
			;;
		-d )
			d="1"
			depth="1"
			shift 1
			;;
		-R )
			R="1"
			depth="999999999"
			shift 1
			;;
		-r )
			r="1"
			shift 1
			;;
		-t )
			t="1"
			shift 1
			;;
		* )
			push "$depth $1"
			echo "push"
			shift 1
			;;
	esac
done

# check param
if [ "(" $a = "1" -a $A = "1" ")" -o "(" $d = "1" -a $R = "1" ")" ]; then
	echo "Wrong param combination" > /dev/stderr
	exit 1
fi

# default
if [ "$stackSize" = "0" ]; then
	curr=$(pwd | tr -d "\n")
	push "$depth $curr"
fi

# TODO: -r -t
# bez stacku - find "$path" -maxdepth 1 > /tmp/find
while [ "$stackSize" -ne "0" ]; do
	pop > $tmpPop
	stackSize=$(($stackSize-1))

	read depth path < $tmpPop
	writeFile "$path"

	if [ "(" ! "$depth" = "0" ")" -a "(" "$fileType" = "d" ")" ]; then # pokračuj rekurzivně
		newDepth=$(($depth-1))
		if [ "(" "$a" = "1" ")" -o "(" "$A" = "1" ")" ]; then
			for file in "$path/."*; do
				if [ "(" "$A" = "1" ")" -a "(" "(" "$file" = "$path/." ")" -o "(" "$file" = "$path/.." ")" ")" ]; then
					continue
				fi
				if [ "$file" = "$path/"'*' ]; then
					continue
				fi
				push "$newDepth $file"
			done
		fi

		for file in "$path/"*; do
			if [ "$file" = "$path/"'*' ]; then
				continue
			fi
			push "$newDepth $file"
		done
	fi
done

clean
