# changeSF
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

# changeSF is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# changeSF is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for processing to do
form change Sampling Frequency
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Objects (no labels)
  boolean Move_on_after 0
  optionmenu Change_sampling_frequency 1
    option check, but do not change
    option Resample
    option Override
  real New_sampling_frequency 11025
  real Precision_in_samples 50
endform

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
  oldsp = Get sampling period
  durFile = Get total duration

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

  # change sampling frequency
  if ('change_sampling_frequency' = 1)
    numberOfSelectedSounds = 1
    call check_sampling_frequency
   elsif ('change_sampling_frequency' = 2)
    # resample, creating a new file
    Resample... 'new_sampling_frequency' 'precision_in_samples'
    newSoundNumber = selected ("Sound")
    newSoundName$ = selected$ ("Sound")
    newsp = Get sampling period
    # reselect original file, cut all but 100 points, override sampling frequency
    select 'soundNumber'
    Edit
    editor Sound 'soundName$'
    Select... (100*'oldsp') 10000.0
    Cut
    Close
    endeditor
    Override sampling frequency... 'new_sampling_frequency'  
 
    # select new file, copy to clipboard
    select 'newSoundNumber'
    Edit
    editor Sound 'newSoundName$'
    Select... 0.0 10000.0
    Copy selection to Sound clipboard
    Close
    endeditor

    # reselect original file, paste in new file, cut out the leading 100 points
    select 'soundNumber'
    Edit
    editor Sound 'soundName$'
    Select... 0.0 (100*'newsp')
    Paste after selection
    Select... 0.0 (100*'newsp')
    Cut
    Close
    endeditor

    # clean up, reselect original file
    select 'newSoundNumber'
    Remove
    select 'soundNumber'

   else
   # override existing sampling frequency
   Override sampling frequency... 'new_sampling_frequency'
  endif

  # go on to a new file or quit
  select 'soundNumber'
  Edit
  editor Sound 'soundName$'
  Show all
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
    durFile = Get total duration
    oldsp = Get sampling period

    # find and select the sound being processed
    select 'soundNumber'

    # change sampling frequency
    if ('change_sampling_frequency' = 1)
      call check_sampling_frequency
     elsif ('change_sampling_frequency' = 2)
      # resample, creating a new file
      Resample... 'new_sampling_frequency' 'precision_in_samples'
      newSoundNumber = selected ("Sound")
      newSoundName$ = selected$ ("Sound")
      newsp = Get sampling period
      # reselect original file, cut all but 100 points, override sampling frequency
      select 'soundNumber'
      Edit
      editor Sound 'soundName$'
      Select... (100*'oldsp') 10000.0
      Cut
      Close
      endeditor
      Override sampling frequency... 'new_sampling_frequency'  
      # select new file, copy to clipboard
      select 'newSoundNumber'
      Edit
      editor Sound 'newSoundName$'
      Select... 0.0 10000.0
      Copy selection to Sound clipboard
      Close
      endeditor
      # reselect original file, paste in new file, cut out the leading 100 points
      select 'soundNumber'
      Edit
      editor Sound 'soundName$'
      Select... 0.0 (100*'newsp')
      Paste after selection
      Select... 0.0 (100*'newsp')
      Cut
      Close
       endeditor
      # clean up, reselect original file
      select 'newSoundNumber'
      Remove
      select 'soundNumber'
     else
      # override existing sampling frequency
      Override sampling frequency... 'new_sampling_frequency'
    endif
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
procedure check_sampling_frequency
  clearinfo
  for i from 1 to 'numberOfSelectedSounds'
    select sound'i'Number
    soundNumber = sound'i'Number
    soundName$ = sound'i'Name$
    sf = Get sampling frequency
    printline 'soundNumber'. Sound 'soundName$' 'sf'
  endfor
  printline
  # reselect sound files
  select 'sound1Number'
  for i from 2 to 'numberOfSelectedSounds'
   plus sound'i'Number
  endfor
endproc
