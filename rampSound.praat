# rampSound
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

# rampSound is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# rampSound is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query user for ramping parameters
form ramp Sound
  optionmenu Processing_mode 1
    option set processing mode first
    option Editor (no labels)
    option Objects (no labels)
  boolean Move_on_after 0
  optionmenu Ramp_type 1
    option set ramp type first
    option linear
    option exponential
  real Ramp_length_(ms) 10
  comment Select location for linear ramping.
  optionmenu Ramp_location 3
    option beginning
    option end
    option both
  boolean At_zero_crossings 0
  comment In Editor mode, select Window placement
  comment In Objects mode, entire file is used.
  optionmenu Window_placement 1
    option entire file
    option selected segment
    option around cursor
endform

# set ramp-length variable
rampLength = ('ramp_length' / 1000)

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
 
  # get sampling frequency
  sf = Get sampling frequency

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

  # get number of samples for ramp, target segment, and file
  rampSamples = 'rampLength' * 'sf'
  beginTargetSamples = 'beginTarget' * 'sf'
  endTargetSamples = 'endTarget' * 'sf'
  totalSamples = Get number of samples
  # ramp from beginning, if selected
  if (ramp_location <> 2)
    # set begin and end of ramping section
    beginRampSamples = 'beginTargetSamples'
    endRampSamples = 'beginRampSamples' + 'rampSamples'
    if ('window_placement' = 1)
      # window is entire file, use beginning of file
      if ('ramp_type' = 2)
        # linear ramp
        Formula... if (col>'endRampSamples') then self else (self*(col/'rampSamples')) endif
       else
        # exponential ramp
        Formula... if (col>'endRampSamples')
        ...then self 
        ...else (self*100^(-('endRampSamples'-col)/('rampSamples'))) endif        
      endif
     elsif ('window_placement' = 2)
      # window is selected segment, use beginning of segment
      if ('ramp_type' = 2)
        # linear ramp
        Formula... if ((col>='beginRampSamples') and (col<='endRampSamples'))
        ...then self*((col-'beginRampSamples'+1)/'rampSamples')
        ...else self endif
       else
        # exponential ramp
        Formula... if ((col>='beginRampSamples') and (col<='endRampSamples'))
        ...then (self*100^(-('endRampSamples'-col)/('rampSamples')))
        ...else self endif
      endif
    else
      # window is around cursor, use cursor location as beginning
      if ('ramp_type' = 2)
        # linear ramp
        Formula... if ((col>='beginRampSamples') and (col<='endRampSamples'))
        ...then self*((col-'beginRampSamples'+1)/'rampSamples')
        ...else self endif
       else
        # exponential ramp
        Formula... if ((col>='beginRampSamples') and (col<='endRampSamples'))
        ...then (self*100^(-('endRampSamples'-col)/('rampSamples')))
        ...else self endif
      endif
    endif
    # end start-ramp section
  endif
  # ramp to end, if selected
  if (ramp_location >= 2)
    # set begin and end of ramping section
    endRampSamples = 'endTargetSamples'
    beginRampSamples = 'endRampSamples'-'rampSamples'
    if ('window_placement' = 1)
      # window is entire file, use end of file
      if ('ramp_type' = 2)
        # apply a linear ramp 
        Formula... if (col>=('totalSamples'-'rampSamples')) then (self*(('totalSamples'-col+1)/'rampSamples')) else self endif
       else
        # apply an exponential ramp
        Formula... if (col<('totalSamples'-'rampSamples'))
         ...then self 
         ...else (self*100^(-(col-'beginRampSamples')/('rampSamples'))) endif        
      endif
     elsif ('window_placement' = 2)
      # window is selected segment, use end of segment
      if ('ramp_type' = 2)
        # apply a linear ramp 
        Formula... if (col>='beginRampSamples' and col<='endRampSamples')
         ...then self*(('endRampSamples'-col+1)/'rampSamples')
         ...else self endif
       else
        # apply an exponential ramp
        Formula... if ((col>='beginRampSamples') and (col<=('beginRampSamples'+'rampSamples')))
        ...then (self*100^(-(col-beginRampSamples)/(endRampSamples-beginRampSamples)))       
        ...else self endif
       endif
     else
      # window is around cursor, use cursor location as end
      if ('ramp_type' = 2)
        # apply a linear ramp 
        Formula... if (col>='beginRampSamples') and (col<='endRampSamples')
         ...then self*((col-'endRampSamples'+1)/'rampSamples')
         ...else self endif
       else
        # apply an exponential ramp
        Formula... if ((col>='beginRampSamples') and (col<=('beginRampSamples'+'rampSamples')))
        ...then (self*100^(-(col-'beginRampSamples')/'rampSamples'))       
        ...else self endif
      endif
    endif 
  # end end-ramp section
  endif
  # return control to Editor window
  editor Sound 'soundName$'

  # return to midpoint of file, selection, or cursor location
  if ('window_placement' = 1)
    Select... ('endTarget'-'beginTarget')/2 ('endTarget'-'beginTarget')/2
   else 
    Select... 'beginTarget' 'endTarget'
  endif
  Show all

  # go on to a new file or quit
  select 'soundNumber'
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

    # get sampling frequency and duration
    sf = Get sampling frequency

    # get number of samples in file and ramp
    totalSamples = Get number of samples
    rampSamples = 'rampLength' * 'sf'

    # ramp from beginning, if selected
    if (ramp_location <> 2)
      if ('ramp_type' = 2)
        # apply a linear ramp
        Formula... if (col>'rampSamples') then self else (self*(col/'rampSamples')) endif
       else
        # exponential ramp
        Formula... if (col>'rampSamples')
        ...then self 
        ...else (self*100^(-('rampSamples'-col)/('rampSamples'))) endif        
      endif
      # end of start-ramp section
    endif
    # ramp to end, if selected
    if (ramp_location >= 2)
      if ('ramp_type' = 2)
        # apply a linear ramp
        Formula... if (col>('totalSamples'-'rampSamples'))
        ...then (self*(('totalSamples'-col+1)/'rampSamples'))
        ...else self endif
       else
        # exponential ramp
        Formula... if (col<('totalSamples'-'rampSamples'))
        ...then self 
        ...else (self*100^(-(col-('totalSamples'-'rampSamples'))/('rampSamples'))) endif
      endif
    endif
    # end of end-ramp section
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
procedure prompt_for_target
  if beginTarget = endTarget 
    pause Drag cursor to mark target segment
    # send control back to SoundEditor
    editor Sound 'soundName$'
    # compute begin and end times, set window
    beginTarget = Get begin of selection
    endTarget = Get end of selection
    Select... 'beginTarget' 'endTarget'
  endif
endproc

############################################################
procedure still_not_set
  if beginTarget = endTarget
    # set window length based on millisec values
    window_size = ('window_in_millisecs' / 1000)
    # if a preset points value has been entered, change to that
    if 'window_in_points' > 1
      call set_window_points
    endif
    # set window around cursor location
    call set_window_around_cursor
  endif
endproc
