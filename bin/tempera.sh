#!/bin/bash
alerta1=48
alerta2=60
core=($(sensors | grep "Core" | cut -f2 -d"+" | cut -c1-2))
inc=0
icon="  "
red="\033[1;33m"
nc="\033[0m"
printf "$icon "
printf "$fire"
for i in ${core[@]}
		do
			if ((${i} > "$alerta1"))
			then
				notify-send  "alerta de temperatura no nucleo ${inc} com ${core} graus"

				set fire=" "
			fi
			if ((${i} >= "$alerta2"))
		
	
			then
				notify-send  "Sistema em chamas, melhor desligar o computador imediatamente!"
			
				set fire=" "

			fi


			printf "[$i ${inc}]"	
			inc=$(($inc+1))
done
unset fire


		printf " ";	 

