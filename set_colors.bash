# Put .colors.tsv in your home directory
# Put Color_Names.webloc in your Desktop directory
# Add the following functions to your .bash_profile
#
# Change colors and fonts of the OSX terminal from the command line:
# 
# $ set_foreground_color lime green
# $ set_font "Oxygen Mono" 12


#
# Colors for Apple Terminal
#
alias view_colors='open "${HOME}/Desktop/Color_Names.webloc"'

function list_colors {
    cat ${HOME}/.colors.tsv
}

function grep_apple_color {
    grep "$*" ${HOME}/.colors.tsv
}

# A colorname starts with newline or ',' and ends with a ',' or tab since there may be
# comma separated variations on a colorname at the start of a line
# example:
#   black	#000000	0	0	0	{0, 0, 0}
#   misty rose,MistyRose	#ffe9e6	255	233	230	{65535, 59881, 59110}
#
# Replacing tabs with '<t>' and spaces with '_':
#   misty_rose,MistyRose<t>#ffe9e6<t>255<t>233<t>230<t>{65535,_59881,_59110}
#   1                      2         3     4     5     \_ 6:apple_color ___/
# RETURN the three digits in braces at the end (6th tab separated field)
# field 2 is the hex color
# fields 2,4,5 are the equivalent RGB colors
# field 6 is composed of each RGB value * 257
function get_apple_color {
    grep -v '^#' ${HOME}/.colors.tsv | egrep -i "(^|,)$*(,|\t)" | cut -f 6
}

function set_foreground_color {
    color=$(get_apple_color $*)
    if [ "$color" != "" ] ; then
        osascript -e "tell application \"Terminal\" to set normal text color of window 1 to ${color}"
        echo "Normal text color set to: $*: $color"
    fi
}    

function set_background_color {
    color=$(get_apple_color $*)
    if [ "$color" != "" ] ; then
        osascript -e "tell application \"Terminal\" to set background color of window 1 to ${color}"
        echo "Background color set to: $*: $color"
    fi
}    

function set_theme {
    set_foreground_color $1
    set_background_color $2
}    

function set_font {
    osascript -e "tell application \"Terminal\" to set the font name of window 1 to \"$1\""
    osascript -e "tell application \"Terminal\" to set the font size of window 1 to $2"
}
