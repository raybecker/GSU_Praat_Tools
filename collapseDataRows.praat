# collapseDataRows
#######################################################################

# Michael J. Owren, Ph.D.
# Psychology of Voice and Sound Laboratory
# Department of Psychology
# Georgia State University
# Atlanta, GA 30303, USA

# email: owren@gsu.edu
# home page: http://sites.google.com/site/michaeljowren/
# lab page: http://sites.google.com/site/psyvoso/home

# Copyright 2007-2011 Michael J. Owren

# collapseDataRows is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# collapseDataRows is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for sequence type, number of sequences, and output file name
form Parameter entry for collapsing data rows
  comment Please note:
  comment - entries on each row of the data file must be separated by spaces
  comment - any header information in the data file must be in the first row only
  boolean Header_present 0
  comment Enter the total number of entries per row
  integer Entries_per_row 18
  comment Total number of bookkeeping entries at the beginning of each row
  comment (this number includes from date and time through all labeling entries)
  integer Number_of_initial_entries 13
  comment Enter the number of rows to collapse
  integer Rows_to_collapse 2
endform

# set operating system, directory paths and names as needed
call set_data_paths

# read in files from folder
Create Strings as file list... fileList 'dataDirectoryPath$'/*.out
numberOfFilesIn = Get number of strings
i = 1
for i to 'numberOfFilesIn'
  select Strings fileList
  dataFileIn$ = Get string... 'i'
  Read Strings from raw text file... 'dataDirectoryPath$'/'dataFileIn$'
endfor
select Strings fileList
Remove
select all

# count number of selected strings files in the Objects window
numberOfSelectedStringsFiles = numberOfSelected ("Strings")
if 'numberOfFilesIn' = 0
  echo No files selected! Please begin again...
  exit
endif

# loop through all the data files, getting names and id numbers
for z from 1 to 'numberOfFilesIn'
  data'z'Name$ = selected$ ("Strings", 'z')
  data'z'Number = selected ("Strings", 'z')
endfor

# clear info window
clearinfo

##########################################################
# main program loop

# select and work on each file in turn

for z from 1 to 'numberOfFilesIn'

  # select data file 'z'
  targetDataName$ = data'z'Name$
  targetDataNumber = data'z'Number
  select 'targetDataNumber'

  # set new data file name
  dataFile$ = targetDataName$ + ".out.collapsed"

  # get name and number of input file, and number of lines in the file
  dataFileName$ = selected$ ("Strings", 1)
  dataFileNumber = selected ("Strings", 1)
  numberStrings = Get number of strings

  # set data file location and name
  dataFile1$ = "'dataPath$'/'dataDirectory$'/"+"'dataFileName$'"+""

  # alert user to progress
  printline Working on 'targetDataName$'

  # create a table for the data, adjusting for possible header
  if header_present = 1
    numberStrings = 'numberStrings' - 1 
  endif
  Create Table without column names... dataInTable 'numberStrings' 'entries_per_row' 
  dataInTable = selected ("Table", 1)
  for i from 1 to 'entries_per_row'
    columnLabel$ = "'i'"
    Set column label (index)... 'i' 'columnLabel$'
  endfor

  # parse each string, entering values into table with all data
  startRow = 1
  select 'dataFileNumber'
  if (header_present = 1)
    header_row$ = Get string... 1
    startRow = 2
  endif
  for i from 'startRow' to 'numberStrings'
    select 'dataFileNumber'
    call parseString
     # enter initial values into the table
     select 'dataInTable'
     for j from 1 to 'entries_per_row'
       newItem$ = newItem'j'$
       column$ = "'j'"
       if (header_present = 1)
         Set string value... ('i'-1) 'column$' 'newItem$'
        else
         Set string value... 'i' 'column$' 'newItem$'
       endif
     endfor
  endfor

  # calculate dimensions of new table, create, and initialze with column labels
  numberDataEntries = 'entries_per_row' -  'number_of_initial_entries'
  new_table_rows = ('numberStrings' / 'rows_to_collapse')
  new_entries_per_row = 'entries_per_row' + ('numberDataEntries' * ('rows_to_collapse' - 1))
  Create Table without column names... dataOutTable 'new_table_rows' 'new_entries_per_row' 
  dataOutTable = selected ("Table", 1)
  for i from 1 to 'new_entries_per_row'
    columnLabel$ = "'i'"
    Set column label (index)... 'i' 'columnLabel$'
  endfor

  # collapse rows 
  newRow = 1
  for oldRow from 1 to 'numberStrings'
    for j from 1 to 'number_of_initial_entries'
      columnLabel$ = "'j'"
      select 'dataInTable'
      transferItem$ = Get value... 'oldRow' 'columnLabel$'
      select 'dataOutTable'
      Set string value... 'newRow' 'columnLabel$' 'transferItem$'
    endfor
    for k from 1 to 'rows_to_collapse'
      oldRow = oldRow + ('k' - 1)
      for j from ('number_of_initial_entries' + 1) to 'entries_per_row'
        columnLabel$ = "'j'"
        select 'dataInTable'
        transferItem$ = Get value... 'oldRow' 'columnLabel$'
        select 'dataOutTable'
        columnNumber = 'j' + ('numberDataEntries' * ('k' - 1)) 
        columnLabel$ = "'columnNumber'"
        Set string value... 'newRow' 'columnLabel$' 'transferItem$'
      endfor
      lastColumn = 'j'
    endfor
    newRow = 'newRow' + 1
  endfor

  # print out data
  call data_to_file

endfor

# clean up
select all
Remove

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure set_data_paths
  # check operating system type, set sl$ as (back)slash character
  if (macintosh = 1)
    opSys$ = "macintosh"
    sl$ = "/"
   elsif (windows = 1)
    opSys$ = "windows"
    sl$ = "\"
   else
    # system not recognized, alert user
    echo "Operating system is unknown, the script has terminated"
    exit
  endif
  # set name of desktop, data directory, and the pathnames needed
  gsuprtlsDirectory$ = "'defaultDirectory$'"
  pluginDirectory$ = "'preferencesDirectory$''sl$'plugin_GSUPraatTools"
  desktopName$ < 'pluginDirectory$''sl$'desktopNameFile
  dataDirectoryPath$ < 'pluginDirectory$''sl$'dataDirectoryPathFile
  # check for and possibly create the Praat_Data directory
  dataDirectoryExists = fileReadable ("'dataDirectoryPath$'")
  if 'dataDirectoryExists' <> 1
    system mkdir "'dataDirectoryPath$'"
  endif
endproc

############################################################
procedure data_to_file
  # send data to the file
  if 'header_present' = 1
    fileappend "'dataDirectoryPath$''sl$''dataFile$'" 'header_row$' 'newline$'
  endif
  select 'dataOutTable'
  for outRow from 1 to ('newRow' - 1)
    outRow$ = ""
    for entry from 1 to 'new_entries_per_row'
      columnLabel$ = "'entry'"
      transferItem$ = Get value... 'outRow' 'columnLabel$'
      outRow$ = outRow$ + transferItem$ + " "
    endfor
    fileappend "'dataDirectoryPath$''sl$''dataFile$'" 'outRow$' 'newline$'
  endfor
endproc

############################################################
procedure parseString
  # get string with the entire row
  rawString$ = Get string... 'i'
  for j from 1 to 'entries_per_row'
    # remove any leading spaces in front of first item
    while left$(rawString$, 1) = " "
      rawString$ = mid$(rawString$, 2, 1000)
    endwhile
    # read the alphanumeric string
    inString$ = ""
    while (left$(rawString$, 1) <> " ") and (left$(rawString$, 1) <> "")
      inString$ = inString$ + left$(rawString$, 1)
      rawString$ = mid$(rawString$, 2, 1000)
    endwhile
    # save the string to a variable
    newItem'j'$ = inString$ 
  endfor
endproc
