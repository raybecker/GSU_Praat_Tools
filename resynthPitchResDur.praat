# resynthPitchResDur
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

# resynthPitchResDur is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# resynthPitchResDur is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set program name, operating system, directory paths and names as needed
programName$ = "resynthPitchResDur"
dataFile$ = "resynthpitchresdur.out"
call set_data_paths

# bring up a user dialog box for pitch modification
form resynthesize sounds, modifying pitch, resonance, duration
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Editor (with labels)
    option Objects (no labels)
    option Objects (with labels)
  boolean Move_on_after 0
  boolean Save_final_sound 1
  optionmenu Resynthesis_method 1
    option overlap-add
    option lpc
  optionmenu Pitch_modification 1
    option none
    option edit by hand
    option flatten to mean value
    option flatten to fixed value
    option change by scalar
    option NOT QUITE READY (change range by scalar)
    option add or subtract constant
  real Fixed_pitch_value_(Hz) 115
  real Pitch_scalar 1.0
  real Pitch_range_scalar 1.0
  real Constant_pitch_value_(Hz) 10.0
  real Jitter_factor_(%) 0.0
  comment Resonance scalar, duration scalar, and pitch extraction parameters...
  real Resonance_scalar 1.0
  real Duration_scalar 1.0
  real Pitch_time_step_(s) 0.01
  positive Pitch_min_pitch_(Hz) 75
  positive Pitch_max_pitch_(Hz) 600
  optionmenu Window_placement 1
    option entire file or interval
    option selected segment
    option around midpoint
    option around peak amplitude
    option around cursor
    option forward from cursor
    option backward from cursor
    option forward from beginning
    option backward from end
  boolean Boundaries_at_zero_crossings 0
  real Percentage_of_file_interval_selection 100
  real Window_in_millisecs 50
  optionmenu Window_in_points 1
    option 0
    option 32
    option 64
    option 128
    option 256
    option 512
    option 1024
    option 2048
    option 4096
endform

# check if the <Manipulation> utiity will be used
manipulationUtility = 0
if (('pitch_modification' = 2) or ('pitch_modification' = 3) or ('pitch_modification' = 4)
  ...or ('pitch_modification' = 5) or ('pitch_modification' = 6) or ('pitch_modification' = 7) 
  ...or ('jitter_factor' > 0.0))
  manipulationUtility = 1
endif

# check if the <Change gender...> command will be used
changeGender = 0
if ('pitch_modification' = 6) or ('resonance_scalar' <> 1.0) or ('duration_scalar' <> 1.0)
  changeGender = 1
endif

# check that a modification has been made
if (('manipulationUtility' = 0) and ('changeGender' = 0))
  clearinfo
  printline
  printline Error: Select a manipulation to perform!
  printline
  exit
endif

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# set zeropadding variable
zeroPadSecs = 0.1

# set resynthesis method name
if ('resynthesis_method' = 1)
  resynthMethod$ = "Ola"
 else
  resynthMethod$ = "Lpc"
endif

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
  call editor_nolabels
 elsif ('processing_mode' = 3) 
  call editor_withlabels
 elsif ('processing_mode' = 4) 
  call objects_nolabels
 elsif ('processing_mode' = 5) 
  call objects_withlabels
endif

################## run with Editor window: no labels ##################
procedure editor_nolabels

  # make sure control lies with Objects window
  endeditor
  
  # get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # set sampling frequency
  sf = Get sampling frequency

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  select 'soundNumber'
 
  # transfer control to editor
  editor Sound 'soundName$'

  # get selection times to test whether a window has been set,
  # begin and end are the same when file is first opened in Editor
  cursor =  Get cursor
  beginTarget = Get begin of selection
  endTarget = Get end of selection

  # alert user and quit if selection and window size/placement are mismatched
  if (('beginTarget' = 'endTarget') and ('window_placement' = 2))
    clearinfo
    printline
    printline Analysis window error!
    printline ...select a segment, or
    printline ...redo window placement
    printline 
    exit
  endif
  if (('beginTarget' <> 'endTarget') and  (('window_placement' >= 5) and ('window_placement' <= 7))) 
    clearinfo
    printline
    printline Analysis window error!
    printline ...reset cursor to single location, or
    printline ...redo window placement
    printline 
    exit
  endif

  # set window size, get time data at file and selection levels
  endeditor
  call set_window_size
  call get_timedata_entirefile
  if 'beginTarget' <> 'endTarget'
    editor Sound 'soundName$'
    call get_timedata_selection
  endif

  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire file
    window_size = ('durFile' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midFile' - ('window_size' / 2))
    endTarget = ('midFile' + ('window_size' / 2))
   elsif 'window_placement' = 2
    # selected segment
    window_size = ('durSelection' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midSelection' - ('window_size' / 2))
    endTarget = ('midSelection' + ('window_size' / 2))
   elsif 'window_placement' = 3
    # midpoint in file
    call set_window_around_timepoint midFile
   elsif 'window_placement' = 4
    # relative to peak amplitude in file
    call set_window_around_timepoint peakFile   
   elsif 'window_placement' = 5
    # around current cursor location
    call set_window_around_timepoint cursor
   elsif 'window_placement' = 6
    # forward from current cursor location
    call set_window_around_timepoint ('cursor' + ('window_size' / 2))
   elsif 'window_placement' = 7
    # backward from current cursor location
    call set_window_around_timepoint ('cursor' - ('window_size' / 2))
   elsif 'window_placement' = 8
    # forward from beginning of file
    beginTarget = 'beginFile'
    endTarget = 'beginFile' + 'window_size'
   elsif 'window_placement' = 9
    # backward from end of file
    beginTarget = 'endFile' - 'window_size'
    endTarget = 'endFile'
  endif

  # set the window 
  editor Sound 'soundName$'
  Select... 'beginTarget' 'endTarget'

  # adjust boundaries to zero-crossings if desired
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget = Get start of selection
    endTarget = Get end of selection
  endif

  # set other target segment times
  durTarget = 'endTarget' - 'beginTarget'
  midTarget = 'beginTarget' + ('durTarget' / 2)

  # extract to Objects window, with file name
  Extract selected sound (time from 0)
  endeditor

  # name extracted segment by file name, begin and end times in ms
  beginMs = 'beginTarget' * 1000
  endMs = 'endTarget' * 1000
  Rename... 'soundName$''beginMs:0'to'endMs:0'
  targetsegmentNumber = selected ("Sound")
  targetsegmentName$ = selected$ ("Sound")
  # zeropad the file for better pitch extraction
  call sound_zero_pad

  # is <Manipulation> utility needed?
  if ('manipulationUtility' = 1)

    # use the manipulation utility to extract the pitch contour
    select 'targetsegmentNumber'
    To Manipulation... 'pitch_time_step' 'pitch_min_pitch' 'pitch_max_pitch'
    manipulationName$ = selected$ ("Manipulation")
    manipulationNumber = selected ("Manipulation")
    Extract pitch tier
    pitchtierNumber = selected ("PitchTier")
    Rename... 'targetsegmentName$'
    pitchMean = Get mean (curve)... 0 0

    # edit the contour by hand
    if ('pitch_modification' = 2)
      select 'manipulationNumber'
      Edit
      editor Manipulation 'manipulationName$'
      pause Hit Continue or Stop
      Close
      endeditor
    endif

    # manipulate the contour by formula
     if ('pitch_modification' = 3)
      # set the pitch contour to its mean value
      Formula... 'pitchMean'
     elsif ('pitch_modification' = 4)
      # set the pitch contour to a fixed value
      Formula... 'fixed_pitch_value'
     elsif ('pitch_modification' = 5)
      # shift the pitch contour by a scalar amount
      Formula... self * 'scalar_value'
     elsif ('pitch_modification' = 6)
#      # shift the pitch range by a scalar amount
#      Formula... self * 'scalar_value'
     elsif ('pitch_modification' = 7)
      # add or subtract a contant value
      Formula... self + 'constant_pitch_value'
    endif

    # jitter the new pitch contour, if desired
    if ('jitter_factor' > 0)
      jitter_Hz = ('jitter_factor' * 'pitchMean') / 100
      Formula... self + randomInteger (-'jitter_Hz','jitter_Hz')
    endif

    # if by formula, replace the contour in the manipulation utility
    if ('pitch_modification' >= 3)
      select Manipulation 'targetsegmentName$'
      plus PitchTier 'targetsegmentName$'
      Replace pitch tier
    endif

    # re-synthesize and scale the sound
    select Manipulation 'targetsegmentName$'
    if ('resynthesis_method' = 1)
      Get resynthesis (overlap-add)
     else
      Get resynthesis (LPC)
    endif
      resynthNumber = selected ("Sound")
      Scale... 0.99

  endif

  # is <Change gender...> command needed?
  if ('changeGender' = 1)
    Change gender... 'pitch_min_pitch' 'pitch_max_pitch' 'resonance_scalar' 0.0 'pitch_range_scalar' 'duration_scalar'
    Scale... 0.99
  endif

  # rename the final file
  finalResynthNumber = selected ("Sound")
  Rename... 'soundName$''beginMs:0'to'endMs:0'prd'resynthMethod$'
  finalResynthName$ = selected$ ("Sound")

  # save final sound to disk, if desired
  call save_data_to_disk

  # clean up
  select 'targetsegmentNumber'
    if ('manipulationUtility' = 1)
      plus 'manipulationNumber'
      plus 'pitchtierNumber'
    endif
    if (('manipulationUtility' = 1) and ('changeGender' = 1))
      plus 'resynthNumber'
    endif
  Remove

  # reopen the original sound
  select 'soundNumber'
  editor Sound 'soundName$'

  # go on to a new file or quit
  select 'soundNumber'
  editor Sound 'soundName$'
  Select... 'beginTarget' 'endTarget'
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################## run with Editor window: with labels ################
procedure editor_withlabels

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

  # select only sound file to get sampling frequency
  select 'soundNumber'
  sf = Get sampling frequency

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

  # get selection times to test whether a window has been set,
  # begin and end are the same when file is first opened in Editor
  cursor =  Get cursor
  beginTarget = Get start of selection
  endTarget = Get end of selection

  # alert user and quit if selection and window size/placement are mismatched
  if (('beginTarget' = 'endTarget') and ('window_placement' = 2))
    clearinfo
    printline
    printline Analysis window error!
    printline ...select a segment, or
    printline ...redo window placement
    printline 
    exit
  endif
  if (('beginTarget' <> 'endTarget') and  (('window_placement' >= 5) and ('window_placement' <= 7))) 
    clearinfo
    printline
    printline Analysis window error!
    printline ...reset cursor to single location, or
    printline ...redo window placement
    printline 
    exit
  endif

  # set window size, get time data at file, interval, and selection levels
  endeditor
  select 'soundNumber'
  call set_window_size
  call get_timedata_entirefile
  select 'textGridNumber'
  numberOfIntervals = Get number of intervals... 1
  call interval_number_from_time 'cursor'
  select 'soundNumber'
  call get_timedata_interval 'intervalNumber'
  if 'beginTarget' <> 'endTarget'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
    call get_timedata_selection
    select 'soundNumber'
  endif

  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire interval
    window_size = ('durInterval' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midInterval' - ('window_size' / 2))
    endTarget = ('midInterval' + ('window_size' / 2))
   elsif 'window_placement' = 2
    # selected segment
    window_size = ('durSelection' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midSelection' - ('window_size' / 2))
    endTarget = ('midSelection' + ('window_size' / 2))
   elsif 'window_placement' = 3
    # midpoint in file
    call set_window_around_timepoint midInterval
   elsif 'window_placement' = 4
    # relative to peak amplitude in interval
    call set_window_around_timepoint peakInterval
   elsif 'window_placement' = 5
    # around current cursor location
    call set_window_around_timepoint cursor
   elsif 'window_placement' = 6
    # forward from current cursor location
    call set_window_around_timepoint ('cursor' + ('window_size' / 2))
   elsif 'window_placement' = 7
    # backward from current cursor location
    call set_window_around_timepoint ('cursor' - ('window_size' / 2))
   elsif 'window_placement' = 8
    # forward from beginning of interval
    beginTarget = 'beginInterval'
    endTarget = 'beginInterval' + 'window_size'
   elsif 'window_placement' = 9
    # backward from end of interval
    beginTarget = 'endInterval' - 'window_size'
    endTarget = 'endInterval'
  endif

  # set the window
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Select... 'beginTarget' 'endTarget'

  # adjust boundaries to zero-crossings if selected, adjust times
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget = Get start of selection
    endTarget = Get end of selection
  endif

  # set other target segment times
  durTarget = 'endTarget' - 'beginTarget'
  midTarget = 'beginTarget' + ('durTarget' / 2)

  # extract to Objects window, with file name
  Extract selected sound (time from 0)
  endeditor

  # name extracted segment by file name, begin and end times in ms
  beginMs = 'beginTarget' * 1000
  endMs = 'endTarget' * 1000
  Rename... 'soundName$''beginMs:0'to'endMs:0'
  targetsegmentNumber = selected ("Sound")
  targetsegmentName$ = selected$ ("Sound")
  # zeropad the file for better pitch extraction
  call sound_zero_pad

  # get labels associated across all tiers
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  # is <Manipulation> utility needed?
  if ('manipulationUtility' = 1)

    # use the manipulation utility to extract the pitch contour
    select 'targetsegmentNumber'
    To Manipulation... 'pitch_time_step' 'pitch_min_pitch' 'pitch_max_pitch'
    manipulationName$ = selected$ ("Manipulation")
    manipulationNumber = selected ("Manipulation")
    Extract pitch tier
    pitchtierNumber = selected ("PitchTier")
    Rename... 'targetsegmentName$'
    pitchMean = Get mean (curve)... 0 0

    # edit the contour by hand
    if ('pitch_modification' = 2)
      select 'manipulationNumber'
      Edit
      editor Manipulation 'manipulationName$'
      pause Hit Continue or Stop
      Close
      endeditor
    endif

    # manipulate the contour by formula
     if ('pitch_modification' = 3)
      # set the pitch contour to its mean value
      Formula... 'pitchMean'
     elsif ('pitch_modification' = 4)
      # set the pitch contour to a fixed value
      Formula... 'fixed_pitch_value'
     elsif ('pitch_modification' = 5)
      # shift the pitch contour by a scalar amount
      Formula... self * 'scalar_value'
     elsif ('pitch_modification' = 6)
#      # shift the pitch range by a scalar amount
#      Formula... self * 'scalar_value'
     elsif ('pitch_modification' = 7)
      # add or subtract a contant value
      Formula... self + 'constant_pitch_value'
    endif

    # jitter the new pitch contour, if desired
    if ('jitter_factor' > 0)
      jitter_Hz = ('jitter_factor' * 'pitchMean') / 100
      Formula... self + randomInteger (-'jitter_Hz','jitter_Hz')
    endif

    # if by formula, replace the contour in the manipulation utility
    if ('pitch_modification' >= 3)
      select Manipulation 'targetsegmentName$'
      plus PitchTier 'targetsegmentName$'
      Replace pitch tier
    endif

    # re-synthesize and scale the sound
    select Manipulation 'targetsegmentName$'
    if ('resynthesis_method' = 1)
      Get resynthesis (overlap-add)
     else
      Get resynthesis (LPC)
    endif
      resynthNumber = selected ("Sound")
      Scale... 0.99

  endif

  # is <Change gender...> command needed?
  if ('changeGender' = 1)
    Change gender... 'pitch_min_pitch' 'pitch_max_pitch' 'resonance_scalar' 0.0 'pitch_range_scalar' 'duration_scalar'
    Scale... 0.99
  endif

  # rename the final file
  finalResynthNumber = selected ("Sound")
  Rename... 'soundName$''beginMs:0'to'endMs:0'prd'resynthMethod$'
  finalResynthName$ = selected$ ("Sound")

  # save final sound to disk, if desired
  call save_data_to_disk

  # clean up
  select 'targetsegmentNumber'
    if ('manipulationUtility' = 1)
      plus 'manipulationNumber'
      plus 'pitchtierNumber'
    endif
    if (('manipulationUtility' = 1) and ('changeGender' = 1))
      plus 'resynthNumber'
    endif
  Remove

  # go on to a new file or quit
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Select... 'beginTarget' 'endTarget'
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################## run with Objects window: no labels #################
procedure objects_nolabels

  # alert user and quit if selection and window size/placement are mismatched
  if ('window_placement' = 2)
    clearinfo
    printline
    printline Analysis window error!
    printline ...can't use "selected segment" in Objects mode
    printline ...redo window placement
    printline 
    exit
  endif
  if (('window_placement' = 5) or ('window_placement' = 6) or ('window_placement' = 7))
    clearinfo
    printline
    printline Analysis window error!
    printline ...can't use cursor-based windows in Objects mode
    printline ...redo window placement
    printline 
    exit
  endif

  # count number of selected sounds in the Objects window
  numberOfSelectedSounds = numberOfSelected ("Sound")
  if 'numberOfSelectedSounds' = 0
    echo No sound files selected! Please begin again...
    exit
  endif

  # loop through all the sound files, getting names and id numbers
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor

  # loop through, selecting each file in turn and analyzing
  for k from 1 to 'numberOfSelectedSounds'

    # select sound file 'k'
    soundName$ = sound'k'Name$
    soundNumber = sound'k'Number
    select 'soundNumber'

    # get the sampling frequency of the selected sound
    sf = Get sampling frequency

    # set window size, get time data at file level
    call set_window_size
    call get_timedata_entirefile

    # set beginTarget and endTarget according to window placement/size
    if 'window_placement' = 1
      # use entire file
      window_size = ('durFile' * ('percentage_of_file_interval_selection' / 100))
      beginTarget = ('midFile' - ('window_size' / 2))
      endTarget = ('midFile' + ('window_size' / 2))
     elsif 'window_placement' = 3
      # midpoint in file
      call set_window_around_timepoint midFile
     elsif 'window_placement' = 4
      # relative to peak amplitude in file
      call set_window_around_timepoint peakFile   
     elsif 'window_placement' = 8
      # forward from beginning of file
      beginTarget = 'beginFile'
      endTarget = 'beginFile' + 'window_size'
     elsif 'window_placement' = 9
      # backward from end of file
      beginTarget = 'endFile' - 'window_size'
      endTarget = 'endFile'
    endif

    # adjust boundaries to zero-crossings if desired
    Edit
    editor Sound 'soundName$'
    Select... 'beginTarget' 'endTarget'

    # adjust boundaries to zero-crossings if desired
    if 'boundaries_at_zero_crossings' = 1
      Move start of selection to nearest zero crossing
      Move end of selection to nearest zero crossing
      beginTarget = Get start of selection
      endTarget = Get end of selection
      Select... 'beginTarget' 'endTarget'
    endif

    # set other target segment times
    durTarget = 'endTarget' - 'beginTarget'
    midTarget = 'beginTarget' + ('durTarget' / 2)

    # extract to Objects window, with file name
    Extract selected sound (time from 0)
    endeditor

    # name extracted segment by file name, begin and end times in ms
    beginMs = 'beginTarget' * 1000
    endMs = 'endTarget' * 1000
    Rename... 'soundName$''beginMs:0'to'endMs:0'
    targetsegmentNumber = selected ("Sound")
    targetsegmentName$ = selected$ ("Sound")

    # zeropad the file for better pitch extraction
    call sound_zero_pad

    # is <Manipulation> utility needed?
    if ('manipulationUtility' = 1)

      # use the manipulation utility to extract the pitch contour
      select 'targetsegmentNumber'
      To Manipulation... 'pitch_time_step' 'pitch_min_pitch' 'pitch_max_pitch'
      manipulationName$ = selected$ ("Manipulation")
      manipulationNumber = selected ("Manipulation")
      Extract pitch tier
      pitchtierNumber = selected ("PitchTier")
      Rename... 'targetsegmentName$'
      pitchMean = Get mean (curve)... 0 0

      # edit the contour by hand
      if ('pitch_modification' = 2)
        select 'manipulationNumber'
        Edit
        editor Manipulation 'manipulationName$'
        pause Hit Continue or Stop
        Close
        endeditor
      endif

      # manipulate the contour by formula
      if ('pitch_modification' = 3)
        # set the pitch contour to its mean value
        Formula... 'pitchMean'
       elsif ('pitch_modification' = 4)
        # set the pitch contour to a fixed value
        Formula... 'fixed_pitch_value'
       elsif ('pitch_modification' = 5)
        # shift the pitch contour by a scalar amount
        Formula... self * 'pitch_scalar'
      elsif ('pitch_modification' = 6)
#      # shift the pitch range by a scalar amount
#      Formula... self * 'scalar_value'
      elsif ('pitch_modification' = 7)
        # add or subtract a contant value
      Formula... self + 'constant_pitch_value'
      endif

      # jitter the new pitch contour, if desired
      if ('jitter_factor' > 0)
        jitter_Hz = ('jitter_factor' * 'pitchMean') / 100
        Formula... self + randomInteger (-'jitter_Hz','jitter_Hz')
      endif

      # if by formula, replace the contour in the manipulation utility
      if ('pitch_modification' >= 3)
        select Manipulation 'targetsegmentName$'
        plus PitchTier 'targetsegmentName$'
        Replace pitch tier
      endif

      # re-synthesize and rescale the sound
      select Manipulation 'targetsegmentName$'
      if ('resynthesis_method' = 1)
        Get resynthesis (overlap-add)
       else
        Get resynthesis (LPC)
      endif
      resynthNumber = selected ("Sound")
      Scale... 0.99

    endif

    # is <Change gender...> command needed?
    if ('changeGender' = 1)
      Change gender... 'pitch_min_pitch' 'pitch_max_pitch' 'resonance_scalar' 0.0 'pitch_range_scalar' 'duration_scalar'
      Scale... 0.99
    endif

    # rename the final file
    finalResynthNumber = selected ("Sound")
    Rename... 'soundName$''beginMs:0'to'endMs:0'prd'resynthMethod$'
    finalResynthName$ = selected$ ("Sound")

    # save final sound to disk, if desired
    call save_data_to_disk

    # clean up
    select 'soundNumber'
    editor Sound 'soundName$'
    Close
    endeditor
    select 'targetsegmentNumber'
      if ('manipulationUtility' = 1)
        plus 'manipulationNumber'
        plus 'pitchtierNumber'
      endif
      if (('manipulationUtility' = 1) and ('changeGender' = 1))
        plus 'resynthNumber'
      endif
    Remove

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

################# run with Objects window: with labels #################
procedure objects_withlabels

  # alert user and quit if selection and window size/placement are mismatched
  if ('window_placement' = 2)
    clearinfo
    printline
    printline Analysis window error!
    printline ...can't use "selected segment" in Objects mode
    printline ...redo window placement
    printline 
    exit
  endif
  if (('window_placement' = 5) or ('window_placement' = 6) or ('window_placement' = 7))
    clearinfo
    printline
    printline Analysis window error!
    printline ...can't use cursor-based windows in Objects mode
    printline ...redo window placement
    printline 
    exit
  endif

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

    # get the sampling frequency of the selected sound
    sf = Get sampling frequency

    # get textgrid information
    call find_textgrid_ob
    textGridName$ = selected$ ("TextGrid", 1)
    textGridNumber = selected ("TextGrid", 1)
    select 'textGridNumber'
    numberOfIntervals = Get number of intervals... 1

    # analyze each labeled interval in turn
    for intervalNumber from 1 to 'numberOfIntervals'

      currentLabel$ = Get label of interval... 1 'intervalNumber'
      if currentLabel$ <> ""

        # set window size, get time data at file and interval levels
        select 'soundNumber'
        call set_window_size
        call get_timedata_entirefile
        select 'textGridNumber'
        call get_timedata_interval 'intervalNumber'
        select 'soundNumber'

        # set beginTarget and endTarget according to window placement/size
        if 'window_placement' = 1
          # use entire interval
          window_size = ('durInterval' * ('percentage_of_file_interval_selection' / 100))
          beginTarget = ('midInterval' - ('window_size' / 2))
          endTarget = ('midInterval' + ('window_size' / 2))
         elsif 'window_placement' = 3
          # midpoint in file
          call set_window_around_timepoint midInterval
         elsif 'window_placement' = 4
          # relative to peak amplitude in interval
          call set_window_around_timepoint peakInterval
         elsif 'window_placement' = 8
          # forward from beginning of interval
          beginTarget = 'beginInterval'
          endTarget = 'beginInterval' + 'window_size'
         elsif 'window_placement' = 9
          # backward from end of interval
          beginTarget = 'endInterval' - 'window_size'
          endTarget = 'endInterval'
        endif

        # set the window
        plus 'textGridNumber'
        Edit
        editor TextGrid 'textGridName$'
        Select... 'beginTarget' 'endTarget'

        # adjust boundaries to zero-crossings if desired
        if 'boundaries_at_zero_crossings' = 1
          Move start of selection to nearest zero crossing
          Move end of selection to nearest zero crossing
          beginTarget = Get start of selection
          endTarget = Get end of selection
        endif

        # set other target segment times
        durTarget = 'endTarget' - 'beginTarget'
        midTarget = 'beginTarget' + ('durTarget' / 2)

        # extract to Objects window, with file name
        Extract selected sound (time from 0)
        endeditor

       # name extracted segment by file name, begin and end times in ms
       beginMs = 'beginTarget' * 1000
       endMs = 'endTarget' * 1000
       Rename... 'soundName$''beginMs:0'to'endMs:0'
       targetsegmentNumber = selected ("Sound")
       targetsegmentName$ = selected$ ("Sound")

        # zeropad the file for better pitch extraction
        call sound_zero_pad

        # get labels associated across all tiers
        select 'textGridNumber'
        call get_labels_raw midTarget
        call get_label_number
        call parse_interval_labels

        # concatenate labels at tier and interval levels
        call concatenate_labels

        # is <Manipulation> utility needed?
        if ('manipulationUtility' = 1)

          # use the manipulation utility to extract the pitch contour
          select 'targetsegmentNumber'
          To Manipulation... 'pitch_time_step' 'pitch_min_pitch' 'pitch_max_pitch'
          manipulationName$ = selected$ ("Manipulation")
          manipulationNumber = selected ("Manipulation")
          Extract pitch tier
          pitchtierNumber = selected ("PitchTier")
          Rename... 'targetsegmentName$'
          pitchMean = Get mean (curve)... 0 0

          # edit the contour by hand
          if ('pitch_modification' = 2)
            select 'manipulationNumber'
            Edit
            editor Manipulation 'manipulationName$'
            pause Hit Continue or Stop
            Close
            endeditor
          endif

          # manipulate the contour by formula
          if ('pitch_modification' = 3)
            # set the pitch contour to its mean value
            Formula... 'pitchMean'
           elsif ('pitch_modification' = 4)
            # set the pitch contour to a fixed value
            Formula... 'fixed_pitch_value'
           elsif ('pitch_modification' = 5)
           # shift the pitch contour by a scalar amount
            Formula... self * 'pitch_scalar'
           elsif ('pitch_modification' = 6)
#         # shift the pitch range by a scalar amount
#          Formula... self * 'scalar_value'
           elsif ('pitch_modification' = 7)
            # add or subtract a contant value
           Formula... self + 'constant_pitch_value'
          endif

          # jitter the new pitch contour, if desired
          if ('jitter_factor' > 0)
            jitter_Hz = ('jitter_factor' * 'pitchMean') / 100
            Formula... self + randomInteger (-'jitter_Hz','jitter_Hz')
          endif

          # if by formula, replace the contour in the manipulation utility
          if ('pitch_modification' >= 3)
            select Manipulation 'targetsegmentName$'
            plus PitchTier 'targetsegmentName$'
            Replace pitch tier
          endif

          # re-synthesize and rescale the sound
          select Manipulation 'targetsegmentName$'
          if ('resynthesis_method' = 1)
            Get resynthesis (overlap-add)
           else
            Get resynthesis (LPC)
          endif
          resynthNumber = selected ("Sound")
          Scale... 0.99

        endif

        # is <Change gender...> command needed?
        if ('changeGender' = 1)
          Change gender... 'pitch_min_pitch' 'pitch_max_pitch' 'resonance_scalar' 0.0 'pitch_range_scalar' 'duration_scalar'
          Scale... 0.99
        endif

        # rename the final file
        finalResynthNumber = selected ("Sound")
        Rename... 'soundName$''beginMs:0'to'endMs:0'prd'resynthMethod$'
        finalResynthName$ = selected$ ("Sound")

        # save final sound to disk, if desired
        call save_data_to_disk

        # clean up
        select 'soundNumber'
        plus 'textGridNumber'
        editor TextGrid 'textGridName$'
        Close
        endeditor
        select 'targetsegmentNumber'
          if ('manipulationUtility' = 1)
            plus 'manipulationNumber'
            plus 'pitchtierNumber'
          endif
          if (('manipulationUtility' = 1) and ('changeGender' = 1))
            plus 'resynthNumber'
          endif
        Remove

      endif
      select 'textGridNumber'

    # loop to next interval
    endfor

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
    plus 'textGridNumber'
    execute nextTextGridObjects.praat
  endif

endproc

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

############################################################
procedure date_and_time
  date$ = date$ ()
  weekday$ = left$ (date$, 3)
  month$ = mid$ (date$, 5, 3)
  daynumber$ = mid$ (date$, 9, 2)
  if left$ (daynumber$, 1) = " "
   daynumber$ = right$ (daynumber$, 1)
  endif
  time$ = mid$ (date$, 12, 8)
  year$ = right$ (date$, 4)
endproc

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
procedure set_window_size
  # set window length based on millisec values
  window_size = ('window_in_millisecs' / 1000)
  # if a preset points value has been entered, change to that
  if 'window_in_points' > 1
    if 'window_in_points' = 2
      window_size = 32
     elsif 'window_in_points' = 3
      window_size = 64
     elsif 'window_in_points' = 4
      window_size = 128
     elsif 'window_in_points' = 5
      window_size = 256
     elsif 'window_in_points' = 6
      window_size = 512
     elsif 'window_in_points' = 7
      window_size = 1024
     elsif 'window_in_points' = 8
      window_size = 2048
     elsif 'window_in_points' = 9
      window_size = 4096
    endif
    window_size = (1 / sf) * 'window_size'
  endif
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
procedure get_timedata_selection
  beginSelection = Get start of selection
  endSelection = Get end of selection
  durSelection = 'endSelection' - 'beginSelection'
  midSelection = 'beginSelection' + ('durSelection' / 2)
  endeditor
  select 'soundNumber'
  peakSelection = Get time of maximum... 'beginSelection' 'endSelection' Sinc70
endproc

############################################################
procedure get_timedata_interval currentIntervalNumber
  select TextGrid 'textGridName$'
  beginInterval = Get starting point... 1 'currentIntervalNumber'
  endInterval = Get end point... 1 'currentIntervalNumber'
  durInterval = 'endInterval' - 'beginInterval'
  midInterval = 'beginInterval' + ('durInterval' / 2)
  endeditor
  select 'soundNumber'
  peakInterval = Get time of maximum... 'beginInterval' 'endInterval' Sinc70
  plus 'textGridNumber'
endproc

############################################################
procedure interval_number_from_time currentIntervalTime
  select TextGrid 'textGridName$'
  intervalNumber = Get interval at time... 1 'currentIntervalTime'
endproc

############################################################
procedure set_window_around_timepoint currentTime
  beginTarget = 'currentTime' - ( 'window_size' / 2)
  endTarget = 'currentTime' + ( 'window_size' / 2)
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
procedure sound_zero_pad
  # create a file that is the right length of zeros, copy to clipboard
  Create Sound from formula... TempZeroPad Mono 0.0 'zeroPadSecs' sf 0.0
  zerosoundNumber = selected ("Sound")
  select 'zerosoundNumber'
  Edit
  editor Sound TempZeroPad
  Select... 0.0 0.0
  Copy selection to Sound clipboard
  endeditor
  select 'zerosoundNumber'
  Remove
  # select original sound, open editor
  select 'targetsegmentNumber'
  Edit
  editor Sound 'targetsegmentName$'
  # paste silence at beginning and end
  Move cursor to... 0.0
  Paste after selection
  Move cursor to... 10000.0
  Paste after selection
  # close editor
  Close
endproc

############################################################
procedure save_data_to_disk
  if ('save_final_sound' = 1)
    select 'finalResynthNumber'
    Write to WAV file... 'dataDirectoryPath$''sl$''finalResynthName$'.wav
  endif
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
endproc

############################################################
procedure open_sound_textgrid
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
  editor TextGrid 'textGridName$'
  Show all
  endif
endproc

############################################################
# get the labels for each tier and the selected interval at each tier
procedure get_labels_raw targetTime
  select 'textGridNumber'
  numberOfTiers = Get number of tiers
  for i from 1 to 'numberOfTiers'
    tierName'i'$ = Get tier name... 'i'
  endfor
  for i from 1 to 'numberOfTiers'
    intervalNumber'i' = Get interval at time... 'i' 'targetTime'
    intervalLabel'i'$ = Get label of interval... 'i' intervalNumber'i'
  endfor
endproc

############################################################
# retrieve number preceding the labels
procedure get_label_number
  for i from 1 to 'numberOfTiers'
    # retrieve number preceding the labels
    intervalLabelString'i'$ = intervalLabel'i'$
    firstSpace = index (intervalLabelString'i'$, " ")
    intervalLabelNumber'i'$ = left$(intervalLabelString'i'$, firstSpace-1)
    # shave the number off the original string, including the trailing space
    intervalLabelString'i'$ = mid$(intervalLabelString'i'$, firstSpace+1, 10000)
  endfor
endproc

############################################################
# parse the label string into individual labels
procedure parse_interval_labels
  # the full interval label string minus the leading number is in intervalLabelString$
  for i from 1 to 'numberOfTiers'
    # remove any leading spaces then find length of string with all the labels
    while left$(intervalLabelString'i'$, 1) = " "
      intervalLabelString'i'$ = mid$(intervalLabelString'i'$, 2, 10000)
    endwhile
    remainingLength = length(intervalLabelString'i'$)
    numberOfIntervalLabelsTier'i' = 0
    j = 1
    # as long as there are labels to be retrieved, get the first one, then update string
    while 'remainingLength' >= 1
      firstSpace = index(intervalLabelString'i'$, " ")
      if firstSpace = 0
        # last label, retrieve and quit 
        intervalLabel'i''j'$ = intervalLabelString'i'$
        intervalLabelString'i'$ = "" 
       else
        # multiple labels remaining
        # retrieve and store the first label, not including trailing space
        intervalLabel'i''j'$ = left$(intervalLabelString'i'$, firstSpace-1)
        # shave the first label off the original string, including the trailing space
        intervalLabelString'i'$ = mid$(intervalLabelString'i'$, firstSpace+1, 10000) 
        # remove any leading spaces
        while left$(intervalLabelString'i'$, 1) = " "
          intervalLabelString'i'$ = mid$(intervalLabelString'i'$, 2, 10000)
        endwhile
       endif
       # update label counter for that tier
        numberOfIntervalLabelsTier'i' = numberOfIntervalLabelsTier'i' + 1
       remainingLength = length(intervalLabelString'i'$)   
       j = j + 1
    endwhile
  endfor 
endproc

############################################################
# concatenate labels, removing all spaces
procedure concatenate_labels
  for i from 1 to 'numberOfTiers'
    tierLabelString'i'$ = tierName'i'$ + intervalLabelNumber'i'$
  endfor
 # concatenate tier-level label strings, from the bottom up
  tierLabelStringConcat$ = ""
  tierLabelStringSpaced$ = ""
  i = 'numberOfTiers'
  while i >=1 
    tierLabelStringConcat$ = tierLabelStringConcat$ + tierLabelString'i'$
    tierLabelStringSpaced$ = tierLabelStringSpaced$ + tierLabelString'i'$ + " "
    i = i - 1
  endwhile
  # shave trailing space off tier-level label strings
  if right$(tierLabelStringConcat$, 1) = " "
    stringLength = length(tierLabelStringConcat$)
    tierLabelStringConcat$ = left$(tierLabelStringConcat$, stringLength-1)
  endif
  if right$(tierLabelStringSpaced$, 1) = " "
    stringLength = length(tierLabelStringSpaced$)
    tierLabelStringSpaced$ = left$(tierLabelStringSpaced$, stringLength-1)
  endif
  # concatenate interval-level label strings from first to last
  for i from 1 to 'numberOfTiers'
    intervalLabelStringConcat'i'$ = ""
    intervalLabelStringSpaced'i'$ = ""
    for j from 1 to numberOfIntervalLabelsTier'i'
      intervalLabelStringConcat'i'$ = intervalLabelStringConcat'i'$ + intervalLabel'i''j'$
      intervalLabelStringSpaced'i'$ = intervalLabelStringSpaced'i'$ + intervalLabel'i''j'$ + " "
    endfor
  endfor
  # shave trailing space off interval-level label strings
  for i from 1 to 'numberOfTiers'
    if right$(intervalLabelStringConcat'i'$, 1) = " "
      stringLength = length(intervalLabelStringConcat'i'$)
      intervalLabelStringConcat'i'$ = left$(intervalLabelStringConcat'i'$, stringLength-1)
    endif
    if right$(intervalLabelStringSpaced'i'$, 1) = " "
      stringLength = length(intervalLabelStringSpaced'i'$)
      intervalLabelStringSpaced'i'$ = left$(intervalLabelStringSpaced'i'$, stringLength-1)
    endif
  endfor
endproc
