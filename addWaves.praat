# addWaves
#######################################################################
# adds waveforms selected in the Objects window
# two waveforms can be added to create a stereo file, or an 
# unlimited number of waveforms can be added as a mono file

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
