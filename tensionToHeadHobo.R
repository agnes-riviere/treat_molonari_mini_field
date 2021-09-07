############################################################################
# This script takes processed tension from HZ measurements
# and converts it to head differential (treated data)
# using calibration U=f(T,H) 
############################################################################

setwd('/home/ariviere/Programmes/treat_molonari_mini_field/')
library(lubridate)
library(data.table)

Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving

# ---- definition of paths ----


#path to store processed data
pathProcessed=paste0(getwd(),'/processed_data/')
# path with description of measurements
pathDesc = 'geometrieEtNotices_miniLomos/'
# path with calibration files of pressure sensors
pathCalib = paste0('/home/ariviere/Programmes/calibration_molonari_mini/calib/')


# ---- get metadata for all points ----
metaDataFile <- paste0(pathDesc,'pointsHZ_metadonnees.csv')
metaData <- read.csv(file = metaDataFile,header = T,
                       sep = ';',dec = '.',colClasses = 'character')

# ---- loop over HZ points ----

namePoint = list.files(pathProcessed,pattern = 'p')

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

      
      print(paste0('applying calibration to point ',namePoint[iPoint]))
      
      # ---- get calibration parameters ----

      dataCalib <- 
        read.csv(paste0(pathCalib,pressureSensor,'/calibfit_',pressureSensor,'.csv'),
                 sep=',',header=F,colClasses=c('character','numeric'))
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
  
  # ---- plot raw data ----
  
  temperatureCols = c('blue',terrain.colors(6))
  tsFileT = allFiles[which(substr(allFiles,1,1)=='t')]
  dataProcessedT = read.csv(paste0(pathProcessed,'/',namePoint[iPoint],'/',tsFileT),
                            header=T,sep=',',
                            colClasses=c('character','character','numeric','numeric','numeric','numeric'))
  
  png(file = paste0(getwd(),'/plots/CLEAN',listHobo[i],'.png'),
      width = 1000,height=700)
  dates_i = strptime( dataTreated$dates,'%d/%m/%Y %H:%M:%S')
  plot(x=dates_i,y=  tsTreated,
       pch=19,cex=0.3,ylim=range(dataTreated$pressure_differential_m,na.rm=T),
       main=listHobo[i],xlab='dates',ylab='Delta H [m]',xaxt='n',col="red")
  points(x=dates_i,y=  tsTreated_noTcorrection,
         pch=19,cex=0.3)
  axis.POSIXct(side = 1,at = pretty(dates_i),format='%d/%m/%Y')
  par(new=T)
  ylimRaw = range(data.frame(dataProcessedT[,3:6],dataTreated$temperature_stream_C),na.rm=T)
  ylimMin = max(0,ylimRaw[1])
  ylimMax = min(25,ylimRaw[2])
  plot(x=dates_i,y=rep(NA,length=length(dates_i)),
       ylim=c(ylimMin,ylimMax),
       xaxt='n',yaxt='n',xlab='',ylab='',
       col='red',pch=19,cex=0.3)
  points(x=dates_i,y=dataTreated$temperature_stream_C,pch=19,cex=0.3,
         col=temperatureCols[1])
  for (j in 3:7){
    points(x=dates_i,y=dataProcessedT[,j],pch=19,cex=0.3,
           col=temperatureCols[j])
  }
  axis(4)
  mtext('temperature [C]',side=4,line=3)
  
  
  legend('bottomright',legend = c('pressure differential','pressure differential_no_T',
                                  'temperature in the stream',
                                  paste('temperature depth', 1:4)),
         col=c('red','black',temperatureCols[1:5]),pch=19)
  
dev.off()  
}





