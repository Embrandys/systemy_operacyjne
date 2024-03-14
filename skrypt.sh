#!/bin/bash

#0 START

pomiar1=$(date +%s.%N)


if [ $# -eq 0 ]
then 
	echo "Brak argumentow. Nalezy podac co najmniej dwa argumenty- nazwe katalogu bazowego oraz dowolna ilosc plikow do analizy.">&2
	exit 1
fi

if [ $# -eq 1 ]
then 
	 echo "Podano tylko jeden argument. Nalezy podac co najmniej dwa argumenty- nazwe katalogu bazowego oraz dowolna ilosc plikow do analizy.">&2
        exit 2
fi


#1 START

katalog="$1"
mkdir -p "$katalog"
chmod 750 "$katalog"
if [ ! -e "$katalog" ]
then 
       echo "Brak mozliwosci utworzenia katalogu bazowego">&2
exit 4
else 
	rm -r "$katalog"
fi
shift
for i in "$@"
do 
	if [ ! -e "$i" ]
       	then 
		echo "Plik nie istnieje, dotyczy "$i"">&2
	exit 3
	elif [ ! -r "$i" ]
	then
		echo "Brak dostepu do pliku, dotyczy "$i"">&2
	exit 3	
	fi 
	for j in $(seq 1 $(wc -l "$i" | cut -d " " -f 1))
	do 
		col1=$(cat "$i" | tr -d '"' | cut -d "," -f 3 | head -n "$j" | tail -n 1)
		col2=$(cat "$i" | tr -d '"' | cut -d "," -f 4 | head -n "$j" | tail -n 1)
		mkdir -p "$katalog/$col1/$col2"
		chmod 750 "$katalog/$col1/$col2"
	done
	 
done
#1 STOP


#2,3 START

for i in "$@"
do
	for j in $(seq 1 $(wc -l "$i" | cut -d " " -f 1))
	do
		line=$(cat "$i" | tr -d '"'| head -n "$j" | tail -n 1 )
		SMBD=$(echo "$line" | cut -d "," -f 7 )
		rok=$(echo "$line" | cut -d "," -f 3)
		miesiac=$(echo "$line" | cut -d "," -f 4)
		dzien=$(echo "$line" | cut -d "," -f 5)
		if [ "$SMBD" ==  "8" ]; then
			rok=$(echo "$line" | cut -d "," -f 3)
			miesiac=$(echo "$line" | cut -d "," -f 4)
			echo "$line" >> "$katalog/$rok.$miesiac.errors"
			sort -u "$katalog/$rok.$miesiac.errors" -o "$katalog/$rok.$miesiac.errors"
			chmod 640 "$katalog/$rok.$miesiac.errors"
		else 
			echo "$line" >> "$katalog/$rok/$miesiac/$dzien.csv"
			sort -u "$katalog/$rok/$miesiac/$dzien.csv" -o "$katalog/$rok/$miesiac/$dzien.csv"
			chmod 640 "$katalog/$rok/$miesiac/$dzien.csv" 
		fi
	done
done
#2,3 STOP

#4 START
for k_rok in "$katalog"/*
do
	if [ -d "$k_rok" ]
	then	
	for k_msc in "$k_rok"/*
	do
		for k_dz in "$k_msc"/*
		do
			suma=0
			for l in $(seq 1 $(wc -l "$k_dz" | cut -d " " -f 1))
			do
				wartosc=$( cat "$k_dz" | cut -d "," -f 6 | head -n $l | tail -n 1 )
				suma=$(echo "$suma+$wartosc" | bc)
				
			done
			echo "$suma,$k_dz">> "$katalog"/pom
			
		done
	done

	fi
done 
sort -t ',' -k 1 -n "$katalog"/pom -o "$katalog"/pom
num_l=$(cat "$katalog"/pom | wc -l ) 
min=$(cat "$katalog"/pom | head -n 1 | cut -d "," -f 2 )
max=$(cat "$katalog"/pom | tail -n 1 | cut -d "," -f 2 )

real_min=$(realpath --relative-to="$katalog"/LINKS "$min")
real_max=$(realpath --relative-to="$katalog"/LINKS "$max")

mkdir -p "$katalog"/LINKS

ln -s "$real_min" "$katalog"/LINKS/MIN_OPAD
ln -s "$real_max" "$katalog"/LINKS/MAX_OPAD

rm "$katalog"/pom

#4 STOP

pomiar2=$(date +%s.%N)
czas_dzialania=$(echo "scale=6;(($pomiar2-$pomiar1)*1000)/1" | bc -l)
pid=$$
ppid=$PPID
comm=$(ps -o cmd= | grep "$0")
echo "$pid, $ppid, $czas_dzialania, $0 $@">>"$katalog"/out.log
chmod 750 "$katalog"/out.log
#0 STOP

