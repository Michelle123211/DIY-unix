#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# není potřeba getline v awk
# násobení už je stejné, to si dodělejte

#vars
vars="/tmp/vars" #TODO add $$
newLine="/tmp/newline.tmp" #TODO add $$

# $1 = file
isValidMatrix () {
	valid=$(awk '
		BEGIN {
			lastNF = -1
			success = 0
		}
		{
			if (lastNF == -1 || NF == lastNF) {
				lastNF = NF
			}
			else {
				success = 1
				exit
			}
		}
		END {
			printf("%d", success)
		}
	' $1)
	return $valid
}

# $1 = var; $2 = file
loadVar () { # TODO čeknout jména proměnných
	#TODO odstranění prázdných řádku
	if isValidMatrix $2; then
		if cp "$2" "$vars/$1"; then
			:
		else
			echo "operation error" > /dev/stderr
		fi
	else
		echo "invalid matrix" > /dev/stderr
	fi
}

# $1 = var; $2 = file
saveVar () {
	if [ -f "$vars/$1" ]; then
		if cp "$vars/$1" "$2"; then
			:
		else
			echo "operation error" > /dev/stderr
		fi
	else
		echo "unknown variable $1" > /dev/stderr
	fi
}

# $1 = var
showVar () {
	if [ -f "$vars/$1" ]; then
		if cat "$vars/$1"; then
			echo ""
		else
			echo "operation error" > /dev/stderr
		fi
	else
		echo "unknown variable $1" > /dev/stderr
	fi
}

# $1 = var
getRows () {
	echo -n $(wc -l < "$vars/$1")
}

# $1 = var
getCols () {
	res=$(cat "$vars/$1" | head -n 1 | tr "\t" "\n" | wc -l)
	echo -n $(($res+1))
}

# $1 = result (=a); $2 = b; $3 = operator; $4 = c
compute () {
	#TODO nahradit 0 a 1 za příslušné matice

	bRows=$(getRows $2)
	bCols=$(getCols $2)
	cRows=$(getRows $4)
	cCols=$(getCols $4)

	if [ ! -f "$vars/$2" ]; then
		echo "unknown variable $2" > /dev/stderr
		return 1
	fi

	if [ ! -f "$vars/$4" ]; then
		echo "unknown variable $4" > /dev/stderr
		return 1
	fi

	case $3 in
		+|- )

			if [ bCols -ne cCols -o bRows -ne -bCols ]; then
				echo "wrong dimensions" > /dev/stderr
				exit 1
			fi

			cat "$vars/$2" "$newLine" "$vars/$4" | awk -v op=$3 '
				BEGIN {
					FS = "\t"
					second = 0
					maxRow = 0
				}

				/^$/ {
					second = 1
					maxRow = NR - 1
					next
				}

				{
					if (second == 0) { # čtu první matici
						for (i = 1; i <= NF; i++) {
							result[NR "," i] = $i
						}
					}
					else { #čtu druhou
						for (i = 1; i <= NF; i++) {
							if (op == "+")
								result[NR-maxRow-1 "," i] += $i
							else
								result[NR-maxRow-1 "," i] -= $i
						}
					}
				}
				END {
					for (i = 1; i <= maxRow; i++) {
						for (j = 1; j <= NF; j++) {
							printf("%d", result[i "," j])
							if (j < NF) printf("\t")
						}
						if (i < maxRow) printf("\n")
					}
				}
			' > "$vars/$1"
			;;

		'.' ) #TODO
			if [ bCols -ne bRows ]; then
				echo "wrong dimensions" > /dev/stderr
				exit 1
			fi
			;;

		* )
			echo "unknown operation" > /dev/stderr
	esac
}

# tělo
#rm -Rf $vars
mkdir $vars 2> /dev/null
echo "\n" > $newLine
genDefaultMatrices

while :; do
	read command var file op c
	
	case $command in
		'load' ) 
			loadVar $var $file
			;;
		'save' ) 
			saveVar $var $file
			;;
		'show' ) 
			showVar $var
			;;
		'quit' ) 
			break;
			;;
		* ) 
			if [ "$var" = "=" ]; then
				a=$command
				b=$file
				compute $a $b $op $c
			else
				echo "unknown commnad"
			fi
			;;
	esac
done

#rm -Rf $vars
