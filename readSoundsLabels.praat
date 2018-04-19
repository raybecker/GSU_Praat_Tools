# readSoundsLabels
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

# readSoundsLabels is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# readSoundsLabels is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set operating system, directory paths and names as needed
call set_data_paths

# query user for parameters
form read Sounds, TextGrids, and Collection from the data directory
  comment Before running the script...
  comment ....sound files must have ".wav", ".WAV", ".aiff", or ".AIFF" extensions
  comment ....label files must have ".TextGrid" extensions
  comment ....Praat collection files must have ".Collection" extensions
  comment ....remove any individual files that should not be read in.
  boolean Include_sounds 1
  boolean Include_textgrids 1
  boolean Include_collections 0
  optionmenu File_sorting 1
    option set sort mode if desired
    option by filetype then filename 
    option by filename then filetype
    option by filetype only
    option by filename only
  boolean Include_user_alerts 0
endform

# ensure that Objects window has control
endeditor

# initialize file count variables
soundList1Files = 0
soundList2Files = 0
soundList3Files = 0
soundList4Files = 0
textGridListFiles = 0
collectionListFiles = 0

# read in sound file(s), if desired
if ('include_sounds' = 1)
  Create Strings as file list... list1 'dataDirectoryPath$''sl$'*.wav
    soundList1 = selected ("Strings", 1)
    soundList1Files = Get number of strings
  Create Strings as file list... list2 'dataDirectoryPath$''sl$'*.aiff
    soundList2 = selected ("Strings", 1)
    soundList2Files = Get number of strings
 if (sl$ = "/")
    # it's a MAC, so it's case-sensitive
    Create Strings as file list... list3 'dataDirectoryPath$''sl$'*.WAV
      soundList3 = selected ("Strings", 1)
      soundList3Files = Get number of strings
    Create Strings as file list... list4 'dataDirectoryPath$''sl$'*.AIFF
      soundList4 = selected ("Strings", 1)
      soundList4Files = Get number of strings
  else
    # it's a PC, so not case-sensitive
    Create Strings as file list... list3 'dataDirectoryPath$''sl$'*.NULL
      soundList3 = selected ("Strings", 1)
      soundList3Files = Get number of strings
    Create Strings as file list... list4 'dataDirectoryPath$''sl$'*.NULL
      soundList4 = selected ("Strings", 1)
      soundList4Files = Get number of strings
  endif
endif

# read in textgrid file(s), if desired
if ('include_textgrids' = 1)
  Create Strings as file list... textGridList 'dataDirectoryPath$''sl$'*.TextGrid
  textGridList = selected ("Strings", 1)
  textGridListFiles = Get number of strings
endif

# read in collection file(s), if desired
# this file order not sorted, even if sorting is enabled
if ('include_collections' = 1)
  Create Strings as file list... collectionList 'dataDirectoryPath$''sl$'*.Collection
  collectionList = selected ("Strings", 1)
  collectionListFiles = Get number of strings
endif

# find total number of files in lists
soundFiles = 0
for i from 1 to 4
  soundFiles = soundFiles + soundList'i'Files
endfor
totalSoundTextGrid = 'soundFiles'+ 'textGridListFiles'
totalFiles = 'totalSoundTextGrid' + 'collectionListFiles'

# alert user if there's a problem
if ('include_user_alerts' = 1)
  if ('totalFiles' = 0)
    printline No sound, textgrid, or collection files found, start again
    if ('include_sound_files' = 1)
      select 'soundList1'
        plus 'soundList2'
        plus 'soundList3'
        plus 'soundList4'
      Remove
    endif
    if ('include_textGrids' = 1)
      select 'textGridList'
      Remove
    endif
    if ('include_collections' = 1)
      select 'collectionList'
      Remove
    endif
      Remove
    exit
   else
    clearinfo
    printline
    printline 'totalFiles' sound, textgrid, and collection files found...
    printline
    printline ...select Continue or Stop
    printline
    pause
  endif
endif

# Read in files from each file list, either straight from Praat_Data,
# or with concomitant sorting of sound and textgrid file order

# if sorting has been selected, read file names into a table
if ('file_sorting' <> 1)
  # create a table to accommodate the file names found, initialize
  Create Table without column names... dataInTable 'totalSoundTextGrid' 2 
  dataInTable = selected ("Table", 1)
  Set column label (index)... 1 1
  Set column label (index)... 2 2
  # enter filenames in table
  k = 1
  for i from 1 to 4
    for j from k to soundList'i'Files
      select soundList'i'
      fileName$ = Get string... 'j'
      select 'dataInTable'
      Set string value... 'j' 1 'fileName$'
      Set string value... 'j' 2 S
    endfor
    k = k + soundList'i'Files
  endfor
  for j from 1 to 'textGridListFiles'
    select 'textGridList'
    fileName$ = Get string... 'j'
    select 'dataInTable'
    Set string value... 'k' 1 'fileName$'
    Set string value... 'k' 2 T
    k = 'k' + 1
  endfor
  # sort table
  if ('file_sorting' = 2)
    Sort rows... 2 1
   elsif ('file_sorting' = 3)
    Sort rows... 1 2
   elsif ('file_sorting' = 4)
    Sort rows... 2
   elsif ('file_sorting' = 5)
    Sort rows... 1
  endif

  # read in files based on table order
  for j from 1 to 'totalSoundTextGrid'
    select 'dataInTable'
    fileName$ = Get value... 'j' 1
    Read from file... 'dataDirectoryPath$''sl$''fileName$'
  endfor
 else
  # read in any files in the filelists
  if ('include_sounds' = 1 )
    for i from 1 to 4
      select soundList'i'
      numberOfFiles = Get number of strings
      for j from 1 to 'numberOfFiles'
        select soundList'i'
        fileName$ = Get string... 'j'
        Read from file... 'dataDirectoryPath$''sl$''fileName$'
      endfor
    endfor
  endif
  if ('include_textgrids' = 1 )
    select 'textGridList'
    numberOfFiles = Get number of strings
    for j from 1 to 'numberOfFiles'
      select textGridList
      fileName$ = Get string... 'j'
      Read from file... 'dataDirectoryPath$''sl$''fileName$'
    endfor
  endif
endif

# open files from the collections list, if desired
if ('include_collections' = 1 )
  select 'collectionList'
  numberOfFiles = Get number of strings
  for i from 1 to collectionListFiles
    for j from 1 to 'numberOfFiles'
      select collectionList
      fileName$ = Get string... 'j'
      Read from file... 'dataDirectoryPath$''sl$''fileName$'
    endfor
  endfor
endif

# clean up
if ('include_sounds' = 1)
  select 'soundList1'
    plus 'soundList2'
    plus 'soundList3'
    plus 'soundList4'
  Remove
endif
if ('include_textgrids' = 1)
  select 'textGridList'
  Remove
endif
if ('include_collections' = 1)
  select 'collectionList'
  Remove
endif
if ('file_sorting' <> 1)
  select 'dataInTable'
  Remove
endif

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
