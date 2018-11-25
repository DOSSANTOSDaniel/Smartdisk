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
#	
#	Les disques durs supportant les attributs S.M.A.R.T sont:
#	Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital
#
#	Ce script s'est basé sur la données Power-On Hours (POH) pour
#	déterminer la date de l'erreur fatale.
#	Mais certains constructeurs utilisent cette données en minutes
#	par conséquent ce script ne sera pas compatible.
