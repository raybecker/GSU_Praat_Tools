# eventNumber
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

# eventNumber is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# eventNumber is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for event detection parameters
form event Detector
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor
    option Objects
  boolean Move_on_after 0
  word New_textgrid_tier_name Tier
  optionmenu Number_intervals 2
    option all intervals
    option signal intervals only
    option background intervals only
    option labeled intervals only 
 comment Set parameters for the various functions...
  word Signal_interval_label s
  word Background_interval_label b
endform

# initialize variables
space$ = " "
all_tier_names$ = "'new_textgrid_tier_name$'"
point_tiers$ = ""

# jump to selected processing mode
if ('processing_mode' = 1)
  clearinfo
  printline
  printline Error: Select processing mode!
  printline
  printline Editor (no labels): Select one sound and open it in the Sound Editor
  printline Editor (with labels): Select one sound and open it in the TextGrid Editor
  printline Objects (no labels): Select one sound or more sounds, making sure there are no editors open
  printline Objects (with labels): Select one sound or more sounds, making sure there are no editors open
  exit
 elsif ('processing_mode' = 2) 
  call editor_mode
 elsif ('processing_mode' = 3) 
  call objects_mode
endif

################## run with Editor window: with labels ################
procedure editor_mode

  # make sure control lies with Objects window
  endeditor

  # check whether a sound and textgrid are already open together: soundAndTextGrid
  call check_sound_and_textgrid
  if 'soundAndTextGrid' = 1
    textGridName$ = selected$ ("TextGrid", 1)
    textGridNumber = selected ("TextGrid", 1)
  endif

  # get name and id of file user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files

  # open or textgrid with sound file
  # but do nothing if a textgrid is already open
  if 'soundAndTextGrid' <> 1
    call find_textgrid_ed
    call open_sound_textgrid
   else
    select 'soundNumber'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
  endif

  # close the editor to work on TextGrid file, get number of intervals
  Close
  endeditor
  select 'textGridNumber'
  numberOfIntervals = Get number of intervals... 1

  # number intervals, if desired
  intervalCtr = 1
  for i from 1 to 'numberOfIntervals'
    currentLabel$ = Get label of interval... 1 'i'
    if ('number_intervals' = 1)
      Set interval text... 1 'i' 'intervalCtr' 
       intervalCtr = 'intervalCtr'+ 1
     endif
     if ('number_intervals' = 2) 
       if (currentLabel$ = signal_interval_label$ )
         Set interval text... 1 'i' 'intervalCtr' 
         intervalCtr = 'intervalCtr' + 1
        else
          Set interval text... 1 'i'
       endif
     endif
     if ('number_intervals' = 3) 
       if (currentLabel$ = background_interval_label$ )
         Set interval text... 1 'i' 'intervalCtr' 
         intervalCtr = 'intervalCtr' + 1
        else
          Set interval text... 1 'i'
       endif
     endif 
     if ('number_intervals' = 4) 
       if (currentLabel$ <> "") and (currentLabel$ <> " ")
         Set interval text... 1 'i' 'intervalCtr' 
         intervalCtr = 'intervalCtr' + 1
        else
          Set interval text... 1 'i'
       endif
     endif 
  endfor

  # go on to a new file or quit
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################# run with Objects window: with labels ################
procedure objects_mode

  # count number of selected sounds in the Objects window
  numberOfSelectedSounds = numberOfSelected ("Sound")
  if 'numberOfSelectedSounds' = 0
    echo No sound files selected! Please begin again...
    exit
  endif

  # loop through all the sound files, getting names and id numbers
  for k from 1 to 'numberOfSelectedSounds'
    sound'k'Name$ = selected$ ("Sound", 'k')
    sound'k'Number = selected ("Sound", 'k')
  endfor

  # loop through, selecting each file in turn and analyzing
  for k from 1 to 'numberOfSelectedSounds'
    # select sound file 'k'
    soundName$ = sound'k'Name$
    soundNumber = sound'k'Number
    select 'soundNumber'

    # get textgrid information
    call find_textgrid_ob
    select 'textGridNumber' 

    # get number of intervals
    numberOfIntervals = Get number of intervals... 1

    # number intervals, if desired
    if ('number_intervals' > 1)
      intervalCtr = 1
      for i from 1 to 'numberOfIntervals'
        currentLabel$ = Get label of interval... 1 'i'
        if ('number_intervals' = 1)
          Set interval text... 1 'i' 'intervalCtr' 
           intervalCtr = 'intervalCtr'+ 1
         endif
         if ('number_intervals' = 2) 
           if (currentLabel$ = signal_interval_label$ )
             Set interval text... 1 'i' 'intervalCtr' 
             intervalCtr = 'intervalCtr' + 1
            else
              Set interval text... 1 'i'
           endif
         endif
         if ('number_intervals' = 3) 
           if (currentLabel$ = background_interval_label$ )
             Set interval text... 1 'i' 'intervalCtr' 
             intervalCtr = 'intervalCtr' + 1
            else
              Set interval text... 1 'i'
           endif
         endif
         if ('number_intervals' = 4) 
           if (currentLabel$ <> "") and (currentLabel$ <> " ")
             Set interval text... 1 'i' 'intervalCtr' 
             intervalCtr = 'intervalCtr' + 1
            else
              Set interval text... 1 'i'
           endif
         endif
      endfor
    endif
  endfor

  # reselect the original set
  select sound1Number
  for i from 2 to 'numberOfSelectedSounds'
    plus sound'i'Number
  endfor

  # select next file?
  if 'move_on_after' = 1 
    select 'soundNumber'
    execute nextObjects.praat
  endif

endproc

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure get_starting_last_files
  numberOfSelectedSounds = numberOfSelected ("Sound")
  i = 'numberOfSelectedSounds'
  firstsoundNumber = selected ("Sound", 1)
  lastsoundNumber = selected ("Sound", 'i')
  querysoundNumber = 0
  querysoundNumber = selected ("Sound", 'i')
  while ('querysoundNumber' <> 'soundNumber')
    i = (i - 1)
    querysoundNumber = selected ("Sound", 'i')
  endwhile
  soundPosition = 'i'
endproc

############################################################
procedure get_timedata_entirefile
  beginFile = Get start time
  endFile = Get end time
  durFile = Get total duration
  midFile = 'beginFile' + ('durFile' / 2)
  peakFile = Get time of maximum... 'beginFile' 'endFile' Sinc70
endproc

############################################################
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedObjects = numberOfSelected ()
  if 'numberOfSelectedObjects' = 2
    soundAndTextGrid = 1
  endif
endproc

############################################################
procedure find_textgrid_ed
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
  while (('foundTextGrid' = 0) and ('i' <= 'numberOfSelectedTextGrids'))
    testName$ = textGrid'i'Name$
    if (testName$ = soundName$)
      textGridName$ = testName$
      foundTextGrid = 1
    endif
    i = 'i' + 1
  endwhile
  # if TextGrid doesn't exist, create it
  if ( foundTextGrid = 0 )
    select 'soundNumber'
    To TextGrid... "'all_tier_names$'" 'point_tiers$'
    textGridName$ = soundName$
  endif
  # get TextGrid number
  select TextGrid 'textGridName$'
  textGridNumber = selected ("TextGrid", 1 )
  # close sound editor
   editor Sound 'soundName$'
   Close
   endeditor
endproc

############################################################
procedure find_textgrid_ob
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
  while (('foundTextGrid' = 0) and ('i' <= 'numberOfSelectedTextGrids'))
    testName$ = textGrid'i'Name$
    if (testName$ = soundName$)
      textGridName$ = testName$
      select TextGrid 'textGridName$'
      foundTextGrid = 1
    endif
    i = 'i' + 1
  endwhile
  # if TextGrid doesn't exist, create it
  if ( foundTextGrid = 0 )
    select 'soundNumber'
    To TextGrid... "'all_tier_names$'" 'point_tiers$'
    textGridName$ = soundName$
  endif
  # get TextGrid number
  select TextGrid 'textGridName$'
  textGridNumber = selected ("TextGrid", 1 )
endproc

############################################################
procedure open_sound_textgrid
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
  Show all
endproc
