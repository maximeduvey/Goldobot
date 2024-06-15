#!/bin/bash

### This script is for deploying our environment and it's subfolder
### so that we can't start working and compiling with them without searching what is missing.
#
### it's also a good way to save "state" of project for specific version

#               ／＞　 フ
#             | 　_　_| 
#           ／` ミ__^ノ 
#          /　　　　 |
#         /　 ヽ　　 ﾉ       
#        /　　 |　|　|           
# ／￣|　　 |　|　|                  
# (￣ヽ＿_  ヽ_)__)         
# ＼二) "𝘳𝘦𝘢𝘥𝘺 𝘰𝘳 𝘯𝘰𝘵, 𝘩𝘦𝘳𝘦 𝘪 𝘤𝘰𝘮𝘦.

source Include.sh

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
    Logger $YELLOW "install_apt_and_pip_dependency"
    run_command_and_exist_if_fail sudo apt-get install -y "${apt_packages[@]}"
    run_command_and_exist_if_fail "${command_python_pip_install[@]}" "${python_packages[@]}"
    Logger $GREEN "Success"
}

#!/bin/bash

# Function to check if libraries are installed and ask for confirmation to uninstall if they are
check_and_blacklisted_packages_and_uninstall() {
    # List of libraries to check
    
    # Iterate over each library and check if it is installed
    for library in "${blacklisted_packages[@]}"; do
        if dpkg -l | grep -q "$library"; then
            Logger $RED "$library is installed."
            # Call ask_confirmation function (assumes this function is defined elsewhere)
            if ask_confirmation "Blacklisted package $library is detected, do you want to uninstall it?" "n"; then
                run_command_and_exist_if_fail sudo apt-get remove --purge -y "$library"
                Logger $WHITE "$library has been uninstalled."
            else
                Logger $GREEN "$library was not uninstalled."
            fi
        else
             Logger $BLUE "$library is not installed."
        fi
    done
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
    # set path to protobuf include files
    export PROTOBUF_INCLUDE_PATH="$CURRENT_FOLDER/$PROTOBUF_FOLDER/src/google/protobuf/"
    export PATH=$PATH:$PROTOBUF_INCLUDE_PATH
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
    sync_projects
    if ! ask_confirmation "Do you want to skip APT and PIP instalation ?" "y"; then
        install_apt_and_pip_dependency
    fi
    install_protobuf_dependency
    check_and_blacklisted_packages_and_uninstall
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
