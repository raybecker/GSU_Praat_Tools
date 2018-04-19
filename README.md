# GSU_Praat_Tools

These scripts were from Professor Michael Owren (deceased). I was his lab manager from 2005/06 at Georgia State University in Atlanta, and worked on some of these scripts that he later published here:
Owren, M. J. (2008). GSU Praat Tools: Scripts for modifying and analyzing sounds using Praat acoustics software. Behavior research methods, 40(3), 822-829.

However, after he died, the google site where he was curating the scripts seems to have disappeared, so I am providing my copies here for my use and others, who might find them useful. I will continue curating these scripts here, answering questions, and who knows, maybe a GSU_PraatTools 2.0 might appear in the not-so-near future.

The following is what Michael had written as far as installation and usage:

INSTALLING GSU PRAAT TOOLS 1.9

1) The Praat Tools folder is downloaded in zipped form. After unzipping make sure there is a folder called GSUPraatTools1.9 directly on your desktop. The behavior of unzipping programs can vary, so move or copy this folder as necessary if it is left inside a different shell folder and not on the desktop itself. As the scripts are developed and maintained using Mac OSX, unzipping on a Windows XP machine can leave extraneous folders for files that can be deleted (includling a _MacOSX folder on the desktop, and a _DSTOR file inside the GSUPraatTools1.9 folder).

2) Open Praat, and invoke the <Open Praat script...> command in the Praat pull-down menu, navigate to the _InstallGSUTools.praat script in GSUPraatTools1.9 folder

- this script should appear as the first item listed when the folder is opened, so long as its contents are listed in alphabetical order.
- use the <Run> command to invoke the script
- select the appropriate operating system and set the name of the desktop for your computer and account (on English-language computers, usually just "Desktop")
- Hit <OK> or <Apply> to run the script

3) Close and immediately reopen Praat. You should now have various new buttons and menus installed by GSU Tools.

The scripts are developed and maintained using OSX on a Mac, which means that when the archive is unzipped in a Windows environment, an extra file or two may appear related to Mac bookkeeping. These folders and files can have names like <_MACOSX> and <.DS_STORE>, and can be safely deleted.


UNINSTALLING GSU PRAAT TOOLS 1.9

To uninstall the scripts, run the installation script as described above, but select the <uninstall> option


WHAT INSTALLATION DOES

The install script works by detecting whether the operating system involved is Microsoft’s Windows XP or Apple’s OSX, in order to be able to create pathnames in the proper format. The destination for the scripts is the <Praat> preferences folder in the user’s account, which is at a level “below” the desktop. The install script creates a directory called "plugin_GSUPraatTools" in the preferences directory and copies all the routines into that directory. If this plugin directory already exists, its contents are deleted before copying begins. Once the scripts are in place in the plugin folder,  <Praat> will access the “setup.praat” file it contains each time the program is started. The <GSU Tools> script-related buttons and menus will then appear in appropriate locations among the <Praat> buttons and menus.

The install program “uninstalls” by deleting the scripts and plugin directory from the Praat preferences directory (but not from the desktop).


MANUAL INSTALLATION

If installation fails or a different operating system is being used, installation also works by hand.

1) find the Praat preferences directory

Locate the <Praat> preferences folder by typing the command <echo 'preferencesDirectory$'> into a new Praat script window created using the new Praat script command from the Praat menu in the Objects window. Run this one command to get the directly location (do not include greater- and less-than symbols)

- for Mac OSX, it should be /Users/youraccount/Library/Preferences/Praat Prefs/.
- for Windows XP, it should be C:\Documents and Settings\youraccount\Praat\.

See “preferences directory” in the <Praat> Help Manual for further information.

2) Create the plug-in directory needed

Create a <plugin_GSUPraatTools> folder in the preferences directory. Copy all files from <GSUPraatTools> folder on the desktop into the plug-in folder. 
3) Edit two critical text files in the plugin directory…

The scripts need to be given the name of the Desktop directory as well as the pathname to the <Praat_Data> directory. This information is placed in two corresponding text files in the plugin directory. To complete manual installation, edit these text files as appropriate for your operating system. Note that these files contain no formatting information whatsoever and have no extension. For example, do not save them as either <.rtf> or <.doc> files.

desktopNameFile must contain the name of the desktop on the first line. That typically means the word “Desktop” on the first line. Edit this file accordingly if the desktop has a different name. 

dataDirectoryPathFile must contain the pathname to the default folder used for reading and writing sounds, label files, and data files. Edit this file as needed so that the first line in the file specifies the correct pathname for the Praat_Data folder on your desktop.

- for OSX, this pathname is… /Users/youraccount/Desktop/Praat_Data
- for Windows, this pathname is… C:\Documents and Settings\youraccount\Desktop\Praat_Data

<GSU Tools> can be completely uninstalled by manually deleting the plugin_GSUPraatTools directory and the Praat_Data directory on the desktop.

4) Close and then restart <Praat>.


TROUBLESHOOTING

Make sure of the following…

1) a file called <plugin_GSUPraatTools> exists in the Praat Preferences directory
2) all scripts have been copied from the <GSUPraatTools> folder have been copied over 
3) this is the only such file present; if there is another file that begins with “plugin,” rename it


USER MANUAL
A user manual is included in the GSUPraatTools1.9 folder as a pdf file. It includes lots of helpful information and should be retrieved, read, and kept handy for consultation later.
