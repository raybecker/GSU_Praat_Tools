# zeropadSound
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

# zeropadSound is part of GSU Praat Tools 1.8. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# zeropadSound is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for zeropadding parameters
form zeropad Sound
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Objects (no labels)
  boolean Move_on_after 0
  comment Set a fixed zeropad duration.
  real Zeropad_duration_(ms) 100
  optionmenu Zeropad_location 1
    option both ends
    option beginning
    option end
  boolean At_zero_crossings 0
  comment In Editor mode, select Window placement
  comment In Objects mode, entire file is used.
  optionmenu Window_placement 1
    option entire file
    option selected segment
    option around cursor

endform

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
  soundName$ = selected$ ("Sound", 1)
  soundNumber = selected ("Sound", 1)

  # get the number of the last file in the Objects window, as well as
  # finding the position of the file the user is starting from
  # for the latter, count up from the bottom
  select all
  call get_starting_last_files
  select 'soundNumber'
 
  # get sampling frequnecy and duration
  sf = Get sampling frequency
  durFile = Get total duration

  # window is entire file, use begin and end of file
  if ('window_placement' = 1)
    beginTarget = Get start time
    endTarget = Get end time
   elsif ('window_placement' = 2)
    # send control back to SoundEditor
    editor Sound 'soundName$'
    # window is selected segment, use begin and end of segment
    beginTarget = Get start of selection
    endTarget = Get end of selection
  else
    # send control back to SoundEditor
    editor Sound 'soundName$'
    # window is around cursor, use cursor location as begin and end
    beginTarget = Get cursor
    endTarget = Get cursor
  endif

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

  # return control to Objects window
  endeditor
  # convert silence length to seconds
  zeropad_seconds = ('zeropad_duration'/ 1000)

  # create a file that is the right length of zeros, copy to clipboard
  Create Sound... TempZeroPad 0 'zeropad_seconds' sf 0 * sin(2*pi*0*x)
  silenceSound = selected ("Sound")
  silenceSound$ = selected$ ("Sound")
  select 'silenceSound'
  Edit
  editor Sound 'silenceSound$'
  Select... 0.0 'zeropad_seconds'
  Copy selection to Sound clipboard

  # close editor window, clean up
  Close
  endeditor
  select 'silenceSound'
  Remove

  # reselect original sound, send control to editor
  select 'soundNumber'
  editor Sound 'soundName$'

  # zeropad from beginning, if selected
  if ('zeropad_location' <= 2)
   # window is entire file, use begin and end of file
    if ('window_placement' = 1)    
      Move cursor to... 0.0
     elsif ('window_placement' = 2)
      Move cursor to... 'beginTarget'
     else
      # Move cursor to... 'beginTarget'
    endif
    Paste after selection
    # end start-ramp section
  endif

  # zeropad from end, if selected
  if ('zeropad_location' <> 2)
   # window is entire file, use begin and end of file
    if ('window_placement' = 1)
      Move cursor to... 10000
     elsif ('window_placement' = 2)
      if ('zeropad_location' = 1) 
        Move cursor to... 'endTarget' + 'zeropad_seconds'
       else 
        Move cursor to... 'endTarget'
      endif
     else
      # Move cursor to... 'beginTarget'
    endif
    Paste after selection
  # end end-ramp section
  endif

  # restore cursor location
  if ('zeropad_location' = 1)
    durFile = 'durFile' + (2 *  'zeropad_seconds')
   else
    durFile = 'durFile' + 'zeropad_seconds'
  endif
  Show all
  Move cursor to... ('durFile' / 2)

  # go on to a new file or quit
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

  # loop through, selecting each file in turn and editing
  for i from 1 to 'numberOfSelectedSounds'

    # get number and name of current sound file
    soundNumber = sound'i'Number
    soundName$ = sound'i'Name$
    select 'soundNumber'

    # get sampling frequency and duration
    sf = Get sampling frequency
    fileDuration = Get total duration

    # convert silence length to seconds
    zeropad_seconds = ('zeropad_duration' / 1000)

    # create a file that is the right length of zeros, copy to clipboard
    Create Sound... TempZeroPad 0 'zeropad_seconds' sf 0 * sin(2*pi*0*x)
    silenceSound = selected ("Sound")
    silenceSound$ = selected$ ("Sound")
    select 'silenceSound'
    Edit
    editor Sound 'silenceSound$'
    Select... 0.0 'zeropad_seconds'
    Copy selection to Sound clipboard

    # close editor window, clean up
    Close
    endeditor
    select 'silenceSound'
    Remove

    # reselect original sound, open in editor
    select 'soundNumber'
    Edit
    editor Sound 'soundName$'

    # zeropad from beginning, if selected
    if ('zeropad_location' <= 2)
      # window is entire file, use begin and end of file
      Move cursor to... 0.0
      Paste after selection
      # end start-ramp section
    endif

    # zeropad from end, if selected
    if ('zeropad_location' <> 2)
      # window is entire file, use begin and end of file
      Move cursor to... 10000
      Paste after selection
      # end end-ramp section
    endif

    # close editor
    Close
    endeditor

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
