############################################################################
# This script plot treated data for HZ points
# takes processed temperature from Avenelles/processed_data_KC/HZ/[point]
# plots in plots/PerDevice/Hobo/TREATED[point]
############################################################################

setwd('C:/Data/Bassin-Orgeval/Donnee_Orgeval_Mines/scripts_R')

Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving

# path with treated measurements
pathProcessed = paste0('../Avenelles/processed_data_KC/HZ/')
# path with description of measurements
pathDesc = '../Avenelles/raw_data/DESC_data/DATA_SENSOR/geometrieEtNotices_miniLomos/'
# path to plot data
pathPlot = '../plots/PerDevice/Hobo/'

# ---- read metaData ----

metaDataFile <- paste0(pathDesc,'/pointsHZ_metadonnees.csv')
metaData <- read.table(file = metaDataFile,header = T,quote='',sep = ',',dec = '.',colClasses = 'character')
# get idx of columns containing depths of temperature probes
idx_T_depth <- grep(pattern = 'T_depth',x = names(metaData))

# ---- loop over HZ points ----

namePoint = list.files(pathProcessed,pattern = 'point')

for (iPoint in 1:length(namePoint)){
  
  # empty workspace
  allObjects=ls()
  objectsKeep = c('pathProcessed','pathDesc','pathPlot','metaData','idx_T_depth','namePoint','iPoint')
  objectsDel= allObjects[which(!(allObjects %in% objectsKeep))]
  rm(list=objectsDel)
  
  # check if temperature-compensated conversed timeseries exists
  # enter the plotting loop only if head differential is available
  fileP = paste0('p_',namePoint[iPoint],'_treatedToHead.csv')
  if(file.exists(paste0(pathProcessed,'/',namePoint[iPoint],'/',fileP))){
    
    print(paste0('plotting ',namePoint[iPoint],' (iPoint=',iPoint,')'))
    
    # ---- import head differential data ----
    
    dataP = read.csv(paste0(pathProcessed,namePoint[iPoint],'/',fileP),
                     header=T,sep=',',
                     colClasses=c('character','character','numeric','numeric'))
    
    # ---- import temperature data ----
    fileT = paste0('t_',namePoint[iPoint],'.csv')
    
    # enter the loop only if temperature data available
    if(file.exists(paste0(pathProcessed,'/',namePoint[iPoint],'/',fileT))){
      dataT = read.csv(paste0(pathProcessed,namePoint[iPoint],'/',fileT),
                       header=T,sep=',',
                       colClasses=c(rep('character',2),rep('numeric',4)))
      
      # create vector of depths
      # keeping only depths corresponding to existing values in dataT
      ## read depths
      depthsCm_temp <- metaData[which(metaData$nom_du_point==namePoint[iPoint]),idx_T_depth]
      ## keep indices corresponding to effectively measured timeseries
      idxKeep = rep(F,length=length(depthsCm_temp))
      for (j in 1:length(depthsCm_temp)){
        if(any(grepl(j,names(dataT)))){idxKeep[j]=T}
      }
      depthCm = depthsCm_temp[idxKeep]
    }
    
    # ---- plot raw data ----
    
    temperatureCols = c('blue',terrain.colors(6))
    
    png(file = paste0(getwd(),'/../plots/PerDevice/Hobo/TREATED',namePoint[iPoint],'.png'),
        width=1200,height=1000,res=150)
    
    # find common date ranges
    if(exists('dataP')){dates_P = strptime(dataP$dates,'%d/%m/%Y %H:%M:%S')}else{dates_P=NULL}
    if(exists('dataT')){dates_T = strptime(dataT$dates,'%d/%m/%Y %H:%M:%S')}else{dates_T=NULL}
    if(exists('dataP')){
      if(exists('dataT')){datesRange=range(dates_P,dates_T,na.rm = T)}else{datesRange=range(dates_P,na.rm = T)}
    }else{datesRange=range(dates_T,na.rm = T)}
    
    # start plotting
    par(mar=c(5,5,4,5)+0.1)
    
    # plot head differential measurements if exist
    if(exists('dataP')){
      plot(x=dates_P[!is.na(dataP$pressure_differential_m)],
           y=dataP$pressure_differential_m[!is.na(dataP$pressure_differential_m)],
           type='l',main=namePoint[iPoint],
           xlab='dates',ylab='head differential [m]',xaxt='n',lwd=1.5,
           xlim=as.POSIXct(datesRange))
    }else{
      plot(x=dates_T,y=rep(NA,length(dates_T)),
           type='l',main=namePoint[iPoint],
           xlab='dates',ylab='head differential [m]',xaxt='n',lwd=1.5,
           xlim=as.POSIXct(datesRange))
    }
    axis.POSIXct(side = 1,at = pretty(datesRange),format='%d/%m/%Y')
    abline(v=pretty(datesRange),col='grey',lty=2)
    
    # plot temperature measurements
    par(new=T)
    # get range of temperature variations in stream
    if(exists('dataP')){ylimP=range(dataP$temperature_stream_C,na.rm = T)}else{ylimP=NULL}
    # get range of temperature variations in subsurface
    if(exists('dataT')){
      jTemperature = which(grepl('temperature.depth',names(dataT))) #get columns of temperature
      ylimT = range(dataT[,jTemperature],na.rm=T)
    }else{ylimT=NULL}
    # define final range of temperature
    ylimPT=range(c(ylimP,ylimT),na.rm = T)
    ylimMin = max(0,ylimPT[1])
    ylimMax = min(30,ylimPT[2])
    # if exists, plot temperature in stream
    if(exists('dataP')){
      plot(x=dates_P[!is.na(dataP$temperature_stream_C)],
           y=dataP$temperature_stream_C[!is.na(dataP$temperature_stream_C)],
           ylim=c(ylimMin,ylimMax),
           xaxt='n',yaxt='n',xlab='',ylab='',
           col=temperatureCols[1],type='l',lwd=1.5,xlim=as.POSIXct(datesRange))
    }else{ # otherwise define empty plot
      plot(x=dates_T,y=rep(NA,length(dates_T)),
           ylim=c(ylimMin,ylimMax),
           xaxt='n',yaxt='n',xlab='',ylab='',
           col=temperatureCols[1],type='l',lwd=1.5,xlim=as.POSIXct(datesRange))
    }
    # define temperature axis
    axis(4)
    mtext('temperature [C]',side=4,line=3)
    # plot temperature in the subsurface
    if(exists('dataT')){
      for (j in jTemperature){ 
        lines(x=dates_T[!is.na(dataT[,j])],y=dataT[,j][!is.na(dataT[,j])],
              col = temperatureCols[j-jTemperature[1]+2],lwd=1.5)
      }
    }
    
    # final arrangements
    abline(h=seq(from=as.integer(ylimMin),to=as.integer(ylimMax)+1,by=0.2),
           col='grey',lty=2)
    if(file.exists(paste0(pathProcessed,'/',namePoint[iPoint],'/',fileT))){
      legend('topleft',legend = c(expression(Delta*'H'),
                                  'T stream',
                                  paste0('T ', depthCm,'cm')),
             col=c('black',temperatureCols[1:5]),pch=19,bg='white')
    }else{
      legend('topleft',legend = c(expression(Delta*'H')),
             col=c('black'),pch=19,bg='white')
    }

    # close connection
    dev.off()
    
  }
  
}

