# Smartdisk
## Description:
Script permettant:
- D'afficher le numéro de série d'un disque dur.
- D'afficher le temps de fonctionnement d'un disque dur.
- D'afficher une date préventive pour le changement d'un disque dur avant une éventuelle panne.
- Effectue les testes S.M.A.R.T sur un disque dur.
- Effectue des tests de secteurs avec Badblocks.
- Tenter de réparer les secteurs défectueux sur un disque.

## Usage: ./smartdisk.sh
Exécuter le script en tant que root!

## Compatibilité:
- Les disques durs supportant les attributs S.M.A.R.T sont:
Samsung, Seagate, IBM (Hitachi), Fujitsu, Maxtor, Western Digital

Données utilisées
-------------------
- un jour = 24h
- une semaine = 168h
- un mois = 730.001h
- un ans = 8760h

Donnée du seuil
------------------
<p>D'après se que j'ai lu sur le web le seuil max pour la durée de vie d'un disque dur est de ~40 000 heures (4,6 ans).</p>
<p>Fabrication d'une échelle de l'usure naturelle :</p>

- Plus petit ou égal à 20000 heures ==> [ ~0% ]
- Entre 20001 et 24999 heures ==> [ ~20% ]
- Entre 25000 et 29999 heures ==> [ ~40% ]
- Entre 30000 et 34999 heures ==> [ ~60% ]
- Entre 35000 et 39999 heures ==> [ ~80% ]
- Plus grand ou égal à 40000 heures ==> [ ~100% ]

Lecture des valeurs du tableau S.M.A.R.T
-----------------------------------------

| Colonne     | Description                                                             |
|-------------|:-----------------------------------------------------------------------:|
| VALUE       | Représente l’indice de fiabilité.                                       |
| WORST       | Représente la plus petite valeur de VALUE enregistrée.                  |
| THRESH      | Représente la valeur limite avant une dégradation ou un risque de panne.|
| WHEN_FAILED | S’il y a une erreur cela affiche la probabilité de panne:               |
|             |  1- Failing_Now: panne imminente.                                       |
|             |  2- In_the_past: indique qu’il y a eu une anomalie par le passé.        |
| RAW_VALUE   | Valeur mesuré.                                                          |

**Important:**
Il faut que les valeurs de la colonne VALUE soient toujours supérieures aux valeurs de la colonne THRESH, si c’est pas le cas cela veut dire qu’il y a un problème sur la ligne en question.

Les pannes courantes, voir tableau S.M.A.R.T:
----------------------------------------------

| Ligne par ID          | Panne                                                                 |
|-----------------------|:---------------------------------------------------------------------:|
| 01                    | Surface du disque ou tête de lecture dégradée.                        |
| 02                    | Problème générale.                                                    |
| 05                    | Trop de secteurs ré alloués la vitesse de lecture et écriture diminue.|
| 07, 08, 10, 198 et 11 | Dégradation du sous-système mécanique.                                |
| 191                   | Erreurs dues à des chocs externes ou vibrations violentes.            |

*Documentation S.M.A.R.T:*
https://fr.wikipedia.org/wiki/Self-Monitoring,_Analysis_and_Reporting_Technology#Attributs_S.M.A.R.T._connus

*Estimations des temps de vie:*
https://www.extremetech.com/computing/170748-how-long-do-hard-drives-actually-live-for

#### Autre
Test en destruction écriture:
badblocks -wsv /dev/sdX > badblocks.txt

Test en lécture:
badblocks -nsv /dev/sdX > badblocks.txt

Réparation:
e2fsck -cfpv /dev/sdx  < badblocks.txt

Ou avec la commande fsck:
sudo fsck -C -t ext4 -l badblocks.txt /dev/sdxx

### Voir aussi le programme [Gsmartcontrol](https://gsmartcontrol.sourceforge.io/home/)
