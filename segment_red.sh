#!/bin/bash

# Colors

green="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purpler="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"

# funcions

function ctrl_c(){
    echo -e "${red}[!]${gray} Sortin ...${endColour}"
    exit 1
}

function help(){
    echo -e "\n${gray}Ajuda del programa:\n\n${blue} $0 -i [IP] -c [CIDR]${endColour}"
    echo -e "\n\t${yellow}-i${gray} Posar IP amb el format tipo${green} 192.168.10.1${endColour}"
    echo -e "\n\t${yellow}-c${gray} Posar CIDR amb el format tipo${green} 24${endColour}"
}

function calcular_hosts_cidr(){
    declare -A hosts_cidr
    hosts=1

    for i in {32..1};do
        hosts_cidr["$i"]="$hosts"
        let hosts*=2
    done
    
    echo "${hosts_cidr["$cidr"]}"

}

function calcular_clase(){
    if [ $cidr -gt 0 ] && [ $cidr -lt 9 ];then
        echo "[ ]"
    elif [ $cidr -gt 8 ] && [ $cidr -lt 17 ];then
        echo "[ A ]"
    elif [ $cidr -gt 16 ] && [ $cidr -lt 25 ];then
        echo "[ B ]"
    elif [ $cidr -gt 24 ] && [ $cidr -lt 33 ];then
        echo "[ C ]"
    fi
}

function calcular_binari_ip(){
    IFS='.' read -ra myip <<< "$ip"

    for i in "${myip[@]}"; do
        binary=$(echo "obase=2;$i" | bc)
        binary=$(printf "%08d" "$binary")
        ipbinari+=("$binary")
    done
}

function calcular_mascara(){
    declare -i cont=0
    
    for ((x = 0; x < 4; x++)); do
        for ((i = 0; i < 8; i++)); do
            if [ $cont -lt $cidr ];then
                mascara_octet+="1"
            else
                mascara_octet+="0"
            fi
            let cont++
        done
        mascara_bi+=("$mascara_octet")
        mascara_octet=""
    done

    for i in "${mascara_bi[@]}";do
        mascara+=("$(echo "ibase=2;$i" | bc)")
    done

    resultat_mascara=$(IFS='.'; echo "${mascara[*]}")  

    echo -e "${green}[+]${gray} Mascara de Red:${blue} $resultat_mascara${endColour}"
}

function calcular_network_id(){

    for ((x = 0; x < 4; x++)); do
        for element in "${mascara_bi[$x]}"; do
            for ((i = 0; i < ${#element}; i++)); do
                if [ ${element:i:1} == "1" ] && [ ${ipbinari[x]:i:1} == "1" ]; then
                    network_octet+="1"
                else
                    network_octet+="0"
                fi
            done
        done
        network_id_bi+=("$network_octet")
        network_octet=""
    done

    for octet in "${network_id_bi[@]}";do
        network_id+=("$(echo "ibase=2;$octet" | bc)")
    done

    result_network_id=$(IFS='.'; echo "${network_id[*]}")    

    echo -e "\n${green}[+]${gray} Network ID:${yellow} $result_network_id${endColour}"

}

function calcular_broadcast(){
    declare -i cont=32
    hosts=$((32-$cidr))

    for ((x = 0; x < 4; x++)); do
        for ((i = 0; i < 8; i++)); do
            if [ $cont -le $hosts ];then
                broadcast_octet_bi+="1"
            else
                broadcast_octet_bi+=${network_id_bi[x]:i:1}
            fi
            let cont--
        done
        broadcast_bi+=("$broadcast_octet_bi")
        broadcast_octet_bi=""
    done

    for octet in "${broadcast_bi[@]}";do
        broadcast+=("$(echo "ibase=2;$octet" | bc)")
    done

    resultat_broadcast=$(IFS='.'; echo "${broadcast[*]}")
    echo -e "${green}[+]${gray} BroadCast:${yellow} $resultat_broadcast${endColour}"

}

function calcularRang(){
    hosts_cidr=$(calcular_hosts_cidr)
    clase=$(calcular_clase)
    echo -e "${green}\n[+]${gray} IP:${turquoise} $ip${endColour}\n"
    echo -e "${green}[+]${gray} Clase:${blue} $clase${endColour}"
    echo -e "${green}[+]${gray} Hosts:${blue} $(($hosts_cidr-2))${endColour}"
    calcular_binari_ip
    calcular_mascara
    calcular_network_id
    calcular_broadcast       
    
}
# Inici del programa

declare -a mascara_bi
declare -a mascara
declare -a network_id_bi
declare -a network_id
declare -a broadcast_bi
declare -a broadcast
trap crtl_c INT

while getopts "i:c:h" args;do
    case $args in
        i) ip=$OPTARG;;
        c) cidr=$OPTARG;;
        h) ;;
    esac
done

if ([ $ip ] && [ $cidr ] );then
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        if [[ $cidr =~ ^(32|3[0-1]|[1-2]?[0-9])$ ]];then
            calcularRang
        else
            echo -e "\n${red}[!]${gray} El CIDR "24" no té el format correcte."    
        fi
    else
        echo -e "\n${red}[!]${gray} La IP no té el format de una direcció IP valida."
    fi
else
    help
fi