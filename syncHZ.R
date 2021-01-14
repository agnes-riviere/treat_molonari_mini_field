# setwd('C:/Users/Karina/Documents/01_Dossiers/01a_NumExp/minesSvn/data-hz/scripts_R')

# ---- preliminaries ----

Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving
source('utils/functions_readHoboDates.R')

# ---- script parameters ----

namePoint = 'point20_28_10_15' # nom du point contenant les donnees a synchroniser

pathRawData = paste0('../Avenelles/raw_data/HOBO_data/',namePoint,'/')
path_nonSync = paste0(pathRawData,'non_sync/')

filesNonSync = list.files(path_nonSync,pattern = '.csv')

iFile=1

for(iFile in 1:length(filesNonSync)){
  
  rawData = read.csv(file = paste0(path_nonSync,filesNonSync[iFile]),
                     skip=2,sep=',',header = F,colClasses = 'character')
  
  # read non synchronized dates
  datesRawStr = formatHoboDate(rawData[,2])
  datesRaw = strptime(datesRawStr,format = '%d/%m/%Y %H:%M:%S')
  
  # calculate vector of new dates with timestepping of 15min
  # set next minute to 0, 15, 30 or 45
  firstMin=as.numeric(format(datesRaw[1],format = '%M'))
  startDate <- datesRaw[1];startDate$sec <- 0
  if(firstMin<=14){
    startDate$min <- 15
  }else if(firstMin<=29){
    startDate$min <- 30
  }else if(firstMin<=44){
    startDate$min <- 45
  }else{
    startDate$min <- 00; startDate <- startDate + as.difftime(1,units = 'hours')
  }
  datesSync = seq.POSIXt(from=startDate,by=15*60,length.out=length(datesRaw)-1)
  
  # interpolate values at new dates
  xRaw <- difftime(datesRaw,datesRaw[1],units="min")
  xSync <- difftime(datesSync,datesRaw[1],units="min")
  numSync <- array(0,dim = c(length(xSync),ncol(rawData)-2))
  for(iCol in 3:ncol(rawData)){
    numSync[,iCol-2] <- approx(x = xRaw,y=as.numeric(rawData[,iCol]),xout = xSync)$y
  }

  dataWrite=cbind(1:length(datesSync),format(datesSync,format = '%m/%d/%Y %H:%M:%S'),numSync)
  nameFileWrite = paste0(pathRawData,filesNonSync[iFile])
  write(readLines(paste0(path_nonSync,filesNonSync[iFile]))[1:2],
        file=nameFileWrite)
  write.table(dataWrite,sep=',',file = nameFileWrite,
              quote=F,row.names = F,append = T,col.names = F)
  
}
