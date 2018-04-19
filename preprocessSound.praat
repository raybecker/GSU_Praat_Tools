# preprocessSound
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

# preprocessSound is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# preprocessSound is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for processing to do
form preprocess Sound
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Objects (no labels)
  boolean Move_on_after 0
  comment Preprocessing tasks:
  comment - remove DC contamination by subtracting mean of waveform
  comment - remove AC contamination by bandstop or highpass filtering
  comment (60 Hz: bandstop 50-70; 50 Hz: bandstop 40-60; highpass: 75-Hz cutoff)
  comment - change sampling frequency by resampling or overriding
  comment - normalize by rescaling to full ampitude range.
  boolean Remove_DC 0
  optionmenu Remove_AC 1
    option none
    option 60 Hz
    option 50 Hz
    option Highpass
  optionmenu Change_sampling_frequency 1
    option do not change
    option Resample
    option Override
  real New_sampling_frequency 11025
  real Precision_in_samples 50
  boolean Normalize_amplitude 0
endform

# if no modification has been selected, prompt user
if (('remove_DC' = 0)
  ...and ('remove_AC' = 1)
  ...and ('change_sampling_frequency' = 1)
  ...and ('normalize_amplitude' = 0))
  clearinfo
  printline 
  printline Select a modification to make!
  printline
  exit
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
  call objects_nolabels
endif

################## run with Editor window: no labels ##################
procedure editor_nolabels

  # make sure control lies with Objects window
  endeditor

  # get the name and id number of the sound the user is starting from
  soundName$ = selected$ ("Sound")
  soundNumber = selected ("Sound")

  # set sampling frequency, period, and duration information
  sf = Get sampling frequency
  sp = Get sampling period
  call get_timedata_entirefile

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  select 'soundNumber'
 
  # transfer control to editor, close
  editor Sound 'soundName$'
  Close
  endeditor

  # remove DC contamination
  if ('remove_DC' = 1)
    Subtract mean
  endif

  # remove AC contamination, creating a new file
  if ('remove_AC' > 1)
    if ('remove_AC' = 2)
        # filter out 60-Hz energy
        Filter (formula)... if ((x >= 50) and (x <= 70)) then 0 else self endif
     elsif ('remove_AC' = 3)
      # filter out 50-Hz energy
      Filter (formula)... if ((x >= 40) and (x <= 60)) then 0 else self endif
     else
      # highpass filter at 75 Hz
      Filter (formula)... if ((x >= 0) and (x <= 75)) then 0 else self endif
    endif
    # copy and paste new version into original sound file
    newSoundName$ = selected$ ("Sound")
    newSoundNumber = selected ("Sound")
    oldFileDuration = 'durFile'
    call copy_and_paste
    # clean up, reselect original file
    select 'newSoundNumber'
    Remove
    select 'soundNumber'
  endif

  # change sampling frequency
  if ('change_sampling_frequency' > 1)
    if ('change_sampling_frequency' = 2)
      # resample, creating a new file
      Resample... 'new_sampling_frequency' 'precision_in_samples'
      newSoundNumber = selected ("Sound")
      newSoundName$ = selected$ ("Sound")
      newfileDuration = Get duration
      sp = Get sampling period
      # reselect original file, override sampling frequency
      select 'soundNumber'
      oldFileDuration = durFile
      Override sampling frequency... 'new_sampling_frequency'
       # copy and paste new version into original sound file
      select 'newSoundNumber'
      call copy_and_paste
      # clean up, reselect original file
      select 'newSoundNumber'
      Remove
      select 'soundNumber'
     else
      # override existing sampling frequency
      Override sampling frequency... 'new_sampling_frequency'
    endif
  endif

  # normalize amplitude
  if 'normalize_amplitude' = 1
    select 'soundNumber'
    Scale... 0.99
  endif

  # go on to a new file or quit
  select 'soundNumber'
  Edit
  editor Sound 'soundName$'
  Move cursor to... 'midFile'
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

  # loop through, selecting each file in turn
  for i from 1 to 'numberOfSelectedSounds'

    # get number and name of current sound file
    soundNumber = sound'i'Number
    soundName$ = sound'i'Name$
    select 'soundNumber'

    # get sampling frequency, period, and duration information
    sf = Get sampling frequency
    sp = Get sampling period
    call get_timedata_entirefile

    # find and select the sound being processed
    select 'soundNumber'

    # remove DC contamination
    if ('remove_DC' = 1)
      Subtract mean
    endif

    # remove AC contamination, creating a new file
    if ('remove_AC' > 1)
      if ('remove_AC' = 2)
          # filter out 60-Hz energy
          Filter (formula)... if ((x >= 50) and (x <= 70)) then 0 else self endif
       elsif ('remove_AC' = 3)
        # filter out 50-Hz energy
        Filter (formula)... if ((x >= 40) and (x <= 60)) then 0 else self endif
       else
        # highpass filter at 75 Hz
        Filter (formula)... if ((x >= 0) and (x <= 75)) then 0 else self endif
      endif
      # copy and paste new version into original sound file
      newSoundName$ = selected$ ("Sound")
      newSoundNumber = selected ("Sound")
      oldFileDuration = 'durFile'
      call copy_and_paste
      # clean up, reselect original file
      select 'newSoundNumber'
      Remove
      select 'soundNumber'
    endif

    # change sampling frequency
    if ('change_sampling_frequency' > 1)
      if ('change_sampling_frequency' = 2)
        # resample, creating a new file
        Resample... 'new_sampling_frequency' 'precision_in_samples'
        newSoundNumber = selected ("Sound")
        newSoundName$ = selected$ ("Sound")
        newfileDuration = Get duration
        sp = Get sampling period
        # reselect original file, override sampling frequency
        select 'soundNumber'
        oldFileDuration = durFile
        Override sampling frequency... 'new_sampling_frequency'
        # copy and paste new version into original sound file
        select 'newSoundNumber'
        call copy_and_paste
        # clean up, reselect original file
        select 'newSoundNumber'
        Remove
        select 'soundNumber'
       else
        # override existing sampling frequency
        Override sampling frequency... 'new_sampling_frequency'
      endif
    endif

    # normalize amplitude
    if 'normalize_amplitude' = 1
      select 'soundNumber'
      Scale... 0.99
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
procedure get_timedata_entirefile
  beginFile = Get start time
  endFile = Get end time
  durFile = Get total duration
  midFile = 'beginFile' + ('durFile' / 2)
endproc

############################################################
procedure copy_and_paste
  Edit
  editor Sound 'newSoundName$'
  Select... 'sp' 10000.0
  Copy selection to Sound clipboard
  Close
  # reselect original file, paste in at end, cut first half
  select 'soundNumber'
  Edit
  editor Sound 'soundName$'
  Select... 0.0 'sp'
  Paste after selection
  Select... 0.0 'sp'
  Cut
  Select... 'oldFileDuration' 10000.0
  Cut
  Close
  endeditor
endproc