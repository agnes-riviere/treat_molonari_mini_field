
Treatment of the hyporheic zone data (mini LOMOS)
========================
With the help of this script, the field data will be processed, and the pressure differences measured in volts will be converted to centimeters. It treats the field data of the mini LOMOS such as the pressure differential, the stream temperature, and the hyporheic zone temperature profiles. 
The scripts are in the correct order for execution. You must have calib and scripts R from the calibration molonari mini download.


It is necessary to store the raw field data in the repository: 'treat_molonari_mini_field/raw_data/HOBO_data'




# required R libraries:

library(tidyverse)
library(lubridate)
library(data.table)
library(lmtest)
library(stats)
library(ggplot2)

# 1) geometrieEtNotices_miniLomos

Adding the following fields to the file "pointsHZ metadonnees.csv":

* Point identification 

* index of points 

* GPS_N coordinates;

* GPS_E coordinates; 

* data_p; if data of the pressure diffential exist, set 1; otherwise, set 0. 
* data_t; if data of the hyporheic zone temperature profile exists, set 1; otherwise, set 0. 
* donata_tstream; if data of the river temperature exist, set 1; otherwise, set 0. 
* data_all; if all  data sets exist, set 1; otherwise, set 0. 
* pressure sensor;
* P_depth_cm; 
* T_depth_1_cm; 
* T_depth_2_cm; 
* T_depth_3_cm; 
* T_depth_4_cm; 
* date_begin_model: This date is not used, but it could be if we want to optimize the ginette application "mini_LOMOS"; 
* date_begin_calib: This date is not used, but it could be if we want to optimize the ginette application 'mini_LOMOS;
* date_end: This date is not used, but it could be if we want to optimize the ginette application 'mini_LOMOS;
* field comments

The file header must contain the following: nom_du_point;index_du_point;GPS_N;GPS_E;donnees_p;donnees_t;donnees_tstream;donnees_all;capteur_pression;P_depth_cm;T_depth_1_cm;T_depth_2_cm;T_depth_3_cm;T_depth_4_cm;date_debut_model;date_debut_calib;date_fin;commentaires

# 2) ** If there is a problem with data synchronization between the hyporheic zone and the stream, use the syncHZ.R script. **
This script may be executed if the hobo configuration is incorrectly set up during field work.. 
Its purpose is to retrieve data at 15-minute intervals at regular quarter-hour intervals, synchronizing pressure and temperature data. 


# 3) processHobo_mini.R
This script reads the raw field data collected with the mini-Lomos sensing device. It performs a preliminary data processing and stores the results in the "processed_data" directory. 


# 4) tensionToHead.R

This script is used to convert tension readings from a pressure sensor into charge differentials. 
The script uses the calibration coefficients found in the 'calibration molonari mini/calib' directory.
1) Verify that the file "pointsHZ metadonnées.csv" in the "geometrieEtNotices miniLomos" repository is complete. 
2) Check that the pressure sensor is properly calibrated in the calibration database. 
The file 'calibfit sensorname.csv' must contain these three lines:: 

* Intercept;xxxxxx
* dU/dH;xxxxxxx
 * dU/dT;xxxxxxxxxxxxx
3) If you are using a new sensor, you must follow the calibration and installation procedures. 
# 5. plotHoboTreated.

The R script plots measurements of pressure and temperature. It uses the treated files in the **treat_molonari_minifield/processed_data** repository as its argument. 
* It produces plots in the "plots/TREATED[point]** repertory




#6. special_treat_remove_temperature_effect.R


This script could be utilized if the pressure differential data are not temperature-corrected. The most significant issue may stem from the calibration measurements. To utilize this script, you must provide the path setwd ("/home/ariviere/Programmes/treat_molonari_mini_field/') and the name of the point sensor=. All plots are contained in the "plot" directory, while the "processed data" directory contains the corrected data.




The script fits the linear regression model of pressure as a function of temperature data. 



It calculates the residual time series and plots the residuals (the difference between the observed and predicted values). It can  help you check if the errors are randomly distributed and have constant variance. If the residuals are randomly dispersed around zero, it is an indication that the linear model is appropriate.


To check the normality of the residuals, it creates a histogram of the residuals and a normal probability plot (Q-Q plot) to check if the residuals are normally distributed.  

Linear regression models assume that the residuals are normally distributed. To check this assumption, a histogram of the residuals is plotted and/or a normal probability plot (also known as a Q-Q plot) is created. If the residuals are normally distributed, the points on the normal probability plot will fall close to a straight line.

Outliers can have a substantial impact on linear regression models. A scatterplot of the residuals is created to identify any anomalous points.

 Linear regression models assume that the residuals are not correlated. 
To  check for autocorrelation, a scatterplot of the residuals is created against the order of observations or by using the Ljung-Box test for autocorrelation.





Linear regression models assume that the relationship between the independent and dependent variables is linear. You can check for linearity by creating a scatterplot of the independent variable and dependent variable and checking if the points fall roughly along a straight line.









