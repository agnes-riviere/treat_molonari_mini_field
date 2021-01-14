############################################################################
# This script arranges the temperature for HZ points
# takes processed temperature as input data
# shifts the temperature timeseries
############################################################################
# marche uniquement pour le point 8 pour l'instant

setwd('C:/Data/Bassin-Orgeval/Donnee_Orgeval_Mines/scripts_R')

Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving

##########
# function to eailsy plot temperature timeseries
temperatureCols = c('blue',terrain.colors(6))
plotFun = function(){
  xDays = 1:length(tempSurf)/(4*24)
  plot(x=xDays,y=tempSurf,col=temperatureCols[1],type='l',
       xlab='time [days]',ylim=c(15.5,18.5))
  for (i in 1:4){
    lines(x=xDays,y=tempSout[,i],col=temperatureCols[i+1])
  }
  legend('topright',legend=c(0,0.15,0.30,0.45,0.60),col=temperatureCols,
         lty=1,title='depths [m]',bg='white',ncol=2)
}
##########

# path with tension measurements
pathProcessed = '../Avenelles/processed_data_KC/HZ/point8_09_07_15/'
# path with description of measurements
pathDesc = '../Avenelles/raw_data/DESC_data/DATA_SENSOR/IntD_02_07_15/Point8/'
# path with calibration files of pressure sensors
pathCalib = '../Avenelles/raw_data/DESC_data/DATA_SENSOR/capteurs_pression/Calibration/'

allFiles = list.files(pathProcessed)
fileP = allFiles[which(substr(allFiles,1,1)=='p' & !grepl('treatedToHead',allFiles))]
fileT = allFiles[which(substr(allFiles,1,1)=='t' & !grepl('treated',allFiles))]
dataP = read.csv(paste0(pathProcessed,fileP),
                 header=T,sep=',',
                 colClasses=c('character','character','numeric','numeric'))
tempSurf = dataP[,4]
dataT = read.csv(paste0(pathProcessed,fileT),
                 header=T,sep=',',
                 colClasses=c(rep('character',2),rep('numeric',4)))
tempSout = dataT[,3:6]

tempSout[,1] <- NA
tempSout[,2] <- tempSout[,2] - 1.25
tempSout[325:355,2] <- NA
# plotFun()

# complete with NA
# improve that later
idxNa = c(325,355)
tempSout[idxNa[1]:idxNa[2],2] <- approx(x = c(idxNa[1]-1,idxNa[2]+1),
                            y = tempSout[c(idxNa[1]-1,idxNa[2]+1),2],
                            xout = idxNa[1]:idxNa[2])$y

# plotFun()
for(i in 1:4){
  dataT[,i+2] <- tempSout[,i]
}
# do not write depth 15 cm that I deleted
dataT$temperature.depth.1..C. <- NULL
write.table(dataT,
            file=paste0(pathProcessed,unlist(strsplit(fileT,split = '.csv')),'_treated','.csv'),
            dec='.',row.names=F,sep=',',quote = F)

