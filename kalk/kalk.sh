#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# jednoduchá prefixová kalkulačka, fungují pole a všechno

# var
stack="/tmp/calc/stack"
parsedLine="/tmp/calc/parsedLine"
vars="/tmp/calc/vars"
stackSize="0"

# na stdout, nesnižuje stackSize
pop () {
	item=$(tail -n 1 < $stack) # TODO dodělat test a evaluaci proměnné 

	ed -s $stack <<END
.d
w
q
END
	echo $item
}

# $1 = dir
push () {
	echo "$1" >> $stack
	stackSize=$(($stackSize+1))
}

# $1 = nmb/var, na stdout číslo
evaluate () {
	if [ $1 -eq $1 2> /dev/null ]; then # cislo
		echo $1
	else # var
		getVar $1
	fi

}

# $1 varName
getVar () {
	grep "^$1=.*$" $vars | sed "s|^$1=\(.*\)$|\1|"
}

# $1 varName, $2 value
setVar () {
	if grep "^$1=.*$" $vars > /dev/null; then
		ed  -s $vars >> /dev/null <<END
/$1/
d
\$a
$1=$2
.
w
q
END
	else 
		ed -s $vars >> /dev/null <<END
\$a
$1=$2
.
w
q
END
	fi
}

rm -Rf "/tmp/calc"
mkdir "/tmp/calc"

#rm -f $stack
#rm -f $parsedLine

#getVar "a"
#getVar "b"
#getVar 'c_4'
#setVar "d" "14"

#exit

while read line; do # řádky
	echo $line | tr -s " \t" | tr " " "\n" > $parsedLine
	#cat $parsedLine
	#exit
	while read ex; do # operátory
		echo "STACK:"
		cat $stack
		echo "STACKEDN"
		case $ex in 
			[0-9] )
				push "$ex"
				;;
			'+' | '-' | '*' | '/' ) #TODO: vyřešit hvězdičku
				b=$(pop)
				#echo $b
				b=$(evaluate $b)
				#echo $b
				stackSize=$(($stackSize-1))

				a=$(pop)
				a=$(evaluate $a)
				stackSize=$(($stackSize-1))
				
				res=$(($a$ex$b))
				#echo "... $a $ex $b = $res"
				push "$res"
				;;
			'=' )
				v=$(pop)
				stackSize=$(($stackSize-1))

				nmb=$(pop)
				nmb=$(evaluate $nmb)
				stackSize=$(($stackSize-1))

				setVar "$v" "$nmb"
				;;
			']' )
				#echo "konec pole"
				v=$(pop)
				stackSize=$(($stackSize-1))

				index=$(pop)
				index=$(evaluate $index)
				stackSize=$(($stackSize-1))

				echo "$v"'_'"$index"
				push "$v"'_'"$index"
				;;
			* )
				push "$ex"
				;;

		esac
	done < "$parsedLine"
done

rm -Rf "/tmp/calc"

