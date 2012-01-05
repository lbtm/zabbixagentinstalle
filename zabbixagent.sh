#!/bin/bash
#
# Script d'installation de l'agent Zabbix
# Lotaut Brian aka LBTM - 12/2011
# Script libre: GPLv3
#
# Syntaxe: # sudo ./zabbixagent.sh 
# Parametres: <installe|supp|statut>
script_version="0.2" 

#===================================Varibles==================================
ARCH=$(uname -m)
DOMAINE=local
SERVEURZABBIX=localhost
DAEMON_NAME=zabbix_agentd
PID=/var/tmp/$DAEMON_NAME.pid
ZABBIXDIR=/opt/zabbix
ZABBIXDIR_1=/etc/zabbix
ZABBIXDIR_2=/usr/local/zabbix/bin
ZABBIXLOG=/var/log/zabbix
ZABBIXTMP=/tmp/zabbixtmp
#=============================================================================

# Test que le script est lance en root
if [ "$(id -u)" != "0" ]; then
	echo "Le script doit etre execute en tant que root."
  	echo "Syntaxe: su - ./zabbixagent.sh"
  	exit 1
fi

# Fonctions
check_user() {
	if [ ! `id -u zabbix` ]; then
		echo "Creation de l'utilisateur zabbix"
		/usr/sbin/useradd zabbix
    	echo "Definissez un mot de passe pour l'utilisateur zabbix:"
      	passwd zabbix
	fi
}

case "$1" in
    installe)
        echo "----------------------------------------------------"
        date +"! %T %a %D : Installation de l'agent zabbix."
        echo "----------------------------------------------------"
		check_user
		echo "Creation des repertoires d'/installation"
        if [ -e $ZABBIXDIR ]; then
			echo "Le repertoire $ZABBIXDIR existe"
		else 
			mkdir /opt/zabbix
		fi
		if [ -e $ZABBIXDIR/bin ]; then
			echo "Le repertoire $ZABBIXDIR/bin existe"
		else
			mkdir /opt/zabbix/bin
		fi
		if [ -e $ZABBIXDIR/conf ]; then
			echo "Le repertoire $ZABBIXDIR/conf existe"
		else
			mkdir /opt/zabbix/conf
		fi
		if [ -e $ZABBIXDIR_1 ]; then
			echo "Le repertoire $ZABBIXDIR_1 existe"
		else
			mkdir /etc/zabbix
		fi
		if [ -e $ZABBIXDIR_2 ]; then
			echo "Le repertoire $ZABBIXDIR_2 existe"
		else
			 mkdir -p /usr/local/zabbix/bin
		fi
		if [ -e $ZABBIXLOG ]; then
			echo "Le repertoire $ZABBIXLOG existe"
		else
			mkdir /var/log/zabbix
			touch /var/log/zabbix/zabbix_agentd.log
			chmod 666 /var/log/zabbix/zabbix_agentd.log
		fi
		echo "Verification de l'archittecture"
		if [ "$ARCH" == 'x86_64' ]; then
			mkdir $ZABBIXTMP
			cd $ZABBIXTMP
			echo "Telechargement des binaires x86_64"
			wget http://www.zabbix.com/downloads/1.8.5/zabbix_agents_1.8.5.linux2_6.amd64.tar.gz
			tar zxvf zabbix_agents_1.8.5.linux2_6.amd64.tar.gz
		else
			mkdir $ZABBIXTMP
			cd $ZABBIXTMP
			echo "Telechargement des binaires i386"
			wget http://www.zabbix.com/downloads/1.8.5/zabbix_agents_1.8.5.linux2_6.i386.tar.gz
			tar zxvf zabbix_agents_1.8.5.linux2_6.i386.tar.gz
		fi
		echo "Copie des sources et des binaires"
			cd $ZABBIXTMP
			cp sbin/* $ZABBIXDIR/bin
			cp bin/* $ZABBIXDIR/bin
			chmod +x $ZABBIXDIR/bin/*
			ln -s $ZABBIXDIR/bin/zabbix_agentd $ZABBIXDIR_2/zabbix_agentd
		echo "Termine."
		
		echo "Telechargement du fichier de configuration de l'agent"
			wget --no-check-certificate https://github.com/downloads/lbtm/zabbixagentinstalle/zabbix_agentd.conf
			chmod 644 zabbix_agentd.conf
			echo "Copie du fichier de configuration de l'agent"
			cp zabbix_agentd.conf  $ZABBIXDIR/conf
			ln -s $ZABBIXDIR/conf/zabbix_agentd.conf $ZABBIXDIR_1/zabbix_agentd.conf  
		echo "Termine."
		
		echo "Configuration du demarrage automatique de l'agent"
			echo "zabbix_agent 10050/tcp" >> /etc/services
			echo "zabbix_trap 10051/tcp"  >> /etc/services
		
		echo "Telechargement du script zabbix_agentd 'source Zabbix SIA'"
			wget --no-check-certificate https://github.com/downloads/lbtm/zabbixagentinstalle/zabbix_agentd
			chmod +x zabbix_agentd
		echo "Copie du fichier 'zabbix_agentd' dans le repertoire /etc/init.d/"
			cp zabbix_agentd /etc/init.d/
			/sbin/chkconfig --add zabbix_agentd
			/sbin/chkconfig --level 345 zabbix_agentd on
		echo "Termine."
		
		echo "Configuration de l'agent 'zabbix_agentd.conf'"
			echo "#----VARIABLES POSITIONNEES A L'INSTALLATION PAR L'ADMIN----" >> $ZABBIXDIR/conf/zabbix_agentd.conf
			echo "LogFile=$ZABBIXLOG/zabbix_agentd.log" >> $ZABBIXDIR/conf/zabbix_agentd.conf
			echo "Pidfile=/var/run/zabbix/zabbix_agentd.pid" >> $ZABBIXDIR/conf/zabbix_agentd.conf
			echo "Server=$SERVEURZABBIX" >> $ZABBIXDIR/conf/zabbix_agentd.conf
			echo "Hostname=$Hostname.$DOMAINE" >> $ZABBIXDIR/conf/zabbix_agentd.conf
			echo "#----------------------------------------------------------" >> $ZABBIXDIR/conf/zabbix_agentd.conf
        echo "Termine."
		
		echo "Demarrage du service 'zabbix_agentd'"
			$ZABBIXDIR/bin/zabbix_agentd -c $ZABBIXDIR/conf/zabbix_agentd.conf
		echo "Suppression des fichiers temporaires"
			rm -rf $ZABBIXTMP
		echo "----------------------------------------------------"
        date +"! %T %a %D : Fin."
        echo "----------------------------------------------------"
        ;;

    supp)
        echo "Desinstallation de l'agent zabbix"
        echo "----------------------------------------------------"
        date +"! %T %a %D : Desinstallation de l'agent zabbix ." 
        echo "----------------------------------------------------"
        echo "Arret $DAEMON_NAME"
		if [ -e $PID ]; then
			killall -q $DAEMON_NAME
		fi
		echo "L'agent zabbix a ete arrete."
		
		echo "Suppression du repertoire d'installation"
			rm -rf $ZABBIXDIR
			rm -rf $ZABBIXLOG
		echo "Suppression de l'utilisateur zabbix"
			userdel zabbix
        echo "L'utilisateur zabbix a ete supprime."
		   
		echo "----------------------------------------------------"
        date +"! %T %a %D : Fin." 
        echo "----------------------------------------------------"
        ;;

    statut)
        echo "----------------------------------------------------"
        date +"! %T %a %D : Statut du service de l'agent zabbix."
        echo "----------------------------------------------------"
		echo "Verification du statut $DAEMON_NAME "
			if [ -e $PID ]; then
				echo "Statut: $DAEMON_NAME est en marche."
			else
				echo "Statut: $DAEMON_NAME n'est pas en marche."
			fi
		;;
		*)
        echo "Usage: zabbixagent {installe|supp|statut}"
        exit 1
esac
