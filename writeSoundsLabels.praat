# writeSoundsLabels
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

# writeSoundsLabels is part of GSU Praat Tools 1.8. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# writeSoundsLabels is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set operating system, directory paths and names as needed
call set_data_paths

# query user for parameters
form write sound and label files in Objects window
  comment Writes sound and label files to the designated data directory...
  comment ....sounds should have unique names to avoid overwriting
  comment ....label files will get a ".TextGrid" extension.
  optionmenu Output_format 1
    option wav
    option aiff
  optionmenu Select_files 1
    option automatically (all)
    option manually (subset)
endform

# set output format
if 'output_format' = 1
  output_format$ = "wav"
 else
  output_format$ = "aiff"
endif

# check for all or subset
if 'select_files' = 1
  select all
endif

# ensure that Objects window has control
endeditor

# find the number of sound files
numberOfSelectedSounds = numberOfSelected ("Sound")
numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
numberOfSelectedObjects = 'numberOfSelectedSounds' + 'numberOfSelectedTextGrids' 
if ('numberOfSelectedObjects' = 0)
  clearinfo
  printline
  printline No files selected, start again
  printline
  exit
endif

# get all file id numbers
for i from 1 to 'numberOfSelectedSounds'
  sound'i'Number = selected ("Sound", 'i')
  sound'i'Name$ = selected$ ("Sound", 'i')  
endfor
for i from 1 to 'numberOfSelectedTextGrids'
  textgrid'i'Number = selected ("TextGrid", 'i')  
  textgrid'i'Name$ = selected$ ("TextGrid", 'i')  
endfor

# write files to the data folder
for i from 1 to 'numberOfSelectedSounds'
  select sound'i'Number
  soundName$ = selected$ ("Sound", 1)
  if output_format$ = "wav"
    Write to WAV file... 'dataDirectoryPath$''sl$''soundName$'.wav
   else
    Write to AIFF file... 'dataDirectoryPath$''sl$''soundName$'.aiff
  endif
endfor
for i from 1 to 'numberOfSelectedTextGrids'
  select textgrid'i'Number
  labelName$ = selected$ ("TextGrid", 1)
  Write to binary file... 'dataDirectoryPath$''sl$''labelName$'.TextGrid
endfor

# send message to user
clearinfo
printline
printline Saved 'numberOfSelectedObjects' file(s) to 'dataDirectoryPath$'
printline
for i from 1 to 'numberOfSelectedSounds'
  soundName$ = sound'i'Name$
  printline 'soundName$'.'output_format$'
endfor
for i from 1 to 'numberOfSelectedTextGrids'
  textgridName$ = textgrid'i'Name$
  printline 'textgridName$'.TextGrid
endfor
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
  # create Praat_Data directory (no change if it already exists)
  dataDirectoryExists = fileReadable ("'dataDirectoryPath$'")
  if 'dataDirectoryExists' <> 1
    system mkdir "'dataDirectoryPath$'"
  endif

endproc
