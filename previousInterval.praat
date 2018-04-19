# previousInterval
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

# previousInterval is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# previousInterval is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# main program
#######################################################################

# check whether a sound and textgrid are selected together
call check_sound_and_textgrid

# jump to processing mode
if ('soundAndTextGrid' = 1)
  call editor_labels
 elsif ('soundAndTextGrid' = 2)
  call editor_soundslabels
endif

################## run with Editor window: labels only ###############
procedure editor_labels
  endeditor
  # get the name and id number of the textgrid the user is starting from
  textGridNumber = selected ("TextGrid", 1)
  textGridName$ = selected$ ("TextGrid", 1)
  # get the starting, ending, and number of intervals
  call get_starting_last_intervals
  # get the starting, ending, and number of intervals
  call get_zoom_information
  # find previous interval
  call find_previous_labeled_interval
  # select the previous interval and zoom
  call previous_interval_labels
  call adjust_zoom
endproc

############## run with Editor window: sounds and labels #############
procedure editor_soundslabels
  # get the name and id number of the sound and textgrid the user is starting from
  soundNumber = selected ("Sound", 1)
  soundName$ = selected$ ("Sound", 1)
  textGridNumber = selected ("TextGrid", 1)
  textGridName$ = selected$ ("TextGrid", 1)
  # get the starting, ending, and number of intervals
  call get_starting_last_intervals
  # get the starting, ending, and number of intervals
  call get_zoom_information
  # find previous interval
  call find_previous_labeled_interval
  # select the previous interval and zoom
  call previous_interval_soundslabels
  call adjust_zoom
endproc

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedSounds = numberOfSelected ("Sound")
  numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
  if (('numberOfSelectedSounds' = 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 1
  elsif (('numberOfSelectedSounds' > 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 2
  endif
endproc

############################################################
procedure get_starting_last_intervals
  editor TextGrid 'textGridName$'
  startInterval = Get start of selection
  endInterval = Get end of selection
  endeditor
  select 'textGridNumber'
  currentInterval = Get interval at time... 1 (('endInterval' - 'startInterval') / 2) + 'startInterval'
  currentLabel$ = Get label of interval... 1 ('currentInterval')
  numberOfIntervals = Get number of intervals... 1
endproc

############################################################
procedure get_zoom_information
  # get the begin time, end time, and length of the visible textgrid
  # information needed to return window to same zoom level later
  editor TextGrid 'textGridName$'
  editorText$ = Editor info
  startEditor = extractNumber(editorText$, "Editor start:")
  endEditor = extractNumber(editorText$, "Editor end:")
  durationEditor = 'endEditor' - 'startEditor'
  startCurrentWindow = extractNumber(editorText$, "Window start:")
  endCurrentWindow = extractNumber(editorText$, "Window end:")
  durationCurrentWindow = 'endCurrentWindow' - 'startCurrentWindow'
  Show all
  Select... 0 10000
  endeditor
  select 'textGridNumber'
endproc

############################################################
procedure find_previous_labeled_interval
  intervalCtr = 1
  previousLabel$ = ""
  while (previousLabel$ = "")
    previousInterval  = 'currentInterval' - 'intervalCtr'
    if ('previousInterval' < 1)
      previousInterval  = ('currentInterval' + 'numberOfIntervals') - 'intervalCtr'
    endif
    previousLabel$ = Get label of interval... 1 'previousInterval'
    if (previousLabel$ = "0")
      previousLabel$ = ""
    endif
    intervalCtr = 'intervalCtr' + 1
  endwhile
endproc

############################################################
procedure previous_interval_labels
  startPreviousInterval = Get starting point... 1 'previousInterval'
  endPreviousInterval = Get end point... 1 'previousInterval'
  select 'textGridNumber'
  editor TextGrid 'textGridName$'
  Move cursor to... ((('endPreviousInterval' - 'startPreviousInterval') / 2) + 'startPreviousInterval')
  cursorPosition = Get cursor
  Select... 'startPreviousInterval' 'endPreviousInterval'
endproc

############################################################
procedure previous_interval_soundslabels
  startPreviousInterval = Get starting point... 1 'previousInterval'
  endPreviousInterval = Get end point... 1 'previousInterval'
  select 'soundNumber'
    plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Move cursor to... ((('endPreviousInterval' - 'startPreviousInterval') / 2) + 'startPreviousInterval')
  cursorPosition = Get cursor
  Select... 'startPreviousInterval' 'endPreviousInterval'
endproc

############################################################
procedure adjust_zoom
  if ('durationCurrentWindow' < 'durationEditor')
    startPreviousWindow = ('cursorPosition' - ('durationCurrentWindow' / 2))
    endPreviousWindow = ('cursorPosition' + ('durationCurrentWindow' / 2))
    if ('startPreviousWindow' < 0)
      endPreviousWindow = 'endPreviousWindow' - 'startPreviousWindow'
      startPreviousWindow = 0
    endif
    if ('endPreviousWindow' > 'endEditor')
      startPreviousWindow = 'startPreviousWindow' - ('endPreviousWindow' - 'durationEditor')
      endPreviousWindow = 'endEditor'
    endif
    Zoom... 'startPreviousWindow' 'endPreviousWindow'
   else
    Show all
  endif
endproc
