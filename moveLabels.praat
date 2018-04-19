# moveLabels
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

# moveLabels is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# moveLabels is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query for...
form move boundaries of labeled TextGrid intervals
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (with labels)
    option Objects (with labels)
  boolean Move_on_after 0
  comment Editor mode:
  comment - select an interval in the Editor window 
  comment - enter tier, boundary, and amount for Label 1--but do not enter a label.
  comment Objects mode:
  comment - up to two differently labeled intervals can be moved at a time
  comment - set parameters for each kind separately
  comment - include one distinctive label component for each
  comment - alternatively, enter * as a wildcard for Move label 1 to target all intervals.
  boolean Leave_boundaries_at_zero_crossings 0
  optionmenu Which_tier 1
    option 1
    option 2
    option 3
    option 4
  optionmenu Move_boundary_1 1
    option none
    option both - forward
    option both - backward
    option both - together (shrink)
    option both - apart (expand)
    option begin only - forward
    option begin only - backward
    option end only - forward
    option end only - backward
  real Move_amount_1_(ms) 0
  word Move_label_1
  optionmenu Move_boundary_2 1
    option none
    option both - forward
    option both - backward
    option both - together (shrink)
    option both - apart (expand)
    option begin only - forward
    option begin only - backward
    option end only - forward
    option end only - backward
  real Move_amount_2_(ms) 0
  word Move_label_2
endform

# tranform move amount values from ms to sec
if (move_amount_1 <> 0)
  move_amount_1 =  ('move_amount_1' / 1000)
endif
if (move_amount_2 <> 0)
  move_amount_2 =  ('move_amount_2' / 1000)
endif

# check that a label has been entered
if (( 'processing_mode' = 3 ) and (move_label_1$ = ""))
  clearinfo
  printline
  printline Error: Select a label to search for!
  printline
  printline Enter a specific label or part of a label to identify target intervals,
  printline or use "*" to perform the boundary movement on all labeled intervals.
  exit
endif

# jump to selected processing mode
if (processing_mode = 1 )
  clearinfo
  printline
  printline Error: Select processing mode!
  printline
  printline Editor (with labels): Select one sound and open it in the TextGrid Editor
  printline Objects (with labels): Select one sound or more sounds, making sure there are no editors open
  exit
 elsif ( 'processing_mode' = 2 )
  call editor_withlabels
 elsif ( 'processing_mode' = 3 )
  call objects_withlabels
endif

################# run with Editor window: with labels #################
procedure editor_withlabels

  # make sure control lies with objects window
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

  # open or create textgrid with sound file
  # but do nothing if a textgrid is already open
  if 'soundAndTextGrid' <> 1
    call find_textgrid_ed
    call open_sound_textgrid
   else
    select 'soundNumber'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
  endif

  # select sound and textgrid, transfer control to editor
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'

  # get number and label of selected interval
  cursor = Get cursor
  endeditor
  select 'textGridNumber'
  intervalNumber =  Get interval at time... 'which_tier' 'cursor'
  intervalLabel$ = Get label of interval... 'which_tier' 'intervalNumber'
 
  # get begin and end of interval
  beginInterval = Get starting point... 'which_tier' 'intervalNumber'
  endInterval = Get end point... 'which_tier' 'intervalNumber'

  # transfer control to editor
  plus 'soundNumber'
  Edit
  editor TextGrid 'textGridName$'

  # select current interval
  Select... 'beginInterval' 'endInterval'
  # copy interval label, then delete
  intervalLabel$ = Get label of interval
  endeditor
  select 'textGridNumber'
  Set interval text... 'which_tier' 'intervalNumber' 

  # set variables
  move_boundary = 'move_boundary_1'
  move_amount = 'move_amount_1'

  # set new boundary time(s), the direction and amount of move variables
  oldBeginInterval = 'beginInterval'
  oldEndInterval = 'endInterval'
  if (move_boundary = 2)
    beginInterval = ('beginInterval' + 'move_amount')
    endInterval = ('endInterval' + 'move_amount')
   elsif (move_boundary = 3)
    beginInterval = ('beginInterval' - 'move_amount')
    endInterval = ('endInterval' - 'move_amount')
   elsif (move_boundary = 4)
    beginInterval = ('beginInterval' + 'move_amount')
    endInterval = ('endInterval' - 'move_amount')
   elsif (move_boundary = 5)
    beginInterval = ('beginInterval' - 'move_amount')
    endInterval = ('endInterval' + 'move_amount')
   elsif (move_boundary = 6)
    beginInterval = ('beginInterval' + 'move_amount')
   elsif (move_boundary = 7)
    beginInterval = ('beginInterval' - 'move_amount')
   elsif (move_boundary = 8)
    endInterval = ('endInterval' + 'move_amount')
   elsif (move_boundary = 9)
    endInterval = ('endInterval' - 'move_amount')
  endif

  # open sound file with textgrid             
  select 'textGridNumber'
  plus 'soundNumber'
  editor TextGrid 'textGridName$'

  # add new boundaries, delete old ones
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
 
  if 'beginInterval' <> 'oldBeginInterval'
    Move cursor to... 'beginInterval'
    Add on tier 'which_tier'
    Move cursor to... 'oldBeginInterval'
    Remove
  endif
  if 'endInterval' <> 'oldEndInterval'        
    Move cursor to... 'endInterval'
    Add on tier 'which_tier'
    Move cursor to... 'oldEndInterval'
    Remove
  endif

  # set new boundaries at zero-crossings, if desired
  if 'leave_boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    beginInterval = Get cursor
    Move end of selection to nearest zero crossing
    endInterval = Get cursor
  endif

  # paste label back in
  Close
  endeditor
  select 'textGridNumber'
  Set interval text... 'which_tier' 'intervalNumber' 'intervalLabel$'
  plus 'soundNumber'
  editor TextGrid 'textGridName$'

  # go on to a new file or quit  
  Select... 'beginInterval' 'endInterval'
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################ run with Objects window: with labels #################
procedure objects_withlabels

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

  # loop through, selecting each file in turn and procesing
  for k from 1 to 'numberOfSelectedSounds'

    # select sound file 'k' 
    soundName$ = sound'k'Name$
    soundNumber = sound'k'Number
    select 'soundNumber'

    # get textgrid information
    call find_textgrid_ob
    textGridName$ = selected$ ("TextGrid", 1)
    textGridNumber = selected ("TextGrid", 1)
    select 'textGridNumber'
    numberOfIntervals = Get number of intervals... 'which_tier'

    # check each labeled interval in turn
    for intervalNumber from 1 to 'numberOfIntervals'

      intervalLabel$ = Get label of interval... 'which_tier' 'intervalNumber'
      if (intervalLabel$ <> "")

        # get begin and end of interval
        beginInterval = Get starting point... 'which_tier' 'intervalNumber'
        endInterval = Get end point... 'which_tier' 'intervalNumber'

        # check for matching labels
        for i from 1 to 2
          # set variables
          targetInterval = ('intervalNumber' / 2)
          targetLabel$ = move_label_'i'$
          move_boundary = move_boundary_'i'
          move_amount = move_amount_'i'

          # check the full label for the target label component
          stringFound = 0
          stringFound = index (intervalLabel$, targetLabel$)

          if (('stringFound' > 0) or (move_label_1$ = "*"))
            move_amount = move_amount_'i'

            # transfer control to editor
            plus 'soundNumber'
            Edit
            editor TextGrid 'textGridName$'

            # select current interval
            Select... 'beginInterval' 'endInterval'

            # delete interval label
            endeditor
            select 'textGridNumber'
            Set interval text... 'which_tier' 'intervalNumber' 

            # set new boundary time(s), the direction and amount of move variables
            oldBeginInterval = 'beginInterval'
            oldEndInterval = 'endInterval'
            if (move_boundary = 2)
              beginInterval = ('beginInterval' + 'move_amount')
             endInterval = ('endInterval' + 'move_amount')
             elsif (move_boundary = 3)
              beginInterval = ('beginInterval' - 'move_amount')
              endInterval = ('endInterval' - 'move_amount')
             elsif (move_boundary = 4)
              beginInterval = ('beginInterval' + 'move_amount')
              endInterval = ('endInterval' - 'move_amount')
             elsif (move_boundary = 5)
              beginInterval = ('beginInterval' - 'move_amount')
              endInterval = ('endInterval' + 'move_amount')
             elsif (move_boundary = 6)
              beginInterval = ('beginInterval' + 'move_amount')
             elsif (move_boundary = 7)
              beginInterval = ('beginInterval' - 'move_amount')
             elsif (move_boundary = 8)
              endInterval = ('endInterval' + 'move_amount')
             elsif (move_boundary = 9)
              endInterval = ('endInterval' - 'move_amount')
            endif

            # open sound file with textgrid             
            select 'textGridNumber'
            plus 'soundNumber'
            editor TextGrid 'textGridName$'

            # add new boundaries, delete old ones
            select 'soundNumber'
            plus 'textGridNumber'
            editor TextGrid 'textGridName$'

            if 'beginInterval' <> 'oldBeginInterval'
              Move cursor to... 'beginInterval'
              Add on tier 'which_tier'
              Move cursor to... 'oldBeginInterval'
              Remove
            endif
            if 'endInterval' <> 'oldEndInterval'        
              Move cursor to... 'endInterval'
              Add on tier 'which_tier'
              Move cursor to... 'oldEndInterval'
              Remove
            endif

            # set new boundaries at zero-crossings, if desired
            if 'leave_boundaries_at_zero_crossings' = 1
              Move start of selection to nearest zero crossing
              beginInterval = Get cursor
              Move end of selection to nearest zero crossing
              endInterval = Get cursor
            endif

            # paste label back in
            Close
            endeditor
            select 'textGridNumber'
            Set interval text... 'which_tier' 'intervalNumber' 'intervalLabel$'

          endif
        endfor
      endif
    endfor
  endfor

  # reselect the original set
  select sound1Number
  for i from 2 to 'numberOfSelectedSounds'
    plus sound'i'Number
  endfor

  # select next file?
  if 'move_on_after' = 1 
    select 'soundNumber'
    plus 'textGridNumber'
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
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedObjects = numberOfSelected ()
  if 'numberOfSelectedObjects' = 2
    soundAndTextGrid = 1
  endif
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
endproc

############################################################
procedure open_sound_textgrid
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
  Show all
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
