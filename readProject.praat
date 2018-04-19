# readProject
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

# readPraatToolsProject is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# readPraatToolsProject is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set operating system, directory paths and names as needed
call set_data_paths

# query user for parameters
form restore GSU Tools Project(s)
  comment Reads GSU Tools Project files from the data directory.
  comment Before running the script...
  comment .....copy the GSU Tools Project into the Praat_Data folder
  comment .....the Project file should have the extension ".gsutoolsProject" 
  comment .....remove any unwanted Project files from the data directory.
  boolean Include_user_alerts 1
endform

# ensure that Object window has control
endeditor

# read in praattoolsProject file(s)
Create Strings as file list... fileList 'dataDirectoryPath$''sl$'*.praattoolsProject
numberOfFiles = Get number of strings
for i from 1 to 'numberOfFiles'
  project'i'Name$ = Get string... 'i'
endfor

# alert user to what has been found
if ( 'include_user_alerts' = 1 )
  clearinfo
  if 'numberOfFiles' = 0
    printline No project files found, start again
    select Strings fileList
    Remove
    exit
   else
    clearinfo
    printline
    printline The following Project file(s) found...
    printline
    for i from 1 to 'numberOfFiles'
      projectName$ = project'i'Name$
      printline 'tab$' 'projectName$'
    endfor
      printline
      printline ...select Continue or Stop
    pause
  endif
endif

# recover files from Project
totalFiles = 0
for i from 1 to 'numberOfFiles'
  select Strings fileList
    inDataFile$ = Get string... 'i'
    Read from file... 'dataDirectoryPath$'/'inDataFile$'
  endfor
  select Strings fileList
  Remove
endif

# loop through any resulting strings files, getting names and id numbers
select all
numberOfStrings = numberOfSelected ("Strings")
for i from 1 to 'numberOfStrings'
  strings'i'Name$ = selected$ ("Strings", 'i')
  strings'i'Number = selected ("Strings", 'i')
endfor

# save strings file to data directory as ".out" data files
for i from 1 to 'numberOfStrings'
  stringNumber = strings'i'Number
  stringName$ = strings'i'Name$
  select 'stringNumber'
  Write to raw text file... 'dataDirectoryPath$'/'stringName$'.out
  Remove
endfor

# alert user
clearinfo
printline
printline 'numberOfFiles' Project(s) restored to the Objects window
printline
printline 'numberOfStrings' ".out" file(s) restored to the PraatData folder

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
