# rwin
Remote Window: Perl script to open a color-coded ssh session to another system.
Variants of the script exist to create a connection through 
- Gnome-Terminal 
- X-terminal
- MacOS Terminal

For a Mac Terminal profile version of this command bring in information from:
https://www.ict4g.net/adolfo/notes/2014/07/16/change-osx-terminal-settings-from-command-line.html

## macTerm
Steps to do:

Parse colors from colors.tsv, used to convert names to apple colors.

Convert colors in rwin-data to apple colors, using data from colors.tsv to convert names if needed.

Create a terminal window
- activate it
- set colors
- run login command

##Links that may be of use:
https://apple.stackexchange.com/questions/156544/how-to-open-a-shell-script-in-a-new-terminal-window-and-run-it-with-administrato

This worked to open a window
https://stackoverflow.com/questions/48591219/open-multiple-terminal-windows-mac-using-bash-script

Open a window and run a command
https://stackoverflow.com/questions/50476752/macos-bash-terminal-command-to-open-terminal-change-directory-and-run-command
osascript -e "tell application \"Terminal\" to do script \"cd /Users/tanakak/bin && ~/src/git/github/rwin/cmd.sh\""

Open a window and run a command
https://stackoverflow.com/questions/31524499/open-terminal-from-shell-and-execute-commands
osascript -e 'tell application "Terminal" to do script "cd /tmp;pwd"'

Programmatically set theme for a terminal
https://apple.stackexchange.com/questions/344401/how-to-programatically-set-terminal-theme-profile

## Color Resources
Website with color display for trying different RGB values: https://www.htmlcsscolor.com/hex/66B348
