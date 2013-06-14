#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# samotný diff funguje, ostatní přepínače jsou už snadné


#tmp files
left="/tmp/left"
right="/tmp/right"
both="/tmp/both"
diff="/tmp/diff"
patterns="/tmp/patterns"

fileA="a.txt"
fileB="b.txt"

# $1 = fileA; $2 = fileB
# výstup se uloží do $diff
doDiff () {

	fileA = $1
	fileB = $2

	#TODO: vyřešit delimitéry
	comm "$fileA" "$fileB" | sed 's|$|\t\t|' | cut -d '	' -f1 > "$left"
	comm "$fileA" "$fileB" | sed 's|$|\t\t|' | cut -d '	' -f2 > "$right"
	comm "$fileA" "$fileB" | sed 's|$|\t\t|' | cut -d '	' -f3 > "$both"

	#awk bere jenom sloupce commu
	#fakticky nečte žádný vstup, proto ten /dev/null
	awk -v left="$left" -v right="$right" -v both="$both" '

		#načte řádku commu (po sloupcích), zazálohuje předchozí řádku
		function read () {
			preLeft = leftLine
			getline < left
			leftLine = $0

			preRight = rightLine
			getline < right
			rightLine = $0

			preBoth = bothLine
			getline < both
			bothLine = $0

			idx++
		}

		#předpokládá správně naplněné operator, change, preIdxA, preIdxB, idxA, idxB
		function nicePrint () {
			from = preIdxA "," idxA
			to = preIdxB "," idxB
			if (preIdxA == idxA) from = idxA
			if (preIdxB == idxB) to = idxB

			printf("%s%s%s\n", from, operator, to)
			printf("%s", change)

		}

		BEGIN {	
			idx = 0				#pozice v comm

			idxA = 0			#pozice v prvním souboru
			idxB = 0			#pozice v druhém souboru

			preLeft = ""		# předhozí řádky
			preRight = ""
			preBoth = ""
		}

		END {
			while (idx <= N) {
				if (dontRead == 1) { # už mám načteno
					dontRead = 0
				}
				else { # normální průběh
					read()
				}

				#####printf("---NEW TURN --- %d | %d %d\n", idx, idxA, idxB)

				#------------------------------------------------------------------
				if (leftLine != "" && rightLine == "" && bothLine == "" ) { # levý sloupec je neprázdný
					#začíná levý sloupec

					preIdxA = idxA+1
					preIdxB = idxB
					change = ""

					do {
						change = change "< " leftLine "\n"
						read()
						idxA++
						dontRead = 1
					} while (leftLine != "")

					#konec čtení levého sloupce

					if (rightLine == "") { #jsme v pravém -> delete
						operator = "d"
					}
					else { # jsme v prostředním -> change
						preIdxB++
						change = change "---\n"

						# načítej prostřední sloupec
						do {
							change = change "> " rightLine "\n"
							read()
							idxB++
							dontRead = 1
						} while (rightLine != "")

						operator = "c"
					}

					nicePrint()
				} #------------------------------------------------------------------
				else if (leftLine == "" && rightLine != "" && bothLine == "" ) {
					#začíná prostřední sloupec

					preIdxA = idxA
					preIdxB = idxB+1
					change = ""

					do {
						change = change "> " rightLine "\n"
						read()
						idxB++
						dontRead = 1
					} while (rightLine != "")

					#konec čtení prostředního sloupce

					if (leftLine == "") { #jsme v pravém -> add
						operator = "a"
					}
					else { # jsme v levém -> change
						preIdxA++
						change = "---\n" change 
						change2 = ""

						# načítej prostřední sloupec
						do {
							change2 = change2 "< " leftLine "\n"
							read()
							idxA++
							dontRead = 1
						} while (leftLine != "")

						change = change2 change

						operator = "c"
					}

					nicePrint()
				} #------------------------------------------------------------------
				else if (leftLine == "" && rightLine == "" && bothLine != "" ) {
					# třetí sloupec, nic se neděje, pokračuj
					idxA++
					idxB++
				} #------------------------------------------------------------------
				else {
					#koncová řádka
					####printf("MEGA ERROR: %d\n", idx)
					break
				}
			}

		}
	' /dev/null > "$diff"
}

doDiff "$fileA" "$fileB"