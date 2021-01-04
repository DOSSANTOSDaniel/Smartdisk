#!/bin/bash

# Description:
#Script permettant:
#  1- D'afficher le numéro de série d'un disque dur.
#  2- D'afficher le temps de fonctionnement d'un disque dur.
#  3- D'afficher une date préventive pour le changement
#  d'un disque dur avant une éventuelle panne.
#  4- Effectue les testes S.M.A.R.T sur un disque dur.
#  5- Effectue des tests de secteurs avec Badblocks.
#  6- Tente de réparer les secteurs défectueux d'un disque.
#----------------------------------------------------------------#
# Usage: ./smartdisk.sh
#  Exécuter le script en tant que root!
#
# Compatibilité:
#  Les disques durs supportant les attributs S.M.A.R.T sont:
#  Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital.
#
# Auteur:
#    Daniel DOS SANTOS < dossantosjdf@gmail.com >
#----------------------------------------------------------------#

### Les fonctions ####
#$1
installation()
{
app=$(echo "${1}" | tr "[:upper:]" "[:lower:]")

stat_app=$(dpkg -s "${app}" | grep Status | awk '{print $2}')

if [[ ${stat_app} != 'install' && ! $(command -v ${app}) ]]
then
  echo -e "\n Installation de ${app} en cours \n"
  apt-get update -q
  apt-get install -qy ${app}
  
  if [[ "${?}" == "0" ]]
  then
    echo -e "\n Installation de ${app} réussie \n"
  else
    echo -e "\n Erreur : \n"
    echo -e "\n Installation de ${app} Impossible!\n"
    exit 1
  fi
fi
}

end_p()
{
  echo -e "\n Tester un autre disque[o] ou arrêter le programme[x] ?"
  read -p " : " final
  if [[ ! "${final}" =~ [oO] ]]
  then
    echo -e "\n FIN DU PROGRAMME S.M.A.R.T_disk"
    echo -e " S.M.A.R.T_disk \n"
    exit 1
  fi
}

#$id_disk, $disk
fix_disk()
{
chemin=badblocks_erreurs-${id_disk}

# -s fichier non vide
if [[ -s ${chemin} ]]
then
  echo "Des erreurs ont été trouvés!"
  read -p 'Voulez vous réparer le disque [o]oui [n]non ? : ' fix
    
  if [[ ${fix} =~ [Oo] ]]
  then
    e2fsck -cfpv /dev/${disk} < ${chemin}
  elif [[ ${fix} =~ [Nn] ]]
  then
    echo "Disque non réparé!"
  else
    echo "Erreur de saisie"
  fi
else
  echo "Pas d'erreurs trouvées!"
fi
}

status_test()
{
echo -e "\n Veuillez attendre la fin du teste puis validez \n"
read

echo -e "\n    Résultats du teste"
echo -e "-------------------------"

#Ensuite pour avoir accès au résultats du test
smartctl -l selftest /dev/${disk}

# Si erreurs
echo -e "\n   Détail si erreurs :"
echo -e "------------------------"
smartctl -q errorsonly -H -l selftest /dev/${disk}
}

time_estimate()
{
# Heures
heures=$(smartctl -a /dev/${disk} | grep Power_On_Hours | awk -F' ' '{print $10}')

if [[ -z ${heures} || ! ${heures} =~ ^[0-9]+$ ]]
then
  echo -e "\n Pas d'information sur la donnée Power-On Hours (POH) \n"
else
  # Temps écoulé
  if [[ ${heures} -le 23 ]]
  then
    echo -e "\nFonctionnement depuis : ${heures} heures \n"
  elif [[ ${heures} -ge 24 && ${heures} -le 167 ]]
  then
    jours=$(printf "%.1f\n" $(echo "${heures}/24" | bc -l | sed 's/\./,/'))
    echo -e "\nFonctionnement depuis : ${jours} jours \n"
  elif [[ ${heures} -ge 168 && ${heures} -le 729 ]]
  then
    semaines=$(printf "%.1f\n" $(echo "${heures}/168" | bc -l | sed 's/\./,/'))
    echo -e "\nFonctionnement depuis : ${semaines} semaines \n"
  elif [[ ${heures} -ge 730 && ${heures} -le 8759 ]]
  then
    mois=$(printf "%.1f\n" $(echo "${heures}/730.001" | bc -l | sed 's/\./,/'))
    echo -e "\nFonctionnement depuis : ${mois} mois \n"
  elif [[ ${heures} -ge 6087 ]]
  then
    ans=$(printf "%.1f\n" $(echo "${heures}/8760" | bc -l | sed 's/\./,/'))
    echo -e "\nFonctionnement depuis : ${ans} ans \n"
  fi
  
  # Temps de vie restant
  t_rest=$(echo "40000-${heures}" | bc -l)
  
  if [[ ${t_rest} =~ ^-+ || ${t_rest} =~ ^0+ ]]
  then
    echo "Durée de vie du disque dépassé, plus de 40 000 heures de fonctionnement!"
  else
    echo -e "Temps restant avant une éventuelle panne fatale : "
    if [[ ${t_rest} -le 23 ]]
    then
      echo -e " ==> ~ ${t_rest} heures\n"
    elif [[ ${t_rest} -ge 24 && ${t_rest} -le 167 ]]
    then
      jrest=$(printf "%.1f\n" $(echo "${t_rest}/24" | bc -l | sed 's/\./,/'))
      echo -e " ==> ~ ${jrest} jours\n"
    elif [[ ${t_rest} -ge 168 && ${t_rest} -le 729 ]]
    then
      srest=$(printf "%.1f\n" $(echo "${t_rest}/168" | bc -l | sed 's/\./,/'))
      echo -e " ==> ~ ${srest} semaines\n"
    elif [[ ${t_rest} -ge 730 && ${t_rest} -le 8759 ]]
    then
      mrest=$(printf "%.1f\n" $(echo "${t_rest}/730.001" | bc -l | sed 's/\./,/'))
      echo -e " ==> ~ ${mrest} mois\n"
    elif [[ ${t_rest} -ge 8760 ]]
    then
      arest=$(printf "%.1f\n" $(echo "${t_rest}/8760" | bc -l | sed 's/\./,/'))
      echo -e " ==> ~ ${arest} ans\n"
    fi
  fi
  # Seuil d'alarme
  echo -e "Probabilité de panne par l'usure naturelle : "
  if [[ ${heures} -le 20000 ]]
  then
    echo -e " ==> [ ~0% ] \n"
  elif [[ ${heures} -ge 20001 && ${heures} -le 24999 ]]
  then
    echo -e " ==> [ ~20% ] \n"
  elif [[ ${heures} -ge 25000 && ${heures} -le 29999 ]]
  then
    echo -e " ==> [ ~40% ] \n"
  elif [[ ${heures} -ge 30000 && ${heures} -le 34999 ]]
  then
    echo -e " ==> [ ~60% ] \n"
  elif [[ ${heures} -ge 35000 && ${heures} -le 39999 ]]
  then
    echo -e " ==> [ ~80% ] \n"
  elif [[ ${heures} -ge 40000 ]]
  then
    echo -e " ==> [ ~100% ] \n"
  fi
fi
}

### Début du programme ####

# Variables
readonly dat=$(date "+%m_%d_%y-%H_%M_%S")

# Bannière
clear
echo -e "\n <<<   S.M.A.R.T_disk   >>>"
echo -e "----------------------------------- \n"

if [[ ${LOGNAME} != "root" ]]
then
  echo -e "\n Attention vous devez exécuter ce script en tant que root ! \n"
  end_p
fi

# Installation de smartmontools,bc,badblocks
installation smartmontools
installation bc
installation e2fsprogs

while [ : ]
do
  # Scan des disques sur le système
  echo "NOM  TYPE TAILLE      MODELE"
  
  devices=$(smartctl --scan | cut -d "#" -f2 | cut -d "," -f1 | cut -d ' ' -f2)
  
  d_tab=()
  d_count="0"
  
  for dev in ${devices}
  do
    if [[ ${dev} =~ ^/dev ]]
    then
      ok=$(lsblk -lnd -o NAME ${dev})
      d_tab[${d_count}]="${ok}"
      lsblk -lnd -o NAME,TYPE,SIZE,MODEL ${dev}
      d_count=$(echo "$d_count + 1" | bc -l)
    fi
  done
  
  #Choix du disque à tester
  echo -e "\nNom du disque à tester."
  echo -e "Exemples [ sdX, mdX ou hdX ] \n"
  read -p "Disque à tester : " disk
  sleep 1
  
  # Regex
  regex_1="^[s|h][d][a-z]$"
  regex_2="^[m][d][0-9]$"
  
  if [[ -z ${disk} ]]
  then
    echo -e "\n Champ vide ! \n"
    sleep 2
    clear
    continue
  elif [[ ! ${disk} =~ ${regex_1} || ${disk} =~ ${regex_2} ]]
  then
    echo -e "\n Erreur de saisie \n"
    sleep 2
    clear
    continue
  fi
  
  b_ch="0"
  
  for i in ${d_tab[@]}
  do
    if [[ ${i} == ${disk} ]]
    then
      b_ch=$(echo "$b_ch + 1" | bc -l)
    fi
  done
  
  if [[ ${b_ch} == "0" ]]
  then
    echo -e "\n Erreur : Le périphérique ${choix} n'est pas présent dans le système! \n"
    sleep 3
    clear
    continue
  fi
  
  # Récupération id
  readonly id_disk=$(smartctl -i /dev/${disk} | grep "Serial Number:" | awk '{print $3}')
  
  #-s Active le support SMART (ou pas s'il est déjà activé...)
  #-o Active la collecte des données hors connexion.
  #-S Active la sauvegarde automatique des attributs.
  smartctl -s on -o on -S on /dev/${disk} > /dev/null
  
  #Si le résultat est PASSED, c’est qu’il n’y a pas d’erreur de constatée sur les indicateurs S.M.A.R.T,
  #Si par contre le résultat est FAILING, c’est qu’un ou plusieurs #indicateurs affichent des erreurs.
  testpassed1=$(smartctl -H /dev/${disk} | grep "SMART" | sed -n "2p" | awk -F':' '{print $2}')
  testpassed2=$(smartctl -H /dev/${disk} | grep "SMART" | sed -n "3p" | awk -F':' '{print $2}')
  
  #Teste le résultat de PASSED
  if [[ ${testpassed1} == " PASSED" || ${testpassed2} == " PASSED" ]]
  then
    echo -e "\n Pas d'erreurs constatés sur les indicateurs S.M.A.R.T \n"
  else
    echo "Disque dur endommagé ou non compatible avec les données S.M.A.R.T"
    echo -e "veuillez sauvegarder vos données sur un autre support !\n"
    end_p
  fi
  
  # Numéro de série du disque
  echo -e "\n    Informations disque dur"
  echo -e "-------------------------------\n"
  smartctl -i /dev/${disk} | grep '\(Model Family:\|Device Model:\|Serial Number:\|Rotation Rate:\)'
  
  # Nombre de secteurs ré-alloués automatiquement par le disque dur
  d_sect=$(smartctl -a /dev/${disk} | grep Reallocated_Sector_Ct | awk -F' ' '{print $10}')
  if [[ ${d_sect} -ge "700" ]]
  then
    echo -e "\n ATTENTION : Nombre de secteurs ré-alloués trop grand ! : ${d_sect} \n"
  fi
  
  # Température du disque dur
  d_temp=$(smartctl -a /dev/${disk} | grep Temperature_Celsius | awk -F' ' '{print $10}')
  if [[ ${d_temp} < "15" || ${d_temp} > "50" ]]
  then
    echo -e "\n ATTENTION : Température anormale ! : ${d_sect}"
    echo -e "Température normale : 20°C à 40°C \n"
  fi
  
  time_estimate
  
  read -p "Voulez-vous afficher le tableau des valeurs S.M.A.R.T oui[o] non[n] ? : " -n 1 choixts
  if [[ ${choixts} == "o" || ${choixts} == "O" ]]
  then
    clear
    smartctl -A /dev/${disk}
    read -p "Appuyer sur n'importe quelle touche pour quitter le tableau !"
  fi
  
  clear
  echo -e "\n Menu de tests : "
  PS3='Votre choix: '
  options=("Test SMART Rapide" "Test SMART plus complet" "Test Badblocks (lecture)" "Test Badblocks (écriture)" "Quitter")
  select opt in "${options[@]}"
  do
    case $opt in
      "Test SMART Rapide")
        clear
        smartctl -t short /dev/${disk} | tail -n4
        status_test
        end_p
        sleep 1
        clear
        break
        ;;
      "Test SMART plus complet")
        clear
        smartctl -t long /dev/${disk} | tail -n4
        status_test
        end_p
        sleep 1
        clear
        break
        ;;
      "Test Badblocks (lecture)")
        #"-n" test en lecture
        #"-s" barre de progression
        #"-v" verbosité
        badblocks -nsv /dev/${disk} > badblocks_erreurs-${id_disk}
        fix_disk
        end_p
        sleep 1
        clear
        break
        ;;
      "Test Badblocks (écriture)")
        #"-w" test en écriture
        badblocks -wsv /dev/${disk} > badblocks_erreurs-${id_disk}
        fix_disk
        end_p
        sleep 1
        clear
        break
        ;;
      "Quitter")
        echo -e "\n FIN DU PROGRAMME S.M.A.R.T_disk"
        echo -e " S.M.A.R.T_disk \n"
        exit 1
        ;;
      *) 
        echo "Option invalide : ${REPLY}"
        ;;
    esac
  done
  continue
done
