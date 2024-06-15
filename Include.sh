#!/bin/bash

### this script has no execution on it's own, it's an include file 
### for common function for my scripts

#           __..--''``---....___   _..._    __
# /// //_.-'    .-/";  `        ``<._  ``.''_ `. / // /
#///_.-' _..--.'_    \                    `( ) ) // //
#/ (_..-' // (< _     ;_..__               ; `' / ///
# / // // //  `-._,_)' // / ``--...____..-' /// / //

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m' # No Color
Logger() {
    color=$1
    echo -e "${color}$2${RESET}"
}

### List of variables and Name used ###

CURRENT_FOLDER=$PWD
Logger $BLUE "deploying at $CURRENT_FOLDER"
BUILD_FOLDER_NAME="build"

# these Libraries are blacklisted, they will prevent project compilation if present
local blacklisted_packages=("libprotobuf-dev")

# list of apt dependcy for the project
apt_packages=(protobuf-compiler libprotobuf-dev libzmq3-dev )

# list of python module necessary for the project, should be updated by the next person
python_packages=(numpy opencv-python-headless)

command_python_pip_install=(python3 -m pip install)

# list of cmake project that need to be compiled (clearly nearly goldobot projects)
# "goldo_strat" et "goldobot_ihm" sont des projets python
goldobots_submodules=("goldo_broker_cpp" )
GOLDO_GR_STM32_FOLDER_NAME="goldo_GR_SW4STM32"
GOLDOBOT_IHM_FOLDER_NAME="goldobot_ihm"
GOLDOBOT_IHM_REQUIREMENT_NAME="requirements.txt"

# protobuf
PROTOBUF_TAR_NAME=protobuf-cpp-3.6.1.tar.gz
PROTOBUF_REPO_URL=https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/$PROTOBUF_TAR_NAME
PROTOBUF_FOLDER=protobuf-3.6.1

##############################
### GENERIC tools function ###
##############################

# this command will just execute command line and exit if the line fail
# it's to stop when a step fail
function run_command_and_exist_if_fail {
    # Execute the command
    "$@"
    if [ $? -ne 0 ]; then
        Logger $RED "Error: \"$*\" failed !"
        exit 1
    fi
}

# this function ask the passed message in parameter and return if the user choosed y or n
ask_confirmation() {
    local message="$1"
    local default_choice="$2"
    local choice

    # Display the message and default choice
    Logger $YELLOW "$message [$default_choice]: "

    # Read user input
    read -r choice

    # Use default choice if input is empty
    choice="${choice:-$default_choice}"

    # Check if choice is 'y' or 'n'
    case "$choice" in
        [yY]) return 0 ;;
        [nN]) return 1 ;;
        *) return 1 ;;  # Default to 'no' if input is not recognized
    esac
}
