#!/bin/sh

###################
# Petr Bělohlávek #
###################

# Pozn.:
# uživatelem zadaná pole a podmínky
# rozlišit freeBSD X LINUX

ps -e -o pid,ppid,command | tr -s " " | nawk '

	function sortPid () { #seřadí PID podle rodiče a potom podle vlastního PID
		n = NR
		swapped = 1

		while (swapped == 1) {
			swapped = 0
			for ( i = 1; i <= n; i++ ){
				if (parent[pid[i]] > parent[pid[i+1]] || (parent[pid[i]] == parent[pid[i+1]]) && pid[i] > pid[i+1]) {
					tmp = pid[i+1]
					pid[i+1] = pid[i]
					pid[i] = tmp
					swapped = 1
				}
			}
			n--
		}
	}

	function writeSubtree (id, depth) {
		printf("|")
		for (d = 0; d < depth; d++) printf("-+")
		printf("%d %d %s\n", pid[id], parent[pid[id]], value[pid[id]])

		for (j = id+1; j <= NR; j++) {
			#printf("from id=%d check j=%d\n", id, j)
			if (parent[pid[j]] == pid[id]) {
				stop[id]=j
				writeSubtree(j, depth+1)
				j=stop[id]
				#printf("returning ... from id=%d check j=%d\n", id, j)
			}
		}
	}

	BEGIN {
		FS=" "
		recordCount=0
	}

	NR==1 { #preskoč popisky
		next
	}

	{ #naplň si pole
		pid[++recordCount]=$1
		parent[$1]=$2
		value[$1]=$3
		#printf("%s %s\n", $1, $2)
	}

	END { #vlastní alg.
		#printf("NR=%d\n", NR)
		sortPid()

		for (p = 1; p <= NR; p++) {
			#printf("%d: %d %d %s\n", p, pid[p], parent[pid[p]], value[pid[p]])
		}

		writeSubtree(1, 0)
	}
'
