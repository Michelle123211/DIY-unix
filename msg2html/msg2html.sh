#!/bin/sh


###################
# Petr Bělohlávek #
###################

# Pozn.:
# tak nějak funguje


messages="/tmp/messages"
patterns="/tmp/patterns"
defaultIFS="$IFS"

translateAll="0"

clean () {
	rm -f "$messages"
	rm -f "$patterns"
}


clean

while [ $# -ne "0" ]; do
	case $1 in
		"-r" )
			translateAll="1"
			shift 1
			;;
		* )
			echo "$1" >> $patterns
			shift 1
			;;
	esac
done

if [ ! -e "$patterns" ]; then # pokud neni žádný regexp, narvi tam cokoli
	echo '.*' > $patterns
fi

while read pat; do # nominuj všechny možné soubory
	ls | grep -e "$pat" >> $messages
done < $patterns

cat "$messages" | sort -u -o "$messages" # vyházej duplicity
# a vyhazej nepasujici soubory
sed -n "/^....-...-./p" -i "$messages" # -i neni v normě, ale fuck that

IFS="-"
while read name id serenity; do
	IFS="$defaultIFS"

	#echo "running $name-$id-$serenity"

	# pokud nemusíš všechno a už je aktuální export, přeskoč
	if [ "$translateAll" = "0" ]; then # pokud nemusíš exportovat vše
		#echo "1"
		if [ -e "$name-$id.html" ]; then # a html existuje
			#echo "2"
			if [ "$name-$id" -ot "$name-$id.html" ]; then # a je mladší než orig soubor
				#echo "3"
				IFS="-" #!!!!!
				continue # neni třeba exportovat
			fi
		fi
	fi
	#echo "exporting"
	# jinak exportuj

	serenities=$(cat "$name-$id-$serenity" | head -n 1 | tr " " "\n" | sed -n 's|^.*-\(.\)$|\1|p' | tr "\n" "," | sed 's|,|, |g' | sed 's|^\(.*\), $|\1\n|')

	h1=$(cat "$name-$id-$serenity" | head -n 2 | tail -n 1 | sed -n 's|Text:	\(.*\)$|\1|p')

	cat "$name-$id-$serenity" | sed 's|^Description:	\(.*\)$|\1|' | awk -v name="$name" -v id="$id" -v h1="$h1" -v serenities="$serenities" '

		function correct () {
			# zvyýrazní manpages a opraví entity (možná ještě nejlíp v shellu)
			# return corrected
		}

		BEGIN {
			list = "false"
			paragraph = "false"

			printf("<html>\n")
			printf("<head>\n")
			printf("<title>%s-%s</title>\n", name, id)
			printf("</head>\n")
			printf("<body>\n")
			printf("<h1>%s</h1>\n", h1)
			printf("<h3>Serenity: %s</h3>\n", serenities)
		}

		NR == 1 || NR == 2{
			next
		}

		{
			start = substr($0, 1, 1)
			end = substr($0, length($0), 1)

			if (start == "-") { # list
				if (paragraph == "true") { # end paragraph, nemůžu mít list v para
					printf("</p>\n")
					paragraph = "false"
				}

				if (list == "false") { #start new list
					printf("<ul>\n")
					list = "true"
				}
				printf("<li>%s</li>\n", substr($0, 2, length($0)-1))
			}
			else { # text
				if (list == "true") { #end list
					printf("</ul>\n")
					list = "false"
				}

				if (paragraph == "false") { # start paragraph
					printf("<p>\n")
					paragraph = "true"					
				}

				printf("%s<br/>\n", $0) # echo line, možná bez <br/>

				if (paragraph == "true" && end == ".") { # end paragraph
					printf("</p>\n")
					paragraph = "false"
				}
			}
		}

		END {
			if (list == "true") { #end list
				printf("</ul>\n")
				list = "false"
			}

			if (paragraph == "true") { # end paragraph
				printf("</p>\n")
				paragraph = "false"
			}

			printf("</body>\n")
			printf("</html>\n")
		}
	' > $name-$id.html

IFS="-" #!!!!!
done < $messages

clean
