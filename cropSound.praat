# cropSound
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

# cropSound is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# cropSound is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for cropping parameters
form crop Sound
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Objects (no labels)
  boolean Move_on_after 0
  boolean At_zero_crossings 0
  comment  Editor mode:
  comment     - crop by a fixed duration from one or both ends, or
  comment     - drag the cursor to select a selection to retain.
  optionmenu select_Editor_cropping_mode 1 
    option set cropping mode first
    option crop by fixed duration
    option crop to selected segment
  comment  Objects mode, crop by a fixed duration from one or both ends.
  real Fixed_crop_duration_(ms) 100
  optionmenu Crop_location 1
    option both ends
    option beginning
    option end
endform

# jump to selected processing mode
if ('processing_mode' = 1)
  clearinfo
  printline
  printline Error: Select processing mode!
  printline
  printline Editor (no labels): Select one sound and open it in the Sound Editor
  printline Objects (no labels): Select one sound or more sounds, making sure there are no editors open
  exit
 elsif ('processing_mode' = 2) 
  call editor_nolabels
 elsif ('processing_mode' = 3) 
  call objects_nolabels
endif

################## run with Editor window: no labels ##################
procedure editor_nolabels

  # make sure control lies with Objects window
  endeditor

  # get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  select 'soundNumber'
 
  # get sampling frequency, reset times if needed, get file temporal information
  sf = Get sampling frequency
  Shift times to... "start time" 0
  beginFile = Get start time
  endFile = Get end time
  durFile = Get total duration

  # send control back to SoundEditor, get selection times
  editor Sound 'soundName$'
  call get_timedata_selection

  # check that a segment has been selected if needed
  # otherwise alert user and exit
  if (('beginTarget' = 'endTarget') and ('select_Editor_cropping_mode' = 3))
    clearinfo
    printline
    printline Error: Drag cursor to select segment to retain
    printline
    exit
  endif
  # make sure control lies with Objects window
  endeditor

  # send control back to SoundEditor
  editor Sound 'soundName$'

  # crop based on fixed duration
  if ('select_Editor_cropping_mode' = 2) 
    # convert crop length to seconds
    crop_seconds = ('fixed_crop_duration' / 1000) 
    # set target times
    endTarget = 'crop_seconds'
    beginTarget = 'crop_seconds'
    # crop end
    if ( 'crop_location' <> 2 )
      Select... ('endFile'-'endTarget') 'endFile'
      if ( 'at_zero_crossings' = 1 )
        Move begin of selection to nearest zero crossing
      endif
      Cut
    endif
    # crop beginning
    if ( 'crop_location' <= 2 )
      Select... 'beginFile' ('beginFile'+'beginTarget')
      if ( 'at_zero_crossings' = 1 )
        Move end of selection to nearest zero crossing
      endif
      Cut
    endif
  endif

  # crop based on user selection
  if ('select_Editor_cropping_mode' = 3) 
    # get selection
    beginTarget = Get begin of selection
    endTarget = Get end of selection
    Select... 'beginTarget' 'endTarget'

    # move begin and end markers to zero-crossings
    if ( 'at_zero_crossings' = 1 )
      if ( 'beginTarget' > 'beginFile' )
        Move begin of selection to nearest zero crossing
      endif
      if ( 'endTarget' < 'endFile' )
        Move end of selection to nearest zero crossing
      endif
      beginTarget = Get start of selection
      endTarget = Get end of selection
    endif
  endif
  # crop based on user selection
  if ('select_Editor_cropping_mode' = 3) 
    if ('endTarget' <> 'endFile')
      Select... 'endTarget' 'endFile'
      Cut
    endif
    if ('beginTarget' <> 'beginFile')
      Select... 'beginFile' 'beginTarget'
      Cut
    endif
  endif
  Show all

  # go on to a new file or quit
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################## run with Objects window: no labels #################
procedure objects_nolabels

  # count number of selected sounds in the Objects window
  numberOfSelectedSounds = numberOfSelected ("Sound")

  # loop through all the sound files, getting names and id numbers
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor

  # loop through, selecting each file in turn and editing
  for i from 1 to 'numberOfSelectedSounds'

    # get number and name of current sound file
    soundNumber = sound'i'Number
    soundName$ = sound'i'Name$
    select 'soundNumber'

    # get sampling frequency, reset times if needed, get file temporal information
    sf = Get sampling frequency
    Shift times to... "start time" 0
    beginFile = Get start time
    endFile = Get end time
    durFile = Get total duration

   # convert crop length to seconds
    crop_seconds = ('fixed_crop_duration'/ 1000)
  
    # set target times
    endTarget = 'durFile' - 'crop_seconds'
    beginTarget = 'crop_seconds'

    # crop end
    if ( 'crop_location' <> 2 )
      Edit
      editor Sound 'soundName$'
      Select... 'endTarget' 10000.0
      Cut
      Close
      endeditor
    endif

    # crop beginning
    if ( 'crop_location' <= 2 )
      Edit
      editor Sound 'soundName$'
      Select... 0.0 'beginTarget'
      Cut
      Close
      endeditor
    endif

    # get new file duration
    select 'soundNumber'
    durFile = Get total duration

  # loop to next file
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
procedure get_timedata_selection
  beginTarget = Get start of selection
  endTarget = Get end of selection
  durTarget = 'endTarget' - 'beginTarget'
  midTarget = 'beginTarget' + ('durTarget' / 2)
  endeditor
endproc

############################################################
procedure prompt_for_target
  if beginTarget = endTarget 
    pause Drag cursor to mark target segment
    # send control back to SoundEditor
    editor Sound 'soundName$'
    # compute begin and end times, set window
    beginTarget = Get begin of selection
    endTarget = Get end of selection
    Select... 'beginTarget' 'endTarget'
  endif
endproc

############################################################
procedure still_not_set
  if beginTarget = endTarget
    # set window length based on millisec values
    window_size = ('window_in_millisecs' / 1000)
    # if a preset points value has been entered, change to that
    if 'window_in_points' > 1
      call set_window_points
    endif
    # set window around cursor location
    call set_window_around_cursor
  endif
endproc
