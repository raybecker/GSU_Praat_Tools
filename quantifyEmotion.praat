# quantifyEmotion
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

# quantifyEmotion is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# quantifyEmotion is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for analysis parameters 
form quantify Emotion
  comment quantify Emotion targets emotion in spoken narratives, including pitch and
  comment intensity entropy (after Cohen et al., 2009), voicing, jitter, shimmer, and HNR.
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor
    option Objects
  boolean Move_on_after 0
  boolean Pause_to_check_contour 1
  boolean Pause_to_check_data 0
  optionmenu Save_data_to_file 1
    option no data file
    option space-delimited (.out)
    option comma-delimited (.csv)
  boolean Include_data_header 0
  boolean Include_jitter_and_shimmer 0
  boolean Include_HNR 0
  comment Pitch and intensity extraction parameters...
  real Time_step_(s) 0.0
  positive Pitch_floor_(Hz) 75
  positive Pitch_ceiling_(Hz) 600
  optionmenu Jitter_type 3
    option local
    option local, absolute
    option rap
    option ppq5
    option ddp
  optionmenu Shimmer_type 2
    option local
    option local_dB
    option apq3
    option apq5
    option apq11
    option dda
   boolean Subtract_mean 1
  comment Harmonicity parameters are set to match pitch extraction, except...
    positive Periods_per_window 4.5
  comment Number of bins = Number of frames / Bin constant...
    positive Bin_constant 30
endform 

# set program name, operating system, directory paths and names as needed
programName$ = "quantifyEmotion"
if ('save_data_to_file' = 3)
  dataFile$ = "quantifyemotion.csv"
 else
  dataFile$ = "quantifyemotion.out"
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
  printline Objects (no labels): Select one or more sounds, making sure there are no editors open
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

  # set sampling frequency and duration
  sf = Get sampling frequency
  dur = Get total duration

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  select 'soundNumber'
 
  # do pitch analysis
  To Pitch... 'time_step' 'pitch_floor' 'pitch_ceiling'
  pitchName$ = selected$ ("Pitch")
  pitchNumber = selected ("Pitch")

  if pause_to_check_contour = 1
    # pause to allow user to fix pitch contour
    select 'soundNumber'
    Edit
    select 'pitchNumber'
    Edit
    editor Pitch 'pitchName$'
    pause Check the pitch contour, edit as needed
    Close
    endeditor
    editor Sound 'soundName$'
    Close
    endeditor
  endif

  # compute intensity values
  select 'soundNumber'
  To Intensity... 'pitch_floor' 'time_step' 'subtract_mean'
  intensityName$ = selected$ ("Intensity")
  intensityNumber = selected ("Intensity")
  minInt = Get minimum... 0.0 0.0 Parabolic
  maxInt = Get maximum... 0.0 0.0  Parabolic
  meanInt = Get mean... 0.0 0.0 dB
  stdevInt = Get standard deviation... 0.0 0.0

  # compute F0, voicing values
  call derive_F0
  call derive_percent_voicing
  if ('include_Jitter_and_shimmer' = 1)
    call derive_jitter
    call derive_shimmer
  endif
  if ('include_HNR' = 1)
    call derive_HNR
  endif

  # compute pitch entropy
  call derive_pitch_entropy

  # clean up pitch-related files
  select 'pitchNumber'
    plus 'pitchTierNumber'
    plus 'tableOfReal1Number'
    plus 'matrix1Number'
  Remove

  # compute intensity entropy
  call derive_intensity_entropy

  # clean up intensity-related files
  select 'intensityNumber'
    plus 'intensityTierNumber'
    plus 'tableOfReal1Number'
    plus 'matrix1Number'
  Remove

  # clean up jitter, shimmer, HNR if computed
  if ('include_Jitter_and_shimmer' = 1) 
    select 'pointprocessNumber'
    Remove
  endif
  if ('include_HNR' = 1) 
    select 'harmonicityNumber'
    Remove
  endif

  # show data, save to file
  call show_data_and_pause_nolabels
  if ( 'save_data_to_file' > 1 )
    call data_to_file_nolabels
  endif

  # go on to a new file or quit
  select 'soundNumber'
  editor Sound 'soundName$'
  if 'move_on_after' = 1
    execute nextEditor.praat
  endif

endproc

################## run with Objects window: no labels #################
procedure objects_nolabels

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

    # get the sampling frequency and duration
    sf = Get sampling frequency
    dur = Get total duration

    # do pitch analysis
    To Pitch... 'time_step' 'pitch_floor' 'pitch_ceiling'
    pitchName$ = selected$ ("Pitch")
    pitchNumber = selected ("Pitch")

    if pause_to_check_contour = 1
      # pause to allow user to fix pitch contour
      select 'soundNumber'
      Edit
      select 'pitchNumber'
      Edit
      editor Pitch 'pitchName$'
      pause Check the pitch contour, edit as needed
      Close
      endeditor
      editor Sound 'soundName$'
      Close
      endeditor
    endif

    # compute intensity values
    select 'soundNumber'
    To Intensity... 'pitch_floor' 'time_step' 'subtract_mean'
    intensityName$ = selected$ ("Intensity")
    intensityNumber = selected ("Intensity")
    minInt = Get minimum... 0.0 0.0 Parabolic
    maxInt = Get maximum... 0.0 0.0  Parabolic
    meanInt = Get mean... 0.0 0.0 dB
    stdevInt = Get standard deviation... 0.0 0.0

    # compute F0, voicing values
    call derive_F0
    call derive_percent_voicing
    if ('include_jitter_and_shimmer' = 1)
      call derive_jitter
      call derive_shimmer
    endif
    if ('include_HNR' = 1)
      call derive_HNR
    endif

    # compute pitch entropy
    call derive_pitch_entropy

    # clean up pitch-related files
    select 'pitchNumber'
      plus 'pitchTierNumber'
      plus 'tableOfReal1Number'
      plus 'matrix1Number'
    Remove

    # compute intensity entropy
    call derive_intensity_entropy

    # clean up intensity-related files
    select 'intensityNumber'
      plus 'intensityTierNumber'
      plus 'tableOfReal1Number'
      plus 'matrix1Number'
    Remove

    # clean up jitter, shimmer, HNR if computed
    if ('include_jitter_and_shimmer' = 1) 
      select 'pointprocessNumber'
      Remove
    endif
    if ('include_HNR' = 1) 
      select 'harmonicityNumber'
      Remove
    endif

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
procedure derive_F0
  select 'pitchNumber'
  minF0 = Get minimum... 0 0 Hertz Parabolic
    if (minF0 = undefined)
      minF0 = 0
    endif
  maxF0 = Get maximum... 0 0 Hertz Parabolic
    if (maxF0 = undefined)
      maxF0 = 0
    endif
  meanF0 = Get mean... 0 0 Hertz
    if (meanF0 = undefined)
      meanF0 = 0
    endif
  stdevF0 = Get standard deviation... 0 0 Hertz
    if (stdevF0 = undefined)
      stdevF0 = 0
    endif
endproc

############################################################
procedure derive_percent_voicing
  select 'pitchNumber'
  numberFrames = Get number of frames
  voicedFrames = Count voiced frames
  frameLength = Get frame length
  percentVoicedFrames = ('voicedFrames' / 'numberFrames') * 100
  if (percentVoicedFrames = undefined)
    percentVoicedFrames = 0
  endif
  if percentVoicedFrames > 100
    percentVoicedFrames = 100.0
  endif
endproc

############################################################
procedure derive_pitch_entropy
  select 'pitchNumber'
  Down to PitchTier
  pitchTierNumber = selected ("PitchTier", 1)
  pitchTierName$ = selected$ ("PitchTier", 1)
  Down to TableOfReal... Hertz
  tableOfReal1Number = selected ("TableOfReal", 1)
  tableOfReal1fName$ = selected$ ("TableOfReal", 1)
  colLabel$ = "F0"
  call process_table

  pitchBins = 'numberBins'
  hPitch = 'hEntropy'
endproc

############################################################
procedure derive_intensity_entropy
  select 'intensityNumber'
  Down to IntensityTier
  intensityTierNumber = selected ("IntensityTier", 1)
  intensityTierName$ = selected$ ("IntensityTier", 1)
  Down to TableOfReal
  tableOfReal1Number = selected ("TableOfReal", 1)
  tableOfReal1fName$ = selected$ ("TableOfReal", 1)
  colLabel$ = "Intensity (dB)"
  call process_table
  intensityBins = 'numberBins'
  hIntensity = 'hEntropy'
endproc

############################################################
procedure process_table
  # alert user to delay
  clearinfo
  printline
  printline Working...
  printline
  # create table: pitch uses voiced frames only 
  Remove column (index)... 1
  Standardize columns
  Sort by column... 1 0
  # get number of values and bins
  numberRows = Get number of rows
  numberBins = 'numberRows' / 'bin_constant'
  numberBins = round('numberBins')
  # make matrix, find max, min, and binwidth values
  To Matrix
  matrix1Number = selected ("Matrix", 1)
  matrix1Name$ = selected$ ("Matrix", 1) 
  maxValue = Get maximum
  minValue = Get minimum
  binWidth = ('maxValue' - 'minValue') / numberBins
  # tabulate frequency values from table
  lowerValue = 'minValue'
  upperValue = 'lowerValue' + 'binWidth'
  x = 1
  repeat
    select 'matrix1Number'
    Copy... dummyMatrix
    matrix2Number = selected ("Matrix", 1)
    matrix2Name$ = selected$ ("Matrix", 1) 
    Formula... if ((self>='lowerValue') and (self<'upperValue')) then 1 else 0 endif
    freqValue = Get sum
    Remove
    # put count in matrix
    select 'matrix1Number'
    Set value... 'x' 1 'freqValue'
    x = x + 1
    # set new lower and upper values for bin
    lowerValue = 'upperValue'
    upperValue = 'upperValue' + 'binWidth'
  until ('lowerValue' > 'maxValue') or (x > 'numberBins')
  # convert frequency values to probabilities
  select 'matrix1Number'
  Formula... (self / 'numberRows')
  # calculate H as entropy measure
  hEntropy = 0
  currentValue = 0
  for z from 1 to 'numberBins'
    currentValue = Get value in cell... 'z' 1
    if ('currentValue' <> 0)
      hEntropy = 'hEntropy' + ('currentValue' * log2('currentValue'))
    endif
  endfor
  hEntropy = -'hEntropy'
endproc

############################################################
procedure derive_jitter
  select 'pitchNumber'
  To PointProcess
  pointprocessNumber = selected ("PointProcess")
  select 'pointprocessNumber'
  if jitter_type = 1
    jitter = Get jitter (local)... 0 0 0.0001 0.02 1.3
  endif
  if jitter_type = 2
    jitter = Get jitter (local,absolute)... 0 0 0.0001 0.02 1.3
  endif
  if jitter_type = 3
    jitter = Get jitter (rap)... 0 0 0.0001 0.02 1.3
  endif
  if jitter_type = 4
    jitter = Get jitter (ppq5)... 0 0 0.0001 0.02 1.3
  endif
  if jitter_type = 5
    jitter = Get jitter (ddp)... 0 0 0.0001 0.02 1.3
  endif
  if (jitter = undefined)
    jitter = 0
  endif
endproc

############################################################
procedure derive_shimmer
  select 'pointprocessNumber'
  plus 'soundNumber'
  if shimmer_type = 1
    shimmer = Get shimmer (local)... 0 0 0.0001 0.02 1.3 1.6
    endif
  if shimmer_type = 2
    shimmer = Get shimmer (local_dB)... 0 0 0.0001 0.02 1.3 1.6
    endif
  if shimmer_type = 3
    shimmer = Get shimmer (apq3)... 0 0 0.0001 0.02 1.3 1.6
    endif
  if shimmer_type = 4
    shimmer = Get shimmer (apq5)... 0 0 0.0001 0.02 1.3 1.6
    endif
  if shimmer_type = 5
    shimmer = Get shimmer (apq11)... 0 0 0.0001 0.02 1.3 1.6
    endif
  if shimmer_type = 6
    shimmer = Get shimmer (dda)... 0 0 0.0001 0.02 1.3 1.6
  endif
  if (shimmer = undefined)
    shimmer = 0
  endif
endproc

############################################################
procedure derive_HNR
  select 'soundNumber'
  harmonicity_time_step = (0.75 / 'pitch_floor')
  To Harmonicity (cc)... 'harmonicity_time_step' 'pitch_floor' 0.1 'periods_per_window'
  harmonicityName$ = selected$ ("Harmonicity")
  harmonicityNumber = selected ("Harmonicity")
  select 'harmonicityNumber'
  maxHNR = Get maximum... 0 0 Parabolic
  meanHNR = Get mean... 0 0
  stdevHNR = Get standard deviation... 0 0
  if (maxHNR = undefined)
    maxHNR = 0
  endif
  if (meanHNR = undefined)
    meanHNR = 0
  endif
  if (stdevHNR = undefined)
    stdevHNR = 0
  endif
endproc

############################################################
procedure show_data_and_pause_nolabels
  # send data to the screen
  clearinfo
  printline file'tab$''tab$''soundName$'
  printline dur'tab$''tab$''dur:3'
  printline
  printline frms'tab$''tab$''numberFrames'
  printline voi frms'tab$''voicedFrames'
  printline %voi frms'tab$''percentVoicedFrames:1'
  printline
  printline minF0   'tab$''minF0:1'
  printline maxF0   'tab$''maxF0:1'
  printline mnF0    'tab$''meanF0:1'
  printline sdF0    'tab$''stdevF0:2'
  printline
  printline mnInt    'tab$''minInt:1'
  printline mnInt    'tab$''meanInt:1'
  printline mnInt    'tab$''maxInt:1'
  printline sdInt    'tab$''stdevInt:2'
  printline
  if ('include_jitter_and_shimmer' = 1)
    printline jtr'tab$''tab$''jitter:10'
    printline shmr'tab$''tab$''shimmer:10'
  printline
  endif
  if ('include_HNR' = 1)
    printline maxHN   'tab$''maxHNR:1'
    printline mnHN    'tab$''meanHNR:2'
    printline sdHN    'tab$''stdevHNR:2' 
  printline
  endif
  printline pitch H'tab$''hPitch:3'
  printline pitch bins'tab$''pitchBins'
  printline int H'tab$''tab$''hIntensity:3'
  printline int bins'tab$''intensityBins'
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
      fileappend "'dataFilePath$'" Mo/Day/Yr Time ProgramName SoundName 
      fileappend "'dataFilePath$'" Dur NumFrms VoiFrms %VoiFrms 
      fileappend "'dataFilePath$'" MinF0 MaxF0 MeanF0 StDevF0
      fileappend "'dataFilePath$'" MinInt MaxInt MeanInt StDevInt
      if ('include_Jitter_and_shimmer' = 1)
        fileappend "'dataFilePath$'" Jitter Shimmer
      endif
      if ('include_HNR' = 1) 
        fileappend "'dataFilePath$'" MaxHNR MeanHNR StDevHNR 
      endif
      fileappend "'dataFilePath$'" HPitch PitchBins HInt IntBins
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$' 'time$' 'programName$' 'soundName$' 
    fileappend "'dataFilePath$'" 'dur:4' 'numberFrames' 'voicedFrames' 'percentVoicedFrames:1' 
    fileappend "'dataFilePath$'" 'minF0:1' 'maxF0:1' 'meanF0:1' 'stdevF0:2'
    fileappend "'dataFilePath$'" 'minInt:1' 'maxInt:1' 'meanInt:1' 'stdevInt:2'
    if ('include_jitter_and_shimmer' = 1)
      fileappend "'dataFilePath$'" 'jitter:10' 'shimmer:10'
    endif
    if ('include_HNR' = 1) 
      fileappend "'dataFilePath$'" 'maxHNR:1' 'meanHNR:2' 'stdevHNR:2' 
    endif
    fileappend "'dataFilePath$'" 'hPitch:3' 'pitchBins' 'hIntensity:3' 'intensityBins'
  endif
  if ('save_data_to_file' = 3)
    if ('include_data_header') = 1
      include_data_header = 0
      fileappend "'dataFilePath$'" Mo/Day/Yr,Time,ProgramName,SoundName
      fileappend "'dataFilePath$'" ,Dur,NumFrms,VoiFrms,%VoiFrms
      fileappend "'dataFilePath$'" ,MinF0,MaxF0,MeanF0,StDevF0
      fileappend "'dataFilePath$'" ,MinInt,MaxInt,MeanInt,StDevInt
      if ('include_jitter_and_shimmer' = 1)
        fileappend "'dataFilePath$'" ,Jitter,Shimmer
      endif
      if ('include_HNR' = 1) 
        fileappend "'dataFilePath$'" ,MaxHNR,MeanHNR,StDevHNR 
      endif
      fileappend "'dataFilePath$'" ,HPitch,PitchBins,HInt,IntBins
      fileappend "'dataFilePath$'" 'newline$'
    endif
    fileappend "'dataFilePath$'" 'month$'/'daynumber$'/'year$','time$','programName$','soundName$'
    fileappend "'dataFilePath$'" ,'dur:4','numberFrames','voicedFrames','percentVoicedFrames:1'
    fileappend "'dataFilePath$'" ,'minF0:1','maxF0:1','meanF0:1','stdevF0:2'
    fileappend "'dataFilePath$'" ,'minInt:1','maxInt:1','meanInt:1','stdevInt:2'
    if ('include_jitter_and_shimmer' = 1)
      fileappend "'dataFilePath$'" ,'jitter:10','shimmer:10'
    endif
    if ('include_HNR' = 1) 
      fileappend "'dataFilePath$'" ,'maxHNR:1','meanHNR:2','stdevHNR:2' 
    endif
    fileappend "'dataFilePath$'" ,'hPitch:3','pitchBins','hIntensity:3','intensityBins'
  endif
    fileappend "'dataFilePath$'" 'newline$'
endproc
