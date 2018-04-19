# setup.praat for GSU Praat Tools 1.9
#######################################################################

# Michael J. Owren, Ph.D.
# Psychology of Voice and Sound Laboratory
# Department of Psychology
# Georgia State University
# Atlanta, GA 30303, USA

# email: owren@gsu.edu
# home page: http://michaeljowren.googlepages.com
# lab page: http://psyvoso.googlepages.com

# Copyright 2007-2011 Michael J. Owren

# This setup.ini file is part of GSU Praat Tools 1.9. GSU Tools is
# free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your
# option) any later version.

# This setup.ini file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# in a text file called "Copying" along with this program. If not, see
# <http://www.gnu.org/licenses/>.

########################################################################################################
################################### TEXTGRID FROM SOUND, SOUND FROM TEXTGRID ##############################
########################################################################################################

# IN OBJECTS WINDOW
Add action command... Sound 1 "" 0 "" 0 "Edit with labels" "Edit" 0 labelSound.praat

# IN TEXTGRID EDITOR
Add action command... TextGrid 1 "" 0 "" 0 "Edit with sound" "& Sound: Edit?" 0 labelSound.praat
Add action command... Sound 1 TextGrid 1 "" 0 "Edit with labels" "Edit" 0 labelSound.praat

########################################################################################################
############################################# READ AND WRITE #############################################
########################################################################################################

# READ COMMANDS
Add menu command... Objects Read "-- read multiple files --" "" 1
Add menu command... Objects Read "Set data directory..." "-- read multiple files --" 1 setDataDirectory.praat
Add menu command... Objects Read "Read sounds and labels..." "Set data directory..." 1 readSoundsLabels.praat
Add menu command... Objects Read "Read from GSU Tools Project..." "Read sounds and labels..." 1 readProject.praat

# WRITE COMMANDS
Add action command... Sound 0 TextGrid 0 "" 0 "Write sounds and labels..." "-- write multiple files --" 1 writeSoundsLabels.praat
Add action command... Sound 0 TextGrid 0 "" 0 "Write to GSU Tools Project..." "Write sounds and labels..." 1 writeProject.praat
Add action command... Sound 0 "" 0 "" 0 "Write sounds and labels..." "-- write multiple files --" 1 writeSoundsLabels.praat
Add action command... Sound 0 "" 0 "" 0 "Write to GSU Tools Project..." "Write sounds and labels..." 1 writeProject.praat
Add action command... TextGrid 0 "" 0 "" 0 "Write sounds and labels..." "-- write multiple files --" 1 writeSoundsLabels.praat
Add action command... TextGrid 0 "" 0 "" 0 "Write to GSU Tools Project..." "Write sounds and labels..." 1 writeProject.praat

########################################################################################################
################################# UTILITY, LABEL, QUANTIFY, FIGURE, and SYNTHESIS ###############################
########################################################################################################

##########################################################################
# IN OBJECTS WINDOW AND/OR  SOUND EDITOR
Add action command... Sound 0 "" 0 "" 0 "GSU Tools -" "Combine sound-" 0
##########################################################################

##### SYNTHESIS SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Synthesis -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "harmonic resynthesis..." "Synthesis -" 2 resynthHarmonics.praat
Add action command... Sound 0 "" 0 "" 0 "lpc resynthesis..." "harmonic resynthesis..." 2 resynthLPC.praat
Add action command... Sound 0 "" 0 "" 0 "pitch-resonance-duration resynthesis..." "lpc resynthesis..." 2 resynthPitchResDur.praat
Add action command... Sound 0 "" 0 "" 0 "time-reverse resynthesis..." "pitch-resonance-duration resynthesis..."  2 resynthTimeReverse.praat
Add action command... Sound 0 "" 0 "" 0 "vocoding resynthesis..." "time-reverse resynthesis..."  2 resynthVocoding.praat
Add action command... Sound 0 "" 0 "" 0 "sine wave resynthesis..." "vocoding resynthesis..." 2 resynthSineWaves.praat

##### FIGURES SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Figures -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "waveform, spectrum, and spectrogram..." "Figures -" 2 waveSpectrumSpectrogram.praat
Add action command... Sound 0 "" 0 "" 0 "waveform, tracks, and spectrogram..." "waveform, spectrum, and spectrogram..." 2 waveTracksSpectrogram.praat

##### QUANTIFY SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Quantify -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "quantify Amp and Dur..." "Quantify -" 2 quantifyAmpDur.praat
Add action command... Sound 0 "" 0 "" 0 "quantify Bands..." "quantify Amp and Dur..." 2 quantifyBands.praat
Add action command... Sound 0 "" 0 "" 0 "quantify Crosscorrelation..." "quantify Bands..." 2 quantifyCrosscorr.praat
Add action command... Sound 0 "" 0 "" 0 "quantify Emotion..." "quantify Crosscorrelation..." 2 quantifyEmotion.praat
Add action command... Sound 0 "" 0 "" 0 "quantify FFT..." "quantify Emotion..." 2 quantifyFFT.praat
Add action command... Sound 0 "" 0 "" 0 "quantify Formants..." "quantify FFT..." 2 quantifyFormants.praat
Add action command... Sound 0 "" 0 "" 0 "quantify LPC..." "quantify Formants..." 2 quantifyLPC.praat
Add action command... Sound 0 "" 0 "" 0 "quantify Source..." "quantify LPC..." 2 quantifySource.praat

##### LABELING SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Labeling -" "GSU Tools -" 1
Add action command... Sound 99 "" 0 "" 0 "check Labels..." "Labeling -" 2 checkLabels.praat
Add action command... Sound 99 "" 0 "" 0 "edit Labels..." "check Labels..." 2 editLabels.praat
Add action command... Sound 99 "" 0 "" 0 "edit Tiers..." "edit Labels..." 2 editTiers.praat
Add action command... Sound 0 "" 0 "" 0 "event Detector..." "edit Tiers..." 2 eventDetector.praat
Add action command... Sound 0 "" 0 "" 0 "event Number..." "event Detector..." 2 eventNumber.praat
Add action command... Sound 99 "" 0 "" 0 "move Labels..." "event Number..." 2 moveLabels.praat

##### MODIFY SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Modify -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "add Noise..." "Modify -" 2 addNoise.praat
Add action command... Sound 0 "" 0 "" 0 "add Waves..." "add Noise..." 2 addWaves.praat
Add action command... Sound 0 "" 0 "" 0 "crop Sound..." "add Waves..." 2 cropSound.praat
Add action command... Sound 0 "" 0 "" 0 "preprocess Sound..." "crop Sound..." 2 preprocessSound.praat
Add action command... Sound 0 "" 0 "" 0 "ramp Sound..." "preprocess Sound..." 2 rampSound.praat
Add action command... Sound 0 "" 0 "" 0 "rescale Sound..." "ramp Sound..." 2 rescaleSound.praat
Add action command... Sound 0 "" 0 "" 0 "zeropad Sound..." "rescale Sound..." 2 zeropadSound.praat

##### FILTER SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Filter -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "acdc Filtering..." "Filter -" 2 acdcFiltering.praat
Add action command... Sound 0 "" 0 "" 0 "band Filtering..." "acdc Filtering..." 2 bandFiltering.praat
Add action command... Sound 0 "" 0 "" 0 "emphasis Filtering..." "band Filtering..." 2 emphasisFiltering.praat
Add action command... Sound 0 "" 0 "" 0 "formant Filtering..." "emphasis Filtering..." 2 formantFiltering.praat
Add action command... Sound 0 "" 0 "" 0 "smoothing Waveform..." "formant Filtering..." 2 smoothingWaveform.praat

##### UTILITY SUBMENU
Add action command... Sound 0 "" 0 "" 0 "Utility -" "GSU Tools -" 1
Add action command... Sound 0 "" 0 "" 0 "change Sampling Frequency" "Utility -" 2 changeSF.praat
Add action command... Sound 0 "" 0 "" 0 "check File" "change Sampling Frequency" 2 checkFile.praat
Add action command... Sound 1 "" 0 "" 0 "choose Window..." "check File" 2 chooseWindow.praat
Add action command... Sound 0 "" 0 "" 0 "collapse Data Rows..." "choose Window..." 2 collapseDataRows.praat
Add action command... Sound 0 "" 0 "" 0 "display Spectrum..." "collapse Data Rows..." 2 displaySpectrum.praat


##########################################################################
# IN TEXTGRID EDITOR (with one or more Sounds plus TextGrids selected)
Add action command... Sound 0  TextGrid 0 "" 0 "GSU Tools -" "Clone time domain" 0
##########################################################################

###### SYNTHESIZE SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Synthesis -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "harmonic resynthesis..." "Synthesis -" 2 resynthHarmonics.praat
Add action command... Sound 0 TextGrid 0 "" 0 "lpc resynthesis..." "harmonic resynthesis..." 2 resynthLPC.praat
Add action command... Sound 0 TextGrid 0 "" 0 "pitch-resonance-duration resynthesis..." "lpc resynthesis..." 2 resynthPitchResDur.praat
Add action command... Sound 0 TextGrid 0 "" 0 "time-reverse resynthesis..." "pitch-resonance-duration resynthesis..." 2 resynthTimeReverse.praat
Add action command... Sound 0 TextGrid 0 "" 0 "vocoding resynthesis..." "time-reverse resynthesis..." 2 resynthVocoding.praat
Add action command... Sound 0 TextGrid 0 "" 0 "sine wave resynthesis..." "vocoding resynthesis..." 2 resynthSineWaves.praat

##### MAKE FIGURES SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Figures -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "waveform, spectrum, and spectrogram..." "Figures -" 2 waveSpectrumSpectrogram.praat
Add action command... Sound 0 TextGrid 0 "" 0 "waveform, tracks, and spectrogram..." "waveform, spectrum, and spectrogram..." 2 waveTracksSpectrogram.praat

##### QUANTIFY SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Quantify -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Amp and Dur..." "Quantify -" 2 quantifyAmpDur.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Bands..." "quantify Amp and Dur..." 2 quantifyBands.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Crosscorrelation..." "quantify Bands..." 2 quantifyCrosscorr.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Emotion..." "quantify Crosscorrelation..." 2 quantifyEmotion.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify FFT..." "quantify Emotion..." 2 quantifyFFT.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Formants..." "quantify FFT..." 2 quantifyFormants.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify LPC..." "quantify Formants..." 2 quantifyLPC.praat
Add action command... Sound 0 TextGrid 0 "" 0 "quantify Source..." "quantify LPC..." 2 quantifySource.praat

##### LABELING SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Labeling -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "check Labels..." "Labeling -" 2 checkLabels.praat
Add action command... Sound 0 TextGrid 0 "" 0 "edit Labels..." "check Labels..." 2 editLabels.praat
Add action command... Sound 0 TextGrid 0 "" 0 "edit Tiers..." "edit Labels..." 2 editTiers.praat
Add action command... Sound 0 TextGrid 99 "" 0 "event Detector..." "edit Tiers..." 2 eventDetector.praat
Add action command... Sound 0 TextGrid 0 "" 0 "event Number..." "event Detector..." 2 eventNumber.praat
Add action command... Sound 0 TextGrid 0 "" 0 "move Labels..." "event Number..." 2 moveLabels.praat

##### MODIFY SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Modify -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "add Noise..." "Modify -" 2 addNoise.praat
Add action command... Sound 0 TextGrid 0 "" 0 "add Waves..." "add Noise..." 2 addWaves.praat
Add action command... Sound 99 TextGrid 0 "" 0 "crop Sound..." "add Waves..." 2 cropSound.praat
Add action command... Sound 0 TextGrid 0 "" 0 "preprocess Sound..." "crop Sound..." 2 preprocessSound.praat
Add action command... Sound 99 TextGrid 0 "" 0 "ramp Sound..." "preprocess Sound..." 2 rampSound.praat
Add action command... Sound 0 TextGrid 0 "" 0 "rescale Sound..." "ramp Sound..." 2 rescaleSound.praat
Add action command... Sound 99 TextGrid 0 "" 0 "zeropad Sound..." "rescale Sound..." 2 zeropadSound.praat

##### FILTER SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Filter -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 0 "" 0 "acdc Filtering..." "Filter -" 2 acdcFiltering.praat
Add action command... Sound 0 TextGrid 0 "" 0 "band Filtering..." "acdc Filtering..." 2 bandFiltering.praat
Add action command... Sound 0 TextGrid 0 "" 0 "emphasis Filtering..." "band Filtering..." 2 emphasis Filtering.praat
Add action command... Sound 0 TextGrid 0 "" 0 "formant Filtering..." "emphasis Filtering..." 2 formantFiltering.praat
Add action command... Sound 0 TextGrid 0 "" 0 "smoothing Waveform..." "formant Filtering..." 2 smoothingWaveform.praat

##### UTILITY SUBMENU
Add action command... Sound 0 TextGrid 0 "" 0 "Utility -" "GSU Tools -" 1
Add action command... Sound 0 TextGrid 99 "" 0 "change Sampling Frequency" "Utility -" 2 changeSF.praat
Add action command... Sound 0 TextGrid 99 "" 0 "check File" "change Sampling Frequency" 2 checkFile.praat
Add action command... Sound 1 TextGrid 0 "" 0 "choose Window..." "check File" 2 chooseWindow.praat
Add action command... Sound 0 TextGrid 99 "" 0 "collapse Data Rows..." "choose Window..." 2 collapseDataRows.praat
Add action command... Sound 0 TextGrid 0 "" 0 "display Spectrum..." "collapse Data Rows..." 2 displaySpectrum.praat


##########################################################################
# IN TEXTGRID EDITOR (with only TextGrids selected)
Add action command... TextGrid 1 "" 0 "" 0 "GSU Tools -" "Merge" 0
##########################################################################

###### SYNTHESIZE SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Synthesis -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "harmonic resynthesis..." "Synthesis -" 2 resynthHarmonics.praat
Add action command... TextGrid 99 "" 0 "" 0 "lpc resynthesis..." "harmonic resynthesis..." 2 resynthLPC.praat
Add action command... TextGrid 99 "" 0 "" 0 "pitch-resonance-duration resynthesis..." "lpc resynthesis..." 2 resynthPitchResDur.praat
Add action command... TextGrid 99 "" 0 "" 0 "time-reverse resynthesis..." "pitch-resonance-duration resynthesis..." 2 resynthTimeReverse.praat
Add action command... TextGrid 99 "" 0 "" 0 "vocoding resynthesis..." "time-reverse resynthesis..." 2 resynthVocoding.praat
Add action command... TextGrid 99 "" 0 "" 0 "sine wave resynthesis..." "vocoding resynthesis..." 2 resynthSineWaves.praat

##### MAKE FIGURES SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Figures -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "waveform, spectrum, and spectrogram..." "Figures -" 2 waveSpectrumSpectrogram.praat
Add action command... TextGrid 99 "" 0 "" 0 "waveform, tracks, and spectrogram..." "waveform, spectrum, and spectrogram..." 2 waveTracksSpectrogram.praat

##### QUANTIFY SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Quantify -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "quantify Amp and Dur..." "Quantify -" 2 quantifyAmpDur.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify Bands..." "quantify Amp and Dur..." 2 quantifyBands.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify Crosscorrelation..." "quantify Bands..." 2 quantifyCrosscorr.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify Emotion..." "quantify Crosscorrelation..." 2 quantifyEmotion.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify FFT..." "quantify Emotion..." 2 quantifyFFT.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify Formants..." "quantify FFT..." 2 quantifyFormants.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify LPC..." "quantify Formants..." 2 quantifyLPC.praat
Add action command... TextGrid 99 "" 0 "" 0 "quantify Source..." "quantify LPC..." 2 quantifySource.praat

##### LABELING SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Labeling -" "GSU Tools -" 1
Add action command... TextGrid 0 "" 0 "" 0 "check Labels..." "Labeling -" 2 checkLabels.praat
Add action command... TextGrid 0 "" 0 "" 0 "edit Labels..." "check Labels..." 2 editLabels.praat
Add action command... TextGrid 0 "" 0 "" 0 "edit Tiers..." "edit Labels..." 2 editTiers.praat
Add action command... TextGrid 99 "" 0 "" 0 "event Detector..." "edit Tiers..." 2 eventDetector.praat
Add action command... TextGrid 0 "" 0 "" 0 "event Number..." "event Detector..." 2 eventNumber.praat
Add action command... TextGrid 0 "" 0 "" 0 "move Labels..." "event Number..." 2 moveLabels.praat

##### MODIFY SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Modify -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "add Noise..." "Modify -" 2 addNoise.praat
Add action command... TextGrid 99 "" 0 "" 0 "add Waves..." "add Noise..." 2 addWaves.praat
Add action command... TextGrid 99 "" 0 "" 0 "crop Sound..." "add Waves..." 2 cropSound.praat
Add action command... TextGrid 99 "" 0 "" 0 "preprocess Sound..." "crop Sound..." 2 preprocessSound.praat
Add action command... TextGrid 99 "" 0 "" 0 "ramp Sound..." "preprocess Sound..." 2 rampSound.praat
Add action command... TextGrid 99 "" 0 "" 0 "rescale Sound..." "ramp Sound..." 2 rescaleSound.praat
Add action command... TextGrid 99 "" 0 "" 0 "zeropad Sound..." "rescale Sound..." 2 zeropadSound.praat

##### FILTER SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Filter -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "acdc Filtering..." "Filter -" 2 acdcFiltering.praat
Add action command... TextGrid 99 "" 0 "" 0 "band Filtering..." "acdc Filtering..." 2 bandFiltering.praat
Add action command... TextGrid 99 "" 0 "" 0 "emphasis Filtering..." "band Filtering..." 2 emphasisFiltering.praat
Add action command... TextGrid 99 "" 0 "" 0 "formant Filtering..." "emphasis Filtering..." 2 formantFiltering.praat
Add action command... TextGrid 99 "" 0 "" 0 "smoothing Waveform..." "formant Filtering..." 2 smoothingWaveform.praat

##### UTILITY SUBMENU
Add action command... TextGrid 0 "" 0 "" 0 "Utility -" "GSU Tools -" 1
Add action command... TextGrid 99 "" 0 "" 0 "change Sampling Frequency" "Utility -" 2 changeSF.praat
Add action command... TextGrid 99 "" 0 "" 0 "check File" "change Sampling Frequency" 2 checkFile.praat
Add action command... TextGrid 99 "" 0 "" 0 "choose Window..." "check File" 2 chooseWindow.praat
Add action command... TextGrid 99 "" 0 "" 0 "collapse Data Rows..." "choose Window..." 2 collapseDataRows.praat
Add action command... TextGrid 99 "" 0 "" 0 "display Spectrum..." "crop Sound..." 2 displaySpectrum.praat


########################################################################################################
####################################### PREVIOUS AND NEXT COMMANDS ######################################
########################################################################################################

# EDITOR <FILE> MENU
Add menu command... SoundEditor File "previous" "Open editor script..." 1 previousEditor.praat
Add menu command... SoundEditor File "next" "previous" 1 nextEditor.praat
Add menu command... TextGridEditor File "previous" "Open editor script..." 1 previousEditor.praat
Add menu command... TextGridEditor File "next" "previous" 1 nextEditor.praat

# OBJECTS WINDOW ONLY
Add action command... Sound 1 "" 0 "" 0 "previous (Objects)" "sine wave resynthesis..." 0 previousObjects.praat
Add action command... Sound 1 "" 0 "" 0 "next (Objects)" "previous (Objects)" 0 nextObjects.praat

# OBJECTS WINDOW AND SOUND EDITOR
Add action command... Sound 1 "" 0 "" 0 "previous (Editor)" "next Objects" 0 previousEditor.praat
Add action command... Sound 1 "" 0 "" 0 "next (Editor)" "previous Editor" 0 nextEditor.praat

# OBJECTS WINDOW, BOTH SOUND AND TEXTGRID EDITOR
Add action command... Sound 1 TextGrid 1 "" 0 "previous (Objects)" "next (Editor)" 0 previousObjects.praat
Add action command... Sound 1 TextGrid 1 "" 0 "next (Objects)" "previous (Objects)" 0 nextObjects.praat
Add action command... Sound 1 TextGrid 1 "" 0 "previous (Editor)" "next (Objects)" 0 previousEditor.praat
Add action command... Sound 1 TextGrid 1 "" 0 "next (Editor)" "previous (Editor)" 0 nextEditor.praat
Add action command... Sound 1 TextGrid 1 "" 0 "previous Interval" "next (Editor)" 0 previousInterval.praat
Add action command... Sound 1 TextGrid 1 "" 0 "next Interval" "previous Interval" 0 nextInterval.praat

# OBJECTS WINDOW AND TEXTGRID EDITOR, NO SOUND
Add action command... TextGrid 1 "" 0 "" 0 "previous (Objects)" "sine wave resynthesis..." 0 previousObjects.praat
Add action command... TextGrid 1 "" 0 "" 0 "next (Objects)" "previous (Objects)" 0 nextObjects.praat
Add action command... TextGrid 1 "" 0 "" 0 "previous (Editor)" "next (Objects)" 0 previousEditor.praat
Add action command... TextGrid 1 "" 0 "" 0 "next (Editor)" "previous (Editor)" 0 nextEditor.praat
Add action command... TextGrid 1 "" 0 "" 0 "previous Interval" "next (Editor)" 0 previousInterval.praat
Add action command... TextGrid 1 "" 0 "" 0 "next Interval" "previous Interval" 0 nextInterval.praat
