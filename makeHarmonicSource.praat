# makeHarmonicSource
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

# makeHarmonicSource is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# makeHarmonicSource is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# bring up a user dialog box prompting for sinewave parameters
form make harmonic source
   real Signal_length_(seconds) 1.0
   real Minimum_frequency_(Hz) 400
   real Maximum_frequency_(Hz) 500
   real Relative_peak_position 0.50
   optionmenu Harmonics_option 2
     option up to Nyquist frequency
     option fixed number
   real Number_of_harmonics 1
   real Sampling_frequency_(Hz) 22050
   word New_file_name harmonicSource
   boolean One_over_f 0
   boolean Pause_to_check_contour 0
endform

# set variables
start_frequency = 'minimum_frequency'
end_frequency = 'maximum_frequency'
sf = 'sampling_frequency'
up_length = 'signal_length' * 'relative_peak_position'
down_length = 'signal_length' * (1.0 - 'relative_peak_position')

# set number of harmonics, or warn user if too many are requested
nyquist = 'sf' / 2
if ('harmonics_option' = 1)
  number_of_harmonics = floor('nyquist' / 'maximum_frequency')
 else
 # check for possible aliasing in the highest harmonics
  if (('number_of_harmonics' * 'maximum_frequency') > 'nyquist')
    exit Warning: Aliasing will result in the highest harmonics!
  endif
endif

# set pitch extraction variables
min_search_pitch = ('minimum_frequency'*0.75)
max_search_pitch = ('maximum_frequency'*'number_of_harmonics')
pitch_time_step = 0.0
max_candidates = 15
very_accurate = 0
pitch_silence_threshold = 0.03
voicing_threshold = 0.45
octave_cost = 0.01
octave_jump_cost = 0.35
voiced_unvoiced_cost = 0.14

# set zeropadding variable
zeroPadSecs = 0.1

# determine window length, determine correction factor for time of slices
if 'very_accurate' = 0
  number_cycles = 3
 else
  number_cycles = 6
endif
windowLength = 'number_cycles' / 'min_search_pitch'
correctionFactor = 'zeroPadSecs' - ('windowLength' * 2)

# make the upsweep, if applicable
if relative_peak_position > 0.0
  modf_up = ('end_frequency' - 'start_frequency')
  modf_up = 'modf_up' / (2*'up_length')
  Create Sound... upSound 0 'up_length' 'sf' sin(2*pi*('start_frequency'*x+'modf_up'*x^2))
  upSoundNumber =  selected ("Sound")
  Scale... 0.99
endif

# make the down-sweep, if applicable
if relative_peak_position < 1.0
  modf_down = ('start_frequency' - 'end_frequency')
  modf_down = 'modf_down' / (2*'down_length') 
  Create Sound... downSound 0 'down_length' 'sf' sin(2*pi*('end_frequency'*x+'modf_down'*x^2))
  downSoundNumber = selected ("Sound")
  Scale... 0.99
endif

# concatenate the sounds, rename the new file
if (relative_peak_position > 0.0) and (relative_peak_position < 1.0)
  select 'upSoundNumber'
  plus 'downSoundNumber'
  Concatenate
  f0Number = selected ("Sound")
  Rename... 'new_file_name$'
  # clean up
  select 'upSoundNumber'
  plus 'downSoundNumber'
  Remove
  elsif relative_peak_position = 1.0
    f0Number = 'upSoundNumber'
    Rename... 'new_file_name$'
    elsif relative_peak_position = 0.0
      f0Number = 'downSoundNumber'
      Rename... 'new_file_name$'
    endif
  endif
endif

select 'f0Number'
# make the sound
if ('number_of_harmonics' > 1)

  # do pitch analysis
  To Pitch (ac)... 'pitch_time_step' 'min_search_pitch' 'max_candidates'
    ... 'very_accurate' 'pitch_silence_threshold' 'voicing_threshold' 'octave_cost'
    ... 'octave_jump_cost' 'voiced_unvoiced_cost' 'max_search_pitch'
  # get the name, number, and number of frames for pitch file
  pitchName$ = selected$ ("Pitch")
  pitchNumber = selected ("Pitch")
  numberOfFrames = Get number of frames
  if pause_to_check_contour = 1
    # pause to allow user to fix pitch contour
    Edit
    editor Pitch 'pitchName$'
    pause Check the pitch contour, edit as needed
    Close
    endeditor
  endif
  for i from 1 to 'number_of_harmonics'
    select 'pitchNumber'
    # multiply f0 to create the harmonic
    Copy... pitch_'i'
    pitch_'i' = selected ("Pitch")
    Formula... (self * 'i')
    To Sound (sine)... 'sf' at nearest zero crossings
    if ('one_over_f') = 1
      Multiply... (1 / 'i')
    endif
    harmonic'i'Number = selected ("Sound")
    harmonic'i'Name$ = selected$ ("Sound")
  endfor
  # use the first file as the one to add all subsequent files to
  select 'harmonic1Number'
  Copy... 'new_file_name$''number_of_harmonics'
  finalSynthName$ = selected$ ("Sound")
  finalSynthNumber = selected ("Sound")
  numberOfSamples = Get number of samples
  # add each additional wavefrom in turn
  for i from 2 to 'number_of_harmonics'
    select 'finalSynthNumber'
    currentHarmonicName$ = harmonic'i'Name$
    Formula... self + Sound_'currentHarmonicName$'[col]
  endfor
  # remove dc and rescale
  select 'finalSynthNumber'
  Subtract mean
  Scale... 0.99
  # clean up
  select 'f0Number'
    plus 'pitchNumber'
    for i from 1 to 'number_of_harmonics'
      plus pitch_'i'
      plus harmonic'i'Number
    endfor
  Remove
  select Sound 'new_file_name$''number_of_harmonics'
 else
  # f0 only
  Rename... 'new_file_name$''number_of_harmonics'
endif
