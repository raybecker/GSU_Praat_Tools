# setDataDirectory
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

# setDataDirectory is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# setDataDirectory is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

form set data directory...
comment To show current data directory in Info window
comment - select "show or set directory"
comment Apply.
comment To change the data directory
comment - type in new path and directory name 
comment or
comment - retrieve current data directory, cut, paste, and edit (be precise!)
comment Apply.
comment To reset data directory to Praat_Data
comment - select "restore_to_Praat_Data"
comment Apply.
optionmenu Processing_mode 1
  option show or set directory
  option restore to Praat_Data
boolean include_subdirectories 1
boolean include_Praat-related_files 0
boolean Include_all_content 0
word Set_directory_to
endform

# set operating system, directory paths and names as needed
call set_data_paths
if (set_directory_to$ <> "")
  dataDirectoryPath$ = set_directory_to$
endif

# show current directory path, or set and show new directory path
if ('processing_mode' = 1)
  if (dataDirectoryPath$ <> "")
    filedelete 'pluginDirectory$''sl$'dataDirectoryPathFile
    fileappend "'pluginDirectory$''sl$'dataDirectoryPathFile" 'dataDirectoryPath$'
  endif
  call showDataDirectory
  call showDirectoryContentsOverall
endif

# restore pathname to Praat_Data directory, if desired
if ('processing_mode' = 2)
  dataDirectoryPath$ = "'homeDirectory$'" + sl$ + desktopName$ + sl$ + "Praat_Data"
  filedelete 'pluginDirectory$''sl$'dataDirectoryPathFile
  fileappend "'pluginDirectory$''sl$'dataDirectoryPathFile" 'dataDirectoryPath$'
  # check for and possibly create the Praat_Data directory
  praat_DataExists = fileReadable ("'homeDirectory$''sl$''desktopName$''sl$'Praat_Data")
  if 'praat_DataExists' <> 1
    system mkdir "'homeDirectory$''sl$''desktopName$''sl$'Praat_Data"
  endif
  call showDataDirectory
  call showDirectoryContentsOverall
endif

# show contents of the data directory, if desired
call showDirectoryContentsDetailed

# clean up
select 'directoryListNumber'
 plus 'allListNumber'
 plus 'wavListNumber'
 plus 'aiffListNumber'
 plus 'labelListNumber'
 plus 'outListNumber'

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
endproc

############################################################
procedure showDataDirectory
  clearinfo
  printline
  printline the data directory is...
  printline
  printline 'dataDirectoryPath$'
  printline
endproc

############################################################
procedure showDirectoryContentsOverall
  Create Strings as directory list... directoryList 'dataDirectoryPath$''sl$'*
  directoryListNumber = selected ("Strings", 1)
  numberOfDirectories = Get number of strings
  Create Strings as file list... allFileList 'dataDirectoryPath$''sl$'*
  allListNumber = selected ("Strings", 1)
  numberOfAll = Get number of strings
  Create Strings as file list... wavFileList 'dataDirectoryPath$''sl$'*.wav
  wavListNumber = selected ("Strings", 1)
  numberOfWavs = Get number of strings
  Create Strings as file list... aiffFileList 'dataDirectoryPath$''sl$'*.aiff
  aiffListNumber = selected ("Strings", 1)
  numberOfAiffs = Get number of strings
  Create Strings as file list... labelFileList 'dataDirectoryPath$''sl$'*.TextGrid
  labelListNumber = selected ("Strings", 1)
  numberOfLabels = Get number of strings
  Create Strings as file list... outFileList 'dataDirectoryPath$''sl$'*.out
  outListNumber = selected ("Strings", 1)
  numberOfOuts = Get number of strings
  numberOfPraatRelated = 'numberOfWavs' + 'numberOfAiffs' + 'numberOfLabels' + 'numberOfOuts'
  printline this directory contains...
  printline ...'numberOfDirectories' subdirectories
  printline ...'numberOfAll' total files
  printline ...'numberOfWavs' wav files
  printline ...'numberOfAiffs' aiff files
  printline ...'numberOfLabels' label files
  printline ...'numberOfOuts' out files
  printline
endproc

############################################################
procedure showDirectoryContentsDetailed
  if ((('include_all_content' = 1) or ('include_subdirectories' = 1)) and ('numberOfDirectories' > 0))
    select 'directoryListNumber'
    printline subdirectories...
    for i from 1 to 'numberOfDirectories'
      directoryName$ = Get string... 'i'
      printline 'directoryName$'
    endfor
    printline
  endif
  if (('include_all_content' = 1) and ('numberOfAll' > 0))
    printline all files...
    select 'allListNumber'
    for i from 1 to 'numberOfAll'
      fileName$ = Get string... 'i'
      printline 'fileName$'
    endfor
   elsif (('include_Praat-related_files' = 1) and ('numberOfPraatRelated' > 0))
    printline Praat-related files...
    select 'wavListNumber'
    for i from 1 to 'numberOfWavs'
      wavName$ = Get string... 'i'
      printline 'wavName$'
    endfor
    select 'aiffListNumber'
    for i from 1 to 'numberOfAiffs'
      aiffName$ = Get string... 'i'
      printline 'aiffName$'
    endfor
    select 'labelListNumber'
    for i from 1 to 'numberOfLabels'
      labelName$ = Get string... 'i'
      printline 'labelName$'
    endfor
    select 'outListNumber'
    for i from 1 to 'numberOfOuts'
      outName$ = Get string... 'i'
      printline 'outName$'
    endfor
   endif
  endif
  printline
endproc
