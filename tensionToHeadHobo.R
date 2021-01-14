############################################################################
# This script takes processed tension from HZ measurements
# and converts it to head differential (treated data)
# using calibration U=f(T,H) 
############################################################################

<<<<<<< .mine
setwd('C:/Data/Bassin-Orgeval/Donnee_Orgeval_Mines/scripts_R')
||||||| .r137
setwd('C:/Users/Karina/Documents/01_Dossiers/01a_NumExp/minesSvn/data-hz/scripts_R')
=======
# setwd('C:/Users/Karina/Documents/01_Dossiers/01a_NumExp/minesSvn/data-hz/scripts_R')
>>>>>>> .r175

Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving

# ---- definition of paths ----

# path with tension measurements
pathProcessed = '../Avenelles/processed_data_KC/HZ/'
# path with description of measurements
pathDesc = '../Avenelles/raw_data/DESC_data/DATA_SENSOR/geometrieEtNotices_miniLomos/'
# path with calibration files of pressure sensors
pathCalib = paste0('../Avenelles/raw_data/DESC_data/DATA_SENSOR/',
                   'capteurs_pression/calibration/calib/')


# ---- get metadata for all points ----
metaDataFile <- paste0(pathDesc,'pointsHZ_metadonnees.csv')
metaData <- read.csv(file = metaDataFile,header = T,
                       sep = ',',dec = '.',colClasses = 'character')

# ---- loop over HZ points ----

namePoint = list.files(pathProcessed,pattern = 'point')

for (iPoint in 1:length(namePoint)){
  
  namePoint[iPoint]
  
  # process only if pressure data validated in metadata
  if(metaData[which(metaData$nom_du_point==namePoint[iPoint]),'donnees_p']==""){
    warning(paste0('Pressure data not validated for ',namePoint[iPoint],' in metadata. Skipping the conversion.'))
  }else if(metaData[which(metaData$nom_du_point==namePoint[iPoint]),'donnees_p']=='0'){
    warning(paste0('Pressure data unvalidated for ',namePoint[iPoint],' in metadata. Skipping the conversion.'))
  }else{
    
    # ---- get name of the pressure sensor use for HZ point namePoint[iPoint] ---- 
    pressureSensor <- metaData[which(metaData$nom_du_point==namePoint[iPoint]),'capteur_pression']
    print(as.character(pressureSensor))
    
    # ---- faire les correspondances pour les capteurs qui ont change de nom ----
    # selon l'excel de suivi des capteurs de pression
    ## p506 est l'ex p504
    if (pressureSensor=="p504") {pressureSensor <- "p506"}
    ## p508 est l'ex 501
    if (pressureSensor=="p501") {pressureSensor <- "p508"}
    ## p509 est l'ex 502
    if (pressureSensor=="p502") {pressureSensor <- "p509"}
    
    # process only if the pressure sensor is calibrated
    if(!(pressureSensor %in% c('p505','p506','p507','p508','p509','p520','p531','p532','p533','p534'))){
      warning(paste0('The pressure sensor for ',namePoint[iPoint],' not calibrated. Skipping the conversion.'))
    }else{
      
      print(paste0('applying calibration to point ',namePoint[iPoint]))
      
      # ---- get calibration parameters ----

      dataCalib <- 
        read.csv(paste0(pathCalib,pressureSensor,'/calibfit_',pressureSensor,'.csv'),
                 sep=';',header=F,colClasses=c('character','numeric'))
      paramCalibFit <- as.list(dataCalib[,2]);names(paramCalibFit) <- dataCalib[,1]
      
      # ---- get tension and temperature data ----
      
      #get name of pressure file - beginning with a p
      allFiles = list.files(paste0(pathProcessed,namePoint[iPoint]))
      tsFile = allFiles[which(substr(allFiles,1,1)=='p' & !grepl('treatedToHead',allFiles))]
      dataProcessed = read.csv(paste0(pathProcessed,'/',namePoint[iPoint],'/',tsFile),
                               header=T,sep=',',
                               colClasses=c('character','character','numeric','numeric'))
      
      # ---- use calibration U=f(T,H)  ----
      # in case where temperature is not measured (eg point-1_04_11_14)
      # not possible to apply this method
      if(all(is.na(dataProcessed$temperature_stream_C))){
        conversion_withT=F
        warning(paste0('Temperature-compensated conversion impossible for ',namePoint[iPoint],
                       ', no stream temperature data available. Skipping temperature-compensated conversion.'))
      }else{
        # U = k0 + k1 H + k2 T -> H = 1/k1 * (U - k0 - k2 T)
        conversion_withT=T
        tsTreated = 1/paramCalibFit$`dU/dH` * 
          (dataProcessed$pressure_differential_V - paramCalibFit$Intercept -
             paramCalibFit$`dU/dT` * dataProcessed$temperature_stream_C)
      }
      
      # ---- for comparison, also plot with no temperature correction ----
      # use calibration U=f(H)
      dataCalib = read.csv(paste0(pathCalib,pressureSensor,'/intermediate/',pressureSensor,'_calibUH.csv'),
                           sep=';',header=F,colClasses=c('character','numeric'))
      paramCalibFit=as.list(dataCalib[,2]);names(paramCalibFit) <- dataCalib[,1]
      # U = k0 + k1 H -> H = 1/k1 * (U - k0)
      tsTreated_noTcorrection = 1/paramCalibFit$`dU/dH` * (dataProcessed$pressure_differential_V - paramCalibFit$Intercept)
      
      # ---- save data ----
      # same folder, marked as treated in name
      
      # first save with temperature correction in calibration (if available)
      dataTreated = dataProcessed
      names(dataTreated) <- c('#','dates','pressure_differential_m','temperature_stream_C','')
      if(conversion_withT){
        dataTreated$pressure_differential_m = tsTreated
        write.table(dataTreated,
                    file=paste0(pathProcessed,namePoint[iPoint],
                                '/',unlist(strsplit(tsFile,split = '.csv')),
                                '_treatedToHead','.csv'),
                    dec='.',row.names=F,sep=',',quote = F)
      }
      # now save without temperature correction in calibration (for comparison)
      dataTreated$pressure_differential_m = tsTreated_noTcorrection
      write.table(dataTreated,
                  file=paste0(pathProcessed,namePoint[iPoint],'/',
                              unlist(strsplit(tsFile,split = '.csv')),
                              '_treatedToHead_noTcorrection','.csv'),
                  dec='.',row.names=F,sep=',',quote = F)
    }
    
  }
  
}

