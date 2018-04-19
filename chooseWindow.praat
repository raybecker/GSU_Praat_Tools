# chooseWindow
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

# chooseWindow is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# chooseWindow is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# Query for window size
form choose Window
  optionmenu Processing_mode 1
    option Editor (no labels)
    option Editor (with labels)
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
  optionmenu Size_in_millisecs 3
    option 10
    option 25
    option 50
    option 75
    option 100
    option 250
    option 500
    option 750
    option 1000
  optionmenu Size_in_points 1
    option 0
    option 32
    option 64
    option 128
    option 256
    option 512
    option 1024
    option 2048
    option 4096
  real Custom_size_in_millisecs 0
  real Custom_size_in_points 0
  real Percentage_of_current_selection 100
  boolean Boundaries_at_zero_crossings 0
endform

# jump to selected processing mode
if ( 'processing_mode' = 1 )
  call editor_nolabels
 elsif ( 'processing_mode' = 2 )
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

  # transfer control to editor
  editor Sound 'soundName$'

  # get selection times to test whether a window has been set,
  # begin and end are the same when file is first opened in Editor
  cursor =  Get cursor
  beginTarget = Get start of selection
  endTarget = Get end of selection
  endeditor

  # set window size, get time data at file and selection levels
  call set_window_size
  call get_timedata_entirefile
  if 'beginTarget' <> 'endTarget'
    editor Sound 'soundName$'
    call get_timedata_selection
  endif

  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire file
    beginTarget = 'beginFile'
    endTarget = 'endFile'
   elsif 'window_placement' = 2
    # selected segment
    beginTarget = 'beginSelection'
    endTarget = 'endSelection'
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
    call set_window_around_timepoint ( 'cursor' + ('window_size' / 2) )
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

  # make new selection, get selection times
  editor Sound 'soundName$'
  Select... 'beginTarget' 'endTarget'
  call get_timedata_selection

  # adjust to a percentage, if desired
  if ('percentage_of_current_selection' <> 100)
    call percent_current_selection
    editor Sound 'soundName$'
    Select... 'beginTarget' 'endTarget'
  endif

  # adjust boundaries to zero-crossings, if desired
  if 'boundaries_at_zero_crossings' = 1
    editor Sound 'soundName$'
    Move start of selection to nearest zero crossing
    Move end of selection to nearest zero crossing
    beginTarget = Get start of selection
    endTarget = Get end of selection
  endif

  # set other target segment times
  durTarget = 'endTarget' - 'beginTarget'
  midTarget = 'beginTarget' + ('durTarget' / 2)

  # set the window
  editor Sound 'soundName$'
  Select... 'beginTarget' 'endTarget'

  # keep file selection current
  select 'soundNumber'
  editor Sound 'soundName$'

endproc

################# run with Editor window: with labels #################
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

  # transfer control to editor
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'

  # get selection times to test whether a window has been set,
  # begin and end are the same when file is first opened in Editor
  cursor =  Get cursor
  beginTarget = Get start of selection
  endTarget = Get end of selection
  endeditor
  select 'soundNumber'

  # set window size, get time data at file, interval, and selection levels
  call set_window_size
  call get_timedata_entirefile
  select 'textGridNumber'
  numberOfIntervals = Get number of intervals... 1
  call interval_number_from_time 'cursor'
  call get_timedata_interval 'intervalNumber'
  select 'soundNumber'
  if 'beginTarget' <> 'endTarget'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
    call get_timedata_selection
    endeditor
    select 'soundNumber'
  endif

  # set beginTarget and endTarget according to window placement/size
  if 'window_placement' = 1
    # use entire interval
    beginTarget = 'beginInterval'
    endTarget = 'endInterval'
   elsif 'window_placement' = 2
    # selected segment
    beginTarget = 'beginSelection'
    endTarget = 'endSelection'
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

  # make new selection, get selection times
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Select... 'beginTarget' 'endTarget'
  call get_timedata_selection

  # adjust to a percentage, if desired
  if ('percentage_of_current_selection' <> 100)
    call percent_current_selection
    select 'soundNumber'
    plus 'textGridNumber'
    editor TextGrid 'textGridName$'
    Select... 'beginTarget' 'endTarget'
  endif

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

  # set the window
  select 'soundNumber'
  plus 'textGridNumber'
  editor TextGrid 'textGridName$'
  Select... 'beginTarget' 'endTarget'

endproc

# end main program

############################################################

####################           PROCEDURES         ####################

############################################################
procedure set_window_size
  call set_window_millisecs
  if 'size_in_points' > 1
    call set_window_points
  endif
  if 'custom_size_in_millisecs' > 0
    window_size = custom_size_in_millisecs
    window_size = ('window_size' / 1000)
  endif
  if 'custom_size_in_points' > 0
    window_size = custom_size_in_points
    window_size = (1 / sf) * 'window_size'
  endif
endproc

############################################################
procedure set_window_millisecs
  if 'size_in_millisecs' = 1
    window_size = 0.010
   elsif 'size_in_millisecs' = 2
    window_size = 0.025
   elsif 'size_in_millisecs' = 3
    window_size = 0.050
   elsif 'size_in_millisecs' = 4
    window_size = 0.075
   elsif 'size_in_millisecs' = 5
    window_size = 0.100
   elsif 'size_in_millisecs' = 6
    window_size = 0.250
   elsif 'size_in_millisecs' = 7
    window_size = 0.500
   elsif 'size_in_millisecs' = 8
    window_size = 0.750
   elsif 'size_in_millisecs' = 9
    window_size = 1.000
  endif
endproc

############################################################
procedure set_window_points
  if 'size_in_points' = 2
    window_size = 32
   elsif 'size_in_points' = 3
    window_size = 64
   elsif 'size_in_points' = 4
    window_size = 128
   elsif 'size_in_points' = 5
    window_size = 256
   elsif 'size_in_points' = 6
    window_size = 512
   elsif 'size_in_points' = 7
    window_size = 1024
   elsif 'size_in_points' = 8
    window_size = 2048
   elsif 'size_in_points' = 9
    window_size = 4096
  endif
  window_size = (1 / sf) * 'window_size'
endproc

############################################################
procedure get_timedata_entirefile
  beginFile = 0.0
  endFile = Get total duration
  durFile = 'endFile'
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
procedure forward_from_cursor
  beginTarget = 'cursor'
  endTarget = ('beginTarget' + 'window_size')
endproc

############################################################
procedure backward_from_cursor
  endTarget = 'cursor'
  beginTarget = ('endTarget' - 'window_size')
endproc

############################################################
procedure forward_from_beginning
  beginTarget = 'beginFile'
  endTarget = 'window_size'
endproc

############################################################
procedure backward_from_end
  endTarget = 'endFile'
  beginTarget = 'endTarget' - 'window_size'
endproc

############################################################
procedure percent_current_selection
  window_size = ('durSelection' * ('percentage_of_current_selection' / 100))
  beginTarget = ('midSelection' - ('window_size' / 2))
  endTarget = ('midSelection' + ('window_size' / 2))
endproc

############################################################
procedure check_sound_and_textgrid
  soundAndTextGrid = 0
  numberOfSelectedObjects = numberOfSelected ()
  if 'numberOfSelectedObjects' = 2
    soundAndTextGrid = 1
  endif
endproc
