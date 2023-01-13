# Load required libraries
library(tidyverse)
library(lubridate)
library(data.table)
library(lmtest)
library(car)
library(stats)
library(forecast)
library(ggplot2)


Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving

# ---- definition of paths ----
setwd('/home/ariviere/Programmes/treat_molonari_mini_field/')


Sys.setenv(TZ='UTC') # to avoid the problem of daylight saving
#path to store processed data
pathProcessed=paste0(getwd(),'/processed_data/')
# path with description of measurements
pathDesc = 'geometrieEtNotices_miniLomos/'
# path with calibration files of pressure sensors
pathCalib = paste0('../calibration_molonari_mini/calib/')

# path to plot data
pathPlot = '/plots/'

# ---- read metaData ----
# ---- get metadata for all points ----
metaDataFile <- paste0(pathDesc,'pointsHZ_metadonnees.csv')
metaData <- read.csv(file = metaDataFile,header = T,
                     sep = ';',dec = '.',colClasses = 'character')

# ---- loop over HZ points ----

namePoint = list.files(pathProcessed,pattern = 'p')

iPoint=1

print(namePoint[iPoint])
# empty workspace
allObjects=ls()
objectsKeep = c('pathProcessed','pathDesc','pathPlot','metaData','idx_T_depth','namePoint','iPoint')
objectsDel= allObjects[which(!(allObjects %in% objectsKeep))]
rm(list=objectsDel)
# Load data
fileP = paste0('p_',namePoint[iPoint],'_treatedToHead.csv')
dataP = fread(paste0(pathProcessed,namePoint[iPoint],'/',fileP),
                 header=T,sep=',')
dataP$dates<- strptime(dataP$dates, format="%d/%m/%Y %H:%M:%S")
dataP$dates<-dmy_hms(dataP$dates)


# Merge the data
data <- data.table(dataP$dates,dataP$pressure_differential_m,dataP$temperature_stream_C)

names(data)<-c('dates','pressure','temperature')
data <-data[complete.cases(dates), ]



# Convert date column to POSIXct format
data$dates <- as.POSIXct(data$dates)
# Extract day and month of the data
data$day <- day(data$dates)
data$month <- month(data$dates)
data$time_since_start <- data$date - min(data$date)
data$hour <- hour(data$date)


# Fit the linear regression model
model <- lm(pressure ~ temperature, data = data)

summary(model)

# Obtain the predicted pressure values
data$predicted_pressure <- predict(model, newdata = data)

# Calculate the residual time series
#Plotting the residuals (the difference between the observed and predicted values) 
#can help you check if the errors are randomly distributed and have constant variance. 
#If the residuals are randomly dispersed around zero, it is an indication that the linear model is appropriate
residuals <- data$pressure - data$predicted_pressure

# Plot the residual time series
plot(residuals, type = "l", xlab = "Time", ylab = "Pressure (Residuals)")

#The first step is to check normality of the residuals, it creates a histogram of the residuals 
#and a normal probability plot (Q-Q plot) to check if the residuals are normally distributed.
#Checking the normality of the residuals: Linear regression models assume that the residuals
#are normally distributed. You can check this assumption by creating a histogram of the residuals 
#and/or a normal probability plot (also known as a Q-Q plot). If the residuals are normally distributed, 
#the points on the normal probability plot will fall close to a straight line.
png(file = paste0(getwd(),'/plots/Histogram_Residuals',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
hist(model$residuals, main = "Histogram of Residuals")
dev.off()
png(file = paste0(getwd(),'/plots/Normal_Probability_Residuals',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
qqnorm(model$residuals, main = "Normal Probability Plot of Residuals")
qqline(model$residuals)
dev.off()

# Check for outliers
#Checking for outliers: Outliers can have a large influence on the linear 
#regression model. You can check for outliers by creating a scatterplot of
#the residuals and check if there are any unusual points.
png(file = paste0(getwd(),'/plots/Check_outliers',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
plot(model, which = 1)
dev.off()
# Check for autocorrelation
#Checking for autocorrelation: Linear regression models assume that the residuals are not correlated. 
#You can check for autocorrelation by creating a scatterplot of the residuals against the order of 
#observations or by using the Ljung-Box test for autocorrelation.
png(file = paste0(getwd(),'/plots/Check_autocorrelation',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
acf(model$residuals)
Box.test(model$residuals, lag = 20, type = "Ljung-Box")
dev.off()
# Check for linearity
#Checking for linearity: Linear regression models assume that the relationship between 
#the independent and dependent variables is linear. You can check for linearity by creating a scatterplot
#of the independent variable and dependent variable and check if the points fall roughly along a straight line.
png(file = paste0(getwd(),'/plots/Check_linearity',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
scatterplot(pressure ~ temperature, data = data)

dev.off()

png(file = paste0(getwd(),'/plots/CORECTED',namePoint[iPoint],'.png'),
    width=1200,height=1000,res=150)
# start plotting
par(mar=c(5,5,4,5)+0.1)
datesRange=range(data$dates,na.rm = T)
## Plot the second plot and put axis scale on right
plot(x=data$dates,
     y=data$temperature, pch=15,  xlab="", ylab="", ylim=c(min(data$temperature),max(data$temperature)), 
     axes=FALSE, type="l", col="black")
## a little farther out (line=4) to make room for labels
mtext("temperature [°C]",side=4,col="black",line=3) 
axis(4, ylim=c(min(data$temperature),max(data$temperature)), col="black",col.axis="black",las=1)




box()

## Allow a second plot on the same graph
par(new=TRUE)

# Plot the pressure time series
## Plot first set of data and draw its axis
plot(x=data$dates,
     y=data$pressure[!is.na(dataP$pressure)],
     type='l',main=namePoint[iPoint],
     xlab='dates',ylab='',xaxt='n',lwd=1.5,
     xlim=as.POSIXct(datesRange),ylim= c(min(data$predicted_pressure,data$pressure),max(data$predicted_pressure,data$pressure)),col="green")
lines(x=data$dates,
      y=data$predicted_pressure,col="red")
axis(2, ylim = c(min(data$predicted_pressure,data$pressure),max(data$predicted_pressure,data$pressure)),col="red",col.axis='red')  ## las=1 makes horizontal labels
mtext("head differential [m]",side=2,line=2.5,col="red")
axis.POSIXct(side = 1,at = pretty(datesRange),format='%d/%m/%Y')
abline(v=pretty(datesRange),col='grey',lty=2)

legend('topleft',legend = c(expression('Corrected '*Delta*'H'),expression('Raw '*Delta*'H'),
                            'T stream'),
       col=c('red','green','black'),pch=19,bg='white')


dev.off()
