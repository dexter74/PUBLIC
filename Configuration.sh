#########################################
# Script de configuration de la machine #
#########################################
clear ; 

###################################################
# Configuration du compte secondaire et du groupe #
###################################################
NEW_USER_GROUP=''
NEW_USER_USERNAME=''
NEW_USER_PSWD=''
NEWS_USER_HOME="/home/$NEW_USER_USERNAME"


############################
# Configuration des depôts #
############################
OS_SOURCE='http://ftp.fr.debian.org/debian'
OS_RELEASE='buster'
OS_RELEASE_BRANCHE='main contrib non-free'

########################################
# Configuration du Hostname et Domaine #
########################################
HOST_NAME=''
HOST_DOMAINE=''

########################################
# Configuration des interfaces reseaux #
########################################
INTERFACE_NAME=''
INTERFACE_ADDRESS=''
INTERFACE_MASK=''
INTERFACE_BROADCAST=''
INTERFACE_GATEWAY=''
INTERFACE_DNS=''
INTERFACE_DOMAINE=''

################################################
# Configuration de la Region, Heure et Clavier #
################################################
HOST_TIMEZONE_REGION='Europe'
HOST_TIMEZONE_VILLE='Paris'
HOST_LANGUE='fr_FR.UTF-8'

##################################################
# Configuration de la Securisation de la machine #
##################################################
KEY_SSH=''

##########################################################################################################################################################################################
/usr/sbin/deluser $NEW_USER_USERNAME ;
rm -r $NEWS_USER_HOME ;
/usr/sbin/delgroup $NEW_USER_GROUP ;
/usr/sbin/addgroup $NEW_USER_GROUP ;
/usr/sbin/useradd --home-dir $NEWS_USER_HOME --base-dir $NEWS_USER_HOME --gid $NEW_USER_GROUP --groups sudo --no-user-group --shell /bin/bash --create-home $NEW_USER_USERNAME ;
echo "$NEW_USER_USERNAME:$NEW_USER_PSWD" | chpasswd
##########################################################################################################################################################################################


##########################################################################################################################################################################################
#CD-ROM:
sed -i -- 's/deb cdrom/#deb cdrom/g' /etc/apt/sources.list ;
#
# Backports :
echo "deb $OS_SOURCE $OS_RELEASE-backports $OS_RELEASE_BRANCHE" > /etc/apt/sources.list.d/$OS_RELEASE-backports.list ;
# Cloud-init :
echo "deb http://ftp.de.debian.org/debian $OS_RELEASE main" > /etc/apt/sources.list.d/cloud_init.list ;
##########################################################################################################################################################################################


##########################################################################################################################################################################################
apt update -qq ;
apt upgrade -y -qq ;
#
apt install -y -qq bash-completion ;
apt install -y -qq cloud-init ;
apt install -y -qq curl ;
apt install -y -qq debconf-utils ;
apt install -y -qq dnsutils ;
apt install -y -qq git ;
apt install -y -qq gnupg ;
apt install -y -qq net-tools ;
apt install -y -qq qemu-guest-agent ;
apt install -y -qq sudo ;
apt install -y -qq wget ;

#
apt update --fix-missing -y ;
#
service qemu-guest-agent restart ;
#
#echo "$NEW_USER_USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers ;
#
/usr/sbin/adduser $NEW_USER_USERNAME sudo ;
##########################################################################################################################################################################################


##########################################################################################################################################################################################
# VM UNIQUEMENT: Europe/Paris | fr_FR.UTF-8
# timedatectl set-timezone $HOST_TIMEZONE_REGION/$HOST_TIMEZONE_VILLE ;
# localectl set-locale LANG=$HOST_LANGUE ;
##########################################################################################################################################################################################


##########################################################################################################################################################################################
hostnamectl set-hostname $HOST_NAME ;
echo "#IPV4
127.0.0.1       localhost
127.0.1.1       $HOST_NAME     $HOST_NAME
#127.0.1.1       $HOST_NAME.$HOST_DOMAINE     $HOST_NAME
#IPV6
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters" > /etc/hosts ;
##########################################################################################################################################################################################


##########################################################################################################################################################################################
echo "auto lo
iface lo inet loopback
auto $INTERFACE_NAME
allow-hotplug $INTERFACE_NAME
iface $INTERFACE_NAME inet static
address $INTERFACE_ADDRESS
netmask $INTERFACE_MASK
broadcast $INTERFACE_BROADCAST
gateway $INTERFACE_GATEWAY
dns-nameservers $INTERFACE_DNS" > /etc/network/interfaces ;
#
# Ajout du domaine:
#echo "dns-search $INTERFACE_DOMAINE" >> /etc/network/interfaces ;
#
# Desactiver la prise en charge du protocole IPV6
echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/70-disable-ipv6.conf
##########################################################################################################################################################################################


##########################################################################################################################################################################################
# Creation du dossier ssh
/sbin/runuser -l root -c 'mkdir -p /root/.ssh' ;
/sbin/runuser -l $NEW_USER_USERNAME -c 'mkdir '$NEWS_USER_HOME'/.ssh' ;
#
#Insertion des cles SSH
/sbin/runuser -l root -c "echo '$KEY_SSH' > /root/.ssh/authorized_keys" ;
/sbin/runuser -l $NEW_USER_USERNAME -c "echo '$KEY_SSH' > /home/$NEW_USER_USERNAME/.ssh/authorized_keys" ;
#
# Permission sur le dossier SSH
chmod 700 /root/.ssh ;
chmod 600 /root/.ssh/* ;
chmod 700 /home/$NEW_USER_USERNAME/.ssh/* ;
chmod 600 /home/$NEW_USER_USERNAME/.ssh/* ;
##########################################################################################################################################################################################


##########################################################################################################################################################################################
# Refuser : Aauthentification par mot de passe
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config ;
#
# Acces au root par mot de passe refuser
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config ;
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config ;
#
# Authentification par cle autoriser
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config ;
#
# SSH par le fichier AuthorizedKeysFile ...
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile /g' /etc/ssh/sshd_config ;


# Relance des services
systemctl restart sshd ;
systemctl restart ssh ;
##########################################################################################################################################################################################
