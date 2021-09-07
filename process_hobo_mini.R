setwd('/home/ariviere/Programmes/treat_molonari_mini_field/')
library(lubridate)
Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving
boolPlotPerDevice=T

# ---- functions for date formating ----
source('utils/functions_readHoboDates.R')

#---- get names of stations ----

#path where raw data is stored
pathRawData=paste0(getwd(),
                   '/raw_data/HOBO_data/')
#path to store processed data
pathProcessedData=paste0(getwd(),'/processed_data')
  
  
# listHobo contient la liste de tous les dossiers dans raw_data/HOBO_data
# ces Hobos sont ? la fois ceux des LOMOS et ceux des points HZ
listHobo = list.files(pathRawData)[!grepl('invalid',list.files(pathRawData))]
  
  ##########################---- process data ----
    
    allMeas = list()
  listHobo=subset(listHobo, grepl("^p", listHobo), drop = TRUE)
  for (i in 1:length(listHobo)){
    
    # cat(paste0('\nExtracting data from hobo ',listHobo[i],' (i=',i,')'))
    pathHobo = paste0(pathRawData,listHobo[i],'/')
    listFiles = list.files(pathHobo,pattern='.csv')
    datesStr_i = NULL 
    for (j in 1:length(listFiles)){
      # premiere boucle pour exclure les hobo des MOLONARI perennes
      cat(paste0('\nExtracting data from hobo ',listHobo[i],' (i=',i,')'))
      cat(paste('\nExtracting dates from file:',listFiles[j]))
      fileHobo = paste0(pathHobo,listFiles[j])
      dataHobo_0 = read.csv(fileHobo,colClasses = 'character',sep=',',strip.white = T)
      if(ncol(dataHobo_0)==1){
        dataHobo_0 = read.csv(fileHobo,colClasses = 'character',sep=';',strip.white = T)
      }
      # read dates from file
      dates_Hobo_ij = formatHoboDate(dataHobo_0[,2])
      # now the dates are under the string format %d/%m/%Y %H:%M:%S
      if(is.na(min(dates_Hobo_ij))==T)       {  dates_Hobo_ij= as.character(dmy_hms(dataHobo_0[,2]),'%d/%m/%Y %H:%M:%S') }
      datesStr_i=c(datesStr_i,dates_Hobo_ij)
    }
    
    # sort and keep uniques
    dates0 = unique(datesStr_i)
    dates1=strptime(dates0,'%d/%m/%Y %H:%M:%S')
    dates1Diff=difftime(dates1,dates1[1],units="mins")
    dates=as.character(dates1[order(dates1Diff)],'%d/%m/%Y %H:%M:%S')  
    if(is.na(min(formatHoboDate(dataHobo_0[,2])))==T)       {  dates= as.character(dmy_hms(dataHobo_0[,2]),'%d/%m/%Y %H:%M:%S') }
    # differential pressure (in volts)
    # temperature at bottom of the stream
    # temperatures at depths 1 to 8
    dataHobo = array(NA,dim = c(length(dates),10))
    colnames(dataHobo) <- c('pressure_differential_V','temperature_stream_C',
                            paste0('temperature_depth_',1:8, '_C'))
    
    
    for (j in 1:length(listFiles)){
      if (substring(listHobo[i],1,3)!="Hob") {
        cat(paste('\nExtracting data from file:',listFiles[j]))
        fileHobo = paste0(pathHobo,listFiles[j])
        dataHobo_0 = read.csv(fileHobo,colClasses = 'character',sep=',',strip.white = T) 
        if(ncol(dataHobo_0)==1){
          dataHobo_0 = read.csv(fileHobo,colClasses = 'character',sep=';',strip.white = T)
        }
        
        # find dates corresponding to file
        dates_Hobo_ij = formatHoboDate(dataHobo_0[,2])
        
        datesStr_ij=as.character(dates_Hobo_ij,'%d/%m/%Y %H:%M:%S')
        # now the dates are under the string format %d/%m/%Y %H:%M:%S
        if(is.na(min(datesStr_ij))==T)       { datesStr_ij= as.character(dmy_hms(dataHobo_0[,2]),'%d/%m/%Y %H:%M:%S') }
        idxToFill = match(datesStr_ij,dates) #find indices of dates corresponding to elements of datesStr_ij
        # incorporate in dataHobo_i
        
        temperature_Hobo = dataHobo_0[,grepl('Temp',names(dataHobo_0))]
        pression_Hobo = data.matrix(dataHobo_0[,grepl('Volt',names(dataHobo_0)) | grepl('Tension',names(dataHobo_0))])
        if(ncol(pression_Hobo)==1){ # if there are pressure differential measurements
          dataHobo[idxToFill,1] <- pression_Hobo
          if(ncol(data.matrix(temperature_Hobo))==1){ # in that case it is temperature in the bottom of the river
            dataHobo[idxToFill,2] <- temperature_Hobo
          }
        }else if (grepl('bas',listFiles[j])){
          for(icol in 1:ncol(temperature_Hobo)){
            dataHobo[idxToFill,6+icol] <- temperature_Hobo[,icol]
          }
        }else {
          for(icol in 1:ncol(temperature_Hobo)){
            dataHobo[idxToFill,2+icol] <- temperature_Hobo[,icol]
          }
        }
        
      }
    }
    
    class(dataHobo) <- 'numeric'
    
    # take out lines of NAs
    IndsNA = which(rowSums(is.na(dataHobo))==ncol(dataHobo)) 
    # take out lines of NAs
    IndsNA = which(rowSums(is.na(dataHobo))==ncol(dataHobo))
    if(length(IndsNA)>0){
      dataHobo <- dataHobo[-IndsNA,]
      dates <- dates[-IndsNA]
    }
    # take out values of temperature <0 or >35
    idx = which(dataHobo[,3:10] > 30 | dataHobo[,3:10] < 0 ,arr.ind = T)
    if(length(idx)>0){
      dataHobo[,3:10][idx] <- NA
    }
    
    allMeas[[i]] <- data.frame(dates=dates,dataHobo=dataHobo)
    colnames(allMeas[[i]]) <- c('dates',colnames(dataHobo))
    
  }
  
  # ---- plot raw data ----
  
  temperatureCols = c('blue',terrain.colors(6))
  
  
  if(boolPlotPerDevice){
    for (i in 1:length(listHobo)){
      if (substring(listHobo[i],1,3)!="Hob") {
        png(file = paste0(getwd(),'/plots/RAW',listHobo[i],'.png'),
            width = 1000,height=700)
        dates_i = strptime(allMeas[[i]]$dates,'%d/%m/%Y %H:%M:%S')
        indNonEmpty = as.numeric(which(colSums(!is.na(allMeas[[i]]))!=0))
        if (2 %in% indNonEmpty & !(3 %in% indNonEmpty)){ #in that case there is a differential pressure time series
          plot(x=dates_i,y=allMeas[[i]][,2],
               pch=19,cex=0.3,ylim=range(allMeas[[i]][,2],na.rm=T),
               main=listHobo[i],xlab='dates',ylab='pressure differential [V]',xaxt='n')
          axis.POSIXct(side = 1,at = pretty(dates_i),format='%d/%m/%Y')
        }else if (2 %in% indNonEmpty & 3 %in% indNonEmpty){
          par(mar=c(5,5,4,5)+0.1)
          plot(x=dates_i,y=allMeas[[i]][,2],main=listHobo[i],
               ylim=range(allMeas[[i]][,2],na.rm=T),
               xlab='dates',ylab='pressure differential [V]',
               xaxt='n',pch=19,cex=0.3)
          axis.POSIXct(side = 1,at = pretty(dates_i),format='%d/%m/%Y %H:%M')
          par(new=T)
          ylimRaw = range(allMeas[[i]][,3:7],na.rm=T)
          ylimMin = max(0,ylimRaw[1])
          ylimMax = min(25,ylimRaw[2])
          plot(x=dates_i,y=rep(NA,length=length(dates_i)),
               ylim=c(ylimMin,ylimMax),
               xaxt='n',yaxt='n',xlab='',ylab='',
               col='red',pch=19,cex=0.3)
          for (j in 3:11){
            points(x=dates_i,y=allMeas[[i]][,j],pch=19,cex=0.3,
                   col=temperatureCols[j-2])
          }
          axis(4)
          mtext('temperature [C]',side=4,line=3)
        }else{
          ylimRaw = range(allMeas[[i]][,3:7],na.rm=T)
          ylimMin = max(0,ylimRaw[1])
          ylimMax = min(25,ylimRaw[2])
          plot(x=dates_i,y=rep(NA,length=length(dates_i)),
               pch=19,cex=0.3,ylim=c(ylimMin,ylimMax),
               main=listHobo[i],xlab='dates',ylab='temperature [C]',xaxt='n')
          axis.POSIXct(side = 1,at = pretty(dates_i),format='%d/%m/%Y')
          for (j in 3:7){
            points(x=dates_i,y=allMeas[[i]][,j],pch=19,cex=0.3,
                   col=temperatureCols[j-2])
          }
        }
        legend('topright',legend = c('pressure differential',
                                     'temperature in the stream',
                                     paste('temperature depth', 1:4)),
               col=c('black',temperatureCols[1:5]),pch=19)
        
        dev.off()
      }
    }
  }
  
  # ---- save in csv files ----
  StationNames=listHobo
  for (i in 1:length(listHobo)){
    if (substring(listHobo[i],1,3)!="Hob") { 
      print(i)
      
      pathExportDir = pathProcessedData
      if(!file.exists(pathExportDir)){dir.create(pathExportDir)}
      if(!file.exists(paste0(pathExportDir,'/',StationNames[i]))){
        dir.create(paste0(pathExportDir,'/',StationNames[i]))
      }
      pathExportStation = paste0(pathExportDir,'/',StationNames[i],'/')
      
      dataMatrix = allMeas[[i]]
      dataMatrix[,1] <- as.character(allMeas[[i]]$dates,'%d/%m/%Y %H:%M:%S')
      dataMatrix = cbind('#'=1:nrow(dataMatrix),dataMatrix,rep('',nrow(dataMatrix)))
      colnames(dataMatrix) <- c(colnames(dataMatrix)[1:12],'')
      dataMatrix[is.na(dataMatrix)] <- ''
      

        if(!file.exists(paste0(pathExportStation,listHobo[i]))){
          if(!file.exists(pathExportStation)) { dir.create(paste0(pathExportStation))}
        }
        # write pressure file, starting with letter p
        whichColsNonEmpty = c(which(colSums(dataMatrix == '') != nrow(dataMatrix)),13) # ajout de la derniere colonne pour virgule a la fin
        if(sum(c(3,4) %in% whichColsNonEmpty) > 0){
          write.table(dataMatrix[,c(1:4,13)],
                      file=paste0(pathExportStation,'p_',listHobo[i],'.csv'),
                      dec='.',row.names=F,sep=',',quote = F)
        }
        # write temperature file, starting with letter t
        # check which columns are non-empty
        # write only columns corresponding to temperature and non-empty
        if(sum(5:10 %in% whichColsNonEmpty) > 0){
          write.table(dataMatrix[,intersect(whichColsNonEmpty,c(1:2,5:10,13))],
                      file=paste0(pathExportStation,'t_',listHobo[i],'.csv'),
                      dec='.',row.names=F,sep=',',quote = F)
        }
      
    }
  }
  
  