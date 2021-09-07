
Traitement des donnees HZ (Molonari-mini)
========================
The purpose of this script is to process the field data and to transform the pressure differences recorded in volt into cm
The scripts are in order that they should be executed.
Il est nécessaire d'avoir télécharger en amont  calibration_molonari_mini dans lequel est contenu calib et scripts_R

Les données de terrain doivent être stockées dans treat_molonari_mini_field/raw_data/HOBO_data/
treat_molonari_mini_field/raw_data/HOBO_data/

# 1) geometrieEtNotices_miniLomos

Compléter le fichier pointsHZ_metadonnees.csv avec :
* nom_du_point;
* index_du_point;
* GPS_N;
* GPS_E;
* donnees_p; si les données existent mettre 1 sinon 0
* donnees_t; si les données existent mettre 1 sinon 0
* donnees_tstream; si les données existent mettre 1 sinon 0
* donnees_all; si les données existent mettre 1 sinon 0
* capteur_pression;
* P_depth_cm;
* T_depth_1_cm;
* T_depth_2_cm;
* T_depth_3_cm;
* T_depth_4_cm;
* date_debut_model;
* date_debut_calib;
* date_fin;
* commentaires

L'entête du fichier doit être : nom_du_point;index_du_point;GPS_N;GPS_E;donnees_p;donnees_t;donnees_tstream;donnees_all;capteur_pression;P_depth_cm;T_depth_1_cm;T_depth_2_cm;T_depth_3_cm;T_depth_4_cm;date_debut_model;date_debut_calib;date_fin;commentaires

# 2) syncHZ.R **a utiliser en cas de problème sur le terrain de syncronisation des données.**
Ce script peut etre lance si la configuration des hobo a mal ete faite sur le terrain.
Il sert a recuperer des donnee a un intervalle de temps de 15min sur les quarts d'heures réguliers des heures, de maniere a ce que les donnees de pression et de température soient synchrones.

# 3) processHobo_mini.R
lit les donnees HZ (mini-Lomos)
fait un premier traitement des donnees et enregistre dans processed_data_KC/

# 4) tensionToHead.R
1) pointsHZ_metadonnees.csv à compléter dans geometrieEtNotices_miniLomos
2) Vérifier que le capteur de pression est bien calibre dans le répertoire calib
vous devez avoir calibfit_sensorname.csv avec trois lignes 
			* Intercept;xxxxxx
			* dU/dH;xxxxxxx
			* dU/dT;xxxxxxxxxxxxx
3) si vous utilise un nouveau capteur vous devez suivre la procedur de calibration et de mise en place des dossier
De plus, vous devez ajouter le nom du capteur dans la ligne 53 du script R tensionToHead.R
ce script sert a transformer les donnees de tension mesurees par le capteur de pression en differentiel de charge.
Il lit les coefficients de calibration dans calibration_molonari_mini/calib

# 5. plotHoboTreated.R
*plot les donnees traitees des Hobos HZ.
*Prend en argument les fichiers treated dans **treat_molonari_mini_field/processed_data[point]**
*Produit le plot dans **plots/TREATED[point]**
