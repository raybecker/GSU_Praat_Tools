# resynthLPC
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

# resynthLPC is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# resynthLPC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set program name, operating system, directory paths and names as needed
programName$ = "resynthLPC"
dataFile$ = "resynthlpc.out"
call set_data_paths

# bring up a user dialog box for pitch and LPC analyses
form resynthesize sounds using LPC
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Editor (with labels)
    option Objects (no labels)
    option Objects (with labels)
  boolean Move_on_after 0
  boolean Save_final_sound 1
  positive lpc_prediction_order 10
  real lpc_analysis_width_(s) 0.025
  real lpc_time_step_(s) 0.005
  boolean Use_preemphasis 1
  optionmenu Source_energy 1
    option both voiced and unvoiced
    option voiced segments only
    option unvoiced segments only
    option all unvoiced
  real Number_harmonics_to_retrieve 30
  optionmenu Unvoiced_source 1
    option Gaussian noise
    option Uniform
    option Chaotic noise
#  comment To create chaos, r can range from 3.57 to 3.90...
  real r_value_for_chaos 3.90
  comment Pitch extraction parameters...
  real Pitch_time_step_(s) 0.01
  positive Pitch_min_pitch_(Hz) 75
  positive Pitch_max_pitch_(Hz) 600
  boolean Pause_to_check_contour 1
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

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# set the remainder of pitch extraction variables
max_candidates = 15
very_accurate = 0
pitch_silence_threshold = 0.03
voicing_threshold = 0.45
octave_cost = 0.01
octave_jump_cost = 0.35
voiced_unvoiced_cost = 0.14

# set zeropadding variable
zeroPadSecs = 0.1

# set other variables
initial_x = 0.50
if ('source_energy' = 1)
  sourceType$ = "VoiUnv"
 elsif ('source_energy' = 2)
  sourceType$ = "VoiSeg"
 elsif ('source_energy' = 3)
  sourceType$ = "UnvSeg"
 elsif ('source_energy' = 4)
  sourceType$ = "AllUnv"
endif
if ('unvoiced_source' = 1)
  unvoicedType$ = "Gauss"
 elsif ('unvoiced_source' = 2)
  unvoicedType$ = "Chaos"
 else
  unvoicedType$ = ""
endif

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

  # set sampling frequency and period
  sf = Get sampling frequency
  sp = Get sampling period

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
  Close
  endeditor

  # name extracted segment by file name, begin and end times in ms
  beginMs = 'beginTarget' * 1000
  endMs = 'endTarget' * 1000
  Rename... 'soundName$''beginMs:0'to'endMs:0'
  targetsegmentNumber = selected ("Sound")
  targetsegmentName$ = selected$ ("Sound")

  # zeropad the file for better pitch extraction
  call sound_zero_pad

  # get intensity contour of the selected sound
  To Intensity... 100 0
  intensityNumber = selected ("Intensity") 
  intensityName$ = selected$ ("Intensity") 
  Down to IntensityTier
  intensityTierNumber = selected ("IntensityTier")
  intensityTierName$ = selected$ ("IntensityTier")

  # set pre-emphasis variable to the appropriate value
  if 'use_preemphasis' = 1
    lpc_preemphasis_from = 50    
   else
    lpc_preemphasis_from = ('sf' / 2)
  endif

  # reselect sound file
  select 'targetsegmentNumber'

  # get number of points in sound file
  durSound = 'durTarget' + (2 * 'zeroPadSecs')
  numberOfPoints = 'durSound' * 'sf'

  # make harmonic source energy, or an empty file
  if ('source_energy' <= 3)

    # do pitch analysis
    To Pitch (ac)... 'pitch_time_step' 'pitch_min_pitch' 'max_candidates'
      ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
      ... 'octave_jump_cost' 'voiced_unvoiced_cost' ('sf'/2)

    # get the name and number of the pitch file
    pitch1Name$ = selected$ ("Pitch")
    pitch1Number = selected ("Pitch")

    if pause_to_check_contour = 1
      # pause to allow user to fix pitch contour, if desired
      select 'pitch1Number'
      Edit
      editor Pitch 'pitch1Name$'
      pause Check the pitch contour, edit as needed
      Close
      endeditor
    endif

    # get max F0 in file, make fundamental frequency contour
    select 'pitch1Number'
    maxF0 = Get maximum... 0 0 Hertz Parabolic
    To Sound (sine)... 'sf' at nearest zero crossings
    harmonic1Number = selected ("Sound")
    harmonic1Name$ = selected$ ("Sound")

    # create remaining harmonics
    for i from 2 to 'number_harmonics_to_retrieve'
      # multiply to create the correct harmonic 
      select 'pitch1Number'
      Copy... pitch'i''soundName$'
      pitch'i'Number = selected ("Pitch")
      Formula... self*'i'
      To Sound (sine)... 'sf' at nearest zero crossings
      harmonic'i'Number = selected ("Sound")  
      harmonic'i'Name$ = selected$ ("Sound")
    endfor

    # use the first file as the one to add all subsequent files to
    select 'harmonic1Number'
    Copy... 'soundName$'Harmonics'number_harmonics_to_retrieve'
    harmonicSourceName$ = selected$ ("Sound")
    harmonicSourceNumber = selected ("Sound")
    numberOfSamples = Get number of samples

    # add each additional wavefrom in turn
    for i from 2 to 'number_harmonics_to_retrieve'
      select 'harmonicSourceNumber'
      currentHarmonicName$ = harmonic'i'Name$
      Formula... self + Sound_'currentHarmonicName$'[col]
    endfor

    # scale the final product, turn into a matrix
    Scale... 0.99
    Override sampling frequency... 1
    Down to Matrix

    # get name and number of harmonics matrix
    harmonicMatrixName$ = selected$ ("Matrix")
    harmonicMatrixNumber = selected ("Matrix")

   else
  
    # make an empty file
    Create simple Matrix... HarmonicSource 1 'numberOfPoints' 0

    # get name and number of harmonics matrix
    harmonicMatrixName$ = selected$ ("Matrix")
    harmonicMatrixNumber = selected ("Matrix")

    # turn into an empty sound, for bookkeeping purposes
    To Sound (slice)... 1
    Override sampling frequency... 'sf'
    harmonicSourceName$ = selected$ ("Sound")
    harmonicSourceNumber = selected ("Sound")

  endif

  # make noisy source energy, or an empty file
  if ('source_energy' <> 2)

    # make a noise-filled file
    if ('unvoiced_source' = 1)
      # create Gaussian noise in a matrix
      Create simple Matrix... NoiseSource 1 'numberOfPoints' randomGauss(0,0.1)
     elsif ('unvoiced_source' = 2)
      # create uniform noise in a matrix
      Create simple Matrix... NoiseSource 1 'numberOfPoints' randomUniform(0,0.1)
     elsif ('unvoiced_source' = 3)
      # create chaotic noise in a matrix based on the logistic equation: rx(1-x)
      x = 'initial_x'
      r = 'r_value'
      Create simple Matrix... NoiseSource 1 'numberOfPoints' if col=1 then 'x' else 'r'*self[col-1]*(1-self[col-1]) endif
    endif

    # subtract mean
    sumOfRow = Get sum
    meanOfRow = ('sumOfRow' / 'numberOfPoints')
    Formula... self - 'meanOfRow'     

   else

    # make an empty file
    Create simple Matrix... NoiseSource 1 'numberOfPoints' 0

  endif

  # get name and number of noise matrix
  noiseMatrixName$ = selected$ ("Matrix")
  noiseMatrixNumber = selected ("Matrix")

  # merge the matrices, with harmonic energy overriding noisy energy
  select 'harmonicMatrixNumber'
  plus 'noiseMatrixNumber'
  Merge (append rows)
  combinedMatrixName$ = selected$ ("Matrix")
  combinedMatrixNumber = selected ("Matrix")

  # turn matrix into sound
  if ('source_energy' = 1)
    for column from 1 to 'numberOfPoints'
      currentValue = Get value in cell... 1 'column'
      if ('currentValue' <> 0)
        Set value... 2 'column' 'currentValue'
      endif
    endfor
    To Sound (slice)... 2
  endif
  if ('source_energy' = 2)
    To Sound (slice)... 1
  endif
  if ('source_energy' = 3)
    for column from 1 to 'numberOfPoints'
      currentValue = Get value in cell... 1 'column'
      if ('currentValue' <> 0)
        Set value... 2 'column' 0
      endif
    endfor
    To Sound (slice)... 2
  endif
  if ('source_energy' = 4)
    To Sound (slice)... 2
  endif

  # get name and number of sound
  combinedSourceName$ = selected$ ("Sound")
  combinedSourceNumber = selected ("Sound")

  # set critical sound parameters
  Override sampling frequency... 'sf'

  # make sure sound begins at 0, get name and number of file
  Edit
  editor Sound 'combinedSourceName$'
  Select... 0.0 10000
  Extract selected sound (time from 0)
  Close
  endeditor
  Rename... 'combinedSourceName$'
  adjustedSourceName$ = selected$ ("Sound")
  adjustedSourceNumber = selected ("Sound")
    
  # scale by intensity contour of original sound
  plus 'intensityTierNumber'
  Multiply
  Scale... 0.99

  # get name, number, and duration of final source
  finalSourceName$ = selected$ ("Sound")
  finalSourceNumber = selected ("Sound")
  sourceDuration = Get total duration

  # do LPC analysis on original sound, get file duration
  select 'targetsegmentNumber'
  To LPC (autocorrelation)... 'lpc_prediction_order' 'lpc_analysis_width' 'lpc_time_step' 'lpc_preemphasis_from'
  lpcNumber = selected ("LPC")
  filterDuration = Get total duration

  # if source and filter are different durations, adjust the source file as needed
  differenceDuration = abs('sourceDuration' - 'filterDuration')
  if (('sourceDuration' <> 'filterDuration') and ('differenceDuration' > 'sp'))
    select 'finalSourceNumber'
    Edit
    editor Sound 'finalSourceName$'
    begin_segment = 'sourceDuration' - 'differenceDuration' 
    end_segment = 'sourceDuration'
    Select... 'begin_segment' 'end_segment'
    if ('sourceDuration' > 'filterDuration')
      Cut
     elsif ('sourceDuration' < 'filterDuration')
      Copy selection to Sound clipboard
      Paste after selection
    endif
    Close
    endeditor
  endif

  # do the filtering
  select 'finalSourceNumber'
  plus 'lpcNumber'
  Filter... 1
  finalSynthNumber = selected ("Sound")
  Rename... 'soundName$''beginMs:0'to'endMs:0''sourceType$''unvoicedType$'Lpc
  finalSynthName$ = selected$ ("Sound")
  Scale... 0.99

  # clean up
  select 'targetsegmentNumber'
    plus 'intensityNumber'
    plus 'intensityTierNumber'
    plus 'lpcNumber'
    if ('source_energy' <= 3)
      for i from 1 to 'number_harmonics_to_retrieve'
        plus pitch'i'Number
        plus harmonic'i'Number
      endfor
    endif
    plus 'harmonicSourceNumber'
    plus 'harmonicMatrixNumber'
    plus 'noiseMatrixNumber'
    plus 'combinedMatrixNumber'
    plus 'combinedSourceNumber'
    plus 'adjustedSourceNumber'
    plus 'finalSourceNumber'
  Remove

  # save final sound to disk, if desired
  if ('save_final_sound' = 1)
    call save_data_to_disk
  endif

  # go on to a new file or quit
  select 'soundNumber'
  Edit
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

  # select only sound file to get sampling frequency and period
  select 'soundNumber'
  sf = Get sampling frequency
  sp = Get sampling period

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

  # get labels associated across all tiers
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  # zeropad the file or segment for better pitch extraction
  call sound_zero_pad

  # get intensity contour of the selected sound
  To Intensity... 100 0
  intensityNumber = selected ("Intensity") 
  intensityName$ = selected$ ("Intensity") 
  Down to IntensityTier
  intensityTierNumber = selected ("IntensityTier")
  intensityTierName$ = selected$ ("IntensityTier")

  # set pre-emphasis variable to the appropriate value
  if 'use_preemphasis' = 1
    lpc_preemphasis_from = 50    
   else
    lpc_preemphasis_from = ('sf' / 2)
  endif

  # get number of points in sound file
  durSound = 'durTarget' + (2 * 'zeroPadSecs')
  numberOfPoints = 'durSound' * 'sf'

  select 'targetsegmentNumber'
  # make harmonic source energy, or an empty file
  if ('source_energy' <= 3)

    # do pitch analysis
    To Pitch (ac)... 'pitch_time_step' 'pitch_min_pitch' 'max_candidates'
      ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
      ... 'octave_jump_cost' 'voiced_unvoiced_cost' ('sf'/2)

    # get the name and number of the pitch file
    pitch1Name$ = selected$ ("Pitch")
    pitch1Number = selected ("Pitch")

    if pause_to_check_contour = 1
      # pause to allow user to fix pitch contour, if desired
      select 'pitch1Number'
      Edit
      editor Pitch 'pitch1Name$'
      pause Check the pitch contour, edit as needed
      Close
      endeditor
    endif

    # get max F0 in file, make fundamental frequency contour
    select 'pitch1Number'
    maxF0 = Get maximum... 0 0 Hertz Parabolic
    To Sound (sine)... 'sf' at nearest zero crossings
    harmonic1Number = selected ("Sound")
    harmonic1Name$ = selected$ ("Sound")

    # create remaining harmonics
    for i from 2 to 'number_harmonics_to_retrieve'
      # multiply to create the correct harmonic 
      select 'pitch1Number'
      Copy... pitch'i''soundName$'
      pitch'i'Number = selected ("Pitch")
      Formula... self*'i'
      To Sound (sine)... 'sf' at nearest zero crossings
      harmonic'i'Number = selected ("Sound")  
      harmonic'i'Name$ = selected$ ("Sound")
    endfor

    # use the first file as the one to add all subsequent files to
    select 'harmonic1Number'
    Copy... 'soundName$'Harmonics'number_harmonics_to_retrieve'
    harmonicSourceName$ = selected$ ("Sound")
    harmonicSourceNumber = selected ("Sound")
    numberOfSamples = Get number of samples

    # add each additional wavefrom in turn
    for i from 2 to 'number_harmonics_to_retrieve'
      select 'harmonicSourceNumber'
      currentHarmonicName$ = harmonic'i'Name$
      Formula... self + Sound_'currentHarmonicName$'[col]
    endfor

    # scale the final product, turn into a matrix
    Scale... 0.99
    Override sampling frequency... 1
    Down to Matrix

    # get name and number of harmonics matrix
    harmonicMatrixName$ = selected$ ("Matrix")
    harmonicMatrixNumber = selected ("Matrix")

   else
  
    # make an empty file
    Create simple Matrix... HarmonicSource 1 'numberOfPoints' 0

    # get name and number of harmonics matrix
    harmonicMatrixName$ = selected$ ("Matrix")
    harmonicMatrixNumber = selected ("Matrix")

    # turn into an empty sound, for bookkeeping purposes
    To Sound (slice)... 1
    Override sampling frequency... 'sf'
    harmonicSourceName$ = selected$ ("Sound")
    harmonicSourceNumber = selected ("Sound")

  endif

  # make noisy source energy, or an empty file
  if ('source_energy' <> 2)

    # make a noise-filled file
    if ('unvoiced_source' = 1)
      # create Gaussian noise in a matrix
      Create simple Matrix... NoiseSource 1 'numberOfPoints' randomGauss(0,0.1)
     else
      # create chaotic noise in a matrix based on the logistic equation: rx(1-x)
      x = 'initial_x'
      r = 'r_value'
      Create simple Matrix... NoiseSource 1 'numberOfPoints' if col=1 then 'x' else 'r'*self[col-1]*(1-self[col-1]) endif
    endif

    # subtract mean
    sumOfRow = Get sum
    meanOfRow = ('sumOfRow' / 'numberOfPoints')
    Formula... self - 'meanOfRow'     

   else

    # make an empty file
    Create simple Matrix... NoiseSource 1 'numberOfPoints' 0

  endif

  # get name and number of noise matrix
  noiseMatrixName$ = selected$ ("Matrix")
  noiseMatrixNumber = selected ("Matrix")

  # merge the matrices, with harmonic energy overriding noisy energy
  select 'harmonicMatrixNumber'
  plus 'noiseMatrixNumber'
  Merge (append rows)
  combinedMatrixName$ = selected$ ("Matrix")
  combinedMatrixNumber = selected ("Matrix")

  # turn matrix into sound
  if ('source_energy' = 1)
    for column from 1 to 'numberOfPoints'
      currentValue = Get value in cell... 1 'column'
      if ('currentValue' <> 0)
        Set value... 2 'column' 'currentValue'
      endif
    endfor
    To Sound (slice)... 2
  endif
  if ('source_energy' = 2)
    To Sound (slice)... 1
  endif
  if ('source_energy' = 3)
    for column from 1 to 'numberOfPoints'
      currentValue = Get value in cell... 1 'column'
      if ('currentValue' <> 0)
        Set value... 2 'column' 0
      endif
    endfor
    To Sound (slice)... 2
  endif
  if ('source_energy' = 4)
    To Sound (slice)... 2
  endif

  # get name and number of sound
  combinedSourceName$ = selected$ ("Sound")
  combinedSourceNumber = selected ("Sound")   

  # set critical sound parameters
  Override sampling frequency... 'sf'

  # scale by intensity contour of original sound
  plus 'intensityTierNumber'
  Multiply
  Scale... 0.99

  # get name and number of sound
  combinedSourceName$ = selected$ ("Sound")
  combinedSourceNumber = selected ("Sound")

  # set critical sound parameters
  Override sampling frequency... 'sf'

  # make sure sound begins at 0, get name and number of file
  Edit
  editor Sound 'combinedSourceName$'
  Select... 0.0 10000
  Extract selected sound (time from 0)
  Close
  endeditor
  Rename... 'combinedSourceName$'
  adjustedSourceName$ = selected$ ("Sound")
  adjustedSourceNumber = selected ("Sound")
    
  # scale by intensity contour of original sound
  plus 'intensityTierNumber'
  Multiply
  Scale... 0.99

  # get name, number, and duration of final source
  finalSourceName$ = selected$ ("Sound")
  finalSourceNumber = selected ("Sound")
  sourceDuration = Get total duration

  # do LPC analysis on original sound, get file duration
  select 'targetsegmentNumber'
  To LPC (autocorrelation)... 'lpc_prediction_order' 'lpc_analysis_width' 'lpc_time_step' 'lpc_preemphasis_from'
  lpcNumber = selected ("LPC")
  filterDuration = Get total duration

  # if source and filter are different durations, adjust the source file as needed
  differenceDuration = abs('sourceDuration' - 'filterDuration')
  if (('sourceDuration' <> 'filterDuration') and ('differenceDuration' > 'sp'))
    select 'finalSourceNumber'
    Edit
    editor Sound 'finalSourceName$'
    begin_segment = 'sourceDuration' - 'differenceDuration' 
    end_segment = 'sourceDuration'
    Select... 'begin_segment' 'end_segment'
    if ('sourceDuration' > 'filterDuration')
      Cut
     elsif ('sourceDuration' < 'filterDuration')
      Copy selection to Sound clipboard
      Paste after selection
    endif
    Close
    endeditor
  endif

  # do the filtering
  select 'finalSourceNumber'
  plus 'lpcNumber'
  Filter... 1
  finalSynthNumber = selected ("Sound")
  Rename... 'soundName$''beginMs:0'to'endMs:0''sourceType$''unvoicedType$'Lpc
  finalSynthName$ = selected$ ("Sound")
  Scale... 0.99

  # clean up
  select 'targetsegmentNumber'
    plus 'intensityNumber'
    plus 'intensityTierNumber'
   plus 'lpcNumber'
    if ('source_energy' <= 3)
      for i from 1 to 'number_harmonics_to_retrieve'
        plus pitch'i'Number
        plus harmonic'i'Number
      endfor
    endif
    plus 'harmonicSourceNumber'
    plus 'harmonicMatrixNumber'
    plus 'noiseMatrixNumber'
    plus 'combinedMatrixNumber'
    plus 'combinedSourceNumber'
    plus 'adjustedSourceNumber'
    plus 'finalSourceNumber'
  Remove

  # go on to a new file or quit
  select 'soundNumber'
  plus 'textGridNumber'
  Edit
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

    # set sampling frequency and period
    sf = Get sampling frequency
    sp = Get sampling period

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

    # set selection in editor
    Edit
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

    # zeropad the file or segment for better pitch extraction
    call sound_zero_pad

    # get intensity contour of the selected sound
    To Intensity... 100 0
    intensityNumber = selected ("Intensity") 
    intensityName$ = selected$ ("Intensity") 
    Down to IntensityTier
    intensityTierNumber = selected ("IntensityTier")
    intensityTierName$ = selected$ ("IntensityTier")

    # set pre-emphasis variable to the appropriate value
    if 'use_preemphasis' = 1
      lpc_preemphasis_from = 50    
     else
      lpc_preemphasis_from = ('sf' / 2)
    endif

    # reselect sound file
    select 'targetsegmentNumber'

    # get number of points in sound file
    durSound = 'durTarget' + (2 * 'zeroPadSecs')
    numberOfPoints = 'durSound' * 'sf'

    # make harmonic source energy, or an empty file
    if ('source_energy' <= 3)

      # do pitch analysis
      To Pitch (ac)... 'pitch_time_step' 'pitch_min_pitch' 'max_candidates'
        ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
        ... 'octave_jump_cost' 'voiced_unvoiced_cost' ('sf'/2)

      # get the name and number of the pitch file
      pitch1Name$ = selected$ ("Pitch")
      pitch1Number = selected ("Pitch")

      if pause_to_check_contour = 1
        # pause to allow user to fix pitch contour, if desired
        select 'pitch1Number'
        Edit
        editor Pitch 'pitch1Name$'
        pause Check the pitch contour, edit as needed
        Close
        endeditor
      endif

      # get max F0 in file, make fundamental frequency contour
      select 'pitch1Number'
      maxF0 = Get maximum... 0 0 Hertz Parabolic
      To Sound (sine)... 'sf' at nearest zero crossings
      harmonic1Number = selected ("Sound")
      harmonic1Name$ = selected$ ("Sound")

      # create remaining harmonics
      for i from 2 to 'number_harmonics_to_retrieve'
        # multiply to create the correct harmonic 
        select 'pitch1Number'
        Copy... pitch'i''soundName$'
        pitch'i'Number = selected ("Pitch")
        Formula... self*'i'
        To Sound (sine)... 'sf' at nearest zero crossings
        harmonic'i'Number = selected ("Sound")  
        harmonic'i'Name$ = selected$ ("Sound")
      endfor

      # use the first file as the one to add all subsequent files to
      select 'harmonic1Number'
      Rename... 'soundName$'Harmonics'number_harmonics_to_retrieve'
      harmonicSourceName$ = selected$ ("Sound")
      harmonicSourceNumber = selected ("Sound")
      numberOfSamples = Get number of samples

      # add each additional wavefrom in turn
      for i from 2 to 'number_harmonics_to_retrieve'
        select 'harmonicSourceNumber'
        currentHarmonicName$ = harmonic'i'Name$
        Formula... self + Sound_'currentHarmonicName$'[col]
      endfor

      # scale the final product, turn into a matrix
      Scale... 0.99
      Override sampling frequency... 1
      Down to Matrix

      # get name and number of harmonics matrix
      harmonicMatrixName$ = selected$ ("Matrix")
      harmonicMatrixNumber = selected ("Matrix")

     else

      # make an empty file
      Create simple Matrix... HarmonicSource 1 'numberOfPoints' 0

      # get name and number of harmonics matrix
      harmonicMatrixName$ = selected$ ("Matrix")
      harmonicMatrixNumber = selected ("Matrix")

      # turn into an empty sound, for bookkeeping purposes
      To Sound (slice)... 1
      Override sampling frequency... 'sf'
      harmonicSourceName$ = selected$ ("Sound")
      harmonicSourceNumber = selected ("Sound")

    endif

    # make noisy source energy, or an empty file
    if ('source_energy' <> 2)

      # make a noise-filled file
      if ('unvoiced_source' = 1)
        # create Gaussian noise in a matrix
        Create simple Matrix... NoiseSource 1 'numberOfPoints' randomGauss(0,0.1)
       else
        # create chaotic noise in a matrix based on the logistic equation: rx(1-x)
        x = 'initial_x'
        r = 'r_value'
        Create simple Matrix... NoiseSource 1 'numberOfPoints' if col=1 then 'x' else 'r'*self[col-1]*(1-self[col-1]) endif
      endif

      # subtract mean
      sumOfRow = Get sum
      meanOfRow = ('sumOfRow' / 'numberOfPoints')
      Formula... self - 'meanOfRow'     

     else

      # make an empty file
      Create simple Matrix... NoiseSource 1 'numberOfPoints' 0

    endif

    # get name and number of noise matrix
    noiseMatrixName$ = selected$ ("Matrix")
    noiseMatrixNumber = selected ("Matrix")

    # merge the matrices, with harmonic energy overriding noisy energy
    select 'harmonicMatrixNumber'
    plus 'noiseMatrixNumber'
    Merge (append rows)
    combinedMatrixName$ = selected$ ("Matrix")
    combinedMatrixNumber = selected ("Matrix")

    # turn matrix into sound
    if ('source_energy' = 1)
      for column from 1 to 'numberOfPoints'
        currentValue = Get value in cell... 1 'column'
        if ('currentValue' <> 0)
          Set value... 2 'column' 'currentValue'
        endif
      endfor
      To Sound (slice)... 2
    endif
    if ('source_energy' = 2)
      To Sound (slice)... 1
    endif
    if ('source_energy' = 3)
      for column from 1 to 'numberOfPoints'
        currentValue = Get value in cell... 1 'column'
        if ('currentValue' <> 0)
          Set value... 2 'column' 0
        endif
      endfor
      To Sound (slice)... 2
    endif
    if ('source_energy' = 4)
      To Sound (slice)... 2
    endif

    # get name and number of sound
    combinedSourceName$ = selected$ ("Sound")
    combinedSourceNumber = selected ("Sound")   

    # set critical sound parameters
    Override sampling frequency... 'sf'

    # make sure sound begins at 0, get name and number of file
    Edit
    editor Sound 'combinedSourceName$'
    Select... 0.0 10000
    Extract selected sound (time from 0)
    Close
    endeditor
    Rename... 'combinedSourceName$'
    adjustedSourceName$ = selected$ ("Sound")
    adjustedSourceNumber = selected ("Sound")
    
    # scale by intensity contour of original sound
    plus 'intensityTierNumber'
    Multiply
    Scale... 0.99

    # get name, number, and duration of final source
    finalSourceName$ = selected$ ("Sound")
    finalSourceNumber = selected ("Sound")
    sourceDuration = Get total duration

    # do LPC analysis on original sound, get file duration
    select 'targetsegmentNumber'
    To LPC (autocorrelation)... 'lpc_prediction_order' 'lpc_analysis_width' 'lpc_time_step' 'lpc_preemphasis_from'
    lpcNumber = selected ("LPC")
    filterDuration = Get total duration

    # if source and filter are different durations, adjust the source file as needed
    differenceDuration = abs('sourceDuration' - 'filterDuration')
    if (('sourceDuration' <> 'filterDuration') and ('differenceDuration' > 'sp'))
      select 'finalSourceNumber'
      Edit
      editor Sound 'finalSourceName$'
      begin_segment = 'sourceDuration' - 'differenceDuration' 
      end_segment = 'sourceDuration'
      Select... 'begin_segment' 'end_segment'
      if ('sourceDuration' > 'filterDuration')
        Cut
       elsif ('sourceDuration' < 'filterDuration')
        Copy selection to Sound clipboard
        Paste after selection
      endif
      Close
      endeditor
    endif

    # do the filtering
    select 'finalSourceNumber'
    plus 'lpcNumber'
    Filter... 1
    finalSynthNumber = selected ("Sound")
    Rename... 'soundName$''beginMs:0'to'endMs:0''sourceType$''unvoicedType$'Lpc
    finalSynthName$ = selected$ ("Sound")
    Scale... 0.99

    # clean up
    select 'soundNumber'
    editor Sound 'soundName$'
    Close
    endeditor
    select 'targetsegmentNumber'
      plus 'intensityNumber'
      plus 'intensityTierNumber'
      plus 'lpcNumber'
      if ('source_energy' <= 3)
        for i from 1 to 'number_harmonics_to_retrieve'
          plus pitch'i'Number
          plus harmonic'i'Number
        endfor
      endif
      plus 'harmonicSourceNumber'
      plus 'harmonicMatrixNumber'
      plus 'noiseMatrixNumber'
      plus 'combinedMatrixNumber'
      plus 'combinedSourceNumber'
      plus 'adjustedSourceNumber'
      plus 'finalSourceNumber'
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

    # set sampling frequency and period
    sf = Get sampling frequency
    sp = Get sampling period

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

        # zeropad the file or segment for better pitch extraction
        call sound_zero_pad

        # get intensity contour of the selected sound
        To Intensity... 100 0
        intensityNumber = selected ("Intensity") 
        intensityName$ = selected$ ("Intensity") 
        Down to IntensityTier
        intensityTierNumber = selected ("IntensityTier")
        intensityTierName$ = selected$ ("IntensityTier")

        # get labels associated across all tiers
        select 'textGridNumber'
        call get_labels_raw midTarget
        call get_label_number
        call parse_interval_labels

        # concatenate labels at tier and interval levels
        call concatenate_labels

        # set pre-emphasis variable to the appropriate value
        if 'use_preemphasis' = 1
          lpc_preemphasis_from = 50    
         else
          lpc_preemphasis_from = ('sf' / 2)
        endif

        # reselect sound file
        select 'targetsegmentNumber'

        # get number of points in sound file
        durSound = 'durTarget' + (2 * 'zeroPadSecs')
        numberOfPoints = 'durSound' * 'sf'

        # make harmonic source energy, or an empty file
        if ('source_energy' <= 3)

          # do pitch analysis
          To Pitch (ac)... 'pitch_time_step' 'pitch_min_pitch' 'max_candidates'
            ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
            ... 'octave_jump_cost' 'voiced_unvoiced_cost' ('sf'/2)

          # get the name and number of the pitch file
          pitch1Name$ = selected$ ("Pitch")
          pitch1Number = selected ("Pitch")

          if pause_to_check_contour = 1
            # pause to allow user to fix pitch contour, if desired
            select 'pitch1Number'
            Edit
            editor Pitch 'pitch1Name$'
            pause Check the pitch contour, edit as needed
            Close
            endeditor
          endif

          # get max F0 in file, make fundamental frequency contour
          select 'pitch1Number'
          maxF0 = Get maximum... 0 0 Hertz Parabolic
          To Sound (sine)... 'sf' at nearest zero crossings
          harmonic1Number = selected ("Sound")
          harmonic1Name$ = selected$ ("Sound")

          # create remaining harmonics
          for i from 2 to 'number_harmonics_to_retrieve'
            # multiply to create the correct harmonic 
            select 'pitch1Number'
            Copy... pitch'i''soundName$'
            pitch'i'Number = selected ("Pitch")
            Formula... self*'i'
            To Sound (sine)... 'sf' at nearest zero crossings
            harmonic'i'Number = selected ("Sound")  
            harmonic'i'Name$ = selected$ ("Sound")
          endfor

          # use the first file as the one to add all subsequent files to
          select 'harmonic1Number'
          Rename... 'soundName$'Harmonics'number_harmonics_to_retrieve'
          harmonicSourceName$ = selected$ ("Sound")
          harmonicSourceNumber = selected ("Sound")
          numberOfSamples = Get number of samples

          # add each additional wavefrom in turn
          for i from 2 to 'number_harmonics_to_retrieve'
            select 'harmonicSourceNumber'
            currentHarmonicName$ = harmonic'i'Name$
            Formula... self + Sound_'currentHarmonicName$'[col]
          endfor

          # scale the final product, turn into a matrix
          Scale... 0.99
          Override sampling frequency... 1
          Down to Matrix

          # get name and number of harmonics matrix
          harmonicMatrixName$ = selected$ ("Matrix")
          harmonicMatrixNumber = selected ("Matrix")

         else

          # make an empty file
          Create simple Matrix... HarmonicSource 1 'numberOfPoints' 0

          # get name and number of harmonics matrix
          harmonicMatrixName$ = selected$ ("Matrix")
          harmonicMatrixNumber = selected ("Matrix")

          # turn into an empty sound, for bookkeeping purposes
          To Sound (slice)... 1
          Override sampling frequency... 'sf'
          harmonicSourceName$ = selected$ ("Sound")
          harmonicSourceNumber = selected ("Sound")

        endif

        # make noisy source energy, or an empty file
        if ('source_energy' <> 2)

          # make a noise-filled file
          if ('unvoiced_source' = 1)
            # create Gaussian noise in a matrix
            Create simple Matrix... NoiseSource 1 'numberOfPoints' randomGauss(0,0.1)
           else
            # create chaotic noise in a matrix based on the logistic equation: rx(1-x)
            x = 'initial_x'
            r = 'r_value'
            Create simple Matrix... NoiseSource 1 'numberOfPoints' if col=1 then 'x' else 'r'*self[col-1]*(1-self[col-1]) endif
          endif

          # subtract mean
          sumOfRow = Get sum
          meanOfRow = ('sumOfRow' / 'numberOfPoints')
          Formula... self - 'meanOfRow'     

         else

          # make an empty file
          Create simple Matrix... NoiseSource 1 'numberOfPoints' 0

        endif

        # get name and number of noise matrix
        noiseMatrixName$ = selected$ ("Matrix")
        noiseMatrixNumber = selected ("Matrix")

        # merge the matrices, with harmonic energy overriding noisy energy
        select 'harmonicMatrixNumber'
        plus 'noiseMatrixNumber'
        Merge (append rows)
        combinedMatrixName$ = selected$ ("Matrix")
        combinedMatrixNumber = selected ("Matrix")

        # turn matrix into sound
        if ('source_energy' = 1)
          for column from 1 to 'numberOfPoints'
            currentValue = Get value in cell... 1 'column'
            if ('currentValue' <> 0)
            Set value... 2 'column' 'currentValue'
            endif
          endfor
          To Sound (slice)... 2
        endif
        if ('source_energy' = 2)
          To Sound (slice)... 1
        endif
        if ('source_energy' = 3)
          for column from 1 to 'numberOfPoints'
            currentValue = Get value in cell... 1 'column'
            if ('currentValue' <> 0)
              Set value... 2 'column' 0
            endif
          endfor
          To Sound (slice)... 2
        endif
        if ('source_energy' = 4)
          To Sound (slice)... 2
        endif

        # get name and number of sound
        combinedSourceName$ = selected$ ("Sound")
        combinedSourceNumber = selected ("Sound")

        # set critical sound parameters
        Override sampling frequency... 'sf'

        # make sure sound begins at 0, get name and number of file
        Edit
        editor Sound 'combinedSourceName$'
        Select... 0.0 10000
        Extract selected sound (time from 0)
        Close
        endeditor
        Rename... 'combinedSourceName$'
        adjustedSourceName$ = selected$ ("Sound")
        adjustedSourceNumber = selected ("Sound")
    
        # scale by intensity contour of original sound
        plus 'intensityTierNumber'
        Multiply
        Scale... 0.99

        # get name, number, and duration of final source
        finalSourceName$ = selected$ ("Sound")
        finalSourceNumber = selected ("Sound")
        sourceDuration = Get total duration

        # do LPC analysis on original sound, get file duration
        select 'targetsegmentNumber'
        To LPC (autocorrelation)... 'lpc_prediction_order' 'lpc_analysis_width' 'lpc_time_step' 'lpc_preemphasis_from'
        lpcNumber = selected ("LPC")
        filterDuration = Get total duration

        # if source and filter are different durations, adjust the source file as needed
        differenceDuration = abs('sourceDuration' - 'filterDuration')
        if (('sourceDuration' <> 'filterDuration') and ('differenceDuration' > 'sp'))
          select 'finalSourceNumber'
          Edit
          editor Sound 'finalSourceName$'
          begin_segment = 'sourceDuration' - 'differenceDuration' 
          end_segment = 'sourceDuration'
          Select... 'begin_segment' 'end_segment'
          if ('sourceDuration' > 'filterDuration')
            Cut
           elsif ('sourceDuration' < 'filterDuration')
            Copy selection to Sound clipboard
            Paste after selection
          endif
          Close
          endeditor
        endif

        # do the filtering
        select 'finalSourceNumber'
        plus 'lpcNumber'
        Filter... 1
        finalSynthNumber = selected ("Sound")
        Rename... 'soundName$''beginMs:0'to'endMs:0''sourceType$''unvoicedType$'Lpc
        finalSynthName$ = selected$ ("Sound")
        Scale... 0.99

        # clean up
        select 'soundNumber'
        editor TextGrid 'textGridName$'
        Close
        endeditor
        select 'targetsegmentNumber'
          plus 'intensityNumber'
          plus 'intensityTierNumber'
          plus 'lpcNumber'
          if ('source_energy' <= 3)
            for i from 1 to 'number_harmonics_to_retrieve'
              plus pitch'i'Number
              plus harmonic'i'Number
            endfor
          endif
          plus 'harmonicSourceNumber'
          plus 'harmonicMatrixNumber'
          plus 'noiseMatrixNumber'
          plus 'combinedMatrixNumber'
          plus 'combinedSourceNumber'
          plus 'adjustedSourceNumber'
          plus 'finalSourceNumber'
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
  select 'finalSynthNumber'
  Write to WAV file... 'dataDirectoryPath$''sl$''finalSynthName$'.wav
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
