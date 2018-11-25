# Description:
Script permettant:
1- D'afficher le numéro de série d'un disque dur.
2- D'afficher le temps en fonctionnement d'un disque dur.
3- D'afficher une date préventive pour le changement 
d'un disque dur avant une éventuelle panne fatale possible.
5- Effectue les testes S.M.A.R.T sur un disque dur.

# Usage: ./smartdisk.sh
Exécuter le script en root!

# Campatibilité:	
Les disques durs supportant les attributs S.M.A.R.T sont:
Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital

Ce script s'est basé sur la données Power-On Hours (POH) pour
déterminer la date de l'erreur fatale.
Mais certains constructeurs utilisent cette données en minutes
par conséquent ce script ne sera pas compatible.

Données utilisées
-------------------

un jour = 24h
une semaine = 168h
un mois = 730.001h
un ans = 8760h

Donnée du seuil
------------------

D'après mes recherches le seuil max pour la durée de vie d'un disque dur est de 40 000 heures.

D'après cette information la probabilité de panne par l'usure naturelle est:

Plus petit ou égal à 20000 ==> [ ~0% ]
Entre 20001 et 24999 ==> [ ~20% ]
Entre 25000 et 29999 ==> [ ~40% ]
Entre 30000 et 34999 ==> [ ~60% ]
Entre 35000 et 39999 ==> [ ~80% ]
Plus grand ou égal à 40000 ==> [ ~100% ]
