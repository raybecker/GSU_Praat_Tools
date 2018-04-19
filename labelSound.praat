# labelSound
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

# labelSound is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# labelSound is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set default tier name for new label files
tierName$ = "Tier"
point_tiers$ = ""

# check whether a sound and textgrid are already open together soundAndTextGrid
call check_sound_and_textgrid

# one sound selected, find its position in the list, then find or create corresponding textgrid
if ( "'soundAndTextGrid$'" = "10" )
  call get_start_sound
  # check for corresponding textgrid, create if necessary
  call find_textgrid
  if ( 'foundTextGrid' <> 1 )
    call create_textgrid
  endif
endif

# one textgrid selected, find corresponding sound and its position in the list
if ( "'soundAndTextGrid$'" = "01" )
  call get_start_textgrid
  call find_sound
  if ( 'foundSound' <> 1 ) 
    # no corresponding sound found, alert user and quit
    clearinfo
    printline There is no sound file for the selected TextGrid!
    exit
  endif
endif

# one sound and one textgrid selected, check that they match
if ( "'soundAndTextGrid$'" = "11" )
  # if a match, find sound position in the list, continue
  call get_start_sound
  call get_start_textgrid
  if ( soundName$ <> textGridName$ )
    # not a match, alert user and quit
    clearinfo
    printline You have selected mismatched files!
    exit
  endif
endif

# open sound and textgrid together
call open_sound_textgrid
call select_first_labeled_interval

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure check_sound_and_textgrid
  # set selection code
  # 10 = one soundfile selected
  # 01 = one textgrid selected
  # 11 = one sound and one textgrid selected  
  numberOfSelectedSounds = numberOfSelected ("Sound")
  numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
  numberOfSelectedSounds$ = fixed$('numberOfSelectedSounds', 0)
  numberOfSelectedTextGrids$ = fixed$('numberOfSelectedTextGrids', 0)
  soundAndTextGrid$ = numberOfSelectedSounds$ + numberOfSelectedTextGrids$
endproc

############################################################
procedure get_start_sound
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)
endproc

############################################################
procedure get_start_textgrid
  textGridName$ = selected$ ("TextGrid", 1)
  textGridNumber = selected ("TextGrid", 1)
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
procedure find_sound
  select all
  # get file numbers and names of Sounds in the Objects window
  numberOfSelectedSounds = numberOfSelected ("Sound")
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor
  # if selected TextGrid file has a corresponding Sound file, find it
  foundSound = 0
  i = 1
  while (('foundSound' = 0) and ('i' <= 'numberOfSelectedSounds'))
    testName$ = sound'i'Name$
    testNumber = sound'i'Number  
    if ( testName$ = textGridName$ )
      soundName$ = testName$
      soundNumber = testNumber
      foundSound = 1
    endif
    i = 'i' + 1
  endwhile
endproc

############################################################
procedure create_textgrid
  select 'soundNumber'
  To TextGrid... 'tierName$'
  textGridName$ = soundName$
  # get TextGrid number
  select TextGrid 'textGridName$'
  textGridNumber = selected ("TextGrid", 1 )
endproc

############################################################
procedure open_sound_textgrid
  endeditor
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
  Show all
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
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Show all
  if ('foundFirstInterval' <> 0)
    Select... 'beginInterval' 'endInterval'
  endif
endproc
