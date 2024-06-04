#!/bin/bash

#               ／＞　 フ
#             | 　_　_| 
#           ／` ミ__^ノ 
#          /　　　　 |
#         /　 ヽ　　 ﾉ       
#        /　　 |　|　|           
# ／￣|　　 |　|　|                  
# (￣ヽ＿_  ヽ_)__)         
# ＼二) "𝘳𝘦𝘢𝘥𝘺 𝘰𝘳 𝘯𝘰𝘵, 𝘩𝘦𝘳𝘦 𝘪 𝘤𝘰𝘮𝘦.

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

# list of apt dependcy for the project
apt_packages=(protobuf-compiler libprotobuf-dev protobuf-java libzmq3-dev )

# list of python module necessary for the project, should be updated by the next person
python_packages=("numpy")

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

#################
### FUNCTIONS ###
#################

 # Sync all Git submodules
sync_projects () {
    Logger $WHITE "sync_projects"
    git submodule sync
    git submodule update --init --recursive
    Logger $GREEN "Success"
}

# will install apt-get and pip / python dependency 
install_apt_and_pip_dependency() {
    Logger $YELLOW "sync_projects"
    run_command_and_exist_if_fail sudo apt-get install -y "${apt_packages[@]}"
    run_command_and_exist_if_fail "${command_python_pip_install[@]}" "${python_packages[@]}"
    Logger $GREEN "Success"
}

# Install the specific protobuf version and make it 
install_protobuf_dependency() {
    Logger $WHITE "install_protobuf_dependency"

    if [ -d "$PROTOBUF_FOLDER" ] && ! ask_confirmation "$PROTOBUF_FOLDER already exists, do you want to overwrite it" "n"; then
        Logger $GREEN "Protobuf skipped"
        return
    fi

    rm -rf $PROTOBUF_FOLDER

    run_command_and_exist_if_fail wget $PROTOBUF_REPO_URL && \
    run_command_and_exist_if_fail tar -xzf $PROTOBUF_TAR_NAME && \
    run_command_and_exist_if_fail rm $PROTOBUF_TAR_NAME
    run_command_and_exist_if_fail cd $PROTOBUF_FOLDER && \
    run_command_and_exist_if_fail ./configure && \
    run_command_and_exist_if_fail make && \
    run_command_and_exist_if_fail sudo make install && \
    run_command_and_exist_if_fail sudo ldconfig

    protobuf_version=$(protoc --version)
    Logger $GREEN "Success! protobuf version is $protobuf_version"
    run_command_and_exist_if_fail cd $CURRENT_FOLDER
}


# instal all external dependency one after the other (like protobuf)
install_external_dependencies() {
    Logger $WHITE "---- install_external_dependencies ----"
    install_protobuf_dependency 
}

compile_goldo_GR_SW4STM32() {
    Logger $WHITE "$GOLDO_GR_STM32_FOLDER_NAME"
    run_command_and_exist_if_fail cd $GOLDO_GR_STM32_FOLDER_NAME
    if [ -d "$BUILD_FOLDER_NAME" ] && ! ask_confirmation "$BUILD_FOLDER_NAME folder already exists for $GOLDO_GR_STM32_FOLDER_NAME, do you want to overwrite it" "n"; then
        Logger $GREEN "$1 skipped"
        run_command_and_exist_if_fail cd $CURRENT_FOLDER
        return
    fi
    run_command_and_exist_if_fail mkdir -p $BUILD_FOLDER_NAME
    run_command_and_exist_if_fail cd $BUILD_FOLDER_NAME
    run_command_and_exist_if_fail cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain/gcc-stm32f303xe.toolchain ..
    run_command_and_exist_if_fail cmake --build .
    run_command_and_exist_if_fail make
    run_command_and_exist_if_fail cd $CURRENT_FOLDER
    Logger $GREEN "$GOLDO_GR_STM32_FOLDER_NAME installed successfully"
}

# generic step to compile a cmake module
compile_module() {
    Logger $WHITE "$1"
    run_command_and_exist_if_fail cd $1
    if [ -d "$BUILD_FOLDER_NAME" ] && ! ask_confirmation "$BUILD_FOLDER_NAME folder already exists for $1, do you want to overwrite it" "n"; then
        Logger $GREEN "$1 skipped"
        run_command_and_exist_if_fail cd $CURRENT_FOLDER
        return
    fi
    run_command_and_exist_if_fail rm -rf $BUILD_FOLDER_NAME
    run_command_and_exist_if_fail mkdir -p $BUILD_FOLDER_NAME
    run_command_and_exist_if_fail cd $BUILD_FOLDER_NAME
    run_command_and_exist_if_fail cmake ../
    run_command_and_exist_if_fail make
    run_command_and_exist_if_fail cd $CURRENT_FOLDER
    Logger $GREEN "$1 Success !"
}

install_goldobot_ihm() {
    Logger $WHITE "installing $GOLDOBOT_IHM_FOLDER_NAME"
    run_command_and_exist_if_fail cd $GOLDOBOT_IHM_FOLDER_NAME
    run_command_and_exist_if_fail "${command_python_pip_install[@]}" -r $GOLDOBOT_IHM_REQUIREMENT_NAME

    run_command_and_exist_if_fail cd $CURRENT_FOLDER
    Logger $GREEN "$GOLDOBOT_IHM_FOLDER_NAME Success !"
    Logger $MAGENTA "run python3 main.py --robot-ip 192.168.0.212 --config-path config/coupe_2024_opti"
    Logger $MAGENTA "run comm_uart executable on the raspbery pi"
}

# for each submodule/project to compile will proceed with the same steps
parse_all_module_for_compilation() {
    Logger $WHITE "---- parse_all_module_for_compilation ----"
    compile_goldo_GR_SW4STM32
    # Print the submodules
    for submodule in "${goldobots_submodules[@]}"; do
        echo "$submodule"
        compile_module $submodule
    done

    install_goldobot_ihm
}

# it's a main
main () {
    if ! ask_confirmation "Do you want to skip APT and PIP instalation ?" "y"; then
        install_apt_and_pip_dependency
    fi
    install_protobuf_dependency
    parse_all_module_for_compilation

    Logger $GREEN "#########################################"
    Logger $GREEN "--- EVERYTHING Installed successfully ---"
    Logger $GREEN "#########################################"
}

# just a tmp test func, to delete later
test() {
    run_command_and_exist_if_fail echo "hey"
    run_command_and_exist_if_fail Logger $GREEN "Ehhlo"
    run_command_and_exist_if_fail sudo ls -la
}

echo "hello"
main
