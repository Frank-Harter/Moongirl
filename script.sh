#!/bin/bash

#En el caso que se presione Control + C se parara el programa
cerrarC(){
    echo "Adeu!!!!"
    exit 1
}
trap 'cerrarC' SIGINT



#Instalara y mirara los puertos abieros del equipo
puertos_nmap () {
	#Comprbar si esta  instlado
	ssh $host 'nmap -v >/dev/null 2>&1'
	if [ $? -eq 0 ];then
		respuesta=$(ssh $host 'nmap localhost')
	else
		#No esta instalado
		read -p "Nmap no esta instalado, instalar?(y/n) " insnmap
		if [ $insnmap == "y" ];then
			#Instalarlo			
			echo "ContraseÃ±a root "
			read -s contrasena
			echo "$contrasena" | ssh -tt $host 'sudo -S apt install nmap -y'
			respuesta=$(ssh $host 'nmap localhost')
		else
			#No se dea instalar y con ello hacer comprobaciÃ³n
			echo "Se ha saltado InstalaciÃ³n/ComprobaciÃ³n de NMAP"
			exit 1
		fi
	fi
	respuesta_html=$(echo "$respuesta" | sed 's/$/<br>/')
	generar_html "$respuesta_html"
}




#Mostrar estado de un servicio
estado_servicio() {
    # ComprobaciÃ³n de si existe
    read -p "Servicio que desea comprobar: " servicio
    echo "Servicio: $servicio"
    estado=$(ssh $host "systemctl is-active $servicio" 2>&1)
    if [ $? -eq 0 ]; then
        # MostrarÃ¡ el estado del servicio
        generar_html "Estado del servicio $servicio: $estado"
    else
        generar_html "'$servicio' no estÃ¡ instalado o no se encuentra en ejecuciÃ³n."
    fi
}


rendimiento() {
ssh $host 'sar 1 2 >/dev/null 2>&1'
	if [ $? -eq 0 ];then
		respuesta=$(ssh $host 'sar 1 2' | sed 's/$/<br>/')
	else
		#No esta instalado
		read -p "Sar no esta instalado, instalar?(y/n) " inssar
		if [ $inssar == "y" ];then
			#Instalarlo
			echo "ContraseÃ±a root "
			read -s contrasena
			echo "$contrasena" | ssh -tt $host 'sudo -S apt install sysstat -y'
			respuesta=$(ssh $host 'sar 1 2' | sed 's/$/<br>/')
		else
			#No se dea instalar y con ello hacer comprobaciÃ³n
			echo "Se ha saltado InstalaciÃ³n/ComprobaciÃ³n de SAR"
			exit 1
		fi
		fi
		generar_html "$respuesta"
}


#Mostrar estado del disco/espacio
estado_disco() {
    respuesta=$(ssh $host << 'FINAL'
        df -h
FINAL
)
    # Usamos awk para filtrar solo las lÃ­neas que contienen informaciÃ³n de disco
    respuesta_html=$(echo "$respuesta" | sed 's/$/<br>/' |tail -n 8)
    generar_html "$respuesta_html"
}



procesos() {
    respuesta=$(ssh $host "ps -aux | sed 's/$/<br>/'")
    generar_html "$respuesta"
}



#Esta funcion nos dara el output de lo que se haya ejecutado en un html
#Ponemos $1 por que se llamara a la funcion con un parametro
generar_html () {
echo "
<!DOCTYPE html>
<html>
<head>
<title>Frank ssh</title>
</head>
<body>
<h1>RESPUESTA</h1>
<p>$1</p>
</body>
</html>" > respuesta.html
}



#read -p "Por favor, inserte un 'usuario@dominio'" host
host="frank@192.168.1.122"


#Creamos la variable opcion y hacemso que sea un bucle
#hasta que se deseÃ© salir
op=0
while [ $op -ne 6 ];do 
	echo ""
	echo "1. Comprobar Puertos Abiertos"
	echo "2. Status de un Servicio"
	echo "3. Mostrar Rendimiento del Sistema"
	echo "4. Estado de Espacio"
	echo "5. InformaciÃ³n de PS -AUX"
	echo "6. Salir de las Comprobaciones"
	echo ""
	read -p "Opcio: " op
	
	case $op in
		1) puertos_nmap;;
		2) estado_servicio;;
		3) rendimiento;;
		4) estado_disco;;
		5) procesos;;
		6) echo "ADIOS!!!";;
		*) echo "Por favor inserte un NÂº del 1-6,no es muy dificil :)";;
	esac
done
