# waveSpectrumSpectrogram
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

# waveSpectrumSpectrogram is part of GSU Praat Tools 1.8. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# waveSpectrumSpectrogram is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# set directory paths and names as needed
call set_data_paths

# get date and time: date$, weekday$, month$, daynumber$, time$, year$
call date_and_time

# query for what kind of figure to make
form make waveform, spectrum, and spectrogram figure
  optionmenu Processing_mode 1
    option none
    option Editor (no labels)
    option Editor (with labels)
  optionmenu Show_waveform 2
    option none
    option curve
    option bars
    option poles
    option speckles
  optionmenu Show_spectra 1
    option none
    option Fourier spectrum
    option LPC spectrum
    option Fourier plus LPC spectra
  optionmenu Show_spectrogram 2
    option none
    option spectrogram alone
    option ...plus visible pitch
    option ...plus visible formants
    option ...plus pitch and formants
  comment Spectrogram, LPC, and figure parameters...
  real Window_length 0.005
  integer Max_frequency_(Hz) 5500
  real Time_step_(s) 0.0002
  integer Frequency_step_(Hz) 20
  integer Dynamic_range_(dB) 50
  real Pre-emphasis_(dB/octave) 0
  optionmenu lpc_type 1
    option autocorrelation
    option covariance
    option burg
  integer Prediction_order 12
  real Max_time_for_figure_(s) 0 (= same as original)
  optionmenu Font_type 1
    option Times
    option Helvetica
    option Palatino
    option Courier
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

# initialize variables
font_size = 20
zeropadSecs = 0
zeroPadded = 0
resampleSegment = 0
if ('show_waveform' = 2)
  show_waveform$ = "curve"
 elsif ('show_waveform' = 3)
  show_waveform$ = "bars"
 elsif ('show_waveform' = 3)
  show_waveform$ = "poles"
 elsif ('show_waveform' = 5)
  show_waveform$ = "speckles"
endif

# jump to selected processing mode
if ('processing_mode' = 1)
  clearinfo
  printline
  printline Error: Select processing mode!
  printline
  printline Editor (no labels): Select one sound and open it in the Sound Editor
  printline Editor (with labels): Select one sound and open it in the TextGrid Editor
  exit
 elsif ('processing_mode' = 2) 
  call editor_nolabels
 elsif ('processing_mode' = 3) 
  call editor_withlabels
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

  # extract sound
  Extract selected sound (time from 0)

  # send control to Objects window
  endeditor

  # get sound name and number
  targetSegmentNumber = selected ("Sound", 1)
  targetSegmentName$ = selected$ ("Sound", 1)

  # get sampling frequency
  sf = Get sampling frequency

  # zeropad the waveform segment if needed, adjust length
  select 'targetSegmentNumber'
  targetSegmentDuration = Get total duration
  if ('max_time_for_figure' = 0)
    call find_round_number
   else
    zeroPadded = 1
    zeropadSecs = ('max_time_for_figure' - 'durTarget') / 2
    Copy... zeroPaddedTargetSegment
    zeroPaddedTargetSegmentNumber = selected ("Sound", 1)
    zeroPaddedTargetSegmentName$ = selected$ ("Sound", 1)
    select 'zeroPaddedTargetSegmentNumber'
    call zeropad_the_sound
    newSegmentDuration = 'max_time_for_figure'
  endif
  Scale times to... 0 'newSegmentDuration'

  # prepare Picture window: ink color, line type, font type, font size
  Erase all
  Black
  Solid line
  Line width... 1.0
  'font_type$'
  Font size... 'font_size'

 # select appropriate target segment
  if ('zeroPadded' = 1) 
    select 'zeroPaddedTargetSegmentNumber'
   else
    select 'targetSegmentNumber'
  endif

  # create waveform panel, if desired
  if ('show_waveform' > 1)
    beginX = 0
    endX = 6
    beginY = 0
    endY = 3
    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    Draw... 0 0 -1 1 yes 'show_waveform$'

    # paint over undesired labels if waveform is included, spectrum is not, spectrogram is
    if (('show_spectra' = 1) and ('show_spectrogram' > 1))
      beginX = -100
      endX = 100
      beginY = -1.2
      endY = -2.75
      Paint rectangle... White 'beginX' 'endX' 'beginY' 'endY'
    endif
  endif

  select 'targetSegmentNumber'
  # create spectrum panel, if desired
  # downsample to twice the visible frequency, if needed
  if ('show_spectra' > 1)
    if ('sf' > ('max_frequency' * 2))
      resampleSegment = 1
      Resample... 'max_frequency'*2 50
      resampledTargetSegmentNumber = selected ("Sound", 1)
    endif

    # create Fourier spectrum, if desired
    if (('show_spectra' = 2) or ('show_spectra' = 4)) 
      To Spectrum... yes
      targetSpectrumNumber = selected ("Spectrum", 1)
    endif

    # create LPC spectrum, if desired
    if (('show_spectra' = 3) or ('show_spectra' = 4))
      if ('resampleSegment' = 1)
        select 'resampledTargetSegmentNumber' 
       else
        select 'targetSegmentNumber'
      endif
      if ('pre-emphasis' = 0)
        preemphasis_from = 'max_frequency'
       else
        preemphasis_from = 50
      endif
      if ('lpc_type' = 1)
        To LPC (autocorrelation)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
       elsif ('lpc_type' = 2)
        To LPC (covariance)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
       elsif ('lpc_type' = 3)
        To LPC (burg)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
      endif
      targetLPCNumber = selected ("LPC", 1)
      To Spectrum (slice)... 0 20 0 'preemphasis_from'
       targetLPCSpectrumNumber = selected ("Spectrum", 1)
    endif

    # set Picture window coordinates
    if ('show_waveform' > 1) 
      beginX = 0
      endX = 6
      beginY = 2.5
      endY = 6
     else 
      beginX = 0
      endX = 6
      beginY = 0
      endY = 3.5
    endif

    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    # draw the spectra, as desired
    if (('show_spectra' = 2) or ('show_spectra' = 4)) 
      select 'targetSpectrumNumber'
      Black
      Draw... 0 0 0 0 yes
    endif
    if (('show_spectra' = 3) or ('show_spectra' = 4)) 
      select 'targetLPCSpectrumNumber'
      Line width... 1.0
      Red
      if ('show_spectra' = 3)
        Draw... 0 0 0 0 yes
      else
        Draw... 0 0 0 0 no
      endif
      Line width... 1.0
    endif
  endif

  # create spectrogram panel, if desired
  if ('show_spectrogram' > 1) 
    if ('zeroPadded' = 1) 
      select 'zeroPaddedTargetSegmentNumber'
     else
      select 'targetSegmentNumber'
    endif
    To Spectrogram... 'window_length' 'max_frequency' 'time_step' 'frequency_step' Gaussian
    targetSpectrogramNumber = selected ("Spectrogram", 1)
    targetSpectrogramName$ = selected$ ("Spectrogram", 1)
    if (('show_waveform' > 1) and ('show_spectra' > 1))
      beginX = 0
      endX = 6
      beginY = 5.5
      endY = 9
     elsif ('show_waveform' > 1)
      beginX = 0
      endX = 6
      beginY = 1.75
      endY = 5.25
     elsif ('show_spectra' > 1)
      beginX = 0
      endX = 6
      beginY = 3
      endY = 6.5
     else
      beginX = 0
      endX = 6
      beginY = 0
      endY = 3.5
    endif
    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    Paint... 0 0 0 0 100 yes 'dynamic_range' 'pre-emphasis' 0 yes

   # use target segment for extracting pitch and formant tracks
    if (('show_spectrogram' >= 3) or ('show_spectrogram' <= 5))
      if ('zeroPadded' = 1) 
        select 'zeroPaddedTargetSegmentNumber'
       else
        select 'targetSegmentNumber'
      endif
      Copy... tracksTargetSegment
      tracksTargetSegmentNumber = selected ("Sound", 1)
      tracksTargetSegmentName$ = selected$ ("Sound", 1)
      Edit
      editor Sound 'tracksTargetSegmentName$'
    endif

    # extract and overlay pitch track, if desired
    if (('show_spectrogram' = 3) or ('show_spectrogram' = 5))
      Extract visible pitch contour
      endeditor
      pitchNumber = selected ("Pitch", 1)
      pitchName$ = selected$ ("Pitch", 1)
      Blue
      Dotted line
      Line width... 1.0
      Speckle... 0 0 0 'max_frequency' no
    endif

    # extract and overlay formant track, if desired
    if (('show_spectrogram' = 4) or ('show_spectrogram' = 5))
      editor Sound 'tracksTargetSegmentName$'
      Extract visible formant contour
      endeditor
      formantNumber = selected ("Formant", 1)
      formantName$ = selected$ ("Formant", 1)
      Solid line
      Line width... 1.0
      Red
      Speckle... 0 0 'max_frequency' 30.0 no
    endif
    endeditor
  endif

  # select entire canvas
  Select outer viewport... 0 6 0 'endY'
  endeditor

  # clean up
  select 'targetSegmentNumber'
  if ('zeroPadded' = 1)
    plus 'zeroPaddedTargetSegmentNumber'
  endif
  if (('show_spectra' = 2) or ('show_spectra' = 4))
    plus 'targetSpectrumNumber'
  endif
  if (('show_spectra' = 3) or ('show_spectra' = 4))
    plus 'targetLPCNumber'
    plus 'targetLPCSpectrumNumber'
  endif
  if ('resampleSegment' = 1)
    plus 'resampledTargetSegmentNumber'
  endif
  if ('show_spectrogram' > 1)
    plus 'targetSpectrogramNumber'
    if (('show_spectrogram' >= 3) or ('show_spectrogram' <= 5))
      plus 'tracksTargetSegmentNumber'
    endif
    if (('show_spectrogram' = 3) or ('show_spectrogram' = 5))
      plus 'pitchNumber'
    endif
    if (('show_spectrogram' = 4) or ('show_spectrogram' = 5))
      plus 'formantNumber'
    endif
  endif
  Remove
 
  # display file and quit
  select 'soundNumber'
  editor Sound 'soundName$'
  Select... 'beginTarget' 'endTarget'
  Show all

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

  endeditor
  # get labels associated across all tiers
  call get_labels_raw midInterval
  call get_label_number
  call parse_interval_labels

  # concatenate labels at tier and interval levels
  call concatenate_labels

  editor TextGrid 'textGridName$'
  # extract sound
  Extract selected sound (time from 0)

  # send control to Objects window
  endeditor

  # get sound name and number
  targetSegmentNumber = selected ("Sound", 1)
  targetSegmentName$ = selected$ ("Sound", 1)

  # get sampling frequency
  sf = Get sampling frequency

  # zeropad the waveform segment if needed, adjust length
  select 'targetSegmentNumber'
  targetSegmentDuration = Get total duration
  if ('max_time_for_figure' = 0)
    call find_round_number
   else
    zeroPadded = 1
    zeropadSecs = ('max_time_for_figure' - 'durTarget') / 2
    Copy... zeroPaddedTargetSegment
    zeroPaddedTargetSegmentNumber = selected ("Sound", 1)
    zeroPaddedTargetSegmentName$ = selected$ ("Sound", 1)
    select 'zeroPaddedTargetSegmentNumber'
    call zeropad_the_sound
    newSegmentDuration = 'max_time_for_figure'
  endif
  Scale times to... 0 'newSegmentDuration'

  # prepare Picture window: ink color, line type, font type, font size
  Erase all
  Black
  Solid line
  Line width... 1.0
  'font_type$'
  Font size... 'font_size'

  # select appropriate target segment
  if ('zeroPadded' = 1) 
    select 'zeroPaddedTargetSegmentNumber'
   else
    select 'targetSegmentNumber'
  endif

  # create waveform panel, if desired
  if ('show_waveform' > 1)
    beginX = 0
    endX = 6
    beginY = 0
    endY = 3
    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    Draw... 0 0 -1 1 yes Curve

    # paint over undesired labels if waveform is included, spectrum is not, spectrogram is
    if ('show_spectra' = 1) and ('show_spectrogram' > 1)
      beginX = -100
      endX = 100
      beginY = -1.2
      endY = -2.75
      Paint rectangle... White 'beginX' 'endX' 'beginY' 'endY'
    endif
  endif

 # create spectrum panel, if desired

  select 'targetSegmentNumber'
  # downsample to twice the visible frequency
  if ('show_spectra' > 1)
    resampleSegment = 0
    if ('sf' > ('max_frequency' * 2))
      Resample... 'max_frequency'*2 50
      resampledTargetSegmentNumber = selected ("Sound", 1)
      resampleSegment = 1
    endif

    # create Fourier spectrum, if desired
    if (('show_spectra' = 2) or ('show_spectra' = 4)) 
      To Spectrum... yes
      targetSpectrumNumber = selected ("Spectrum", 1)
      if ('resampleSegment' = 1)
        select 'resampledTargetSegmentNumber' 
       else
        select 'targetSegmentNumber'
      endif
    endif    

    # create LPC spectrum, if desired
    if (('show_spectra' = 3) or ('show_spectra' = 4))
      if ('pre-emphasis' = 0)
        preemphasis_from = 'max_frequency'
       else
        preemphasis_from = 50
      endif
      if ('lpc_type' = 1)
        To LPC (autocorrelation)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
       elsif ('lpc_type' = 2)
        To LPC (covariance)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
       elsif ('lpc_type' = 3)
        To LPC (burg)... 'prediction_order' 'window_length' 'time_step' 'preemphasis_from'
      endif
      targetLPCNumber = selected ("LPC", 1)
      To Spectrum (slice)... 0 20 0 'preemphasis_from'
       targetLPCSpectrumNumber = selected ("Spectrum", 1)
    endif

    # set Picture window coordinates
    if ('show_waveform' > 1) 
      beginX = 0
      endX = 6
      beginY = 2.5
      endY = 6
     else 
      beginX = 0
      endX = 6
      beginY = 0
      endY = 3.5
    endif

    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    # draw the spectra, as desired
    if (('show_spectra' = 2) or ('show_spectra' = 4)) 
      select 'targetSpectrumNumber'
      Draw... 0 0 0 0 yes
    endif
    if (('show_spectra' = 3) or ('show_spectra' = 4)) 
      select 'targetLPCSpectrumNumber'
      Line width... 2.0
      Red
      if ('show_spectra' = 3)
        Draw... 0 0 0 0 yes
      else
        Draw... 0 0 0 0 no
      endif
      Line width... 1.0
    endif
  endif

  # create spectrogram panel, if desired
  if ('show_spectrogram' > 1) 
    if ('zeroPadded' = 1) 
      select 'zeroPaddedTargetSegmentNumber'
     else
      select 'targetSegmentNumber'
    endif
    To Spectrogram... 'window_length' 'max_frequency' 'time_step' 'frequency_step' Gaussian
    targetSpectrogramNumber = selected ("Spectrogram", 1)
    targetSpectrogramName$ = selected$ ("Spectrogram", 1)
    if (('show_waveform' > 1) and ('show_spectra' > 1))
      beginX = 0
      endX = 6
      beginY = 5.5
      endY = 9
     elsif ('show_waveform' > 1)
      beginX = 0
      endX = 6
      beginY = 1.75
      endY = 5.25
     elsif ('show_spectra' > 1)
      beginX = 0
      endX = 6
      beginY = 3
      endY = 6.5
     else
      beginX = 0
      endX = 6
      beginY = 0
      endY = 3.5
    endif
    Select outer viewport... 'beginX' 'endX' 'beginY' 'endY'
    Paint... 0 0 0 0 100 yes 'dynamic_range' 'pre-emphasis' 0 yes

   # use target segment for extracting pitch and formant tracks
    if (('show_spectrogram' >= 3) or ('show_spectrogram' <= 5))
      if ('zeroPadded' = 1) 
        select 'zeroPaddedTargetSegmentNumber'
       else
        select 'targetSegmentNumber'
      endif
      Copy... tracksTargetSegment
      tracksTargetSegmentNumber = selected ("Sound", 1)
      tracksTargetSegmentName$ = selected$ ("Sound", 1)
      Edit
      editor Sound 'tracksTargetSegmentName$'
    endif

    # extract and overlay pitch track, if desired
    if (('show_spectrogram' = 3) or ('show_spectrogram' = 5))
      Extract visible pitch contour
      endeditor
      pitchNumber = selected ("Pitch", 1)
      pitchName$ = selected$ ("Pitch", 1)
      Blue
      Dotted line
      Line width... 1.0
      Speckle... 0 0 0 'max_frequency' no
    endif

    # extract and overlay formant track, if desired
    if (('show_spectrogram' = 4) or ('show_spectrogram' = 5))
      editor Sound 'tracksTargetSegmentName$'
      Extract visible formant contour
      endeditor
      formantNumber = selected ("Formant", 1)
      formantName$ = selected$ ("Formant", 1)
      Solid line
      Line width... 1.0
      Red
      Speckle... 0 0 'max_frequency' 30.0 no
    endif
    endeditor
  endif

  # select entire canvas
  Select outer viewport... 0 6 0 'endY'

  # concatenate interval labels
  x = 'numberOfTiers'
  intervalConcat$ = ""
  while x >= 1
    intervalConcat$ = intervalConcat$ + intervalLabelStringConcat'x'$
    x = x - 1
  endwhile

  # write file name at top of figure
  Text top... no 'soundName$': 'tierLabelStringConcat$' 'intervalConcat$'

  endeditor
  # clean up
  select 'targetSegmentNumber'
  if ('zeroPadded' = 1)
    plus 'zeroPaddedTargetSegmentNumber'
  endif
  if (('show_spectra' = 2) or ('show_spectra' = 4))
    plus 'targetSpectrumNumber'
  endif
  if (('show_spectra' = 3) or ('show_spectra' = 4))
    plus 'targetLPCNumber'
    plus 'targetLPCSpectrumNumber'
  endif
  if ('resampleSegment' = 1)
    plus 'resampledTargetSegmentNumber'
  endif
  if ('show_spectrogram' > 1)
    plus 'targetSpectrogramNumber'
    if (('show_spectrogram' >= 3) or ('show_spectrogram' <= 5))
      plus 'tracksTargetSegmentNumber'
    endif
    if (('show_spectrogram' = 3) or ('show_spectrogram' = 5))
      plus 'pitchNumber'
    endif
    if (('show_spectrogram' = 4) or ('show_spectrogram' = 5))
      plus 'formantNumber'
    endif
  endif
  Remove

  # redisplay file and quit
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Select... 'beginTarget' 'endTarget'
  Show all

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
procedure zeropad_the_sound
  # create a file that is the right length of zeros, copy to clipboard
  Create Sound from formula... TempZeroPad Mono 0.0 'zeropadSecs' sf 0.0
  zeroSoundNumber = selected ("Sound")
  select 'zeroSoundNumber'
  Edit
  editor Sound TempZeroPad
  Select... 0.0 0.0
  Copy selection to Sound clipboard
  endeditor
  select 'zeroSoundNumber'
  Remove
  # select original sound, open editor
  select 'zeroPaddedTargetSegmentNumber'
  Edit
  editor Sound 'zeroPaddedTargetSegmentName$'
  # paste silence at beginning and end
  Move cursor to... 0.0
  Paste after selection
  Move cursor to... 10000.0
  Paste after selection
  # close editor
  Close
endproc

############################################################
procedure find_round_number
  if ('targetSegmentDuration' < 0.01)
    newSegmentDuration = ('targetSegmentDuration' * 10000)
    newSegmentDuration = round ('newSegmentDuration')
    newSegmentDuration = ('newSegmentDuration' / 10000)
   elsif ('targetSegmentDuration' < 0.1)
    newSegmentDuration = ('targetSegmentDuration' * 1000)
    newSegmentDuration = round ('newSegmentDuration')
    newSegmentDuration = ('newSegmentDuration' / 1000)
   elsif ('targetSegmentDuration' < 1.0)
    newSegmentDuration = ('targetSegmentDuration' * 100)
    newSegmentDuration = round ('newSegmentDuration')
    newSegmentDuration = ('newSegmentDuration' / 100)
   elsif ('targetSegmentDuration' < 10.0)
    newSegmentDuration = ('targetSegmentDuration' * 10)
    newSegmentDuration = round ('newSegmentDuration')
    newSegmentDuration = ('newSegmentDuration' / 10)
   else
    newSegmentDuration = round ('targetSegmentDuration')
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
  # shave trailing spaces off tier-level label strings
  while right$(tierLabelStringConcat$, 1) = " "
    stringLength = length(tierLabelStringConcat$)
    tierLabelStringConcat$ = left$(tierLabelStringConcat$, stringLength-1)
  endwhile
  while right$(tierLabelStringSpaced$, 1) = " "
    stringLength = length(tierLabelStringSpaced$)
    tierLabelStringSpaced$ = left$(tierLabelStringSpaced$, stringLength-1)
  endwhile
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
    while right$(intervalLabelStringConcat'i'$, 1) = " "
      stringLength = length(intervalLabelStringConcat'i'$)
      intervalLabelStringConcat'i'$ = left$(intervalLabelStringConcat'i'$, 'stringLength'-1)
    endwhile
    while right$(intervalLabelStringSpaced'i'$, 1) = " "
      stringLength = length(intervalLabelStringSpaced'i'$)
      intervalLabelStringSpaced'i'$ = left$(intervalLabelStringSpaced'i'$, 'stringLength'-1)
      if intervalLabelStringSpaced'i'$ = " "
        intervalLabelStringSpaced'i'$ = ""
      endif
    endwhile
  endfor
endproc
