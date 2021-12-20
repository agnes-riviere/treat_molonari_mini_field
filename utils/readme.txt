this script contains functions for reading hobo dates
 these functions detect the format of input dates
the standard output format is dd/mm/YYYY HH:MM:SS
 main function is formatHoboDate
----------------------------------------

Decription function
----------
addCharInString = function(char,str,loc)
# in string str, add character char at location loc
----------
addZerosInHoboDate = function(dateStr)
# format an unformatted date, the output is a string of the form "dd/mm/YYYY HH:MM:SS"
----------
formatDateWithFullYear = function(dateStr)
# formats a date yy to YYYY by adding '20' in front of yy
----------
addAmPm = function (datesStr)
# add am and pm to the vector of dates
addAmPm = function (datesStr)
----------
formatHoboDate = function(datesStrHoboRaw)
# painful wrapper function combining all functions to format of dates
# input is a vector from any kind of hobo date format
# output is a vector with format %d/%m/%Y %H:%M:%S

  
  
  