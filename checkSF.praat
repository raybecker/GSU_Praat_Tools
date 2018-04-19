# checkSF
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

# checkSF is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# checkSF is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# count number of selected sounds in the Objects window
numberOfSelectedSounds = numberOfSelected ("Sound")

# if no sound files selected, exit with an error message
if ('numberOfSelectedSounds' = 0)
  clearinfo
  printline
  printline Error: No sound files selected!
  printline
  exit
endif

# loop through all the selected sound files, getting names and id numbers
for i from 1 to 'numberOfSelectedSounds'
  sound'i'Name$ = selected$ ("Sound", 'i')
  sound'i'Number = selected ("Sound", 'i')
endfor

# show results in information window
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
