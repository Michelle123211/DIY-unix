#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# tak nějak funguje, ale chtělo by to pořádně předělat přepínače a testovat


# var
stack="/tmp/stack.$$"
stackSize="0"
tmp="/tmp/tmp.$$"

# default
file="*"
fileType="-"
print="1"
exe=""
user=""

# na stdout, nesnižuje stackSize
pop () {
	tail -n 1 < $stack

	ed -s $stack <<END
.d
w
q
END
}

# $1 = dir
push () {
	echo $1 >> $stack
	stackSize=$(($stackSize+1))
}

# $1 = dir
searchDir () {
	# slozky do zasobniku
	ls -l "$1" 2> /dev/null | grep "^d" > $tmp
	while read x x x x x month day t name; do
		push "$1/$name" # TODO pushovat abecedně obráceně
	done < $tmp

	# soubory skouknout
	ls -l "$1" 2> /dev/null | grep "^$fileType" > $tmp
	while read x x owner x x month day t name; do
		if [ "$name" = "$file" -a "$owner" = "$user" ]; then
			if [ "$print" = "1" ]; then
				echo "$1/$name"
			fi
			if [ "$exe" != "" ]; then
				#echo "$exe $1/name"
				echo $exe | sed "s|{}|$1/$name|" | sh
			fi
		fi
	done < $tmp
}

# zpracování param.
while [ $# -ne 0 ]; do
	case $1 in 
		'-name' )
			file="$2"
			shift 2
			;;
		'-type' ) #TODO: kontrola správnosti = [f|d|l]
			fileType="$2"
			if [ $fileType = "f" ]; then
				fileType="-"
			fi
			shift 2
			;;
		'-print' )
			print="1"
			exe=""
			shift 1
			;;
		'-ls' )
			print="1"
			exe="ls -l {}"
			shift 1
			;;
		'-user' ) # předpokládá UID, ale čekne pro jistotu i login
			input=$2
			user=$input
			shift 2
			tmpUser=$(cat /etc/passwd | sed -n "s|^\([^:]*\):[^:]*:$input:.*$|\1|p")
			if [ ! $tmpUser = "" ]; then #byl to UID
				user=$tmpUser
			fi
			;;
		'-exec' )
			print="0"
			shift 1
			while : ; do
				if [ "$1" = ";" ]; then
					shift 1
					break
				else
					exe="$exe $1"
					shift 1
				fi
			done
			exe=$(echo $exe | sed 's|^ \(.*\)$|\1|') # smaž mezeru na začátku
			;;
		* )
			#TODO wildcards/regexps
			push "$1"
			shift 1
			;; 
	esac
done

#echo "--$exe"
#echo '$file='"$file"
#echo '$fileType='"$fileType"

# hlavni smycka
while [ $stackSize -gt 0 ]; do
	dir=$(pop)
	stackSize=$(($stackSize-1))

	#echo "-- $dir"
	#echo "-- $stackSize"
	#break

	searchDir "$dir"
	#read x
	#break
done

# uklid
rm -f $tmp
rm -f $stack
