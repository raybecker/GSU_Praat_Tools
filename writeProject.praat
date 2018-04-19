# writeProject
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

# writeProject is part of GSU Praat Tools 1.8. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# writeProject is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set operating system, directory paths and names as needed
call set_data_paths

# query user for parameters
form write to a Praat Tools Project
  comment Writes files as a Praat Tools Project to the designated data directory...
  comment ....includes sound and label files from Objects window
  comment ....can include ".out" files currently in the data directory
  comment ....appends today's date to the file name entered below
  comment ....file will get a ".praattoolsProject" extension.
  word Project_file_name myfiles
  optionmenu Select_files 1
    option automatically (all)
    option manually (subset)
  boolean Include_out_files 1
endform

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# record all files selected for the Project
if 'select_files' = 1
  select all
endif

# ensure that Objects window has control
endeditor

# find the number of sound files
numberOfSelectedObjects = numberOfSelected ()
if ('numberOfSelectedObjects' = 0)
  clearinfo
  printline
  printline No files selected, start again
  printline
  exit
endif

for i from 1 to 'numberOfSelectedObjects'
  object'i'Number = selected ('i')
  object'i'Name$ = selected$ ('i')
endfor

# if selected, read in ".out" text data files using strings format
if ( 'include_out_files' = 1 )
  # find the ".out" data files, read in as strings files
  Create Strings as file list... fileList 'dataDirectoryPath$''sl$'*.out
  numberOfStrings = Get number of strings
  if ( 'numberOfStrings' > 0 )
    for i from 1 to 'numberOfStrings'
      select Strings fileList
      outDataFile$ = Get string... 'i'
      Read Strings from raw text file... 'dataDirectoryPath$''sl$''outDataFile$'
      strings'i'Number = selected ("Strings", 1)
      strings'i'Name$ = selected$ ("Strings", 1)
    endfor
  endif
  select Strings fileList
  Remove
endif

# reselect the Project files
select 'object1Number'
for i from 2 to 'numberOfSelectedObjects'
  plus object'i'Number
endfor
if ( 'include_out_files' = 1 )
  for i from 1 to 'numberOfStrings'
    plus strings'i'Number
  endfor
endif

# write Project file
numberOfSelectedObjectsAll = numberOfSelected ()

Write to binary file... 'dataDirectoryPath$''sl$''project_file_name$''daynumber$''month$'.praattoolsProject

if ( 'include_out_files' = 1 )
  # remove ".out" files (if selected)
  for i from 1 to 'numberOfStrings'
    stringsNumber = strings'i'Number
    select 'stringsNumber'
    Remove
  endfor
endif

# send message to user
clearinfo
printline
printline Saved 'numberOfSelectedObjects' file(s) to 'project_file_name$''daynumber$''month$'.praattoolsProject in 'dataDirectoryPath$'
printline
for i from 1 to 'numberOfSelectedObjects'
  objectName$ = object'i'Name$
  printline 'objectName$'
endfor
if ( 'include_out_files' = 1 )
  for i from 1 to 'numberOfStrings'
    stringsName$ = strings'i'Name$
    printline 'stringsName$'
  endfor
endif
printline

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
procedure date_and_time
  date$ = date$ ()
  weekday$ = left$ (date$, 3)
  month$ = mid$ (date$, 5, 3)
  daynumber$ = mid$ (date$, 9, 2)
  if left$ (daynumber$, 1) = " "
   daynumber$ = right$ (daynumber$, 1)
  endif
  time$ = mid$ (date$, 12, 8)
  year$ = right$ (date$, 4)
endproc
