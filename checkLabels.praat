# checkLabels
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

# checkLabels is part of GSU Praat Tools 1.9. GSU Praat Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# checkLabels is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

# query for...
form checks labels in TextGrid files
  optionmenu Processing_mode 1
    option Objects (with labels)
  boolean Interval_numbering_present 1
  comment enter Enter background label, if applicable, and different from "0"...
  word Background_label defaults_to_0
  boolean Pause_after_each_TextGrid 0
  comment To check TextGrid labels, first create a text file in the current data
  comment directory, listing all possible labels. A "possible label" is any combination
  comment that can appear as a unit in a labeled interval, set off by spaces.
  comment Please note that label checking is case-sensitive.
  word Label_list_file labelList.praat
  comment The output file is "checkLabels.out," created in the current data directory.
  boolean Move_on_after 0
endform
# initialize variables
labelFile$ = label_list_file$
dataFile$ = "checklabels.out"
if (background_label$ = "defaults_to_0")
  background_label$ = "0"
endif
# set data paths
call set_data_paths
# clear info window and send header to data file
clearinfo
fileappend "'dataFile$'" 'newline$'
fileappend "'dataFile$'" ERROR-CHECKING LABELS IN TEXTGRID FILES 'newline$'
fileappend "'dataFile$'" 'newline$'
# count number of selected TextGrid files in the Objects window
numberOfSelectedTextGrids = numberOfSelected ("TextGrid")
if 'numberOfSelectedTextGrids' = 0
  echo No TextGrid files selected! Please begin again...
  exit
endif
# count number of selected Sounds (if any) in the Objects window
numberOfSelectedSounds = numberOfSelected ("Sound")
# loop through all the TextGrid files, getting names and id numbers
for i from 1 to 'numberOfSelectedTextGrids'
  textGrid'i'Name$ = selected$ ("TextGrid", 'i')
  textGrid'i'Number = selected ("TextGrid", 'i')
endfor
# loop through the Sound files
for i from 1 to 'numberOfSelectedSounds'
  sound'i'Name$ = selected$ ("Sound", 'i')
  sound'i'Number = selected ("Sound", 'i')
endfor
# read in label-list file from data folder
Read Strings from raw text file... 'dataDirectoryPath$''sl$''labelFile$'
rawLabelListNumber = selected ("Strings", 1)
numberOfStrings = Get number of strings
# create a table for the data, get its name and number
Create Table with column names... AllLabels 'numberOfStrings' Label
tableAllLabelsNumber = selected ("Table", 1)
# enter labels from label list
currentRow = 1
for i from 1 to 'numberOfStrings'
  select 'rawLabelListNumber'
  call parse_string
  # enter the values into the first table column
  call enter_values_in_table
endfor
#################################################
# TEXTGRID LOOP
# initialize error-tally variables for all textgrids
numberMissingTotal = 0
numberDisorderedTotal = 0
numberErrorTotal = 0
labelMissingTotal = 0
labelNotFoundTotal = 0
labelErrorTotal = 0
# select and analyze each TextGrid file in turn
for i from 1 to 'numberOfSelectedTextGrids'
  # initialize error-tally variable for this textgrid
  numberMissingTextGrid = 0
  numberDisorderedTextGrid = 0
  numberErrorTextGrid = 0
  labelMissingTextGrid = 0
  labelNotFoundTextGrid = 0
  labelErrorTextGrid = 0
  # select TextGrid file 'i'
  targetTextGridNumber = textGrid'i'Number
  targetTextGridName$ = textGrid'i'Name$
  select 'targetTextGridNumber'
  # alert user to progress
  clearinfo
  printline
  printline Working on TextGrid: 'targetTextGridName$'
  printline
  # get number of tiers in the current textgrid
  numberOfTiers = Get number of tiers
  #################################################
  # TIER LOOP
  for tierCtr from 1 to 'numberOfTiers'
    numberMissingTier = 0
    numberDisorderedTier = 0
    numberErrorTier = 0
    labelMissingTier = 0
    labelNotFoundTier = 0
    labelErrorTier = 0
    # get number of intervals in tier
    numberOfIntervals = Get number of intervals... 'tierCtr'
    # initialize label-number variables
    previousNumber = 0
    currentNumber = 0
    #################################################
    # INTERVAL LOOP
    for intervalCtr from 1 to 'numberOfIntervals'
      select 'targetTextGridNumber'
      intervalLabel$ = Get label of interval... 'tierCtr' 'intervalCtr'
      # parse labels, if not empty and not a background marker
      if ((intervalLabel$ <> "") and (intervalLabel$ <> background_label$))
        # deal with number first
        if ('interval_numbering_present' = 1)
          # set booleans needed
          numberMissing = 0
          numberDisordered = 0
          call parse_label_number
          if ('numberMissing' = 1)
            numberMissingTier = 'numberMissingTier' + 1
            numberErrorTier = 'numberErrorTier' + 1
            numberMissingTextGrid = 'numberMissingTextGrid' + 1
            numberErrorTextGrid = 'numberErrorTextGrid' + 1
            numberMissingTotal = 'numberMissingTotal' + 1
            numberErrorTotal = 'numberErrorTotal' + 1
            if ('pause_after_each_TextGrid' = 1)
              printline Tier: 'tierCtr'  Interval: 'intervalCtr'  Number: 'currentNumber$'  Error: number missing
            endif
            fileappend "'dataFile$'" 'targetTextGridName$'  Tier: 'tierCtr'  Interval: 'intervalCtr'  Number: 'currentNumber$'  Error: number missing 'newline$'
          endif
          if ('numberDisordered' = 1)
            numberDisorderedTier = 'numberDisorderedTier' + 1
            numberErrorTier = 'numberErrorTier' + 1
            numberDisorderedTextGrid = 'numberDisorderedTextGrid' + 1
            numberErrorTextGrid = 'numberErrorTextGrid' + 1
            numberDisorderedTotal = 'numberDisorderedTotal' + 1
            numberErrorTotal = 'numberErrorTotal' + 1
            if ('pause_after_each_TextGrid' = 1)
              printline Tier: 'tierCtr'  Interval: 'intervalCtr'  Number: 'currentNumber$'  Error: number disordered
            endif
            fileappend "'dataFile$'" 'targetTextGridName$'  Tier: 'tierCtr'  Interval: 'intervalCtr'  Number: 'currentNumber$'  Error: number out of order 'newline$'
          endif
        endif
        # process any and all labels in the interval
        labelCtr = 0
        # remove any leading spaces in label, set continue variable to remaining label length
        call remove_leading_spaces
        continueInterval = length (intervalLabel$)
        while ('continueInterval' >= 1)
          # check the next label in the string against the table
          labelNotFoundInterval = 0
          labelCtr = 'labelCtr' + 1
          call get_next_label
          call check_label_against_table
          # if not found, report and tally error, else move on
          if ('labelFound' = 0)
            labelNotFoundTier = 'labelNotFoundTier' + 1
            labelErrorTier = 'labelErrorTier' + 1
            labelNotFoundTextGrid = 'labelNotFoundTextGrid' + 1
            labelErrorTextGrid = 'labelErrorTextGrid' + 1
            labelNotFoundTotal = 'labelNotFoundTotal' + 1
            labelErrorTotal = 'labelErrorTotal' + 1
            if ('pause_after_each_TextGrid' = 1)
              printline Tier: 'tierCtr'  Interval: 'intervalCtr'  Label: 'currentLabel$'  Error: no such label
           endif
           fileappend "'dataFile$'" 'targetTextGridName$'  Tier: 'tierCtr'  Interval: 'intervalCtr'  Label: 'currentLabel$'  Error: no such label 'newline$'
         endif
         # go to next label or quit if interval is done
         if (intervalLabel$ = "")
           continueInterval = 0
         endif
      endwhile
      # no more labels, interval is done
      # if no labels were found, update error variables, send message to screen and file
      if (labelCtr = 0)
        labelMissingTier = 'labelMissingTier' + 1
        labelErrorTier = 'labelErrorTier' + 1
        labelMissingTextGrid = 'labelMissingTextGrid' + 1
        labelErrorTextGrid = 'labelErrorTextGrid' + 1
        labelMissingTotal = 'labelMissingTotal' + 1
        labelErrorTotal = 'labelErrorTotal' + 1
        if ('pause_after_each_TextGrid' = 1)
          printline Tier: 'tierCtr'  Interval: 'intervalCtr'  Label: 'currentLabel$'  Error: label missing
        endif
        fileappend "'dataFile$'" 'newline$'
        fileappend "'dataFile$'" 'targetTextGridName$'  Tier: 'tierCtr'  Interval: 'intervalCtr'  Label: 'currentLabel$' Error: label missing 'newline$'
      endif
    endif
    #################################################
    # END INTERVAL AND TIER LOOPS
    # on to next interval
    endfor
  # on to next tier
  endfor
  # send TextGrid data to screen and pause, if desired
  if ('pause_after_each_TextGrid' = 1)
    printline
    if ('interval_numbering_present') = 1
      errorTotalTextGrid = 'numberErrorTextGrid'+'labelErrorTextGrid'
      printline TextGrid 'targetTextGridName$' had 'errorTotalTextGrid' total error(s)
      printline ...'numberMissingTextGrid' unnumbered interval(s)
      printline ...'numberDisorderedTextGrid' interval(s) numbered out of order 
    endif
    printline ...'labelMissingTextGrid' unlabeled interval(s)
    printline ...'labelNotFoundTextGrid' label(s) not in the label list
    pause Select Continue or Stop
  endif
#################################################
# END TEXTGRID LOOP
# loop to next TextGrid
endfor
#################################################
# SEND DATA TO SCREEN AND FILE, CLEAN UP, END
# send final data to screen
clearinfo
printline
printline Checked 'numberOfSelectedTextGrids' TextGrid file(s)
printline
for i from 1 to 'numberOfSelectedTextGrids'
  targetTextGridName$ = textGrid'i'Name$
  printline 'targetTextGridName$'
endfor
# send final tallies to screen and file
errorTotal = ('numberErrorTotal' + 'labelErrorTotal')
printline
printline File(s) included 'errorTotal' total error(s)
fileappend "'dataFile$'" 'newline$'
fileappend "'dataFile$'" File(s) included 'errorTotal' total error(s)
fileappend "'dataFile$'" 'newline$'
if ('interval_numbering_present') = 1
  printline ...'numberMissingTotal' unnumbered interval(s)
  printline ...'numberDisorderedTotal' interval(s) numbered out of order
  fileappend "'dataFile$'" ...'numberMissingTotal' unnumbered interval(s) 'newline$'
  fileappend "'dataFile$'" ...'numberDisorderedTotal' interval(s) numbered out of order 'newline$'
endif
printline ...'labelMissingTotal' unlabeled interval(s)
printline ...'labelNotFoundTotal' label(s) not in the label list
fileappend "'dataFile$'" ...'labelMissingTotal' unlabeled interval(s) 'newline$'
fileappend "'dataFile$'" ...'labelNotFoundTotal' label(s) not in the label list 'newline$'
printline
# clean up
select 'rawLabelListNumber'
plus 'tableAllLabelsNumber'
Remove
# reselect the original set
if ('numberOfSelectedSounds' >= 1)
  select 'sound1Number'
    plus 'textGrid1Number'
  if ('numberOfSelectedSounds' >= 2)
    for i from 2 to 'numberOfSelectedSounds'
      plus sound'i'Number
      plus textGrid'i'Number
    endfor
  endif
 else
  select 'textGrid1Number'
  for i from 2 to 'numberOfSelectedTextGrids'
    plus textGrid'i'Number
  endfor 
endif
# select next file?
if 'move_on_after' = 1 
  if ('numberOfSelectedSounds' >= 1)
    select sound'numberOfSelectedSounds'Number
      plus textGrid'numberOfSelectedSounds'Number
    execute nextObjects.praat
  endif
endif
  # end main program
exit

#############################################################

####################           PROCEDURES          ####################

#############################################################
procedure set_data_paths
  # check operating system type, set sl$ as (back)slash character
  if (macintosh = 1)
    opSys$ = "macintosh"
    sl$ = "/"
   elsif (windows = 1)
    opSys$ = "windows"
    sl$ = "\"
   else
    # system not recognized, alert user
    echo "Operating system is unknown, the script has terminated"
    exit
  endif
  # set name of desktop, data directory, and the pathnames needed
  gsuprtlsDirectory$ = "'defaultDirectory$'"
  pluginDirectory$ = "'preferencesDirectory$''sl$'plugin_GSUPraatTools"
  desktopName$ < 'pluginDirectory$''sl$'desktopNameFile
  dataDirectoryPath$ < 'pluginDirectory$''sl$'dataDirectoryPathFile
  dataFile$ = dataDirectoryPath$ + sl$ + dataFile$
  # check for and possibly create the Praat_Data directory
  dataDirectoryExists = fileReadable ("'dataDirectoryPath$'")
  if 'dataDirectoryExists' <> 1
    system mkdir "'dataDirectoryPath$'"
  endif
endproc

############################################################
procedure date_and_time
  date$ = date$ ()
  weekday$ = left$ (date$, 3)
  month$ = mid$ (date$, 5, 3)
  daynumber$ = mid$ (date$, 9, 2)
  if left$ (daynumber$, 1) = " "
   daynumber$ = right$ (daynumber$, 1)
  endif
  time$ = mid$ (date$, 12, 8)
  year$ = right$ (date$, 4)
endproc

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
procedure parse_string
  # get string
  rawString$ = Get string... 'i'
  continue = 1
  labelCtr = 0
  while ('continue' = 1)
    # remove leading spaces in front of string item
    while left$(rawString$, 1) = " "
      rawString$ = mid$(rawString$, 2, 1000)
    endwhile
    # read the alphanumeric string
    inString$ = ""
    while (left$(rawString$, 1) <> " ") and (left$(rawString$, 1) <> "")
      inString$ = inString$ + left$(rawString$, 1)
      rawString$ = mid$(rawString$, 2, 1000)
    endwhile
    if (inString$ = "")
      continue = 0
     else
      labelCtr = 'labelCtr' + 1
      labelItem'labelCtr'$ = inString$
    endif
  endwhile
endproc

############################################################
procedure enter_values_in_table
  # enter the values into the first table column
  select 'tableAllLabelsNumber'
  for j from 1 to 'labelCtr'
    newItem$ = labelItem'j'$
    Set string value... 'currentRow' Label 'newItem$'
    currentRow = 'currentRow' + 1
  endfor
  totalRows = ('currentRow' - 1)
endproc

############################################################
procedure parse_label_number
  # get the first label
  firstSpace = index (intervalLabel$, " ")
  if ('firstSpace' > 0)
    labelNumber$ = left$(intervalLabel$, 'firstSpace'-1)
   else
    labelNumber$ = intervalLabel$
  endif
  # check if it's a number
  currentNumber = extractNumber(labelNumber$, "")
  if (currentNumber = undefined)
    currentNumber$ = "--"
    numberMissing = 1
    currentNumber = 'previousNumber' + 1
   else
    # there is a number, shave it off, as well as trailing space
    intervalLabel$ = mid$(intervalLabel$, 'firstSpace'+1, 10000)
    # is number one more than previous interval number?
    if ('currentNumber' <> ('previousNumber' + 1))
      currentNumber$ = "'currentNumber'"
      numberDisordered = 1
     endif
    previousNumber = 'currentNumber'
  endif
endproc

############################################################
procedure remove_leading_spaces
  # remove any leading spaces
  while left$(intervalLabel$, 1) = " "
    intervalLabel$ = mid$(intervalLabel$, 2, 10000)
  endwhile
  continueInterval = length (intervalLabel$)
endproc

############################################################
procedure get_next_label
  # intervalLabelString has label string without leading numbers or spaces
  # as long as there are labels to be retrieved, get the first one, update string
  firstSpace = index(intervalLabel$, " ")
  if firstSpace = 0
    # last label, retrieve
    currentLabel$ = intervalLabel$
    intervalLabel$ = ""
   else
    # retrieve and store the first label, not including trailing space, update string
    currentLabel$ = left$ (intervalLabel$, firstSpace-1)
    intervalLabel$ = mid$ (intervalLabel$, firstSpace, 10000)
    call remove_leading_spaces
   endif
   continueInterval = length (intervalLabel$)
endproc

############################################################
procedure check_label_against_table
  labelFound = 0
  select 'tableAllLabelsNumber'
  for currentRow from 1 to 'totalRows'
    currentRowLabel$ = Get value... 'currentRow' Label
    if (currentRowLabel$ = currentLabel$)
      labelFound = 1
    endif
  endfor
endproc

############################################################
# get the labels for each tier and the selected interval at each tier
procedure get_labels_raw targetTime
  select 'textGridNumber'
  numberOfTiers = Get number of tiers
  for i from 1 to 'numberOfTiers'
    tierName'i'$ = Get tier name... 'i'
  endfor
  for i from 1 to 'numberOfTiers'
    intervalNumber'i' = Get interval at time... 'i' 'targetTime'
    intervalLabel'i'$ = Get label of interval... 'i' intervalNumber'i'
  endfor
endproc

############################################################
# concatenate labels, removing all spaces
procedure concatenate_labels
  for i from 1 to 'numberOfTiers'
    tierLabelString'i'$ = tierName'i'$ + intervalLabelNumber'i'$
  endfor
 # concatenate tier-level label strings, from the bottom up
  tierLabelStringConcat$ = ""
  tierLabelStringSpaced$ = ""
  i = 'numberOfTiers'
  while i >=1 
    tierLabelStringConcat$ = tierLabelStringConcat$ + tierLabelString'i'$
    tierLabelStringSpaced$ = tierLabelStringSpaced$ + tierLabelString'i'$ + " "
    i = i - 1
  endwhile
  # shave trailing spaces off tier-level label strings
  while right$(tierLabelStringConcat$, 1) = " "
    stringLength = length(tierLabelStringConcat$)
    tierLabelStringConcat$ = left$(tierLabelStringConcat$, stringLength-1)
  endwhile
  while right$(tierLabelStringSpaced$, 1) = " "
    stringLength = length(tierLabelStringSpaced$)
    tierLabelStringSpaced$ = left$(tierLabelStringSpaced$, stringLength-1)
  endwhile
  # concatenate interval-level label strings from first to last
  for i from 1 to 'numberOfTiers'
    intervalLabelStringConcat'i'$ = ""
    intervalLabelStringSpaced'i'$ = ""
    for j from 1 to numberOfIntervalLabelsTier'i'
      intervalLabelStringConcat'i'$ = intervalLabelStringConcat'i'$ + intervalLabel'i''j'$
      intervalLabelStringSpaced'i'$ = intervalLabelStringSpaced'i'$ + intervalLabel'i''j'$ + " "
    endfor
  endfor
  # shave trailing space off interval-level label strings
  for i from 1 to 'numberOfTiers'
    while right$(intervalLabelStringConcat'i'$, 1) = " "
      stringLength = length(intervalLabelStringConcat'i'$)
      intervalLabelStringConcat'i'$ = left$(intervalLabelStringConcat'i'$, 'stringLength'-1)
    endwhile
    while right$(intervalLabelStringSpaced'i'$, 1) = " "
      stringLength = length(intervalLabelStringSpaced'i'$)
      intervalLabelStringSpaced'i'$ = left$(intervalLabelStringSpaced'i'$, 'stringLength'-1)
      if intervalLabelStringSpaced'i'$ = " "
        intervalLabelStringSpaced'i'$ = ""
      endif
    endwhile
  endfor
endproc
