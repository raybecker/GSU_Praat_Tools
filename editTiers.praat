# editTiers
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

# editTiers is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# editTiers is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query for...
form edit Tiers in TextGrid files
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (with labels)
    option Objects (with labels)
boolean Move_on_after 0
  comment Tiers are numbered from top to bottom in ascending order
  comment (tiers are automatically renumbered if an intermediate tier is inserted).
  optionmenu Edit_tier_task
    option set edit tier task first
    option add tier
    option remove tier
    option rename tier
    option edit tier name
  comment - add tier to the TextGrid.
  real Position_of_new_tier 2
  word Name_of_new_tier Tier
  comment - remove tier by number or by name.
  optionmenu Remove_tier
    option set removal option
    option by number
    option by name
  real Number_of_tier_to_remove 1
  word Name_of_tier_to_remove Tier
  comment - rename tier by number or by name.
  word New_name_for_tier Tier
  optionmenu Rename_tier
    option set renaming option
    option by number
    option by name
  real Number_of_tier_to_rename 1
  word Name_of_tier_to_rename Tier
  comment - edit tier name by searching for a particular existing name.
  word Set_tier_name_to Tier
  real Tier_number_to_search 1
  word Search_for_tier_name oldTier
endform

# check that task is set, otherwise alert user and exit
if ('edit_tier_task' = 1)
  clearinfo
  printline Error: Select edit Tier task
  printline
  exit
endif

# jump to selected processing mode
if ('processing_mode' = 1 )
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
    call select_first_labeled_interval
   else
    select 'soundNumber'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
  endif

  # select sound and textgrid, transfer control to editor
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'

  # get number, label, and time data of selected interval
  cursor = Get cursor
  endeditor
  select 'textGridNumber'
  intervalNumber =  Get interval at time... 'tier_for_editing_labels' 'cursor'
  call get_timedata_interval 'intervalNumber'
  select 'textGridNumber'
  oldIntervalLabel$ = Get label of interval... 'tier_for_editing_labels' 'intervalNumber'

##########################
# do tier editing

  # get number of tiers
  endeditor
  select 'textGridNumber'
  numberOfTiers = Get number of tiers
  plus 'soundNumber'
  editor Sound 'soundName$'

  if ('edit_tier_task' = 2)
    # add a new tier
    Add interval tier... 'position_of_new_tier$' 'name_of_new_tier$'

   elsif ('edit_tier_task' = 3)
    # remove an existing tier by number or name
    endeditor
    select 'textGridNumber'
    if ('remove_tier' = 2)
      Remove tier... 'number_of_tier_to_remove'
     else
      oldTierName$ = Get tier name
      for i from 1 to 'numberOfTiers'
        oldTierName$ = Get tier name... 'i'
        if ('oldTierName$' = 'name_of_tier_to_remove$')
          Remove tier... 'i'
          i = 'i' - 1
        endif
      endfor
    endif
    plus 'soundNumber'
    editor Sound 'soundName$'

   elsif ('edit_tier_task' = 4)
    # rename a existing tier by number or by name
    endeditor
    select 'textGridNumber'
    if ('rename_tier' = 2)
      Set tier name... number newTierName$'
     else
      oldTierName$ = Get tier name
      if ('oldTierName$' = 'name_of_tier_to_rename$')
        Rename tier... 'new_name_for_tier'
      endif
    endif
    plus 'soundNumber'
    editor Sound 'soundName$'

  else
   # edit tier name by number or by name
    endeditor
    select 'textGridNumber'
    oldTierName$ = Get tier name... "tier_number_to_search'
    if ('oldTierName$' = 'search_for_tier_name$')
      Set tier name... 'tier_number_to_search' 'set_tier_name_to')
    endif

  endif

  # reselect original file, transfer to editor
  select 'soundNumber'
   plus 'textGridNumber'
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

  # loop through, selecting each file in turn and doing label replacement
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
    numberOfIntervals = Get number of intervals... 'tier_for_editing_labels'

    # check each labeled interval in turn
    for intervalNumber from 1 to 'numberOfIntervals'

      oldIntervalLabel$ = Get label of interval... 'tier_for_editing_labels' 'intervalNumber'
      if (oldIntervalLabel$ <> "")

        # get begin and end of interval
        beginInterval = Get starting point... 'tier_for_editing_labels' 'intervalNumber'
        endInterval = Get end point... 'tier_for_editing_labels' 'intervalNumber'

        if (oldIntervalLabel$ <> "")
          targetInterval = ('intervalNumber' / 2)
          # check for matching labels
          for i from 1 to 4
            # set variables for new and old label  
            old_label$ = old_label'i'$
            new_label$ = new_label'i'$
            newIntervalLabel$ = "'targetInterval' 'new_label$'"
            # find first space in label string, strip off leading digit(s)
            firstSpace = index (oldIntervalLabel$, " ")
            labelLength = length (oldIntervalLabel$)
            oldIntervalLabelStripped$ = mid$(oldIntervalLabel$, 'firstSpace'+1, 'labelLength')
            # if the labels match, replace the old with the new
            if (oldIntervalLabelStripped$ = old_label$)
              # delete old label, paste in replacement label
              Set interval text... 'tier_for_editing_labels' 'intervalNumber' 
              Set interval text... 'tier_for_editing_labels' 'intervalNumber' 'newIntervalLabel$'
            endif
 
         endfor
        endif
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
procedure get_timedata_interval currentIntervalNumber
  select 'textGridNumber'
  beginInterval = Get starting point... 1 'currentIntervalNumber'
  endInterval = Get end point... 1 'currentIntervalNumber'
  durInterval = 'endInterval' - 'beginInterval'
  midInterval = 'beginInterval' + ('durInterval' / 2)
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
