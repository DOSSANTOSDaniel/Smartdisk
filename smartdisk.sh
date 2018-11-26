#!/bin/bash

# Description:
#	Script permettant:
#	1- D'afficher le numéro de série d'un disque dur.
#	2- D'afficher le temps en fonctionnement d'un disque dur.
#	3- D'afficher une date préventive pour le changement 
#	d'un disque dur avant une éventuelle panne fatale possible.
#	5- Effectue les testes S.M.A.R.T sur un disque dur.
#----------------------------------------------------------------#
# Usage: ./smartdisk.sh
#	Exécuter le script en root!
#	
# Campatibilité:
#	Les disques durs supportant les attributs S.M.A.R.T sont:
#	Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital
#
#	Ce script s'est basé sur la données Power-On Hours (POH) pour
#	déterminer la date de l'erreur fatale.
#	Mais certains constructeurs utilisent cette données en minutes
#	par conséquent ce script ne sera pas compatible.
#
# Auteur:
#  	Daniel DOS SANTOS < daniel.massy91@gmail.com >
#----------------------------------------------------------------#

clear
echo " "
echo "    Début du programme S.M.A.R.T_disk"
echo "------------------------------------------"
echo " "

apt-get update > /dev/null 2>&1

#Installation de smartmontools
apt-get install -y smartmontools > /dev/null 2>&1

echo " "
suivant="o"
while [[ $suivant == "o" || $suivant == "O" ]]
do
#Scan des disques du système
echo " "
smartctl --scan
echo " "

#Choix du disque à tester
echo "Choix du disque à tester"
echo "Exemples [ sdX, mdX ou hdX ]"
read -p "Disque à tester : " -n 3 disk
echo " "
if [[ $disk =~ ^[s|h][d][a-z]$ || $disk =~ ^[m][d][0-9]$ ]]
then
	echo "saisie correcte"
else
	echo "Saisie incorrecte"
	read -p "Voulez vous recommencer [o] ou arrêter le programme [n] ?" -n 1 ffon
	echo " "
	if [[ $ffon == "o" || $ffon == "O" ]]
	then
		continue
	else
		exit 1
	fi 
fi	

#-s Active le support SMART (ou pas s'il est déjà activé...)
#-o Active la collecte des données hors connexion.
#-S Active la sauvegarde automatique des attributs.
smartctl -s on -o on -S on /dev/$disk > /dev/null

#Si le résultat est PASSED, c’est qu’il n’y a pas d’erreur de constatée sur les indicateurs S.M.A.R.T,
#Si par contre le résultat est FAILING, c’est qu’un ou plusieurs #indicateurs affichent des erreurs.
testpassed=`smartctl -H /dev/sda | grep "SMART" | awk -F':' '{print $2}'`

#Teste le résultat de PASSED
echo " "
if [ $testpassed == "PASSED" ]
then
        echo -e "Pas d'erreur constaté sur les indicateurs S.M.A.R.T\n"
else
        echo -e "Disque dur endommagé veuillez sauvegarder vos données sur un autre support !\n"
	exit 1
fi

echo " "
#numéro de série du disque
echo "    Informations disque dur"
echo "-------------------------------"
smartctl -i /dev/$disk | grep '\(Model Family:\|Device Model:\|Serial Number:\)'

echo " "
#heures de fonctionnement
heures=`smartctl -a /dev/$disk | grep Power_On_Hours | awk -F' ' '{print $10}'`

#Non arrondie
#jours=$(echo "$heures/24" | bc -l)   
#semaines=$(echo "$heures/168" | bc -l)
#mois=$(echo "$heures/730.001" | bc -l)
#ans=$(echo "$heures/8760" | bc -l)

#Arrondie
jours=`printf "%.2f\n" $(echo "$heures/24" | bc -l | sed 's/\./,/')`
semaines=`printf "%.2f\n" $(echo "$heures/168" | bc -l | sed 's/\./,/')`
mois=`printf "%.2f\n" $(echo "$heures/730.001" | bc -l | sed 's/\./,/')`
ans=`printf "%.2f\n" $(echo "$heures/8760" | bc -l | sed 's/\./,/')`

#Temps écoulé
case 1 in
$(($heures<= 23))) echo -e "Fonctionnement depuis $heures heures\n";;
$(($heures>= 24 & $heures<= 167))) echo -e "Fonctionnement depuis $jours jours\n";;
$(($heures>= 168 & $heures<= 729))) echo -e "Fonctionnement depuis $semaines semaines\n";;
$(($heures>= 730 & $heures<= 8759))) echo -e "Fonctionnement depuis $mois mois\n";;
$(($heures>= 6087))) echo -e "Fonctionnement depuis $ans ans\n";;
*) exit 1;;
esac

#Seuil d'alarme
echo "Probabilité de panne par l'usure naturelle : "
case 1 in
$(($heures<= 20000))) echo -e " ==> [ ~0% ]\n";;
$(($heures>= 20001 & $heures<= 24999))) echo -e " ==> [ ~20% ]\n";;
$(($heures>= 25000 & $heures<= 29999))) echo -e " ==> [ ~40% ]\n";;
$(($heures>= 30000 & $heures<= 34999))) echo -e " ==> [ ~60% ]\n";;
$(($heures>= 35000 & $heures<= 39999))) echo -e " ==> [ ~80% ]\n";;
$(($heures>= 40000))) echo -e " ==> [ ~100% ]\n";;
*) exit 1;;
esac

#temps de vie restant
rest=$(echo "40000-$heures" | bc -l)

if [[ $rest =~ ^-+ || $rest =~ ^0+ ]]
then
	echo "Durée de vie du disque dépassé !"
else	
	#Non arrondie
	#jrest=$(echo "$rest/24" | bc -l)
	#srest=$(echo "$rest/168" | bc -l)
	#mrest=$(echo "$rest/730.001" | bc -l)
	#arest=$(echo "$rest/8760" | bc -l)
	
	#Arrondie
	jrest=`printf "%.2f\n" $(echo "$rest/24" | bc -l | sed 's/\./,/')`
	srest=`printf "%.2f\n" $(echo "$rest/168" | bc -l | sed 's/\./,/')`
	mrest=`printf "%.2f\n" $(echo "$rest/730.001" | bc -l | sed 's/\./,/')`
	arest=`printf "%.2f\n" $(echo "$rest/8760" | bc -l | sed 's/\./,/')`

	echo "Temps restant avant une éventuelle panne fatale: "
	case 1 in
	$(($rest<= 23))) echo -e " ==> ~ $rest heures\n";;
	$(($rest>= 24 & $rest<= 167))) echo -e " ==> ~ $jrest jours\n";;
	$(($rest>= 168 & $rest<= 729))) echo -e " ==> ~ $srest semaines\n";;
	$(($rest>= 730 & $rest<= 8759))) echo -e " ==> ~ $mrest mois\n";;
	$(($rest>= 8760))) echo -e " ==> ~ $arest ans\n";;
	*) exit 3;;
	esac
fi

echo " "
echo -e "    Estimation du temps de teste du disque"
echo -e "----------------------------------------------\n"
#Se faire une idée de la durée des testes
smartctl -c /dev/sda | tail -n8 | head -n4
echo " "

read -p "Voulez-vous afficher le tableau des valeurs S.M.A.R.T oui[o] non[n] ? : " -n 1 choixts
if [[ $choixts == "o" || $choixts == "O" ]]
then
	smartctl -c /dev/$disk | tail -n8 |head -n4
else
	sleep 1
fi 

echo " "
#Début des testes approfondies du disque
read -p "Voulez vous faire un teste rapide [R] ou long [L] ==> " choix
echo " "
case $choix in
#"-t short” désigne un test rapide et moins approfondie
"R" | "r") smartctl -t short /dev/$disk | tail -n4;;
#"-t long” désigne un test long et plus approfondie
"L" | "l") smartctl -t long /dev/$disk | tail -n4;;
*) echo "Erreur de saisie" exit 1;;
esac
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
read -p "Tester un autre disque [o] ou arrêter le programme [n] ? : " -n 1 final
echo " "
if [[ $final == "o" || $final == "O" ]]
then
	continue
else
	exit 1
fi 
done
