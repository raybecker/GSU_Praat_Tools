# quantifyHarmonics
#######################################################################

# Michael J. Owren, Ph.D.
# Psychology of Voice and Sound Laboratory
# Department of Psychology
# Georgia State University
# Atlanta, GA 30303, USA

# email: owren@gsu.edu
# home page: http://michaeljowren.googlepages.com
# lab page: http://psyvoso.googlepages.com

# Copyright 2007-2011 Michael J. Owren

# quantifyHarmonics is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# quantifyHarmonics is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set program name, data file, data directory, and home directory
programName$ = "quantifyHarmonics"
dataFile$ = "quantifyharmonics.out"
call set_data_paths

# query user for parameters
form quantify harmonic spectrum
  optionmenu Processing_mode 1
    option Editor (no labels)
    option Editor (with labels)
    option Objects (no labels)
    option Objects (with labels)
  boolean Move_on_after 0
  boolean Pause_to_check_contour 1
  boolean Show_data_during_processing 1
  boolean Pause_to_check_data 0
  boolean Save_data_to_file 1
  optionmenu Harmonic_frequencies_are 1
    option calculated from pitch
    option from spectrogram
  comment Pitch extraction, spectrogram, and harmonic extraction parameters...
  positive Pitch_min_pitch_(Hz) 75
  positive Pitch_max_pitch_(Hz) 7500
  real Fourier_window_length_(ms) 100
  real Frequency_resolution_(Hz) 10
  real Time_step_for_slices_(ms) 2
  real Number_harmonics_to_retrieve 30
  real Search_bandwidth_(Hz) 20
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

# finalize spectrogram parameters using sec values
spectrogram_window_length = ('fourier_window_length' / 1000)
spectrogram_time_step = ('time_step_for_slices' / 1000)

# set the remainder of pitch extraction variables
pitch_time_step = 0.0
max_candidates = 15
very_accurate = 0
pitch_silence_threshold = 0.03
voicing_threshold = 0.45
octave_cost = 0.01
octave_jump_cost = 0.35
voiced_unvoiced_cost = 0.14
zeroPadSecs = 0.1

# determine window length, determine correction factor for time of slices
if 'very_accurate' = 0
  number_cycles = 3
 else
  number_cycles = 6
endif
windowLength = 'number_cycles' / 'pitch_min_pitch'
correctionFactor = 'zeroPadSecs' - ('windowLength' * 2)

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# jump to selected processing mode
if ( 'processing_mode' = 1 )
  call editor_nolabels
 elsif ( 'processing_mode' = 2 ) 
  call editor_withlabels
 elsif ( 'processing_mode' = 3 ) 
  call objects_nolabels
 elsif ( 'processing_mode' = 4 ) 
  call objects_withlabels
endif

################## run with Editor window: no labels ##################
procedure editor_nolabels

  # make sure control lies with objects window
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
  if (('beginTarget' <> 'endTarget') and  ('window_placement' = 4 ))
    clearinfo
    printline
    printline Analysis window error!
    printline ...reset cursor to single location, or
    printline ...redo window placement
    printline 
    exit
  endif
  if (('beginTarget' = 'endTarget') and ('window_placement' = 5))
    clearinfo
    printline
    printline Analysis window error!
    printline ...select a segment, or
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
    beginTarget = 'beginFile'
    endTarget = 'endFile'
   elsif 'window_placement' = 2
    # midpoint in file
    call set_window_around_timepoint midFile
   elsif 'window_placement' = 3
    # relative to peak amplitude in file
    call set_window_around_timepoint peakFile   
   elsif 'window_placement' = 4
    # around current cursor location
    call set_window_around_timepoint cursor
   elsif 'window_placement' = 5
    beginTarget = 'beginSelection'
    endTarget = 'endSelection'
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

  # zero pad the file or segment for better pitch extraction
  call sound_zero_pad

  # reselect sound segment and create the spectrogram used in quantifying harmonic amplitudes
  select 'targetsegmentNumber'
  To Spectrogram... 'spectrogram_window_length' 'sf'/2 'spectrogram_time_step' 'frequency_resolution' Gaussian
  spectrogramName$ = selected$ ("Spectrogram")
  spectrogramNumber = selected ("Spectrogram")

  # reselect sound file and do pitch analysis
  select 'targetsegmentNumber'
  To Pitch (ac)... 'pitch_time_step' 'pitch_min_pitch' 'max_candidates'
    ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
    ... 'octave_jump_cost' 'voiced_unvoiced_cost' 'pitch_max_pitch'

  # get the name and number of the pitch file
  pitchName$ = selected$ ("Pitch")
  pitchNumber = selected ("Pitch")

  if pause_to_check_contour = 1
    # pause to allow user to fix pitch contour
    Edit
    editor Pitch 'pitchName$'
    pause Check the pitch contour, edit as needed
    Close
    endeditor
  endif

  # create matrices for frequency and amplitude data
  numberOfFrames = Get number of frames
  Create simple Matrix... 'targetsegmentName$'Freqs 'number_harmonics_to_retrieve' 'numberOfFrames' 0
  freqsMatrixNumber = selected ("Matrix")
  freqsMatrixName$ = selected$ ("Matrix")
  Create simple Matrix... 'targetsegmentName$'Amps 'number_harmonics_to_retrieve' 'numberOfFrames' 0   
  ampsMatrixNumber = selected ("Matrix")
  ampsMatrixName$ = selected$ ("Matrix")
  Create simple Matrix... 'targetsegmentName$'FreqDiffs 'number_harmonics_to_retrieve' 'numberOfFrames' 0   
  freqDiffsMatrixNumber = selected ("Matrix")
  freqDiffsMatrixName$ = selected$ ("Matrix")

  # initialize matrices
  select 'freqsMatrixNumber'
  for column from 1 to 'numberOfFrames'
    for row from 1 to 'number_harmonics_to_retrieve'
      Set value... 'row' 'column' 0
    endfor
  endfor
   select 'ampsMatrixNumber'
  for column from 1 to 'numberOfFrames'
    for row from 1 to 'number_harmonics_to_retrieve'
      Set value... 'row' 'column' 0
    endfor
  endfor
    select 'freqDiffsMatrixNumber'
  for column from 1 to 'numberOfFrames'
    for row from 1 to 'number_harmonics_to_retrieve'
      Set value... 'row' 'column' 0
    endfor
  endfor

  # fill in frequencies and amplitudes for non-zero pitch-contour bins
  for column from 1 to 'numberOfFrames'
    select 'pitchNumber'
    pitchValue = Get value in frame... 'column' Hertz
    sliceTime = Get time from frame number... 'column'
    correctedSliceTime = ('sliceTime' - 'correctionFactor')
    if (pitchValue <> undefined)
      # get spectral slice from spectrogram
      select 'spectrogramNumber'
      To Spectrum (slice)... 'sliceTime'
      spectrumName$ = ("Spectrum")
      spectrumNumber = selected ("Spectrum")
      # retrieve harmonic frequencies and amplitudes
      currentFreq = 0.0001
      call get_harmonic_freqamp_nolabels
      call concatenate_peak_data
    endif

    # show data, save to file
    if ((show_data_during_processing = 1) or (pause_to_check_data = 1))
      call show_data_and_pause_nolabels
   endif 
   if ( 'save_data_to_file' = 1 )
      call data_to_file_nolabels
      select 'pitchNumber'
        Write to binary file... 'dataDirectoryPath$''sl$''pitchName$'Pitch.gsupraattools
      select 'freqsMatrixNumber'
        Write to binary file... 'dataDirectoryPath$''sl$''freqsMatrixName$'.gsupraattools
      select 'ampsMatrixNumber'
       Write to binary file... 'dataDirectoryPath$''sl$''ampsMatrixName$'.gsupraattools
    endif
    endeditor

    # clean up
    if (pitchValue <> undefined)
      select 'spectrumNumber'
      Remove
    endif 
 endfor

  # clean up
  #  select 'targetsegmentNumber'
  #    plus 'pitchNumber'
  #    plus 'freqsMatrixNumber'
  #    plus 'ampsMatrixNumber'
  select 'spectrogramNumber'
    plus 'freqDiffsMatrixNumber'
  Remove

  # go on to a new file or quit
  select 'soundNumber'
  editor Sound 'soundName$'
  if 'move_on_after' = 1
    execute nextSoundEditor.prtls
  endif

endproc

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
  dataFilePath$ =  dataDirectoryPath$ + sl$ + dataFile$
  # check for and possibly create the Praat_Data directory
  dataDirectoryExists = fileReadable ("'dataDirectoryPath$''sl$'quantifyHarmonics.out")
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
  printline FileName 'tab$' 'soundName$'
  printline
  if 'beginTarget' = 0.0
    beginTarget = 0.0001
  endif
  printline Start  'beginTarget:3'
  printline End 'tab$' 'endTarget:3' 
  printline Dur 'tab$' 'durTarget:3'
  printline Time  'correctedSliceTime:4'
  printline
  printline Pk 'tab$' Freq 'tab$' Amp 'tab$' FreqDiff
  for i from 1 to 'number_harmonics_to_retrieve'
    if ( pitchValue <> undefined )
      peakNumber$ = "'i'"
        select 'freqsMatrixNumber'
      peakFreq =  Get value in cell... 'i' 'column'
        select 'ampsMatrixNumber'
      peakAmp = Get value in cell... 'i' 'column'
        select 'freqDiffsMatrixNumber'
      peakFreqDiff = Get value in cell... 'i' 'column'
      peakFreq$ =  fixed$('peakFreq',1)
      peakAmp$ = fixed$('peakAmp',1)
      peakFreqDiff$ = fixed$('peakFreqDiff',1) 
      printline 'i' 'tab$' 'peakFreq$' 'tab$' 'peakAmp$' 'tab$' 'peakFreqDiff$'
     else
      printline 'i' 'tab$' 0.0001 'tab$' 0.0001 'tab$' 0.0001 
    endif
  endfor
  if pause_to_check_data = 1
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_nolabels
  # send data to the file
  fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'soundName$' 
  fileappend "'dataFilePath$'" 'beginTarget:4' 'endTarget:4' 'durTarget:3' 'correctedSliceTime:4'
  if ( pitchValue <> undefined ) 
    fileappend "'dataFilePath$'" 'peakData$' 
   else
    for i from 1 to 'number_harmonics_to_retrieve'
      fileappend "'dataFilePath$'"  Pk'i' 0.0001 0.0001 0.0001
    endfor
  endif
  fileappend "'dataFilePath$'" 'newline$'
endproc

############################################################
procedure show_data_and_pause_withlabels
  # send data to the screen
  clearinfo
  printline FileName
  printline 'soundName$' 'newline$'
  printline Target segment
  print 'tierLabelStringConcat$' 
  i = 'numberOfTiers'
  while i >= 1
    intervalConcat$ = intervalLabelStringConcat'i'$
    print 'intervalConcat$' 
    i = i -1
  endwhile
  printline 'newline$'
  if 'beginTarget' = 0.0
    beginTarget = 0.0001
  endif

  # send data to the screen
  clearinfo
  printline FileName 'tab$' 'soundName$'
  printline
  if 'beginTarget' = 0.0
    beginTarget = 0.0001
  endif
  printline Start  'beginTarget:3'
  printline End 'tab$' 'endTarget:3' 
  printline Dur 'tab$' 'durTarget:3'
  printline
  printline Pk 'tab$' Freq 'tab$' Amp 'tab$' FreqDiff
  if ( pitchValue <> undefined )
    for i from 1 to 'number_harmonics_to_retrieve'
        peakNumber$ = "'i'"
      select 'freqsMatrixNumber'
        peakFreq =  Get value in cell... 'i' 'column'
      select 'ampsMatrixNumber'
        peakAmp = Get value in cell... 'i' 'column'
      select 'freqDiffsMatrixNumber'
         peakFreqDiff = Get value in cell... 'i' 'column'
      peakFreq$ =  fixed$('peakFreq',1)
      peakAmp$ = fixed$('peakAmp',1)
      peakFreqDiff$ = fixed$('peakFreqDiff',1) 
      printline 'i' 'tab$' 'peakFreq$' 'tab$' 'peakAmp$' 'tab$' 'peakFreqDiff$'
    endfor
    printline
  endif
  if pause_to_check_data = 1
    pause Check the data: hit Continue to save data, Stop to abort
  endif
endproc

############################################################
procedure data_to_file_withlabels
  fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'soundName$' 
  fileappend "'dataFilePath$'" 'tierLabelStringConcat$' 'tierLabelStringSpaced$' 
  for i from 1 to (4 - 'numberOfTiers')
    fileappend "'dataFilePath$'" Xx 
  endfor
    i = 'numberOfTiers'
    while i >= 1
      intervalConcat$ = intervalLabelStringConcat'i'$
      intervalSpaced$ = intervalLabelStringSpaced'i'$
      fileappend "'dataFilePath$'" 'intervalConcat$' 'intervalSpaced$' 
      for j from 1 to (4 - numberOfIntervalLabelsTier'i')
        fileappend "'dataFilePath$'" Xx 
      endfor      
    i = i -1
    endwhile
  fileappend "'dataFilePath$'" 'beginTarget:4' 'endTarget:4' 'durTarget:3' 
  if ( 'number_harmonics_to_retrieve' > 0 )
    fileappend "'dataFilePath$'" 'peakData$' 
  endif
  fileappend "'dataFilePath$'" 'newline$'
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
procedure sound_zero_pad
  # create a file that is the right length of zeros, copy to clipboard
  Create Sound from formula... TempZeroPad Mono 0 'zeroPadSecs' sf 0 * sin(2*pi*0*x)
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
procedure get_harmonic_freqamp_nolabels
  for j from 1 to 'number_harmonics_to_retrieve'
    previousFreq = 'currentFreq'
    # calculate begin and end frequencies for finding harmonic
    beginFrequency = ('pitchValue' * 'j') - ('search_bandwidth' / 2)
    endFrequency = ('pitchValue' * 'j') + ('search_bandwidth' / 2)
    # retrieve the spectral peak values
    call GetSpectralPeak
    if ('harmonic_frequencies_are' = 1)
      currentFreq = 'maxFreq'
     else
      currentFreq = ('pitchValue' * 'j')
    endif
    freqDiff= 'currentFreq' - 'previousFreq'
    currentAmp = 'maxAmp'
    # write data to matrices
    select 'freqsMatrixNumber'
    Set value... 'j' 'column' 'currentFreq'
    select 'ampsMatrixNumber'
    Set value... 'j' 'column' 'currentAmp'
    select 'freqDiffsMatrixNumber'
    Set value... 'j' 'column' 'freqDiff'
  endfor
endproc

############################################################
procedure GetSpectralPeak
  select 'spectrumNumber'
  # set bin limits
  startBin = Get bin number from frequency... 'beginFrequency'
  startBin = round('startBin')
  endBin = Get bin number from frequency... 'endFrequency'
  endBin = round('endBin')
  binWidth = Get bin width
  # retrieve peak frequency and amplitude
  maxBin = 'startBin'
  maxdB = 0.0
  for i from 'startBin' to 'endBin'
    currentFreqAmp = Get real value in bin... 'i'
    currentPhaseAmp = Get imaginary value in bin... 'i'
    # convert amplitude value to dB
    currentdB =  10 * log10 (2 * (currentFreqAmp^2 + currentPhaseAmp^2) * binWidth / 4e-10)
    if 'currentdB' > 'maxdB'
      maxBin = 'i'
      maxdB = 'currentdB'
    endif
  endfor
  # set final frequency and amplitude values
  maxFreq = Get frequency from bin... 'maxBin'
  maxAmp = 'maxdB'
endproc

############################################################
procedure concatenate_peak_data
  peakData$ = ""
  for i from 1 to 'number_harmonics_to_retrieve'
      peakNumber$ = " Pk'i'"
    select 'freqsMatrixNumber'
      peakFreq =  Get value in cell... 'i' 'column'
    select 'ampsMatrixNumber'
      peakAmp = Get value in cell... 'i' 'column'
    select 'freqDiffsMatrixNumber'
      peakFreqDiff = Get value in cell... 'i' 'column'
    peakFreq$ =  fixed$('peakFreq',1)
    peakAmp$ = fixed$('peakAmp',1)
    peakFreqDiff$ = fixed$('peakFreqDiff',1) 
    peakData$ = peakData$ + peakNumber$ + " " + peakFreq$ + " " + peakAmp$ + " " + peakFreqDiff$
  endfor
endproc
