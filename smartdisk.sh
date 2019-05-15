#!/bin/bash

# Description:
#	Script permettant:
#	1- D'afficher le numéro de série d'un disque dur.
#	2- D'afficher le temps en fonctionnement d'un disque dur.
#	3- D'afficher une date préventive pour le changement
#	d'un disque dur avant une éventuelle panne fatale possible.
#	4- Effectue les testes S.M.A.R.T sur un disque dur.
#	5- Effectue des tests de secteurs avec Badblocks.
#	6- Tente de réparer les sécteur défectueux d'un disque.
#	7- Création de fichiers log datés.
#----------------------------------------------------------------#
# Usage: ./smartdisk.sh
#	Exécuter le script en root!
#
# Campatibilité:
#	Les disques durs supportant les attributs S.M.A.R.T sont:
#	Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital
#
#	Ce script s'est basé sur la données Power-On Hours (POH).
#	Certains constructeurs utilisent cette données en minutes
#	par conséquent ce script ne sera pas compatible.
#
# Auteur:
#  	Daniel DOS SANTOS < daniel.massy91@gmail.com >
#----------------------------------------------------------------#

### Les fonctions ###

function installation
{
	inx=$(dpkg -s "$1" | grep Status | awk '{print $2}')
	clear
	if [[ $inx == "install" ]]
	then
		echo -e "\n $1 est déjà installé \n"
	elif [[ $inx == "deinstall" ]]
	then
		echo -e "\n Installation de $1 en cours \n"
		apt-get install -y $1

		if [[ $? == 0 ]]
		then
			echo -e "\n Installation réussi \n"
		else
			echo -e "\n Installation de $1 Impossible!\n"
			exit1
		fi
	else
		pri='type -a'
		$pri $1
		if [[ $? == "0" ]]
		then
			echo -e "\n La commande $1 est installée"
			echo -e "$1 n'est pas gérée par DPKG \n"
		else
			echo -e "\n Installation de $1 en cours \n"
			apt-get install -y $1

			if [[ $? == 0 ]]
			then
				echo -e "\n Installation réussi \n"
			else
				echo -e "\n Erreur \n"
				echo -e "\n Installation de $1 Impossible!\n"
				exit1
			fi
		fi
	fi
}

function testrl
{
	echo " "
	#Début des testes approfondies du disque
	echo '     Menu test  '
	echo '--------------------'
	echo '[s] : SMART Rapide'
	echo '[c] : SMART plus complet'
	echo '[r] : Badblocks (lécture)'
	echo '[w] : Badblocks (écriture)'
	echo '[q] : quitter'
	echo '--------------------'
	read -p " Votre choix ==> " -n 1 choix
	echo " "
	read -p " Taper entrée pour valider! "
	echo " "

	case $choix in
	#"-t short” désigne un test rapide et moins approfondie
	"S" | "s")
		echo " "
		smartctl -t short /dev/$disk | tail -n4;;
	#"-t long” désigne un test long et plus approfondie
	"W" | "w")
		echo " "
	#"-w" test en écriture
	#"-s" barre de progression
	#"-v" verbosité
		badblocks -wsv /dev/$disk > badblocks_erreurs-$id_disk
		reparation
		echo -e "\n FIN DU PROGRAMME S.M.A.R.T_disk \n"
		exit 2;;
	"R" | "r")
		echo " "
	#"-w" test en écriture
	#"-s" barre de progression
	#"-v" verbosité
		badblocks -nsv /dev/$disk > badblocks_erreurs-$id_disk
		reparation
		echo -e "\n FIN DU PROGRAMME S.M.A.R.T_disk \n"
		exit 2;;
	"C" | "c")
		echo " "
		smartctl -t long /dev/$disk | tail -n4;;
	"Q" | "q")
		echo -e "\n FIN DU PROGRAMME S.M.A.R.T_disk \n"
		exit 1;;
	*) echo " "
		echo "Erreur de saisie ! "
		sleep 2
		testrl;;
	esac
}

function reparation
{
chemin="badblocks_erreurs-$id_disk"
if [ -e $chemin ]; then
# le fichier existe
	if [ -s $chemin ]; then
                echo "Des erreurs ont été trouvés!" # fichier non vide
                read -p "Voulez vous réparer le disque [o]oui [n]non ?" repa

                case $repa in
        "o" | "O")
                echo " "
                e2fsck -cfpv /dev/$disk  < $chemin;;
	"n" | "N")
                echo "Disque non réparé!";;
                *)
                echo " "
                echo "Erreur de saisie ! ";;
                esac
        else
                echo "Pas d'erreur trouvé!" #fichier vide
	fi
else
	echo "Erreur fichier non trouvé!"
fi
rm -rf $chemin
}

### Début du programme ###

#Variable date du jour
dat=$(date "+%m_%d_%y-%H_%M_%S")

rapport="smartrapplog"

#Bannière du fichier de rapport
echo "#######################################################################################" >> $rapport 
echo " " >> $rapport 
echo -e "\n    Rapport S.M.A.R.T_disk" >> $rapport   
echo "------------------------------------------" >> $rapport
echo -e "\n Date et heure : $dat \n" >> $rapport

clear
echo " "
echo "    Début du programme S.M.A.R.T_disk"
echo "------------------------------------------"
echo " "
echo -e "Date et heure : $dat"
if [ $LOGNAME != "root" ]
then
	echo -e "\n Attention vous devez exécuter ce script en tant que root! \n"
	exit 1
fi
echo -e "\n En cours d'actualisation! \n"
apt-get update > /dev/null

#Installation de smartmontools,bc,badblocks et lshw
installation smartmontools
installation bc
installation e2fsprogs
installation lshw
clear
suivant="o"
while [[ $suivant == "o" || $suivant == "O" ]]
do
#Scan des disques du système
echo -e "\n  Les disques  " | tee -a $rapport
echo "-------------------" | tee -a $rapport
lshw -short -C disk | cut -c19- | tee -a $rapport
echo " " | tee -a $rapport

#Choix du disque à tester
echo "Choix du disque à tester"
echo "Exemples [ sdX, mdX ou hdX ]"
read -p "Disque à tester : " -n 3 disk
echo " "
read -p " Taper entrée pour valider! "
echo " "
if [[ $disk =~ ^[s|h][d][a-z]$ || $disk =~ ^[m][d][0-9]$ ]]
then
	echo "saisie correcte de $disk"
else
	echo "Saisie incorrecte"
	read -p "Voulez vous recommencer [o] ou arrêter le programme [x] ?" -n 1 ffon
	echo " "
	if [[ $ffon == "o" || $ffon == "O" ]]
	then
		continue
	else
		exit 1
	fi
fi

id_disk=$(smartctl -i /dev/sda | grep "Serial Number:" | awk '{print $3}')

#-s Active le support SMART (ou pas s'il est déjà activé...)
#-o Active la collecte des données hors connexion.
#-S Active la sauvegarde automatique des attributs.
smartctl -s on -o on -S on /dev/$disk > /dev/null

#Si le résultat est PASSED, c’est qu’il n’y a pas d’erreur de constatée sur les indicateurs S.M.A.R.T,
#Si par contre le résultat est FAILING, c’est qu’un ou plusieurs #indicateurs affichent des erreurs.
testpassed=$(smartctl -H /dev/sda | grep "SMART" | sed -n "2p" | awk -F':' '{print $2}')

#Teste le résultat de PASSED
echo " "
if [[ $testpassed == " PASSED" ]]
then
        echo -e "Pas d'erreur constaté sur les indicateurs S.M.A.R.T\n"
else
        echo "Disque dur endommagé ou non compatible avec les données S.M.A.R.T"
	echo -e "veuillez sauvegarder vos données sur un autre support !\n"
	exit 1
fi

#numéro de série du disque
echo -e "\n    Informations disque dur" | tee -a $rapport
echo -e "-------------------------------\n" | tee -a $rapport
smartctl -i /dev/$disk | grep '\(Model Family:\|Device Model:\|Serial Number:\|Rotation Rate:\)' | tee -a $rapport
echo " "
#heures de fonctionnement
heures=`smartctl -a /dev/$disk | grep Power_On_Hours | awk -F' ' '{print $10}'`

if [[ $heures =~ ^[0-9]+$ ]]
then
	echo -e "\n Données en heures correcte! \n"
elif [ -z $heures ]
then
	echo -e "Pas d'information sur la données Power-On Hours (POH)"
	echo -e "Impossible de continuer! \n"
	exit 1
else
	echo -e "Impossible de continuer! \n"
	exit 1
fi

#Arrondie
jours=`printf "%.1f\n" $(echo "$heures/24" | bc -l | sed 's/\./,/')`
semaines=`printf "%.1f\n" $(echo "$heures/168" | bc -l | sed 's/\./,/')`
mois=`printf "%.1f\n" $(echo "$heures/730.001" | bc -l | sed 's/\./,/')`
ans=`printf "%.1f\n" $(echo "$heures/8760" | bc -l | sed 's/\./,/')`

#Temps écoulé
case 1 in
$(($heures<= 23))) echo -e "Fonctionnement depuis : $heures heures\n" | tee -a $rapport;;
$(($heures>= 24 & $heures<= 167))) echo -e "Fonctionnement depuis : $jours jours\n" | tee -a $rapport;;
$(($heures>= 168 & $heures<= 729))) echo -e "Fonctionnement depuis : $semaines semaines\n" | tee -a $rapport;;
$(($heures>= 730 & $heures<= 8759))) echo -e "Fonctionnement depuis : $mois mois\n" | tee -a $rapport;;
$(($heures>= 6087))) echo -e "Fonctionnement depuis : $ans ans\n" | tee -a $rapport;;
*) exit 1;;
esac

#Seuil d'alarme
echo -e "Probabilité de panne par l'usure naturelle : \n" | tee -a $rapport
case 1 in
$(($heures<= 20000))) echo -e " ==> [ ~0% ]\n" | tee -a $rapport;;
$(($heures>= 20001 & $heures<= 24999))) echo -e " ==> [ ~20% ]\n" | tee -a $rapport;;
$(($heures>= 25000 & $heures<= 29999))) echo -e " ==> [ ~40% ]\n" | tee -a $rapport;;
$(($heures>= 30000 & $heures<= 34999))) echo -e " ==> [ ~60% ]\n" | tee -a $rapport;;
$(($heures>= 35000 & $heures<= 39999))) echo -e " ==> [ ~80% ]\n" | tee -a $rapport;;
$(($heures>= 40000))) echo -e " ==> [ ~100% ]\n" | tee -a $rapport;;
*) exit 1;;
esac

#temps de vie restant
rest=$(echo "40000-$heures" | bc -l)

if [[ $rest =~ ^-+ || $rest =~ ^0+ ]]
then
	echo "Durée de vie du disque dépassé, plus de 40 000 heures de fonctionnement!" | tee -a $rapport
else
	#Non arrondie
	#jrest=$(echo "$rest/24" | bc -l)
	#srest=$(echo "$rest/168" | bc -l)
	#mrest=$(echo "$rest/730.001" | bc -l)
	#arest=$(echo "$rest/8760" | bc -l)

	#Arrondie
	jrest=`printf "%.1f\n" $(echo "$rest/24" | bc -l | sed 's/\./,/')`
	srest=`printf "%.1f\n" $(echo "$rest/168" | bc -l | sed 's/\./,/')`
	mrest=`printf "%.1f\n" $(echo "$rest/730.001" | bc -l | sed 's/\./,/')`
	arest=`printf "%.1f\n" $(echo "$rest/8760" | bc -l | sed 's/\./,/')`

	echo -e "Temps restant avant une éventuelle panne fatale : \n" | tee -a $rapport
	case 1 in
	$(($rest<= 23))) echo -e " ==> ~ $rest heures\n" | tee -a $rapport;;
	$(($rest>= 24 & $rest<= 167))) echo -e " ==> ~ $jrest jours\n" | tee -a $rapport;;
	$(($rest>= 168 & $rest<= 729))) echo -e " ==> ~ $srest semaines\n" | tee -a $rapport;;
	$(($rest>= 730 & $rest<= 8759))) echo -e " ==> ~ $mrest mois\n" | tee -a $rapport;;
	$(($rest>= 8760))) echo -e " ==> ~ $arest ans\n" | tee -a $rapport;;
	*) exit 3;;
	esac
fi

read -p "Voulez-vous afficher le tableau des valeurs S.M.A.R.T oui[o] non[n] ? : " -n 1 choixts
echo " "
if [[ $choixts == "o" || $choixts == "O" ]]
then
	smartctl -A /dev/$disk
else
	sleep 1
fi

echo " "
echo -e "    Temps de test SMART estimé"
echo -e "----------------------------------------------\n"
#Se faire une idée de la durée des testes
smartctl -c /dev/$disk | tail -n11 | head -n6

testrl

echo " "
read -p "Veuillez attendre la fin du teste puis validez"

echo " "
echo -e "    Résultats du teste"
echo -e "-------------------------\n"
#Ensuite pour avoir accès au résultats du test
smartctl -l selftest /dev/$disk

#Si erreurs
echo -e "\n   Détail si erreurs :"
echo -e "------------------------"
smartctl -q errorsonly -H -l selftest /dev/$disk

echo " "
echo "FIN DU PROGRAMME S.M.A.R.T_disk"
echo " "
read -p "Tester un autre disque[o] ou arrêter le programme[x] ? : " -n 1 final
echo " "
if [[ $final == "o" || $final == "O" ]]
then
	continue
else
	exit 1
fi
done