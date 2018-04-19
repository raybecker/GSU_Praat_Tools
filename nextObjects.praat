# nextObjects
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

# nextObjects is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# nextObjects is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# main program
#######################################################################

# check whether both sound(s) and textgrid(s) are selected together
call check_sound_and_textgrid

# jump to processing mode
if ('soundAndTextGrid' = 1)
  call objects_sound
 elsif ('soundAndTextGrid' = 2)
  call objects_labels
 else ('soundAndTextGrid' = 3)
  call objects_soundlabels
endif

################ run with Objects window: sound only ################
procedure objects_sound
  # get the id number of the sound the user is starting from
  soundNumber = selected ("Sound", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the next file or quit
  call next_file_sounds
endproc

################# run with Objects window: labels only ###############
procedure objects_labels
  # get the name and id number of the textgrid the user is starting from
  textGridNumber = selected ("TextGrid", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the next file or quit
  call next_file_labels
endproc

############## run with Objects window: sound and labels #############
procedure objects_soundlabels
  # get the name and id number of the sound and textgrid the user is starting from
  soundNumber = selected ("Sound", 1)
  textGridNumber = selected ("TextGrid", 1)
  # get the number of the last file in the Objects window, as well as finding the
  # position of the file the user is starting from for the latter, count up from the bottom
  call get_starting_last_files
  # select the next file or quit
  call next_file_soundslabels
endproc

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedSounds = numberOfSelected ("Sound")
  numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
  if (('numberOfSelectedSounds' > 0) and ('numberOfSelectedTextGrids' = 0))
    soundAndTextGrid = 1
   elsif (('numberOfSelectedSounds' = 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 2
  elsif (('numberOfSelectedSounds' = 0) and ('numberOfSelectedTextGrids' > 0))
    soundAndTextGrid = 3
  endif
endproc

############################################################
procedure get_starting_last_files
  if ('numberOfSelectedSounds' > 0)
    select all
    numberOfSelectedSounds = numberOfSelected ("Sound")
    i = 'numberOfSelectedSounds'
    firstSoundNumber = selected ("Sound", 1)
    lastSoundNumber = selected ("Sound", 'i')
    querySoundNumber = 0
    querySoundNumber = selected ("Sound", 'i')
    while ('querySoundNumber' <> 'soundNumber')
      i = (i - 1)
      querySoundNumber = selected ("Sound", 'i')
    endwhile
    soundPosition = 'i'
  endif
  select all
  if ('numberOfSelectedTextGrids' > 0)
    select all
    numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
    i = numberOfSelected ("TextGrid")
    firstTextGridNumber = selected ("TextGrid", 1)
    lastTextGridNumber = selected ("TextGrid", 'i')
    queryTextGridNumber = 0
    queryTextGridNumber = selected ("TextGrid", 'i')
    while ('queryTextGridNumber' <> 'textGridNumber')
      i = (i - 1)
      queryTextGridNumber = selected ("TextGrid", 'i')
    endwhile
    textGridPosition = 'i'
  endif
endproc

############################################################
procedure next_file_sounds
  if ('soundNumber' <> 'lastSoundNumber')
    soundPosition = ('soundPosition' + 1)
   else
    soundPosition = 1
  endif
  soundNumber = selected ("Sound", 'soundPosition')
  select 'soundNumber'
endproc

############################################################
procedure next_file_labels
  if ('textGridNumber' <> 'lastTextGridNumber')
    textGridPosition = ('textGridPosition' + 1)
   else
    textGridPosition = 1
  endif
  textGridNumber = selected ("TextGrid", 'textGridPosition')
  select 'textGridNumber' 
endproc

############################################################
procedure next_file_soundslabels
  if ('soundNumber' <> 'lastSoundNumber')
    soundPosition = ('soundPosition' + 1)
    textGridPosition = ('textGridPosition' + 1)
   else
    soundPosition = 1
    textGridPosition = 1
  endif
    soundNumber = selected ("Sound", 'soundPosition')
    textGridNumber = selected ("TextGrid", 'textGridPosition')
    select 'soundNumber'
    plus 'textGridNumber' 
endproc
