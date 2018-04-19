# previousEditor
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

# previousEditor is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# previousEditor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# main program
#######################################################################

# initialize variables
# if a new TextGrid file is created, give the one tier the name "Tier"
tierName$ = "Tier"

# check whether a sound and textgrid are already open together: soundAndTextGrid
call check_sound_and_textgrid

# jump to processing mode
if ('soundAndTextGrid' = 1)
  call editor_sound
 elsif ('soundAndTextGrid' = 2)
  call editor_labels
 else ('soundAndTextGrid' = 3)
  call editor_soundslabels
endif

################# run with Editor window: sound only #################
procedure editor_sound
# get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the previous file or quit
  call previous_file_sounds
endproc

################# run with Editor window: labels only #################
procedure editor_labels
  # get the name and id number of the textgrid the user is starting from
  textGridName$ = selected$ ("TextGrid", 1)
  textGridNumber = selected ("TextGrid", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the previous file or quit
  call previous_file_labels
  call select_first_labeled_interval
endproc

############## run with Editor window: sounds and labels ##############
procedure editor_soundslabels
  # get the name and id number of the sound and textgrid the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)
  textGridName$ = selected$ ("TextGrid", 1)
  textGridNumber = selected ("TextGrid", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the previous file or quit
  call previous_file_soundslabels
  call select_first_labeled_interval
endproc

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedSounds = numberOfSelected ("Sound")
  numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
  if (('numberOfSelectedSounds' > 0) and ('numberOfSelectedTextGrids' = 0))
    soundAndTextGrid = 1
   elsif (('numberOfSelectedSounds' = 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 2
  elsif (('numberOfSelectedSounds' > 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 3
  endif
endproc

############################################################
procedure get_starting_last_files
  if ('numberOfSelectedSounds' > 0)
    select all
    numberOfSelectedSounds = numberOfSelected ("Sound")
    i = 'numberOfSelectedSounds'
    firstSoundNumber = selected ("Sound", 1)
    lastSoundNumber = selected ("Sound", 'i')
    lastSoundPosition = 'i'
    querySoundNumber = 0
    querySoundNumber = selected ("Sound", 'i')
    while ('querySoundNumber' <> 'soundNumber')
      i = (i - 1)
      querySoundNumber = selected ("Sound", 'i')
    endwhile
    soundPosition = 'i'
  endif
  select all
  if ('numberOfSelectedTextGrids' > 0)
   select all
   numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
    i = 'numberOfSelectedTextGrids'
    firstTextGridNumber = selected ("TextGrid", 1)
    lastTextGridNumber = selected ("TextGrid", 'i')
    lastTextGridPosition = 'i'
    queryTextGridNumber = 0
    queryTextGridNumber = selected ("TextGrid", 'i')
    while ('queryTextGridNumber' <> 'textGridNumber')
      i = (i - 1)
      queryTextGridNumber = selected ("TextGrid", 'i')
    endwhile
    textGridPosition = 'i'
  endif
endproc

############################################################
procedure previous_file_sounds
  editor Sound 'soundName$'
  Close
  endeditor
  if ('soundNumber' <> 'firstSoundNumber')
    soundPosition = ('soundPosition' - 1)
   else
    soundPosition = 'numberOfSelectedSounds'
  endif
  soundNumber = selected ("Sound", 'soundPosition')
  soundName$ = selected$ ("Sound", 'soundPosition')
  select 'soundNumber'
  Edit
  editor Sound 'soundName$'
endproc

############################################################
procedure previous_file_labels
  editor TextGrid 'textGridName$'
  Close
  endeditor
  if ('textGridNumber' <> 'firstTextGridNumber')
    textGridPosition = ('textGridPosition' - 1)
   else
    textGridPosition = 'numberOfSelectedTextGrids'
  endif
  textGridNumber = selected ("TextGrid", 'textGridPosition')
  textGridName$ = selected$ ("TextGrid", 'textGridPosition')
  select 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
endproc

############################################################
procedure previous_file_soundslabels
  editor TextGrid 'textGridName$'
  Close
  endeditor
  select all
  if ('soundNumber' <> 'firstSoundNumber')
    soundPosition = ('soundPosition' - 1)
   else
    soundPosition = 'lastSoundPosition'
  endif
  soundNumber = selected ("Sound", 'soundPosition')
  soundName$ = selected$ ("Sound", 'soundPosition')
  call find_textgrid
  if ('foundTextGrid' = 0)
    call create_textgrid
  endif
  select 'soundNumber'
  plus 'textGridNumber' 
  Edit
endproc

############################################################
procedure find_textgrid
  select all
  # get file numbers and names of TextGrids in the Objects window
  numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
  for i from 1 to 'numberOfSelectedTextGrids'
    textGrid'i'Name$ = selected$ ("TextGrid", 'i')
    textGrid'i'Number = selected ("TextGrid", 'i')
  endfor
  # if selected Sound file has a corresponding TextGrid file, find it
  foundTextGrid = 0
  i = 1
  while (( 'foundTextGrid' = 0 ) and ( 'i' <= 'numberOfSelectedTextGrids' ))
    testName$ = textGrid'i'Name$
    testNumber = textGrid'i'Number
    if ( testName$ = soundName$ )
      textGridName$ = testName$
      textGridNumber = testNumber
      foundTextGrid = 1
    endif
    i = 'i' + 1
  endwhile
endproc

############################################################
procedure create_textgrid
  select 'soundNumber'
  To TextGrid... 'tierName$' ""
  textGridName$ = soundName$
  # get TextGrid number
  select TextGrid 'textGridName$'
  textGridNumber = selected ("TextGrid", 1 )
endproc

############################################################
procedure select_first_labeled_interval
  # get number of intervals in TextGrid
  endeditor
  select 'textGridNumber'
  numberIntervals = Get number of intervals... 1
  intervalCtr = 1
  foundFirstInterval = 0
  while (('foundFirstInterval' = 0) and ('intervalCtr' <= 'numberIntervals'))
    currentLabel$ = Get label of interval... 1 'intervalCtr'
    if (currentLabel$ <> "")
      foundFirstInterval = 'intervalCtr'
      beginInterval = Get starting point... 1 'intervalCtr'
      endInterval = Get end point... 1 'intervalCtr'
    endif
    intervalCtr = 'intervalCtr' + 1
  endwhile
  select 'textGridNumber'  
  if ('soundAndTextGrid' = 3)
    plus 'soundNumber'
  endif
  editor TextGrid 'textGridName$'
  Show all
  if ('foundFirstInterval' <> 0)
    Select... 'beginInterval' 'endInterval'
  endif 
endproc
