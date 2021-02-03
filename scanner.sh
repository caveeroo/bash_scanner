#!/bin/bash
host=''
port=''
s_flag=''
d_flag=''
ds_flag=''
f_flag=''
o_flag='false'
maxport=65535

extension=$((1 + $RANDOM % 1000))

print_help(){
	echo
	echo "Uso: $0 [option] -t <target>"
	echo
    echo "   -s, --scan           escanear una direccion ip"
    echo "   -d, --discovery      buscar direcciones ip activas en una red"
    echo "   -f, --fast           limitar el numero de puertos escaneados a 1000"
    echo "   -o, --output         conservar archivo con el output del modo discovery"
    echo "   -h, --help           mostrar este mensaje de ayuda"
    echo
}

function print_centered {
     [[ $# == 0 ]] && return 1

     declare -i TERM_COLS="$(tput cols)"
     declare -i str_len="${#1}"
     [[ $str_len -ge $TERM_COLS ]] && {
          echo "$1";
          return 0;
     }

     declare -i filler_len="$(( (TERM_COLS - str_len) / 2 ))"
     [[ $# -ge 2 ]] && ch="${2:0:1}" || ch=" "
     filler=""
     for (( i = 0; i < filler_len; i++ )); do
          filler="${filler}${ch}"
     done

     printf "%s%s%s" "$filler" "$1" "$filler"
     [[ $(( (TERM_COLS - str_len) % 2 )) -ne 0 ]] && printf "%s" "${ch}"
     printf "\n"

     return 0
}

scan_host(){

	if [ "$f_flag" = true ] ; then
    	maxport=1000
    	print_centered "        Modo FRANCESCO VIRGOLINII activado        " "&"
    fi

	if [ "$ds_flag" = true ]; then
    	print_centered "" ""
		while IFS= read -r line; do
	    	for i in $(seq 1 ${maxport}); do
	    		timeout 1 bash -c "echo '' > /dev/tcp/$line/$i" 2>/dev/null && echo "El puerto $i de la dirección $host está abierto" &
			done; wait
	    done < temp_hosts$extension.txt 2> /dev/null

	    if [ "$o_flag" = false ]; then
	    	if [ -f "temp_hosts$extension.txt" ] ; then
    			rm "temp_hosts$extension.txt"
			fi
	    fi
    	print_centered "" ""
	    print_centered " Todas las direcciones han sido escaneadas :) " " "
	    print_centered "" ""

	else
		for i in $(seq 1 ${maxport}); do
	    	timeout 1 bash -c "echo '' > /dev/tcp/$host/$i" 2>/dev/null && echo "El puerto $i está abierto" &
	    done; wait

	    if [ "$f_flag" = true ] ; then
	    	print_centered "" ""
	    	echo 'FIIIIAAAAAAAAUMMMMMMMM'
	    	print_centered "" ""
	    	echo '<Se han escaneado los primeros 1000 puertos>'
    	fi

        echo "El scan ha finalizado"
	fi

    return 1
}

print_centered "-" "-"
print_centered "Escaner programado por caveeroo" ""
print_centered "-" "-"

while [[ "$#" -gt 0 ]]; do
    case $1 in
    	-s|--scan) s_flag=true;;
		-d|--discovery) d_flag=true;;
		-f|--fast) f_flag=true;;
		-o|--output) o_flag=true;;
        -t|--target) host="$2"; shift ;;
        -p|--port) port="$2"; shift ;;
		-h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; ;;
    esac
    shift
done

if [ "$s_flag" = true ] && [ "$d_flag" = true ] ; then
    echo 'No se puede usar discovery y scan a la vez'
    exit 0
fi

if [ "$s_flag" = true ] ; then
    print_centered "" ""
    print_centered " Escaneo de puertos " "."
    print_centered "" ""
    echo "Buscando puertos abiertos en $host"
    print_centered "" ""
    scan_host
fi

if [ "$d_flag" = true ] ; then
	if [ -f "temp_hosts$extension.txt" ] ; then
    	rm "temp_hosts$extension.txt"
	fi
	while true; do
	    read -p "¿Desea además escanear los puertos de todos los host encontrados? (y/N) " yn
	    case $yn in
	        [Yy]* ) ds_flag=true; break;;
	        [Nn]* ) break;;
	        * ) echo "Supongo que no entonces";
				break;;
	    esac
	done

	print_centered " Descubriendo direcciones ipv4 activas " "."
    print_centered "" ""

	#Valido solo para direcciones ipv4 de clase A
	if [ "$ds_flag" = true ] ; then
		for i in $(seq 2 254);do
	    	timeout 1 bash -c "ping -c 1 $host.$i > /dev/null 2>&1" && echo "$host.$i" >> temp_hosts$extension.txt &
	    done; wait
	    scan_host
	else
		for j in $(seq 2 254);do
	    	timeout 1 bash -c "ping -c 1 $host.$j > /dev/null 2>&1" && echo "$host.$j - Activo" &
	    done; wait
		print_centered "" ""
	    echo 'Network discovery finalizado'
	fi
fi
