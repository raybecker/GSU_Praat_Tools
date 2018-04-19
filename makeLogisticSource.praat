# makeLogisticSource
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

# makeLogisticSource is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# makeLogisticSource is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.
# Makes a waveform based on the logistic equation: rx(1-x)

# bring up a user dialog box prompting for logistic equation parameters
form make Logistic Source
comment Makes a waveform based on the logistic equation: rx(1-x).
   word New_file_name logisticSource 
   real Sampling_frequency_(Hz) 22050
  	real Initial_xvalue 0.50
   real Initial_rvalue 3.57
   optionmenu Set_file_duration_by 1
     option duration
     option increment_value
   comment *               If by duration...
   real File_duration_(seconds) 0.1
   comment *               If by increment value...
   real Increment_rvalue 0.01
   real Final_rvalue 3.99
   real Segment_length_(seconds) 0.1
endform


####################################################
# create a file of the appropriate duration by writing the data
# on a point-by-point basis to a text file, with header information
# that makes it a Praat short text file; this file can then be
# read back into the Praat program and saved as a binary file

if 'set_file_duration_by' = 1

  # calculate the number of points to create 
  numberOfPoints = ('file_duration' * 'sampling_frequency')

  # create a corresponding matrix object
  Create simple Matrix... logisticSource 1 'numberOfPoints' 0 
  matrix1Number = selected ("Matrix")

  # calculate the data point-by-point, store in the matrix
  i = 1
  xvalue = 'initial_xvalue'
  Set value... 1 'i' 'xvalue'
  repeat
    Formula... if col=1 then self else (('initial_rvalue'*self[col-1]) * (1-self[col-1])) endif
     i = 'i' + 1 
  until 'i' > 'numberOfPoints'

  # convert Matrix values to Sound file, set sample rate to original
  To Sound (slice)... 1
  sound2Number = selected ("Sound")
  Override sample rate... 'sampling_frequency'
  Subtract mean
  Scale... 0.99996948
  Rename... 'new_file_name$'

 # clean up
  select 'matrix1Number'
  Remove

endif

####################################################
# add to file by incrementing the r value

if 'set_file_duration_by' = 2
  Create Sound... Cumulative 0.0 'segment_length' 'sampling_frequency' (0*x)
  totalsamples = Get number of samples
  current_xvalue = 'initial_xvalue'
  Set value at index... 'totalsamples' 'current_xvalue'
  repeat
    Create Sound... Chaos 0.0 'segment_length' 'sampling_frequency' (0*x)
    Set value at index... 1 'current_xvalue'
    Formula... if col=1 then self else (('initial_rvalue'*self[col-1]) * (1-self[col-1])) endif
    totalsamples = Get number of samples
    current_xvalue = Get value at index... 'totalsamples'
    Scale... 0.99996948
    initial_rvalue=('initial_rvalue'+'increment_rvalue')
    select Sound Cumulative
    plus Sound Chaos
    Concatenate
    select Sound Cumulative
    Remove
    select Sound Chaos
    Remove
    select Sound chain
    Rename... Cumulative
  until 'initial_rvalue'>='final_rvalue'

  Subtract mean
  Scale... 0.99996948
  Rename... 'new_file_name$'
endif

####################################################
