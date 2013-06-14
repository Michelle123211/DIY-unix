#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# funguje docela dobře, složitost je O(M*N) s počtem řádků joinovaných souborů
# šlo by to jednoduše zlepšit -  v awk si pamatovat poslední načtené řádky s daným id (z druhého souboru), ale to je lehké a tohle Forst uznává

# var
defaultIFS=$IFS

t1=""
t2=""
t3=" "

field1="1"
field2="1"

file1=""
file2=""

a1="0"
a2="0"

o=""

# read param
while [ "$#" -ne "0" ]; do
	case $1 in 
		"-t1" )
			t1="$2"
			shift 2
			;;
		"-t2" )
			t2="$2"
			shift 2
			;;
		"-t3" )
			t3="$2"
			shift 2
			;;
		"-a1" )
			a1="1"
			shift 1
			;;
		"-a2" )
			a2="1"
			shift 1
			;;
		"-1" )
			field1="$2"
			shift 2
			;;
		"-2" )
			field2="$2"
			shift 2
			;;
		"-o" )
			o="$2"
			shift 2
			;;
		* )
			if [ "$file1" = "" ]; then
				file1=$1
			else
				file2=$1
			fi
			shift 1
			;;
	esac
done

# param check
if [ "$file1" = "" -o "$file2" = "" ]; then
	echo "Missing files" > /dev/stderr
	exit 1
fi

# joining
echo $o | awk -v t1=$t1 -v t2=$t2 -v t3=$t3 -v a1=$a1 -v a2=$a2 -v file1=$file1 -v file2=$file2 -v field1=$field1 -v field2=$field2 '
	
	function join () { # spojí a vypíše

		if (isFormat == 1) { # vlastní formátování

			for (i = 1; i <= formatCols; i++) {
				if (format[i] == "0") { # extra case pro id
					printf("%s", id)
					if (i < formatCols) printf("%s", t3) # pokud nejsme na konci vytiskni delimiter
					continue
				}

				pos = substr(format[i], 3)
				if (substr(format[i], 0, 2) == "1") {
					printf("%s", leftLine[pos])
				}
				else if (substr(format[i], 0, 2) == "2") {
					printf("%s", rightLine[pos])
				}
				else {
					printf("error\n")
				}
				if (i < formatCols) printf("%s", t3) # pokud nejsme na konci vytiskni delimiter
			}
			printf("\n")
		}
		else { # defaultní formátování

			printf("%s", id)

			for (i = 1; i <= leftNF; i++) {
				if (i != field1) printf("%s%s", t3, leftLine[i])
			}
			for (i = 1; i <= rightNF; i++) {
				if (i != field2) printf("%s%s", t3, rightLine[i])
			}
			printf("\n")
		}
	}

	BEGIN { # nastaví FS pro čtení formátování
		if (t1 == "") t1 = FS # pro nenastavený delimiter whitespacy
		if (t2 == "") t1 = FS

		FS = ","
		#TODO: if RIGHTJOIN: swap
	}

	{ # pouze pro čtení formátu (pouze jedna řádka)
		if ($0 == "") isFormat = 0
		else {
			isFormat = 1
			formatCols = NF
			for (i = 1; i <= NF; i++) {
				format[i] = $i
			}
		}
	}

	END { # vlastní alg.
		#printf("%s %s %s %s %s %s %s %s %s %s\n", t1, t2, t3, a1, a2, file1, file2, field1, field2, o)

		FS = t1
		while ((getline < file1) > 0 ) {
			#printf("first %s -----------------------\n", $field1)

			leftNF = NF
			for (i = 1; i <= leftNF; i++) {
				leftLine[i] = $i
			}

			id = $field1 # podle toho joinuju

			FS = t2
			found = 0

			while ((getline < file2) > 0 ) {
				#printf("second %s\n", $field2)

				if ($field2 == id) {
					rightNF = NF
					for (i = 1; i <= rightNF; i++) {
						rightLine[i] = $i
					}
					join() # joinni dvě řádky
					found++
				}
#				else if (id < $field2) { # TODO breaking
#					#printf("breaking ... %s %s\n", id, $field2)
#					break
#				}
			}
			close(file2)
			if (a1 == 1 && found == 0) { #LEFTJOIN
				for (i = 1; i <= rightNF; i++) {
					rightLine[i] = "-"
				}
				join()
			}

			FS = t1
		}
	}
'
