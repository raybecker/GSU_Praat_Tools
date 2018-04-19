# quantifyAmpDur
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

# quantifyAmpDur is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# quantifyAmpDur is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for analysis parameters 
form quantify Amplitude and Duration
  comment When used with labels, a background noise measurement and
  comment SNR can be included by including a background noise interval 
  comment extending across all tiers with the label "0" entered at each level.
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Editor (with labels)
    option Objects (no labels)
    option Objects (with labels)
  boolean Move_on_after 0
  boolean Pause_to_check_data 0
  optionmenu Save_data_to_file 1
    option no data file
    option space-delimited (.out)
    option comma-delimited (.csv)
  boolean Include_data_header 0
  boolean Include_duration 1
  boolean Include_amplitude 1
  boolean Background_label_present 0
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
  comment Intensity-computation parameters...
  real Minimum_pitch_(Hz) 100.0
  real Time_step_(s) 0.0
endform 

# set program name, operating system, directory paths and names as needed
programName$ = "quantifyAmpDur"
if ('save_data_to_file' = 3)
  dataFile$ = "quantifyampdur.csv"
 else
  dataFile$ = "quantifyampdur.out"
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

 # get intensity-related values
  endeditor
  select 'soundNumber'
  call get_sound_intensity
  ampMean = 'ampTarget'
  ampPeak = 'peakAmpTarget'
  ampPeakTime = 'peakTimeTarget'

  # show data, save to file
  call show_data_and_pause_nolabels
  if ( 'save_data_to_file' > 1 )
    call data_to_file_nolabels
  endif

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

  # get duration of gap to next labeled segment (ignore background interval, if present)
  endeditor
  select 'textGridNumber'
  # find next labeled interval that is not the background noise
  nextInterval = 1
  currentLabel$ = Get label of interval... 1 ('intervalNumber'+'nextInterval')
  while (((currentLabel$ = "") or (currentLabel$ = "0")) and (('intervalNumber' + 'nextInterval') < 'numberOfIntervals'))
    nextInterval = 'nextInterval' + 1
    currentLabel$ = Get label of interval... 1 ('intervalNumber'+'nextInterval')
  endwhile
  beginGap = Get end point... 1 'intervalNumber'
  if (('intervalNumber'+'nextInterval') < 'numberOfIntervals')
  endGap = Get starting point... 1 ('intervalNumber'+'nextInterval')
  durGap = 'endGap' - 'beginGap'
  else
  durGap = 0
  endif

  # get labels associated across all tiers
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  # get intensity-related values
  select 'soundNumber'
  call get_sound_intensity
  ampMean = 'ampTarget'
  ampPeak = 'peakAmpTarget'
  ampPeakTime = 'peakTimeTarget'

  # find background intensity-related values, if desired
  if ('background_label_present' = 1)
    beginTargetOriginal = 'beginTarget'
    endTargetOriginal = 'endTarget'
    call find_background_interval
    beginTarget = Get starting point... 1 'backgroundInterval'
    endTarget = Get end point... 1 'backgroundInterval'
    select 'soundNumber'
    call get_sound_intensity
    ampBackground = 'ampTarget'
    ampSNR = 'ampMean' - 'ampBackground'
    beginTarget = 'beginTargetOriginal'
    endTarget = 'endTargetOriginal'
  endif

  # show data, save to file
  call show_data_and_pause_withlabels
  if ( 'save_data_to_file' > 1 )
    call data_to_file_withlabels
  endif

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
    if 'boundaries_at_zero_crossings' = 1
      Edit
      editor Sound 'soundName$'
      Select... 'beginTarget' 'endTarget'
      Move start of selection to nearest zero crossing
      Move end of selection to nearest zero crossing
      beginTarget = Get start of selection
      endTarget = Get end of selection
      Close
      endeditor
    endif

    # set other target segment times
    durTarget = 'endTarget' - 'beginTarget'
    midTarget = 'beginTarget' + ('durTarget' / 2)

    # get intensity-related values
    select 'soundNumber'
    call get_sound_intensity
    ampMean = 'ampTarget'
    ampPeak = 'peakAmpTarget'
    ampPeakTime = 'peakTimeTarget'

    # show data, save to file
    call show_data_and_pause_nolabels
    if ( 'save_data_to_file' > 1 )
      call data_to_file_nolabels
    endif

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

      select 'textGridNumber'
      currentLabel$ = Get label of interval... 1 'intervalNumber'
      if (currentLabel$ <> "") and (currentLabel$ <> "0") and (currentLabel$ <> "0 ")

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
        Close
        endeditor

        # get duration of gap to next labeled segment (ignore background interval, if present)
        select 'textGridNumber'
        # find next labeled interval that is not the background noise
        nextInterval = 1
        currentLabel$ = Get label of interval... 1 ('intervalNumber'+'nextInterval')
        while (((currentLabel$ = "") or (currentLabel$ = "0")) and (('intervalNumber' + 'nextInterval') < 'numberOfIntervals'))
          nextInterval = 'nextInterval' + 1
          currentLabel$ = Get label of interval... 1 ('intervalNumber'+'nextInterval')
        endwhile
        beginGap = Get end point... 1 'intervalNumber'
        if (('intervalNumber'+'nextInterval') < 'numberOfIntervals')
          endGap = Get starting point... 1 ('intervalNumber'+'nextInterval')
          durGap = 'endGap' - 'beginGap'
         else
          durGap = 0
        endif

        # get labels associated across all tiers
        select 'textGridNumber'
        call get_labels_raw midTarget
        call get_label_number
        call parse_interval_labels

        # concatenate labels at tier and interval levels
        call concatenate_labels

        # get intensity-related values
        select 'soundNumber'
        call get_sound_intensity
        ampMean = 'ampTarget'
        ampPeak = 'peakAmpTarget'
        ampPeakTime = 'peakTimeTarget'

        # find background intensity-related values, if desired
        if ('background_label_present' = 1)
          beginTargetOriginal = 'beginTarget'
          endTargetOriginal = 'endTarget'
          call find_background_interval
          beginTarget = Get starting point... 1 'backgroundInterval'
          endTarget = Get end point... 1 'backgroundInterval'
          select 'soundNumber'
          call get_sound_intensity
          ampBackground = 'ampTarget'
          ampSNR = 'ampMean' - 'ampBackground'
          beginTarget = 'beginTargetOriginal'
          endTarget = 'endTargetOriginal'
        endif

        # show data, save to file
        call show_data_and_pause_withlabels
        if ( 'save_data_to_file' > 1 )
          call data_to_file_withlabels
        endif
      endif
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
  dataDirectoryExists = fileReadable ("'dataDirectoryPath$'/quantifyampdur.out")
  if 'dataDirectoryExists' <> 1
    system_nocheck mkdir "'dataDirectoryPath$'"
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
procedure get_sound_intensity
  To Intensity... 100 0 1
  intensityNumber = selected ("Intensity", 1)
  ampTarget = Get mean... 'beginTarget' 'endTarget' dB
  peakTimeTarget  = Get time of maximum... 'beginTarget' 'endTarget' Sinc70
  peakAmpTarget= Get maximum... 'beginTarget' 'endTarget' Sinc70
  Remove
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
procedure show_data_and_pause_nolabels
  # send data to the screen
  clearinfo
  printline file'tab$''tab$''soundName$'
  printline
  printline start'tab$''tab$''beginTarget:4'
  printline end'tab$''tab$''endTarget:4' 'newline$'
  if 'include_duration' = 1
    printline dur'tab$''tab$''durTarget:4'
    printline
  endif
  if ('include_amplitude' = 1)
    printline amp (dB)'tab$''ampMean:1'
    printline pk amp'tab$''ampPeak:1'
    printline pk time'tab$''ampPeakTime:3'
  endif
  if pause_to_check_data = 1
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_nolabels
  # send data to the file
  if ('save_data_to_file' = 2)
    if ('include_data_header' = 1)
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr Time ProgramName SoundName Begin End
      if ('include_duration' = 1)
        fileappend "'dataFilePath$'"  Duration
      endif
      if ('include_amplitude' = 1)
        fileappend "'dataFilePath$'"  AmpMean
        fileappend "'dataFilePath$'"  AmpPeak
        fileappend "'dataFilePath$'"  AmpPeakTime
      endif
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'soundName$' 
    fileappend "'dataFilePath$'" 'beginTarget:4' 'endTarget:4'
    if 'include_duration' = 1
      fileappend "'dataFilePath$'"  'durTarget:4'
    endif
    if 'include_amplitude' = 1
      fileappend "'dataFilePath$'"  'ampMean:1'
      fileappend "'dataFilePath$'"  'ampPeak:1'
      fileappend "'dataFilePath$'"  'ampPeakTime:3'
    endif
    fileappend "'dataFilePath$'" 'newline$'
  endif
  if ('save_data_to_file' = 3)
    if ('include_data_header') = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr,Time,ProgramName,SoundName,Begin,End
      if ('include_duration' = 1)
        fileappend "'dataFilePath$'" ,Duration
      endif 
      if ('include_amplitude' = 1)
        fileappend "'dataFilePath$'" ,AmpMean
        fileappend "'dataFilePath$'" ,AmpPeak
        fileappend "'dataFilePath$'" ,AmpPeakTime
      endif
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$','time$','programName$','soundName$'
    fileappend "'dataFilePath$'" ,'beginTarget:4','endTarget:4'
    if 'include_duration' = 1
      fileappend "'dataFilePath$'" ,'durTarget:4'
    endif
    if 'include_amplitude' = 1
      fileappend "'dataFilePath$'" ,'ampMean:1'
      fileappend "'dataFilePath$'" ,'ampPeak:1'
      fileappend "'dataFilePath$'" ,'ampPeakTime:3'
    endif
    fileappend "'dataFilePath$'" 'newline$'
  endif
endproc

############################################################
procedure show_data_and_pause_withlabels
  # send data to the screen
  clearinfo
  printline file'tab$''tab$''soundName$'
  print seg'tab$''tab$''tierLabelStringConcat$' 
  x = 'numberOfTiers'
  intervalConcat$ = ""
  while x >= 1
    intervalTemp$ = intervalLabelStringConcat'x'$
    intervalConcat$ = "'intervalConcat$'" + "'intervalTemp$'"
    x = x - 1
  endwhile
  printline 'intervalConcat$' 
  printline
  printline start'tab$''tab$''beginTarget:4'
  printline end'tab$''tab$''endTarget:4' 'newline$'
  if ('include_duration' = 1)
    printline dur'tab$''tab$''durTarget:4'
    printline gap'tab$''tab$''durGap:4'
    printline
  endif
  if ('include_amplitude' = 1)
    printline amp (dB)'tab$''ampMean:1'
    printline pk amp'tab$''ampPeak:1'
    printline pk time'tab$''ampPeakTime:3' 'newline$'
    if ('background_label_present' = 1)
      printline SNR (dB)'tab$''ampSNR:1'
    endif
  endif
  if ('pause_to_check_data' = 1)
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_withlabels
  # send data to the file
  if ('save_data_to_file' = 2)
    if ('include_data_header' = 1)
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr   Time     ProgramName    SoundName
      fileappend "'dataFilePath$'"   -- -- -- -- Tier/Interval Labels -- -- -- -- 
      fileappend "'dataFilePath$'"  Begin End
      if 'include_duration' = 1
        fileappend "'dataFilePath$'"  Duration
      endif
      if 'include_amplitude' = 1
        fileappend "'dataFilePath$'"  AmpMean AMPPeak AmpPeakTime
        if ('background_label_present' = 1)
          fileappend "'dataFilePath$'"  SNR
        endif
      endif
      if 'include_duration' = 1
        fileappend "'dataFilePath$'"  Gap
      endif
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'soundName$' 
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
    fileappend "'dataFilePath$'" 'beginTarget:4' 'endTarget:4'
    if ('include_duration' = 1)
      fileappend "'dataFilePath$'"  'durTarget:4'
    endif
    if ('include_amplitude' = 1)
      fileappend "'dataFilePath$'"  'ampMean:1' 'ampPeak:1' 'ampPeakTime:3'
      if ('background_label_present' = 1)
        fileappend "'dataFilePath$'"  'ampSNR:1'
      endif
    endif
    if ('include_duration' = 1)
      fileappend "'dataFilePath$'"  'durGap:4'
    endif
    fileappend "'dataFilePath$'" 'newline$'
  endif
  if ('save_data_to_file' = 3)
    if ('include_data_header' = 1)
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr,Time,ProgramName,SoundName
      fileappend "'dataFilePath$'" ,TierLabels,Tier1Label,Tier2Label,Tier3Label,Tier4Label
      fileappend "'dataFilePath$'" ,IntervalLabs,IntervalLab1,IntervalLab2,IntervalLab3,IntervalLab4
      fileappend "'dataFilePath$'" ,Begin,End
      if ('include_duration' = 1)
        fileappend "'dataFilePath$'" ,Duration
      endif
      if ('include_amplitude' = 1)
        fileappend "'dataFilePath$'" ,AmpMean,AMPPeak,AMPPeakTime
        if ('background_label_present' = 1)
          fileappend "'dataFilePath$'" ,SNR
        endif
      endif
      if ('include_duration' = 1)
        fileappend "'dataFilePath$'" ,Gap
      endif
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$','time$','programName$','soundName$'
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
    fileappend "'dataFilePath$'" ,'beginTarget:4','endTarget:4'
    if ('include_duration' = 1)
      fileappend "'dataFilePath$'" ,'durTarget:4'
    endif
    if ('include_amplitude' = 1)
      fileappend "'dataFilePath$'" ,'ampMean:1'
      fileappend "'dataFilePath$'" ,'ampPeak:1'
      fileappend "'dataFilePath$'" ,'ampPeakTime:3'
      if ('background_label_present' = 1)
        fileappend "'dataFilePath$'" ,'ampSNR:1'
      endif
    endif
    if ('include_duration' = 1)
      fileappend "'dataFilePath$'" ,'durGap:4'
    endif
    fileappend "'dataFilePath$'" 'newline$'
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
    firstSpace = index(intervalLabelString'i'$, " ")
    if ('firstSpace' > 0)
      labelNumber$ = left$(intervalLabelString'i'$, 'firstSpace'-1)
     else
      labelNumber$ = left$(intervalLabelString'i'$, 1)
    endif
    intervalLabelNumber'i'$ = left$(intervalLabelString'i'$, 'firstSpace'-1)
    # shave the number off the original string, including the trailing space
    intervalLabelString'i'$ = mid$(intervalLabelString'i'$, 'firstSpace'+1, 10000)
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

############################################################
procedure find_background_interval
  # search intervals until found
  backgroundIntervalFound = 0
  endeditor
  select 'textGridNumber'
  numberOfIntervals = Get number of intervals... 1
  for i from 1 to 'numberOfIntervals'
    currentLabel$ = Get label of interval... 1 'i'
    if (currentLabel$ <> "")
      # remove any leading spaces then find length of string with all the labels
      while left$(currentLabel$, 1) = " "
        currentLabel$ = mid$(currentLabel$, 2, 10000)
      endwhile
      # retrieve and store the first label, not including trailing space
      firstSpace = index(currentLabel$, " ")
      if ('firstSpace' > 0)
        labelNumber$ = left$(currentLabel$, 'firstSpace'-1)
       else
        labelNumber$ = left$(currentLabel$, 1)
      endif
      # if "0" label, set variable
      if (labelNumber$ = "0")
        backgroundInterval = 'i'
        backgroundIntervalFound = 1
        i = 'numberOfIntervals'
      endif
    endif
  endfor
  select 'textGridNumber'
endproc
