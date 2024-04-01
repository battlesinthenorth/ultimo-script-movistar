#!/bin/bash
ROUTE=`pwd`                                     #Obtiene ruta de donde se esta ejecutando
#SCRIPT=$(readlink -f $0);
#ROUTE=`dirname $SCRIPT`;        #Obtiene ruta del archivo
BASE=${ROUTE%%/ext*}                   #Muestra de la ruta todo lo que este antes de /ext
ROUTE="$BASE/ext/porta/prevalidacion"
#ORACLE="$BASE/ext/telcasv0.cfg"            
DBUSER="SWBAPPS"
DBUSERPASSWORD="qtip"
DB="telcasv0"

SALIDAT="/home/xymon/client/ext/porta/prevalidacion/out/portint.out"
SALIDA="/home/xymon/client/ext/porta/prevalidacion/out/portin.out"
MACHINE="PORTABILIDAD_NUMERICA"
TEST="PORTA_PREVAL"
PORTINSPN=`cat /home/xymon/client/ext/porta/prevalidacion/out/portint.out | awk '{print $1}'`


function Port_in_SPN(){
        echo "set linesize 400; 
        set pagesize 0;
        set feedback off;
                set appinfo 'preval_porta.sh';
        SELECT COUNT(*), STATECODE FROM Spn_importregister@LINK_SPNSL WHERE FVC >= TRUNC(SYSDATE + 1)  AND RECEIVEROP = 20 GROUP BY STATECODE;" | sqlplus -S $DBUSER/$DBUSERPASSWORD@$DB >$SALIDAT
}

function message(){
        echo " " > $SALIDA
        echo "<!doctype html>" >> $SALIDA
        echo "<HTML>" >> $SALIDA
        echo "<BODY>" >> $SALIDA
        echo "<TABLE BORDER>" >> $SALIDA
        echo "<TR>" >> $SALIDA
        echo "<TH>PORT IN</TH> <TH>PORT OUT</TH>" >> $SALIDA
        echo "</TR>" >> $SALIDA

    echo "<TD>$PORTINSPN </TD> <TD>$PORTINSPN </TD>"  >> $SALIDA
    
    echo "</TABLE>" >> $SALIDA
        echo "</BODY>" >> $SALIDA
        echo "</HTML>" >> $SALIDA
}

function sendXymon()
{
        #Notifica a Xymon los resultados
        LINE="status+55m $MACHINE.$TEST $COLOR `date`
Detalle PORT IN:  
        `cat $SALIDA`"
        $XYMON $XYMSRV "$LINE" 
}

Port_in_SPN
message
sendXymon


        group-only Procesos|conn|cpu|cpuReal|disk|info|memory|msgs|ports|procs|trends Servidores Altamira SG
        include /home/xymon/server/etc/hosts/SG/SV_BACKENDS_SG.cfg
        include /home/xymon/server/etc/hosts/SG/SV_BACKENDS_SG2.cfg


[ErrIVR]
        ENVFILE $XYMONCLIENTHOME/etc/xymonclient.cfg
        CMD $XYMONCLIENTHOME/ext/IVR/ErrIVR.sh
        LOGFILE $XYMONCLIENTLOGS/ErrIVR.log
        INTERVAL 10m


MACHINE="IVRError"
TEST="caidaTrx"

group-compress Procesos Pagos Recargas
                10.50.15.7 pyrpagossv #NAME:"DemonioPagos SIDRA" noconn notrends delayred=rRFacil:22
                10.50.15.7 pyrpagossv2 #NAME:"Rechazados" noconn notrends
                10.50.15.7 pyrtranssv #NAME:"Transacciones IB" noconn notrends
                #10.213.226.54 ptransacciones #NAME:"Modulo de Caja PAGOS" noconn notrends
                10.50.15.7 CajaRecargas #NAME:"Modulo de Caja RECARGAS" noconn notrends
                172.31.2.10 RAPPMMO #NAME:"Recargas APP MMO" noconn notrends
                172.31.2.10 PAPPMMO #NAME:"Pagos APP MMO" noconn notrends
                10.50.15.7 IVRError #NAME:"Recargas IVR Err244" noconn notrends
                10.231.128.126 PORTABILIDAD_NUMERICA #NAME:"PORTA" noconn notrends



MACHINE="PortaNum"
TEST="Preval"



[PORTA_PREVAL]
        ENVFILE $XYMONCLIENTHOME/etc/xymonclient.cfg
        CMD $XYMONCLIENTHOME/ext/porta/prevalidacion/porta_preval.sh
        LOGFILE $XYMONCLIENTLOGS/porta_preval.sh
        INTERVAL 1m


        group-compress Porta
        10.231.128.126 PORTABILIDAD #NAME:"" noconn
                
        group-compress Payment SV
        10.231.128.126 PAYMENT_SV #NAME:"" noconn




    
    while read line
	do
			echo "<TR>" >> $SALIDA
			bloq=`echo $line |egrep 'ONLINE' |awk '{print$1'} `
			bloq2=`echo $line |egrep 'ONLINE' |awk '{print$2'} ` 
			bloq3=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$3'} ` 
			bloq4=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$4'} ` 
			bloq5=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$5'} ` 
					
			if [ "$bloq4" != "" ];then
				if (( $(echo "2 k $bloq4 $UMBRALY [1p] sa <a" | dc) ));then   #comparacion mayor que de decimales
					if (( $(echo "2 k $bloq4 $UMBRALR [1p] sa <a" | dc) ));then   #comparacion mayor que de decimales
						echo "<TD>$bloq &red</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
					else
						echo "<TD>$bloq &yellow</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
					fi      
				else
					echo "<TD>$bloq &green</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
				fi
			fi
			echo "</TR>" >> $SALIDA        
	done <$SALIDAT
	echo "</TABLE>" >> $SALIDA
	echo "</BODY>" >> $SALIDA
	echo "</HTML>" >> $SALIDA
}

Port_in_SPN



function message2(){
	COLOR="red"
	sql
	message
	MSG2="Alarma de Tablespaces en $MSG($PrimeroM)

        Umbral de Alerta: &red >= $((UMBRALR)) &yellow >= $((UMBRALY))
        Intervalo: 15 min
------------------------------------------------------------------------------------"
	camb=`cat $SALIDA | grep "&red" | wc -l`
	if [ "$camb" -gt 0 ]; then
		Conteo=$camb
		COLOR="red"
	else
		camb=`cat $SALIDA | grep "&yellow" | wc -l`
		if [ "$camb" -gt 0 ]; then
			Conteo=$camb
			COLOR="yellow"
		else
			camb=`cat $SALIDA | grep "&green" | wc -l`
			if [ "$camb" -gt 0 ]; then
				Conteo=$camb
				COLOR="green"
			else
				Conteo=0
				COLOR="red"
			fi
		fi
	fi
		MSG2="$MSG2 
Existen: 
		$Conteo Tablespaces... Estado: "
	if [ "$COLOR" = "red" ]; then
		MSG2="$MSG2 ALERTA!!!"
	elif [ "$COLOR" = "yellow" ]; then
		MSG2="$MSG2 ADVERTENCIA!!!"
	else
		MSG2="$MSG2 OK!!!"
	fi
}

function message(){
	echo " " > $SALIDA
	echo "<!doctype html>" >> $SALIDA
	echo "<HTML>" >> $SALIDA
	echo "<BODY>" >> $SALIDA
	echo "<TABLE BORDER>" >> $SALIDA
	echo "<TR>" >> $SALIDA
	echo "<TH>PORT IN</TH> <TH>PORT OUT</TH>" >> $SALIDA
	echo "</TR>" >> $SALIDA
	while read line
	do
			echo "<TR>" >> $SALIDA
			bloq=`echo $line |egrep 'ONLINE' |awk '{print$1'} `
			bloq2=`echo $line |egrep 'ONLINE' |awk '{print$2'} ` 
			bloq3=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$3'} ` 
			bloq4=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$4'} ` 
			bloq5=`echo $line |egrep 'ONLINE' |awk '{printf "%.2f",$5'} ` 
					
			if [ "$bloq4" != "" ];then
				if (( $(echo "2 k $bloq4 $UMBRALY [1p] sa <a" | dc) ));then   #comparacion mayor que de decimales
					if (( $(echo "2 k $bloq4 $UMBRALR [1p] sa <a" | dc) ));then   #comparacion mayor que de decimales
						echo "<TD>$bloq &red</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
					else
						echo "<TD>$bloq &yellow</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
					fi      
				else
					echo "<TD>$bloq &green</TD> <TD>$bloq2</TD> <TD>$bloq3</TD> <TD>$bloq4</TD> <TD>$bloq5</TD>" >> $SALIDA
				fi
			fi
			echo "</TR>" >> $SALIDA        
	done <$SALIDAT
	echo "</TABLE>" >> $SALIDA
	echo "</BODY>" >> $SALIDA
	echo "</HTML>" >> $SALIDA
}

function sendXymon()
{
	#Notifica a Xymon los resultados
	LINE="status+55m $MACHINE.$TEST $COLOR `date`
${MSG2} 
	`cat $SALIDA`"
	$XYMON $XYMSRV "$LINE" 
} 

. $ORACLE
####################################################################
cat $CONFIG | grep -v "#" | while read linea    #Lee y ejecuta linea por linea
do
	#UMBRALES########
	UMBRALR=97    #DEFAULT
	UMBRALY=95    #DEFAULT
	#Obtiene umbral buscando palabra que inicia con  TSR y elimina  TSR de esa palabra, dejando solo el numero
	TEMPR=`echo ${linea##*TSR} | awk '{print $1}'`		#Muestra de la ruta todo lo que este despues de parametro
	#VALIDA UMBRAL
	if [ "$TEMPR" != "" ];then
		if [ "${TEMPR}" = "$(echo ${TEMPR} | egrep '^[0-9]*$')" ];then       #valida que sea numero
			UMBRALR=$TEMPR
		fi
	fi
	#Obtiene umbral buscando palabra que inicia con  DSY y elimina  DSY de esa palabra, dejando solo el numero
	TEMPY=`echo ${linea##*TSY} | awk '{print $1}'`	#Muestra de la ruta todo lo que este despues de parametro 
	#VALIDA UMBRAL
	if [ "$TEMPY" != "" ];then
		if [ "${TEMPY}" = "$(echo ${TEMPY} | egrep '^[0-9]*$')" ];then       #valida que sea numero
			UMBRALY=$TEMPY
		fi
	fi
	#################
	DB=`echo $linea | awk '{print $(NF)}' | sed 's/(//g' | sed 's/)//g'`    #Obtiene ultima columna contenida dentro de parentesis
	#################
	MACHINE=${DB%%.*}	#Muestra de la ruta todo lo que este antes de .
	MSG=`echo $linea | cut -f 2 -d'-'`	#Obtiene todo lo que esta despues del signo menos
	MSG=${MSG%%(*}	#Muestra de la ruta todo lo que este antes de (
	PrimeroM=""
	echo $MACHINE | tr ";" "\n" | while read columna   #Lee y ejecuta machine por machine
	do	
		#################
		if [ "$PrimeroM" = "" ];then
			DB=${DB%%;*}	#Muestra de la ruta todo lo que este antes de ;
			PrimeroM="$columna"
			MACHINE="dbas$columna"
			message2
		else
			MACHINE="$columna"
		fi
		#################
		sendXymon
	done
done
