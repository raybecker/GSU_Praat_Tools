# addWaves
#######################################################################
# adds waveforms selected in the Objects window
# two waveforms can be added to create a stereo file, or an 
# unlimited number of waveforms can be added as a mono file

# Michael J. Owren, Ph.D.
# Psychology of Voice and Sound Laboratory
# Department of Psychology
# Georgia State University
# Atlanta, GA 30303, USA

# email: owren@gsu.edu
# home page: http://sites.google.com/site/michaeljowren/
# lab page: http://sites.google.com/site/psyvoso/home

# Copyright 2007-2011 Michael J. Owren

# addWaves is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# addWaves is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

form add selected waveforms
  comment Select two sounds to become left and right channels of a stereo sound,
  comment or select an unlimited number of sounds for waveform addition.
  comment (Remember to select the sounds in the Objects window!).
  optionmenu Processing_mode 1
    option set processing mode first
    option create stereo sound
    option do waveform addition
  word Summed_waves_name SummedWaves
  boolean Rescale_after_adding 0
endform

# count number of selected sounds in the Objects window
numberOfSelectedSounds = numberOfSelected ("Sound")

# alert user if there is a problem
if processing_mode = 1
    clearinfo
    printline
    printline No processing mode has been selected!
    printline 
    exit
endif
if ((processing_mode = 2) and (numberOfSelectedSounds <> 2))
    clearinfo
    printline
    printline Select two and only two sounds in the Objects window!
    printline 
    exit
endif
if ((processing_mode = 3) and (numberOfSelectedSounds < 2))
    clearinfo
    printline
    printline Select two or more sounds in the Objects window!
    printline 
    exit
endif

# loop through all the selected sound files, getting names and id numbers
for i from 1 to 'numberOfSelectedSounds'
  sound'i'Name$ = selected$ ("Sound", 'i')
  sound'i'Number = selected ("Sound", 'i')
endfor

# create stereo sound
if processing_mode = 2
  # use the first file as the one to add all subsequent files to
  Combine to stereo
  Rename... 'summed_waves_name$'
  summedWavesNumber = selected ("Sound")
endif

# perform waveform addition
if processing_mode = 3
  # use the first file as the one to add all subsequent files to
  select 'sound1Number'
  Copy... 'summed_waves_name$'
  summedWavesNumber = selected ("Sound")
  # add each additional wavefrom in turn
  for i from 2 to 'numberOfSelectedSounds'
    addtoSumName$ = sound'i'Name$
    select 'summedWavesNumber'
    Formula... self + Sound_'addtoSumName$'[col]
  endfor
endif

if rescale_after_adding = 1
  # scale the final product
  Scale... 0.99
endif
