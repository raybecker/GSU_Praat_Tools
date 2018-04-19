# the GSUPraatTools folder should be present on the user's Desktop
form install or uninstall GSU Tools
  optionmenu Installation_mode 1
    option install
    option uninstall
  optionmenu Operating_system 1
    option set operating system first
    option Mac OSX
    option Windows XP
  comment Enter name of desktop (e.g., Desktop, Skrivebord, etc.)...
  word Desktop_name Desktop
endform

# jump to selected processing mode
if ('operating_system' = 1)
  clearinfo
  printline
  printline Error: Select operating system!
  printline
  exit
 elsif ('operating_system' = 2) 
  call mac_osx
 elsif ('operating_system' = 3) 
  call windows_xp
endif

# end main program

############################ procedures ############################

######################### mac osx #########################
procedure mac_osx

  # set slash character, script directory, plugin directory, and default data directory
  sl$ = "/"
  gsuprtlsDirectory$ = "'homeDirectory$'" + sl$ + desktop_name$ + sl$ + "GSUPraatTools1.9"
  pluginDirectory$ = "'preferencesDirectory$''sl$'plugin_GSUPraatTools"
  pluginDirectoryExists = fileReadable ("'pluginDirectory$'")
  dataDirectoryPath$ = "'homeDirectory$'" + sl$ + desktop_name$ + sl$ + "Praat_Data"
  
  if ('installation_mode' = 1)
    # if the plugin_GSUPraatTools folder already exists, delete all its files; otherwise create the folder
    if 'pluginDirectoryExists' = 1
      printline removing current installation...
      system rm -f "'pluginDirectory$'"'sl$'*
      # remove any hidden files as well
      system rm -f "'pluginDirectory$'"/\.??*
     else
      system mkdir "'pluginDirectory$'"
      printline creating the installation directory...
    endif
    # copy files from GSUPraatTools folder on desktop using system command
     system cp 'gsuprtlsDirectory$''sl$'* "'pluginDirectory$'"
    # create the desktop name file in the plugin directory
    filedelete 'pluginDirectory$''sl$'desktopNameFile
    fileappend "'pluginDirectory$''sl$'desktopNameFile" 'desktop_name$'
    # create the data directory path name file in the plugin directory
    filedelete 'pluginDirectory$''sl$'dataDirectoryPathFile
    fileappend "'pluginDirectory$''sl$'dataDirectoryPathFile" 'dataDirectoryPath$'
    # alert user
    clearinfo
    printline
    printline file copying is complete...
    printline 
    printline To finish the installation, close and then re-open Praat
   else
    # uninstall
    # if the plugin_GSUPraatTools folder exists, delete all its files, remove folder, alert user
    # otherwise do nothing, alert user
    if ('pluginDirectoryExists' = 1)
      system rm -f "'pluginDirectory$'"'sl$'*
      # remove all files, including any hidden files
      clearinfo
      printline
      printline deleting GSU Tools files...
      system rm -f "'pluginDirectory$'"/\.??*
      system rmdir "'pluginDirectory$'"
      printline
      printline the GSU Tools installation has been removed
     else
      # installation not found
      clearinfo
      printline
      printline GSU Tools installation was not found
      printline
      printline ...no action taken
    endif
  endif

endproc

######################### windows xp #########################
procedure windows_xp

  # set slash character, script directory, plugin directory, and default data directory
  sl$ = "\"
  gsuprtlsDirectory$ = "'homeDirectory$'" + sl$ + desktop_name$ + sl$ + "GSUPraatTools1.9"
  pluginDirectory$ = "'preferencesDirectory$''sl$'plugin_GSUPraatTools"
  pluginDirectoryExists = fileReadable ("'pluginDirectory$'")
  dataDirectoryPath$ = "'homeDirectory$'" + sl$ + desktop_name$ + sl$ + "Praat_Data"
  if ('installation_mode' = 1)
    # if the plugin_GSUPraatTools folder already exists, delete all its files; otherwise create the folder
    if 'pluginDirectoryExists' = 1
      printline removing current installation...
      system rm -f "'pluginDirectory$'"'sl$'*
      # remove any hidden files as well
      system rm -f "'pluginDirectory$'"/\.??*
     else
      system mkdir "'pluginDirectory$'"
      printline creating the installation directory...
    endif
    # copy files from GSUPraatTools folder on desktop using system command
    system copy "'gsuprtlsDirectory$''sl$'*" "'pluginDirectory$'"
    # create the desktop name file in the plugin directory
    filedelete 'pluginDirectory$''sl$'desktopNameFile
    fileappend "'pluginDirectory$''sl$'desktopNameFile" 'desktop_name$'
    # create the data directory path name file in the plugin directory
    filedelete 'pluginDirectory$''sl$'dataDirectoryPathFile
    fileappend "'pluginDirectory$''sl$'dataDirectoryPathFile" 'dataDirectoryPath$'
    # alert user
    clearinfo
    printline
    printline file copying is complete...
    printline 
    printline To finish the installation, close and then re-open Praat
   else
    # uninstall
    # if the plugin_GSUPraatTools folder exists, delete all its files, remove folder, alert user
    # otherwise do nothing, alert user
    #if ('pluginDirectoryExists' = 1)
      system_nocheck rm -f "'pluginDirectory$'"'sl$'*
      # remove all files, including any hidden files
      clearinfo
      printline
      printline deleting GSU Tools files...
      system del /Q "'pluginDirectory$'"
      system rmdir "'pluginDirectory$'"
      printline
      printline the GSU Tools installation has been removed
     #else
      # installation not found
      #clearinfo
      #printline
      #printline GSU Tools installation was not found
      #printline
      #printline ...no action taken
    #endif
  endif

endproc
