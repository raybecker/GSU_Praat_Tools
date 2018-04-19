# quantifyCrosscorr
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

# quantifyCrosscorr is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# quantifyCrosscorr is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for crosscorrelation parameters
form quantify Crosscorrelation
  comment In Editor mode...
  comment - no labels: Open one sound, set window placement
  comment - with labels: Open one sound with its textgrid, set window.
  comment In Objects mode...
  comment - no labels, across files: Select two or more sounds, set window placement
  comment - with labels, within files: Select two or more sounds, set window
  comment - with labels, across files: Select two or more sounds, set window.
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Editor (with labels)
    option Objects: across files (no labels)
    option Objects: within files (with labels)
    option Objects: across files (with labels)
  boolean Move_on_after 0
  boolean Pause_to_check_data 0
  optionmenu Save_data_to_file 1
    option no data file
    option space-delimited (.out)
    option comma-delimited (.csv)
  boolean Include_data_header 0
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
  real From_lag_time -0.1
  real To_lag_time 0.1
  boolean Normalize 1
endform

# set program name, operating system, directory paths and names as needed
programName$ = "quantifyCrosscorr"
if ('save_data_to_file' = 3)
  dataFile$ = "quantifycrosscor.csv"
 else
  dataFile$ = "quantifycrosscor.out"
endif
call set_data_paths

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# jump to selected processing mode
if ('processing_mode' = 1)
  clearinfo
  printline
  printline Error: Select processing mode!
  printline
  exit
 elsif ('processing_mode' = 2)
  call editor_nolabels
 elsif ('processing_mode' = 3)
  call editor_withlabels
 elsif ('processing_mode' = 4)
  call objects_nolabels
 elsif ('processing_mode' = 5)
  call objects_withlabels_within
 elsif ('processing_mode' = 6)
  call objects_withlabels_across
endif

################## run with Editor window: no labels ##################
procedure editor_nolabels

  # make sure control lies with Objects window
  endeditor

  # get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # save original file name for reinstatement later
  origSoundName$ = soundName$
  origSoundNumber = 'soundNumber'

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  file1Name$ = origSoundName$
  file1Number = 'origSoundNumber'
  select 'file1Number'

  # transfer control to editor
  editor Sound 'file1Name$'

  # alert user as to how to select the first file or segment
  clearinfo
  printline Select sounds or segments for cross-correlation...
  printline
  printline The first segment will come from the open file.
  printline - set the cursor or select a segment, as desired
  printline - hit Continue or Stop in the Pause panel
  printline
  pause Hit Continue or Stop

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

  # set window size, get time data at file and selection levels
  endeditor
  sf = Get sampling frequency
  call set_window_size
    window_size1 = 'window_size'
  call get_timedata_entirefile
    durFile1 = 'durFile'
    midFile1 = 'midFile'
  if 'beginTarget' <> 'endTarget'
    editor Sound 'soundName$'
    call get_timedata_selection
    beginSelection1 = 'beginSelection'
    endSelection1 = 'endSelection'
    durSelection1 = 'durSelection'
    midSelection1 = 'midSelection'
  endif

  # set beginTarget and endTarget according to window placement/size
  call get_times_current_editor_nolabels
  editor Sound 'file1Name$'
  beginTarget1 = 'beginTarget'
  endTarget1 = 'endTarget'
  Select... 'beginTarget1' 'endTarget1'

  # adjust boundaries to zero-crossings if desired
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget1 = Get start of selection
    endTarget1 = Get end of selection
  endif

  # set other target segment times
  durTarget1 = 'endTarget1' - 'beginTarget1'
  midTarget1 = 'beginTarget1' + ('durTarget1' / 2)

  # extract the windowed segment
  Extract selected sound (time from 0)
  endeditor

  # set begin-end times in millisec and rename target segment
  beginMs1 = 'beginTarget1' * 1000
  endMs1 = 'endTarget1' * 1000
  Rename... 'soundName$'Int1
  targetsegment1Number = selected ("Sound")
  targetsegment1Name$ = selected$ ("Sound")

  # return control to the first sound editor
  select 'file1Number'
  editor Sound 'file1Name$'

  # alert user as to how to select the second file or segment
  clearinfo
  printline Select sounds or segments for cross-correlation...
  printline
  printline If the second segment is from the same sound...
  printline - set the cursor or select a segment, as needed
  printline - hit Continue or Stop in the Pause panel
  printline
  printline If the second segment is from a different sound...
  printline - close the current editor, open the new sound
  printline - set the cursor or select a segment, as desired
  printline - hit Continue or Stop in the Pause panel
  printline
  pause Hit Continue or Stop
  endeditor

  # get the name and id number of the sound the user has selected
  file2Name$ = selected$ ("Sound", 1)
  file2Number = selected ("Sound", 1)

  # transfer control to editor
  editor Sound 'file2Name$'

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

  # set window size, get time data at file and selection levels
  endeditor
  call set_window_size
    window_size2 = 'window_size'
  call get_timedata_entirefile
    durFile2 = 'durFile'
    midFile2 = 'midFile'
  if 'beginTarget' <> 'endTarget'
    editor Sound 'file2Name$'
    call get_timedata_selection
    beginSelection2 = 'beginSelection'
    endSelection2 = 'endSelection'
    durSelection2 = 'durSelection'
    midSelection2 = 'midSelection'
  endif

  # set beginTarget and endTarget according to window placement/size
  call get_times_current_editor_nolabels
  beginTarget2 = 'beginTarget'
  endTarget2 = 'endTarget'

  # set the window
  editor Sound 'file2Name$'
  Select... 'beginTarget2' 'endTarget2'

  # adjust boundaries to zero-crossings if desired
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget = Get start of selection
    endTarget = Get end of selection
  endif

  # set other target segment times
  durTarget2 = 'endTarget2' - 'beginTarget2'
  midTarget2 = 'beginTarget2' + ('durTarget2' / 2)

  # extract the windowed segment, return control to Objects window
  Extract selected sound (time from 0)
  Close
  endeditor

  # set begin-end times in millisec and rename target segment
  beginMs2 = 'beginTarget2' * 1000
  endMs2 = 'endTarget2' * 1000
  Rename... 'soundName$'Int2
  targetsegment2Number = selected ("Sound")
  targetsegment2Name$ = selected$ ("Sound")

  # cross-correlate the two target segments
  select 'targetsegment1Number'
  plus 'targetsegment2Number'
  Cross-correlate... 'from_lag_time' 'to_lag_time' 'normalize'

  # rename the cross-correlation file
  Rename... 'targetsegment1Name$'by'targetsegment2Name$'
  crosscorrName$ = selected$ ("Sound")
  crosscorrNumber = selected ("Sound")
  ccValue = Get maximum... 0.0 0.0 Sinc70

  # show data, save to file
  if ('pause_to_check_data' = 1)
    select 'crosscorrNumber'
    Edit
  endif
  call show_data_and_pause_nolabels
  if ('save_data_to_file' > 1)
    call data_to_file_nolabels
  endif

  # clean up
  select 'targetsegment1Number'
  plus 'targetsegment2Number'
  plus 'crosscorrNumber'
  Remove

  # reopen original sound
  select 'origSoundNumber'
  Edit
  editor Sound 'origSoundName$'

  # go on to a new file or quit
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
    origTextGridName$ = selected$ ("TextGrid", 1)
    origTextGridNumber = selected ("TextGrid", 1)
    text1Name$ = selected$ ("TextGrid", 1)
    text1Number = selected ("TextGrid", 1)
  endif

  # get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # save original file name for reinstatement later
  origSoundName$ = soundName$
  origSoundNumber = 'soundNumber'

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  file1Name$ = origSoundName$
  file1Number = 'origSoundNumber'
  select 'file1Number'

  # select first file
  file1Number = selected ("Sound")
  file1Name$ = selected$ ("Sound")

  # set soundName variable for compatibility with procedures
  soundNumber = 'file1Number'
  select 'soundNumber'
  soundName$ = selected$ ("Sound")

  # open or create textgrid with sound file
  # but do nothing if a textgrid is already open
  if 'soundAndTextGrid' <> 1
    call find_textgrid_ed
    call open_sound_textgrid
    text1Name$ = selected$ ("TextGrid", 1)
    text1Number = selected ("TextGrid", 1)
   else
    select 'file1Number'
    plus 'text1Number'
    editor TextGrid 'text1Name$'
  endif
  text1Name$ = selected$ ("TextGrid", 1)
  text1Number = selected ("TextGrid", 1)
  textGridName$ = text1Name$
  textGridNumber = 'text1Number'

  # get number of intervals in textgrid, back to editor
  endeditor
  select 'text1Number'
  numberOfIntervals1 = Get number of intervals... 1
  plus 'file1Number'
  editor TextGrid 'text1Name$'

  # alert user as to how to select the first interval or segment
  clearinfo
  printline Select sounds and labeled intervals for cross-correlation...
  printline
  printline The first interval will come from the open file.
  printline - set the cursor or select an interval, as desired
  printline - hit Continue or Stop in the Pause panel
  printline
  pause Hit Continue or Stop

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
    printline ...select an interval, or
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
  select 'file1Number'
  sf = Get sampling frequency
  call set_window_size
  call get_timedata_entirefile
  select 'text1Number'
  numberOfIntervals = Get number of intervals... 1
  call interval_number_from_time 'cursor'
  select 'file1Number'
  call get_timedata_interval 'intervalNumber'
  if 'beginTarget' <> 'endTarget'
    plus 'text1Number'
    editor TextGrid 'text1Name$'
    call get_timedata_selection
    select 'file1Number'
  endif

  # set beginTarget and endTarget according to window placement/size
  call get_times_current_editor_withlabels
  beginTarget1 = 'beginTarget'
  endTarget1 = 'endTarget'

  # set the window
  plus 'text1Number'
  editor TextGrid 'text1Name$'
  Select... 'beginTarget1' 'endTarget1'

  # adjust boundaries to zero-crossings if selected, adjust times
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget1 = Get start of selection
    endTarget1 = Get end of selection
  endif

  # set other target segment times
  durTarget1 = 'endTarget1' - 'beginTarget1'
  midTarget1 = 'beginTarget1' + ('durTarget1' / 2)

  # extract the windowed segment
  Close
  endeditor
  select 'file1Number'
  Edit
  editor Sound 'file1Name$'
  Select... 'beginTarget1' 'endTarget1'
  Extract selected sound (time from 0)
  Close
  endeditor

  # set begin-end times in millisec and rename target segment
  beginMs1 = 'beginTarget1' * 1000
  endMs1 = 'endTarget1' * 1000
  Rename... 'soundName$'Int1
  targetsegment1Number = selected ("Sound")
  targetsegment1Name$ = selected$ ("Sound")

  # get labels associated across all tiers
  select 'text1Number'
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  # set appropriate label variables
  tierLabelStringConcat1$ = tierLabelStringConcat$
  tierLabelStringSpaced1$ = tierLabelStringSpaced$
  for i from 1 to 'numberOfTiers'
    intervalLabelStringConcat1'i'$ = intervalLabelStringConcat'i'$
    intervalLabelStringSpaced1'i'$ = intervalLabelStringSpaced'i'$
  endfor

  # return control to the first textgrid editor
  select 'file1Number'
  plus 'text1Number'
  Edit
  editor TextGrid 'text1Name$'
  Select... 'beginTarget1' 'endTarget1'

  # alert user as to how to select the second interval or segment
  clearinfo
  printline
  printline Select the second labeled interval, either
  printline from the open file, or another file.
  printline
  printline If the second interval is from the same sound...
  printline - set the cursor or select an interval, as desired
  printline - hit Continue or Stop in the Pause panel
  printline
  printline If the second interval or segment is from a different sound...
  printline - close the current textgrid editor, open the new sound plus textgrid
  printline - set the cursor or select an interval, as desired
  printline - hit Continue or Stop in the Pause panel
  printline
  pause Hit Continue or Stop
  endeditor

  # get the name and id number of the sound the user has selected
  file2Name$ = selected$ ("Sound", 1)
  file2Number = selected ("Sound", 1)
  text2Name$ = selected$ ("TextGrid", 1) 
  text2Number = selected ("TextGrid", 1)

  # transfer control to editor
  editor TextGrid 'text2Name$'

  # get selection times to test whether a window has been set,
  # begin and end are the same when file is first opened in Editor
  cursor = Get cursor
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
  select 'file2Number'
  call set_window_size
  call get_timedata_entirefile
  select 'text2Number'
  numberOfIntervals = Get number of intervals... 1
  call interval_number_from_time 'cursor'
  select 'file2Number'
  call get_timedata_interval 'intervalNumber'
  if 'beginTarget' <> 'endTarget'
    plus 'text2Number'
    editor TextGrid 'text2Name$'
    call get_timedata_selection
    select 'file2Number'
  endif

  # set beginTarget and endTarget according to window placement/size
  call get_times_current_editor_withlabels
  beginTarget2 = 'beginTarget'
  endTarget2 = 'endTarget'

  # set the window
  plus 'text2Number'
  editor TextGrid 'text2Name$'
  Select... 'beginTarget2' 'endTarget2'

  # adjust boundaries to zero-crossings if desired
  if 'boundaries_at_zero_crossings' = 1
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget2 = Get start of selection
    endTarget2 = Get end of selection
  endif

  # set other target segment times
  durTarget2 = 'endTarget2' - 'beginTarget2'
  midTarget2 = 'beginTarget2' + ('durTarget2' / 2)

  # extract the windowed segment
  Close
  endeditor
  select 'file2Number'
  Edit
  editor Sound 'file2Name$'
  Select... 'beginTarget2' 'endTarget2'
  Extract selected sound (time from 0)
  Close
  endeditor

  # set begin-end times in millisec and rename target segment
  beginMs2 = 'beginTarget2' * 1000
  endMs2 = 'endTarget2' * 1000
  Rename... 'soundName$'Int2
  targetsegment2Number = selected ("Sound")
  targetsegment2Name$ = selected$ ("Sound")

  # get labels associated across all tiers
  select 'text2Number'
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  # set appropriate label variables
  tierLabelStringConcat2$ = tierLabelStringConcat$
  tierLabelStringSpaced2$ = tierLabelStringSpaced$
  for i from 1 to 'numberOfTiers'
    intervalLabelStringConcat2'i'$ = intervalLabelStringConcat'i'$
    intervalLabelStringSpaced2'i'$ = intervalLabelStringSpaced'i'$
  endfor

  # cross-correlate the two target segments
  select 'targetsegment1Number'
  plus 'targetsegment2Number'
  Cross-correlate... 'from_lag_time' 'to_lag_time' 'normalize'

  # rename the cross-correlation file
  Rename... 'targetsegment1Name$'by'targetsegment2Name$'
  crosscorrName$ = selected$ ("Sound")
  crosscorrNumber = selected ("Sound")
  ccValue = Get maximum... 0.0 0.0 Sinc70

  # show data, save to file
  if ('pause_to_check_data' = 1)
    select 'crosscorrNumber'
    Edit
  endif
  call show_data_and_pause_withlabels
  if ('save_data_to_file' > 1)
    call data_to_file_withlabels
  endif

  # clean up
  select 'targetsegment1Number'
  plus 'targetsegment2Number'
  plus 'crosscorrNumber'
  Remove

  # reopen original sound
  select 'origSoundNumber'
  plus 'origTextGridNumber'
  Edit
  editor TextGrid 'origTextGridName$'
  Select... 'beginTarget1' 'endTarget1'

  # go on to a new file or quit
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
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
  if ('numberOfSelectedSounds' <= 1)
    clearinfo
    printline
    printline Select two or more sounds! Please begin again...
    printline
    exit
  endif

  # loop through all the sound files, getting names and id numbers
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor

  # loop through, select pairs of files in turn and crosscorrelate
  for firstFile from 1 to ('numberOfSelectedSounds'-1)

    # select first sound, extract target segment
    file1Number = sound'firstFile'Number
    file1Name$ = sound'firstFile'Name$
    select 'file1Number'
    sf = Get sampling frequency

    # set window size, get time data at file level
    call set_window_size
    window_size1 = 'window_size'
    call get_timedata_entirefile
    beginFile1 = 'beginFile'
    endFile1 = 'endFile'
    durFile1 ='durFile'
    midFile1 = 'midFile'
    peakFile1 = 'peakFile'

    # set beginTarget and endTarget according to window placement/size
    call get_times_current_objects_nolabels
    beginTarget1 = 'beginTarget'
    endTarget1 = 'endTarget'

    # adjust boundaries to zero-crossings if desired
    if 'boundaries_at_zero_crossings' = 1
      Edit
      editor Sound 'file1Name$'
      Select... 'beginTarget1' 'endTarget1'
      Move start of selection to nearest zero crossing
      Move end of selection to nearest zero crossing
      beginTarget1 = Get start of selection
      endTarget1 = Get end of selection
      endeditor
    endif

    # set other target segment times
    durTarget1 = 'endTarget1' - 'beginTarget1'
    midTarget1 = 'beginTarget1' + ('durTarget1' / 2)

    # extract the windowed segment, return control to Objects window
    endeditor
    select 'file1Number'
    Edit
    editor Sound 'file1Name$'
    Select... 'beginTarget1' 'endTarget1'
    Extract selected sound (time from 0)
    Close
    endeditor

    # set begin-end times in millisec
    beginMs1 = 'beginTarget1' * 1000
    endMs1 = 'endTarget1' * 1000
    Rename... 'file1Name$'Int1
    targetsegment1Number = selected ("Sound")
    targetsegment1Name$ = selected$ ("Sound")

    for secondFile from ('firstFile'+1) to 'numberOfSelectedSounds'

      # select second sound, extract target segment
      file2Number = sound'secondFile'Number
      file2Name$ = sound'secondFile'Name$
      select 'file2Number'

      # set window size, get time data at file level
      call set_window_size
      window_size2 = 'window_size'
      call get_timedata_entirefile
      beginFile2 = 'beginFile'
      endFile2 = 'endFile'
      durFile2 ='durFile'
      midFile2 = 'midFile'
      peakFile2 = 'peakFile'

      # set beginTarget and endTarget according to window placement/size
      call get_times_current_objects_nolabels
      beginTarget2 = 'beginTarget'
      endTarget2 = 'endTarget'

      # adjust boundaries to zero-crossings if desired
      if ('boundaries_at_zero_crossings' = 1)
        Edit
        editor Sound 'file2Name$'
        Select... 'beginTarget2' 'endTarget2'
        Move start of selection to nearest zero crossing
        Move end of selection to nearest zero crossing
        beginTarget2 = Get start of selection
        endTarget2 = Get end of selection
        endeditor
      endif

      # set other target segment times
      durTarget2 = 'endTarget2' - 'beginTarget2'
      midTarget2 = 'beginTarget2' + ('durTarget2' / 2)

      # extract the windowed segment, return control to Objects window
      select 'file2Number'
      Edit
      editor Sound 'file2Name$'
      Select... 'beginTarget2' 'endTarget2'
      Extract selected sound (time from 0)
      Close
      endeditor

      # set begin-end times in millisec
      beginMs2 = 'beginTarget2' * 1000
      endMs2 = 'endTarget2' * 1000
      Rename... 'file2Name$'Int2
      targetsegment2Number = selected ("Sound")
      targetsegment2Name$ = selected$ ("Sound")

      # cross-correlate the two target segments
      select 'targetsegment1Number'
      plus 'targetsegment2Number'
      Cross-correlate... 'from_lag_time' 'to_lag_time' 'normalize'

      # rename the cross-correlation file
      Rename... 'targetsegment1Name$'by'targetsegment2Name$'
      crosscorrName$ = selected$ ("Sound")
      crosscorrNumber = selected ("Sound")
      ccValue = Get maximum... 0.0 0.0 Sinc70

      # show data, save to file
      if ('pause_to_check_data' = 1)
        select 'crosscorrNumber'
        Edit
        editor Sound 'crosscorrName$'
      endif
      call show_data_and_pause_nolabels
      if ('save_data_to_file' > 1)
        call data_to_file_nolabels
      endif

      # clean up
      if ('pause_to_check_data' = 1)
        select 'crosscorrNumber'
        editor Sound 'crosscorrName$'
        Close
        endeditor
      endif
      select 'targetsegment2Number'
      plus 'crosscorrNumber'
      Remove

    # loop to next pair
    endfor

    # clean up
    select 'targetsegment1Number'
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

########## run with Objects window: with labels, within files ##########
procedure objects_withlabels_within

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
  if ('numberOfSelectedSounds' = 0)
    clearinfo
    printline
    printline No sound files selected! Please begin again...
    printline
    exit
  endif

  # loop through all the sound files, getting names and id numbers
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor

  # loop through, selecting each file in turn and crosscorrelating
  # its labeled intervals with intervals in other files
  for currFile1 from 1 to 'numberOfSelectedSounds'

    # select sound
    soundNumber = sound'currFile1'Number
    select 'soundNumber'
    soundName$ = selected$ ("Sound")

    # get textgrid information
    call find_textgrid_ob
    textGridName$ = selected$ ("TextGrid", 1)
    textGridNumber = selected ("TextGrid", 1)
    select 'textGridNumber'
    numberOfIntervals = Get number of intervals... 1

    # loop through, select pairs of intervals in turn and crosscorrelate
    for interval1 from 1 to ('numberOfIntervals'-1)

      select 'textGridNumber'
      firstLabel$ = Get label of interval... 1 'interval1'
      if (firstLabel$ <> "")

        # set window size, get time data at interval level
        call set_window_size
        window_size = 'window_size'
        select 'textGridNumber'
        call get_timedata_interval 'interval1'
        beginInterval1 = 'beginInterval'
        endInterval1 = 'endInterval'
        durInterval1 = 'durInterval'
        midInterval1 = 'midInterval'
        peakInterval1 = 'peakInterval'
        select 'soundNumber'

        # set beginTarget and endTarget according to window placement/size
        call get_times_current_objects_withlabels
        beginTarget1 = 'beginTarget'
        endTarget1 = 'endTarget'

        # set the window
        plus 'textGridNumber'
        Edit
        editor TextGrid 'textGridName$'
        Select... 'beginTarget1' 'endTarget1'

        # adjust boundaries to zero-crossings if desired
        if 'boundaries_at_zero_crossings' = 1
          Move start of selection to nearest zero crossing
          Move end of selection to nearest zero crossing
          beginTarget1 = Get start of selection
          endTarget1 = Get end of selection
          Select... 'beginTarget1' 'endTarget1'
          endeditor
        endif

        # set other target segment times
        durTarget1 = 'endTarget1' - 'beginTarget1'
        midTarget1 = 'beginTarget1' + ('durTarget1' / 2)
 
        # extract the windowed segment, return control to Objects window
        Close
        endeditor
        select 'soundNumber'
        Edit
        editor Sound 'soundName$'
        Select... 'beginTarget1' 'endTarget1'
        Extract selected sound (time from 0)
        Close
        endeditor

        # set interval name
        targetsegment1Number = selected ("Sound")
        Rename... 'soundName$'Int1
        targetsegment1Name$ = selected$ ("Sound")

        # get labels associated across all tiers
        select 'textGridNumber'
        call get_labels_raw midTarget1
        call get_label_number
        call parse_interval_labels

        # concatenate labels at tier and interval levels
        call concatenate_labels

        # set appropriate label variables
        tierLabelStringConcat1$ = tierLabelStringConcat$
        tierLabelStringSpaced1$ = tierLabelStringSpaced$
        for i from 1 to 'numberOfTiers'
          intervalLabelStringConcat1'i'$ = intervalLabelStringConcat'i'$
          intervalLabelStringSpaced1'i'$ = intervalLabelStringSpaced'i'$
        endfor

        # select the second interval to pair with the first interval
        for interval2 from ('interval1'+1) to 'numberOfIntervals'

          # select sound
          select sound'currFile1'Number

          select 'textGridNumber'
          secondLabel$ = Get label of interval... 1 'interval2'
          if (secondLabel$ <> "")

            # get time data for interval
            call get_timedata_interval 'interval2'
            beginInterval2 = 'beginInterval'
            endInterval2 = 'endInterval'
            midInterval2 = 'midInterval'
            peakInterval2 = 'peakInterval'
            select 'soundNumber'

            # set beginTarget and endTarget according to window placement/size
            call get_times_current_objects_withlabels
            beginTarget2 = 'beginTarget'
            endTarget2 = 'endTarget'

            # set the window
            plus 'textGridNumber'
            Edit
            editor TextGrid 'textGridName$'
            Select... 'beginTarget2' 'endTarget2'

            # adjust boundaries to zero-crossings if desired
            if 'boundaries_at_zero_crossings' = 1
              Move start of selection to nearest zero crossing
              Move end of selection to nearest zero crossing
              beginTarget2 = Get start of selection
              endTarget2 = Get end of selection
              Select... 'beginTarget2' 'endTarget2'
              endeditor
            endif

            # set other target segment times
            durTarget2 = 'endTarget2' - 'beginTarget2'
            midTarget2 = 'beginTarget2' + ('durTarget2' / 2)

            # extract the windowed segment, return control to Objects window
            Close
            endeditor
            select 'soundNumber'
            Edit
            editor Sound 'soundName$'
            Select... 'beginTarget2' 'endTarget2'
            Extract selected sound (time from 0)

            Close
            endeditor

            # set interval name
            targetsegment2Number = selected ("Sound")
            Rename... 'soundName$'Int2
            targetsegment2Name$ = selected$ ("Sound")

            # get labels associated across all tiers
            select 'textGridNumber'
            call get_labels_raw midTarget2
            call get_label_number
            call parse_interval_labels

            # concatenate labels at tier and interval levels
            call concatenate_labels

            # set appropriate label variables
            tierLabelStringConcat2$ = tierLabelStringConcat$
            tierLabelStringSpaced2$ = tierLabelStringSpaced$
            for i from 1 to 'numberOfTiers'
              intervalLabelStringConcat2'i'$ = intervalLabelStringConcat'i'$
              intervalLabelStringSpaced2'i'$ = intervalLabelStringSpaced'i'$
            endfor

          # cross-correlate the two target segments
          select 'targetsegment1Number'
          plus 'targetsegment2Number'
          Cross-correlate... 'from_lag_time' 'to_lag_time' 'normalize'

          # rename the cross-correlation file
          Rename... 'targetsegment1Name$'by'targetsegment2Name$'
          crosscorrName$ = selected$ ("Sound")
          crosscorrNumber = selected ("Sound")
          if ('pause_to_check_data' = 1)
            Edit
          endif
          ccValue = Get maximum... 0.0 0.0 Sinc70

        # show data, save to file
        file1Name$ = soundName$
        file2Name$ = soundName$
        call show_data_and_pause_withlabels
        if ('save_data_to_file' > 1)
          call data_to_file_withlabels
        endif

        # clean up
        select 'targetsegment2Number'
        plus 'crosscorrNumber'
        Remove

      endif
    # loop to next interval2 selection  
    endfor

        # clean up
        select 'targetsegment1Number'
        Remove

  endif

    # loop to next interval1 selection
    endfor

  # loop to next interval1 file
  endfor

  # reselect the original set
  select 'sound1Number'
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

########## run with Objects window: with labels, across files ##########
procedure objects_withlabels_across

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
  if 'numberOfSelectedSounds' <= 1
    clearinfo
    printline
    printline Select at least two sound files! Please begin again...
    printline
    exit
  endif

  # loop through all the sound files, getting names and id numbers
  for i from 1 to 'numberOfSelectedSounds'
    sound'i'Name$ = selected$ ("Sound", 'i')
    sound'i'Number = selected ("Sound", 'i')
  endfor

  # loop through, selecting each file in turn and crosscorrelating each of its
  # labeled intervals with each of the labeled intervals in other files

  # file 1 loop
  for firstFile from 1 to ('numberOfSelectedSounds'-1)

    # select first file
    file1Number = sound'firstFile'Number
    select 'file1Number'
    file1Name$ = selected$ ("Sound")

    # set soundName variable for compatibility with procedures
    soundNumber = 'file1Number'
    select 'soundNumber'
    soundName$ = selected$ ("Sound")

    # get textgrid information
    call find_textgrid_ob
    textGrid1Name$ = selected$ ("TextGrid", 1)
    textGrid1Number = selected ("TextGrid", 1)
    textGridName$ = textGrid1Name$
    textGridNumber = 'textGrid1Number'
    numberOfIntervals1 = Get number of intervals... 1

    # loop through, selecting each interval in the current sound, 
    # and cross-correlating it with each interval in each of the
    # other selected sound files

    # file 1 selection loop
    for interval1 from 2 to ('numberOfIntervals1'-1)

      select 'textGrid1Number'
      firstLabel$ = Get label of interval... 1 'interval1'

      # set window size, get time data at interval level
      select 'sound1Number'
      sf = Get sampling frequency
      call set_window_size
      window_size = 'window_size'
      select 'textGrid1Number'

      # set variables for compatibility with procedures
      textGridName$ = textGrid1Name$
      textGridNumber = textGrid1Number

      # get interval time data
      call get_timedata_interval 'interval1'
      beginInterval1 = 'beginInterval'
      endInterval1 = 'endInterval'
      durInterval1 = 'durInterval'
      midInterval1 = 'midInterval'
      peakInterval1 = 'peakInterval'
      select 'file1Number'

      # set beginTarget and endTarget according to window placement/size
      call get_times_current_objects_withlabels
      beginTarget1 = 'beginTarget'
      endTarget1 = 'endTarget'

      # set the window
      plus 'textGrid1Number'
      Edit
      editor TextGrid 'textGrid1Name$'
      Select... 'beginTarget1' 'endTarget1'

      # adjust boundaries to zero-crossings if desired
      if 'boundaries_at_zero_crossings' = 1
        Move start of selection to nearest zero crossing
        Move end of selection to nearest zero crossing
        beginTarget1 = Get start of selection
        endTarget1 = Get end of selection
        Select... 'beginTarget1' 'endTarget1'
        endeditor
      endif

      # set other target segment times
      durTarget1 = 'endTarget1' - 'beginTarget1'
      midTarget1 = 'beginTarget1' + ('durTarget1' / 2)

      # extract the windowed segment, return control to Objects window
      Close
      endeditor
      select 'file1Number'
      Edit
      editor Sound 'file1Name$'
      Select... 'beginTarget1' 'endTarget1'
      Extract selected sound (time from 0)
      Close
      endeditor

      # name extracted segment by file name, begin and end times in ms
      beginMs1 = 'beginTarget1' * 1000
      endMs1 = 'endTarget1' * 1000
      targetsegment1Number = selected ("Sound")
      Rename... 'file1Name$'Int1
      targetsegment1Name$ = selected$ ("Sound")

      # get labels associated across all tiers
      select 'textGridNumber'
      call get_labels_raw midTarget1
      call get_label_number
      call parse_interval_labels

      # concatenate labels at tier and interval levels
      call concatenate_labels

      # set appropriate label variables
      tierLabelStringConcat1$ = tierLabelStringConcat$
      tierLabelStringSpaced1$ = tierLabelStringSpaced$
      for i from 1 to 'numberOfTiers'
       intervalLabelStringConcat1'i'$ = intervalLabelStringConcat'i'$
       intervalLabelStringSpaced1'i'$ = intervalLabelStringSpaced'i'$
      endfor

      # select the second file to pair with the first file
      for secondFile from ('firstFile'+1) to 'numberOfSelectedSounds'

        # select second file
        file2Number = sound'secondFile'Number
        select 'file2Number'
        file2Name$ = selected$ ("Sound")

        # set soundName variable for compatibility with procedures
        soundNumber = 'file2Number'
        select 'soundNumber'
        soundName$ = selected$ ("Sound")

        # get textgrid information
        call find_textgrid_ob
        textGrid2Name$ = selected$ ("TextGrid", 1)
        textGrid2Number = selected ("TextGrid", 1)
        textGridName$ = textGrid2Name$
        textGridNumber = 'textGrid2Number'
        numberOfIntervals2 = Get number of intervals... 1

        # loop through all the intervals in the file
        for interval2 from 2 to ('numberOfIntervals2'-1)

          select 'textGrid2Number'
          secondLabel$ = Get label of interval... 1 'interval2'

          # set variables for compatibility with procedures
          textGridName$ = textGrid2Name$
          textGridNumber = textGrid2Number

          # get time data for interval
          call get_timedata_interval 'interval2'
          beginInterval2 = 'beginInterval'
          endInterval2 = 'endInterval'
          midInterval2 = 'midInterval'
          peakInterval2 = 'peakInterval'
          select 'file2Number'

          # set beginTarget and endTarget according to window placement/size
          call get_times_current_objects_withlabels
          beginTarget2 = 'beginTarget'
          endTarget2 = 'endTarget'

          # set the window
          plus 'textGrid2Number'
          Edit
          editor TextGrid 'textGrid2Name$'
          Select... 'beginTarget2' 'endTarget2'

          # adjust boundaries to zero-crossings if desired
          if 'boundaries_at_zero_crossings' = 1
            Move start of selection to nearest zero crossing
            Move end of selection to nearest zero crossing
            beginTarget2 = Get start of selection
            endTarget2 = Get end of selection
            Select... 'beginTarget2' 'endTarget2'
            endeditor
          endif

          # set other target segment times
          durTarget2 = 'endTarget2' - 'beginTarget2'
          midTarget2 = 'beginTarget2' + ('durTarget2' / 2)

          # extract the windowed segment, return control to Objects window
          Close
          endeditor
          select 'file2Number'
          Edit
          editor Sound 'file2Name$'
          Select... 'beginTarget2' 'endTarget2'
          Extract selected sound (time from 0)
          Close
          endeditor

          # name extracted segment by file name, begin and end times in ms
          beginMs2 = 'beginTarget2' * 1000
          endMs2 = 'endTarget2' * 1000
          targetsegment2Number = selected ("Sound")
          Rename... 'file2Name$'Int2
          targetsegment2Name$ = selected$ ("Sound")

          # get labels associated across all tiers
          select 'textGridNumber'
          call get_labels_raw midTarget2
          call get_label_number
          call parse_interval_labels

          # concatenate labels at tier and interval levels
          call concatenate_labels

          # set appropriate label variables
          tierLabelStringConcat2$ = tierLabelStringConcat$
          tierLabelStringSpaced2$ = tierLabelStringSpaced$
          for i from 1 to 'numberOfTiers'
           intervalLabelStringConcat2'i'$ = intervalLabelStringConcat'i'$
           intervalLabelStringSpaced2'i'$ = intervalLabelStringSpaced'i'$
          endfor

          # cross-correlate the two target segments
          select 'targetsegment1Number'
          plus 'targetsegment2Number'
          Cross-correlate... 'from_lag_time' 'to_lag_time' 'normalize'

          # rename the cross-correlation file
          Rename... 'targetsegment1Name$'by'targetsegment2Name$'
          crosscorrName$ = selected$ ("Sound")
          crosscorrNumber = selected ("Sound")
          if ('pause_to_check_data' = 1)
            Edit
          endif
          ccValue = Get maximum... 0.0 0.0 Sinc70

          # show data, save to file
          call show_data_and_pause_withlabels
          if ('save_data_to_file' > 1)
            call data_to_file_withlabels
          endif

          # clean up
          if ('pause_to_check_data' = 1)
            select 'crosscorrNumber'
            editor Sound 'crosscorrName$'
            Close
            endeditor
          endif
          select 'targetsegment2Number'
          plus 'crosscorrNumber'
          Remove

          # loop to next file2 selection
          interval2 = ('interval2' + 1)
        endfor

      # loop to next file2
      endfor

    # clean up
    select 'targetsegment1Number'
    Remove

    # loop to next file1 selection
    interval1 = ('interval1' + 1)
    endfor

  # loop to next file1
  endfor

  # reselect the original set
  select sound1Number
  for i from 2 to 'numberOfSelectedSounds'
    plus sound'i'Number
  endfor

  # select next file?
  if 'move_on_after' = 1 
    select 'sound1Number'
    plus 'textGrid1Number'
    execute nextObjects.praat
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
  dataFilePath$ = dataDirectoryPath$ + sl$ + dataFile$
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
  k = 'numberOfSelectedSounds'
  firstsoundNumber = selected ("Sound", 1)
  lastsoundNumber = selected ("Sound", 'k')
  querysoundNumber = 0
  querysoundNumber = selected ("Sound", 'k')
  while ('querysoundNumber' <> 'soundNumber')
    k = (k - 1)
    querysoundNumber = selected ("Sound", 'k')
  endwhile
  soundPosition = 'k'
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
  midFile = beginFile + (durFile / 2)
  peakFile = Get time of maximum... beginFile endFile Sinc70
endproc

############################################################
procedure get_timedata_selection
  beginSelection = Get start of selection
  endSelection = Get end of selection
  durSelection = 'endSelection' - 'beginSelection'
  midSelection = 'beginSelection' + ('durSelection' / 2)
  endeditor
  select 'soundNumber'
endproc

############################################################
procedure get_timedata_interval currentIntervalNumber
  select 'textGridNumber'
  beginInterval = Get starting point... 1 currentIntervalNumber
  endInterval = Get end point... 1 currentIntervalNumber
  durInterval = endInterval - beginInterval
  midInterval = beginInterval + (durInterval / 2)
  endeditor
  select 'soundNumber'
  peakInterval = Get time of maximum... beginInterval endInterval Sinc70
  plus 'textGridNumber'
endproc

############################################################
procedure get_times_current_editor_nolabels
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
endproc

############################################################
procedure get_times_current_editor_withlabels
  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire interval
    window_size = ('durInterval' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midInterval' - ('window_size' / 2))
    endTarget = ('midInterval' + ('window_size' / 2))
   elsif 'window_placement' = 3
    # midpoint in interval
    call set_window_around_timepoint midInterval
   elsif 'window_placement' = 4
    # relative to peak amplitude in Interval
     call set_window_around_timepoint peakInterval
    elsif 'window_placement' = 8
     # forward from beginning of Interval
     beginTarget = 'beginInterval'
     endTarget = 'beginInterval' + 'window_size'
    elsif 'window_placement' = 9
     # backward from end of Interval
     beginTarget = 'endInterval' - 'window_size'
     endTarget = 'endInterval'
    endif
endproc

############################################################
procedure get_times_current_objects_nolabels
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
endproc

############################################################
procedure get_times_current_objects_withlabels
  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire interval
    window_size = ('durInterval' * ('percentage_of_file_interval_selection' / 100))
    beginTarget = ('midInterval' - ('window_size' / 2))
    endTarget = ('midInterval' + ('window_size' / 2))
   elsif 'window_placement' = 3
    # midpoint in interval
    call set_window_around_timepoint midInterval
   elsif 'window_placement' = 4
    # relative to peak amplitude in Interval
     call set_window_around_timepoint peakInterval
    elsif 'window_placement' = 8
     # forward from beginning of Interval
     beginTarget = 'beginInterval'
     endTarget = 'beginInterval' + 'window_size'
    elsif 'window_placement' = 9
     # backward from end of Interval
     beginTarget = 'endInterval' - 'window_size'
     endTarget = 'endInterval'
    endif
endproc

############################################################
procedure interval_number_from_time currentIntervalTime
  select 'textGridNumber'
  intervalNumber = Get interval at time... 1 currentIntervalTime
endproc

############################################################
procedure set_window_around_timepoint currentTime
  beginTarget = 'currentTime' - ( 'window_size' / 2)
  endTarget = 'currentTime' + ( 'window_size' / 2)
endproc

############################################################
procedure show_data_and_pause_nolabels
  # send data to the screen
  clearinfo
  printline
  printline selection 1
  printline file 'tab$''tab$''file1Name$'
  printline sel'tab$''tab$''beginMs1:0' to 'endMs1:0' 
  printline
  printline selection 2
  printline file 'tab$''tab$''file2Name$'
  printline sel'tab$''tab$''beginMs2:0' to 'endMs2:0' 
  printline
  printline corr'tab$''tab$''ccValue:3' 'newline$'
  if pause_to_check_data = 1
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_nolabels
  # send data to the file
  if ('save_data_to_file' = 2)
    if 'include_data_header' = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr   Time     ProgramName
      fileappend "'dataFilePath$'"        File1 BeginInt1 EndInt1 DurInt1
      fileappend "'dataFilePath$'"  File2 BeginInt2 EndInt2 DurInt2
      fileappend "'dataFilePath$'"  CrossCorr
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$'
    fileappend "'dataFilePath$'"  'file1Name$' 'beginTarget1:4' 'endTarget1:4' 'durTarget1:3'
    fileappend "'dataFilePath$'"  'file2Name$' 'beginTarget2:4' 'endTarget2:4' 'durTarget2:3'
    fileappend "'dataFilePath$'"  'ccValue:3'
    fileappend "'dataFilePath$'" 'newline$'
  endif
  if ('save_data_to_file' = 3)
    if 'include_data_header' = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr,Time,ProgramName
      fileappend "'dataFilePath$'" ,File1,BeginInt1,EndInt1,DurInt1
      fileappend "'dataFilePath$'" ,File2,BeginInt2,EndInt2,DurInt2
      fileappend "'dataFilePath$'" ,CrossCorr
      fileappend "'dataFilePath$'" 'newline$'
    endif
      fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$','time$','programName$'
      fileappend "'dataFilePath$'" ,'file1Name$','beginTarget1:4','endTarget1:4','durTarget1:3' 
      fileappend "'dataFilePath$'" ,'file2Name$','beginTarget2:4','endTarget2:4','durTarget2:3' 
      fileappend "'dataFilePath$'" ,'ccValue:3'
      fileappend "'dataFilePath$'" 'newline$'
  endif
endproc

############################################################
procedure show_data_and_pause_withlabels
  # send data to the screen
  clearinfo
  printline
  printline interval 1
  printline file 'tab$''tab$''file1Name$'
  print int'tab$''tab$''tierLabelStringConcat1$' 
  x = 'numberOfTiers'
  intervalConcat1$ = ""
  while x >= 1
    intervalTemp$ = intervalLabelStringConcat1'x'$
    intervalConcat1$ = "'intervalConcat1$'" + "'intervalTemp$'"
    x = x - 1
  endwhile
  printline 'intervalConcat1$'
  printline
  printline interval 2
  printline file 'tab$''tab$''file2Name$'
  print int 'tab$''tab$''tierLabelStringConcat2$' 
  x = 'numberOfTiers'
  intervalConcat2$ = ""
  while x >= 1
    intervalTemp$ = intervalLabelStringConcat2'x'$
    intervalConcat2$ = "'intervalConcat2$'" + "'intervalTemp$'"
    x = x - 1
  endwhile
  printline 'intervalConcat2$'
  printline
  printline corr'tab$''tab$''ccValue:3'
  printline
  if pause_to_check_data = 1
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_withlabels
  # send data to the file
  if ('save_data_to_file' = 2)
    if 'include_data_header' = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr   Time     ProgramName
      fileappend "'dataFilePath$'"        File 1
      fileappend "'dataFilePath$'" -- -- -- -- Tier/Interval Labels -- -- -- --
      fileappend "'dataFilePath$'"  BeginInt1 EndInt1 DurInt1 
      fileappend "'dataFilePath$'"  File 2
      fileappend "'dataFilePath$'" -- -- -- -- Tier/Interval Labels -- -- -- --
      fileappend "'dataFilePath$'"  BeginInt2 EndInt2 DurInt2 
      fileappend "'dataFilePath$'"  CrossCorr 'newline$'
    endif 
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'file1Name$' 
     fileappend "'dataFilePath$'" 'tierLabelStringConcat$' 'tierLabelStringSpaced$' 
    for j from 1 to (4 - 'numberOfTiers')
      fileappend "'dataFilePath$'" Xx 
    endfor
    x = 'numberOfTiers'
    while x >= 1
      intervalConcat$ = intervalLabelStringConcat'x'$
      intervalSpaced$ = intervalLabelStringSpaced'x'$
      if (intervalConcat$ = "")
        intervalConcat$ = "Xx"
        intervalSpaced$ = "Xx"
        numberOfIntervalLabelsTier'x' = 1
      endif
      fileappend "'dataFilePath$'" 'intervalConcat$' 'intervalSpaced$'
      for y from 1 to (4 - numberOfIntervalLabelsTier'x')
        fileappend "'dataFilePath$'"  Xx
      endfor
      fileappend "'dataFilePath$'"  
      x = x - 1
    endwhile
    fileappend "'dataFilePath$'" 'beginTarget1:4' 'endTarget1:4' 'durTarget1:4' 'file2Name$'
    fileappend "'dataFilePath$'"  'tierLabelStringConcat2$' 'tierLabelStringSpaced2$'
    for y from 1 to (4 - 'numberOfTiers')
      fileappend "'dataFilePath$'"  Xx
    endfor
    fileappend "'dataFilePath$'"  
    x = 'numberOfTiers'
    while x >= 1
      if (intervalConcat$ = "")
        intervalConcat$ = "Xx"
        intervalSpaced$ = "Xx"
        numberOfIntervalLabelsTier'x' = 1
      endif
      fileappend "'dataFilePath$'" 'intervalConcat$' 'intervalSpaced$'
      for y from 1 to (4 - numberOfIntervalLabelsTier'x')
        fileappend "'dataFilePath$'"  Xx
      endfor
      fileappend "'dataFilePath$'"  
      x = x - 1
    endwhile
    fileappend "'dataFilePath$'" 'beginTarget2:4' 'endTarget2:4' 'durTarget2:4'
    fileappend "'dataFilePath$'" 'ccValue:3' 'newline$'
  endif
  if ('save_data_to_file' = 3)
    if 'include_data_header' = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr,Time,ProgramName,File1
      fileappend "'dataFilePath$'" ,TierLabels,Tier1Label,Tier2Label,Tier3Label,Tier4Label
      fileappend "'dataFilePath$'" ,IntervalLabs,IntervalLab1,IntervalLab2,IntervalLab3,IntervalLab4
      fileappend "'dataFilePath$'" ,BeginInt1,EndInt1,DurInt1
      fileappend "'dataFilePath$'" ,AcrossTiers,Tier1,Tier2,Tier3,Tier4
      fileappend "'dataFilePath$'" ,TierLabels,Tier1Label,Tier2Label,Tier3Label,Tier4Label
      fileappend "'dataFilePath$'" ,IntervalLabs,IntervalLab1,IntervalLab2,IntervalLab3,IntervalLab4
      fileappend "'dataFilePath$'" ,File2,BeginInt2,EndInt2,DurInt2
      fileappend "'dataFilePath$'" ,CrossCorr 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$','time$','programName$','file1Name$'
    fileappend "'dataFilePath$'" ,'tierLabelStringConcat$','tierLabelStringSpaced$'
    for y from 1 to (4 - 'numberOfTiers')
      fileappend "'dataFilePath$'" ,Xx
    endfor
    x = 'numberOfTiers'
    while x >= 1
      intervalConcat$ = intervalLabelStringConcat'x'$
      intervalSpaced$ = intervalLabelStringSpaced'x'$
      if (intervalConcat$ = "")
        intervalConcat$ = "Xx"
        intervalSpaced$ = "Xx"
        numberOfIntervalLabelsTier'x' = 1
      endif
      fileappend "'dataFilePath$'" ,'intervalConcat$','intervalSpaced$'
      for y from 1 to (4 - numberOfIntervalLabelsTier'x')
        fileappend "'dataFilePath$'" ,Xx
      endfor
      x = x - 1
    endwhile
    fileappend "'dataFilePath$'" ,'beginTarget1:4','endTarget1:4','durTarget1:4','file2Name$'
    fileappend "'dataFilePath$'" ,'tierLabelStringConcat2$','tierLabelStringSpaced2$'
    for y from 1 to (4 - 'numberOfTiers')
      fileappend "'dataFilePath$'" ,Xx
    endfor
    x = 'numberOfTiers'
    while x >= 1
      intervalConcat2$ = intervalLabelStringConcat2'x'$
      intervalSpaced2$ = intervalLabelStringSpaced2'x'$
      if (intervalConcat2$ = "")
        intervalConcat2$ = "Xx"
        intervalSpaced2$ = "Xx"
        numberOfIntervalLabelsTier'x' = 1
      endif
      fileappend "'dataFilePath$'" ,'intervalConcat2$','intervalSpaced2$'
      for y from 1 to (4 - numberOfIntervalLabelsTier'x')
        fileappend "'dataFilePath$'" ,Xx
      endfor
      x = x - 1
    endwhile
    fileappend "'dataFilePath$'" ,'beginTarget2:4','endTarget2:4','durTarget2:4','ccValue:3' 'newline$'
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
    textGridName'i'$ = selected$ ("TextGrid", 'i')
    textGridNumber'i' = selected ("TextGrid", 'i')
  endfor
  # if selected Sound file has a corresponding TextGrid file, find it
  foundTextGrid = 0
  i = 1
  while (('foundTextGrid' = 0) and ('i' <= 'numberOfSelectedTextGrids'))
    testName$ = textGridName'i'$
    testNumber = textGridNumber'i'
    if (testName$ = soundName$)
      textGridName$ = testName$
      textGridNumber = 'testNumber'
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
# concatenate labels
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
    if ('save_data_to_file' = 3)
      tierLabelStringSpaced$ = tierLabelStringSpaced$ + tierLabelString'i'$ + ","
     else
      tierLabelStringSpaced$ = tierLabelStringSpaced$ + tierLabelString'i'$ + " "
    endif
    i = i - 1
  endwhile
  # shave trailing spaces off tier-level label strings
  while ((right$(tierLabelStringConcat$, 1) = " ") or (right$(tierLabelStringConcat$, 1) = ",")) 
    stringLength = length(tierLabelStringConcat$)
    tierLabelStringConcat$ = left$(tierLabelStringConcat$, stringLength-1)
  endwhile
  while ((right$(tierLabelStringSpaced$, 1) = " ") or (right$(tierLabelStringSpaced$, 1) = ","))
    stringLength = length(tierLabelStringSpaced$)
    tierLabelStringSpaced$ = left$(tierLabelStringSpaced$, stringLength-1)
  endwhile
  # concatenate interval-level label strings from first to last
  for i from 1 to 'numberOfTiers'
    intervalLabelStringConcat'i'$ = ""
    intervalLabelStringSpaced'i'$ = ""
    for j from 1 to numberOfIntervalLabelsTier'i'
      intervalLabelStringConcat'i'$ = intervalLabelStringConcat'i'$ + intervalLabel'i''j'$
      if ('save_data_to_file' = 3)
        intervalLabelStringSpaced'i'$ = intervalLabelStringSpaced'i'$ + intervalLabel'i''j'$ + ","
       else
        intervalLabelStringSpaced'i'$ = intervalLabelStringSpaced'i'$ + intervalLabel'i''j'$ + " "
      endif
    endfor
  endfor
  # shave trailing space off interval-level label strings
  for i from 1 to 'numberOfTiers'
    while ((right$(intervalLabelStringConcat'i'$, 1) = " ") or (right$(intervalLabelStringConcat'i'$, 1) = ","))
      stringLength = length(intervalLabelStringConcat'i'$)
      intervalLabelStringConcat'i'$ = left$(intervalLabelStringConcat'i'$, 'stringLength'-1)
    endwhile
    while ((right$(intervalLabelStringSpaced'i'$, 1) = " ") or (right$(intervalLabelStringSpaced'i'$, 1) = ","))
      stringLength = length(intervalLabelStringSpaced'i'$)
      intervalLabelStringSpaced'i'$ = left$(intervalLabelStringSpaced'i'$, 'stringLength'-1)
    endwhile
   if ((intervalLabelStringSpaced'i'$ = " ") or (intervalLabelStringSpaced'i'$ = ",")) 
     intervalLabelStringSpaced'i'$ = ""
   endif
  endfor
endproc