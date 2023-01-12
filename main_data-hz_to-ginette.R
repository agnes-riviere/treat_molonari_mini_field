# this script is a wrapper for ALL other scripts

source('01_adjust_from_meta.R')
rm(list = ls())

source('01bis_plot_adjusted_from_meta.R')
rm(list = ls())

setwd('tests_forEmpiricalCorrections/')
source('tests_VtoH.R')
setwd('../')
rm(list = ls())

source('02_empiricalCorrections.R')
rm(list = ls())

source('02bis_plot_empiricalCorrections.R')
rm(list = ls())

setwd('../data_hz/data/03_manual_corrections/')
all_manual <- list.files('.',pattern = '.R')
for(script in all_manual){source(script);rm(list = ls())}
setwd('../../../scripts_R/')

source('03bis_plot_manualCorrections.R')
rm(list = ls())
