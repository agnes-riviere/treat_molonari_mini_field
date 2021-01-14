# treat_molonari_mini_field
Traitement des donnees HZ (Molonari-mini)
========================
The purpose of this script is to process the field data and to transform the pressure differences recorded in volt into cm
The scripts are in order that they should be executed.

syncHZ.R
-
	Ce script peut etre lance si la configuration des hobo a mal ete faite sur le terrain.
	Il sert a recuperer des donnee a un intervalle de temps de 15min sur les quarts d'heures réguliers des heures.
	de maniere a ce que les donnees de pression et de température soient synchrones.

processHobo_mini.R
-
	lit les donnees HZ (mini-Lomos)
	fait un premier traitement des donnees et enregistre dans Avenelles/processed_data_KC/

treatTempHobo.R
-
	MOVED TO POSTPROCESSING FOLDERS : 01a_NumExp\field_database\1_data-hz_to_ginette\scripts_R
	ce script sert a traiter les donnees de temperature.

tensionToHead.R
-
		1) pointsHZ_metadonnees.csv à compléter dans \raw_data\DESC_data\DATA_SENSOR\geometrieEtNotices_miniLomos
		2) Vérifier que le capteur de pression est bien calibre dans raw_data\DESC_data\DATA_SENSOR\capteurs_pression\calibration\calib
		vous devez avoir calibfit_sensorname.csv avec trois lignes 
			Intercept;xxxxxx
			dU/dH;xxxxxxx
			dU/dT;xxxxxxxxxxxxx
		3) si vous utilise un nouveau capteur vous devez suivre la procedur de calibration et de mise en place des dossier
			De plus, vous devez ajouter le nom du capteur dans la ligne 53 du script R tensionToHead.R
	
	ce script sert a transformer les donnees de tension mesurees par le capteur de pression en differentiel de charge.
	Il lit les coefficients de calibration dans Avenelles/raw_data/DESC_data/DATA_SENSOR/Calibration/calib/

plotHoboTreated.R
-

	plot les donnees traitees des Hobos HZ.
	Prend en argument les fichiers treated dans Avenelles/processed_data_KC/HZ/[point]
	Produit le plot dans plots/PerDevice/Hobo/TREATED[point]
