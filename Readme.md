# Smartdisk
## Description:
Script permettant:
- D'afficher le numéro de série d'un disque dur.
- D'afficher le temps en fonctionnement d'un disque dur.
- D'afficher une date préventive pour le changement d'un disque dur avant une éventuelle panne fatale possible.
- Effectue les testes S.M.A.R.T sur un disque dur.
- Effectue des tests de secteurs avec Badblocks.
- Tenter de réparer les secteurs défectueux sur un disque.

## Usage: ./smartdisk.sh
Exécuter le script en root!

## Compatibilité:
- Les disques durs supportant les attributs S.M.A.R.T sont:
Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital
- Ce script s'est basé sur la données Power-On Hours (POH).
- Certains constructeurs utilisent cette données en minutes
par conséquent ce script ne sera pas compatible.

Données utilisées
-------------------
- un jour = 24h
- une semaine = 168h
- un mois = 730.001h
- un ans = 8760h

Donnée du seuil
------------------
<p>D'après mes recherches le seuil max pour la durée de vie d'un disque dur en production est de ~40 000 heures (4,6 ans).</p>
<p>D'après cette information la probabilité de panne par l'usure naturelle est:</p>

- Plus petit ou égal à 20000 ==> [ ~0% ]
- Entre 20001 et 24999 ==> [ ~20% ]
- Entre 25000 et 29999 ==> [ ~40% ]
- Entre 30000 et 34999 ==> [ ~60% ]
- Entre 35000 et 39999 ==> [ ~80% ]
- Plus grand ou égal à 40000 ==> [ ~100% ]

## à faire
* Afficher une estimation des testes Badblocks.
* Compatibilité avec les données en minutes.
* A l'aide du tableau S.M.A.R.T afficher les composant du disque qui sont susceptibles de tomber en panne prochainement.
* Organisation des logs à revoir.
* Afficher à la fin un récapitulatif des disques téstés ou créer un fichier avec les infos.
* Ajouter un teste de vitesse d'écriture et de lécture voir "Memo_Scripts_Bash".

#### Autre aide
Test en destruction écriture:
badblocks -wsv /dev/sdX > badblocks.txt

Test en lécture:
badblocks -nsv /dev/sdX > badblocks.txt

Réparation:
e2fsck -cfpv /dev/sdx  < badblocks.txt

Ou avec la commande fsck:
sudo fsck -C -t ext4 -l badblocks.txt /dev/sdxx

### Voir aussi le programme [Gsmartcontrol](https://gsmartcontrol.sourceforge.io/home/)
