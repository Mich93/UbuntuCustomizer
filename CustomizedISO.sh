
choose=/tmp/answ 


#dialog that welcomes the user
function welcome() {

dialog --backtitle "Ubuntu 12.04 Customization" --title "Welcome" --clear --yesno "Welcome to the Ubuntu 12.04 customization process created by Stefano Mich. \nDo you want to procede with the customization?\n If you already started the process, you will now continue from the point in with you exit" 7 80
            case $? in
            0)
            selectIso
            ;;
            1)
            exitFrom welcome
            ;;
    
            255)
            exitFrom welcome
            ;;
            esac
}

#dialog that let the user choose the ubuntu 12.04 ISO file and than checks if it is an ISO file or not
function selectIso() {
resumeFrom selectIso mountSystem
    FILE=$(dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Select the ISO of Ubuntu 12.04" --fselect "/home/" 6 60)
    echo "$FILE" | grep ".*.iso"
    if test $? -ne 0   
         then 
            dialog --backtitle "Ubuntu 12.04 Customization" --title "ERROR" --clear --yesno "You are either trying to exit or the file selected is not correct. \nDo you want to select another one?" 7 80
            case $? in
            0)
            selectIso
            ;;
            1)
            exitFrom selectIso
            ;;
    
            255)
            exitFrom selectIso
            ;;
            esac
    else 
         
           dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --yesno "You selected the correct file. \nDo you want to procede with the customization?" 6 60
            case $? in
            0)
            mountSystem
            ;;
            1)
            exitFrom selectIso
            ;;
    
            255)
            exitFrom selectIso
            ;;
            esac 
          
        
            
    fi
mountSystem
}

#Procedure to mount the ubuntu system in a temporary folder
function mountSystem(){
resumeFrom mountSystem copyFolders
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now extract and mount the ubuntu system in a temporary folder. \nDo you want to procede?" 8 70
case $? in
  0)
    cd /tmp
    mkdir liveubuntu
    sudo mount -o loop $FILE /tmp/liveubuntu
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "System mounted succesfully" 5 50
    exitFrom mountSystem
    ;;
  1)
    exitFrom mountSystem
    ;;
    
  255)
    exitFrom mountSystem
    ;;
esac
copyFolders
}

#Procedure that copies the mounted system in the home folder and organizes the directories
function copyFolders(){
resumeFrom copyFolders copySquash
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now create a folder called liveubuntu in your home and then two folders in it: one called custom, which will contain the customized image and one called cd which will contain the original image. \nDo you want to procede?" 8 90
case $? in
    0)
      cd $HOME
      echo "Creating the folders" 
      mkdir liveubuntu
      cd liveubuntu
      mkdir custom
      mkdir cd
      mkdir squashfs
      echo "Copying the mounted system in cd"
      ;;
    1)
       exitFrom copyFolders
       ;;
    255)
       exitFrom copyFolders
       ;;
     esac 
copySquash
    
}
function copySquash(){
    resumeFrom copySquash moveRoot
    rsync --exclude=/casper/filesystem.squashfs -a /tmp/liveubuntu/ ~/liveubuntu/cd
    if [ $? == 127 ]
       then
        dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The package rsync is missing but necessary to continue. \nDo   you want to install it now?" 8 70
        case $? in
        0)
         sudo apt-get install rsync
         dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "rsync has been succesfully installed" 5 50
         ;;
        1)
         exitFrom copyFolders
         ;;
    
        255)
         exitFrom copyFolders
         ;;
         esac
    else
      echo ""
    fi   
    
        
    sudo modprobe squashfs
    sudo mount -t squashfs -o loop /tmp/liveubuntu/casper/filesystem.squashfs ~/liveubuntu/squashfs/
    dialog --infobox "Copying the system in custom, where you will find the future customized image\nPlease wait, it will take around 3 minutes" 6 60 ; sleep 5
    sudo cp -a ~/liveubuntu/squashfs/* ~/liveubuntu/custom
    sudo cp /etc/resolv.conf ~/liveubuntu/custom/etc
    sudo cp /etc/hosts ~/liveubuntu/custom/etc
        
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Operation completed succesfully" 5 50
  
moveRoot
  
}
#Procedure that moves the root to the custom folder
function moveRoot(){
resumeFrom moveRoot enableRepo
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now move the root to custom, so that we can work on our future customized file. \nDo you want to proceed?" 8 70
case $? in
  0)
    sudo chroot ~/liveubuntu/custom sudo mount -t proc none /proc/
    sudo chroot ~/liveubuntu/custom sudo mount -t  sysfs none /sys/
    check moveRoot
    sudo chroot ~/liveubuntu/custom sudo export HOME=/root
    if [ $? == 0 ]
      then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Operation completed succesfully. We can now proceed with the customization." 7 70
    else
      dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Error" 5 50
      exit -1
    fi
    ;;
  1)
    exitFrom moveRoot
    ;;
    
  255)
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Error, the command was not found" 5 50
    exit -1
    ;;
esac
enableRepo
}
function enableRepo(){
resumeFrom enableRepo customizeMenu
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Enable repository" --yesno "The process will now enable universe and multiverse repository. \nDo you want to proceed?" 8 70
            
      case $? in
        0)
          sudo chroot ~/liveubuntu/custom sudo apt-get install libqt4-dbus libqt4-network libqt4-xml libasound2
          sudo chroot ~/liveubuntu/custom sudo dpkg --configure -a
          echo deb http://archive.ubuntu.com/ubuntu precise main universe restricted multiverse | sudo tee -a ~/liveubuntu/custom/etc/apt/sources.list
          echo deb http://archive.ubuntu.com/ubuntu precise universe | sudo tee -a ~/liveubuntu/custom/etc/apt/sources.list
          sudo chroot ~/liveubuntu/custom sudo apt-get update
          if [ $? == 0 ]
           then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The repository has been enabled succesfully" 5 50
          else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while enabling the repo. \nDo you want to try again?" 8 70
            case $? in
             0)
               enableRepo 
             ;;
             1)
               exitFrom enableRepo
             ;;
    
             esac
            
            
          fi
         ;;
       1)
          exitMenu enableRepo
         ;;
    
       esac
dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Well done! We are now ready for customize Ubuntu. \nClick Ok to continue with the customization" 8 80
customizeMenu
}

function removeGame(){
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Remove games" --yesno "The process will now check for the presence of games. \nDo you want to proceed?" 8 70
case $? in
  0)
    sudo chroot ~/liveubuntu/custom dpkg --get-selections | grep games
    if [ $? == 0 ]
      then dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now remove the game packages. \nDo you want to proceed?" 8 70
      case $? in
        0)
          sudo chroot ~/liveubuntu/custom sudo locale-gen us_US
          sudo chroot ~/liveubuntu/custom sudo apt-get remove --purge gnome-games*
          checkMenu removeGame
          sudo chroot ~/liveubuntu/custom sudo dpkg --get-selections | grep games
          if [ $? == 1 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The game packages has been removed." 5 50
          else 
             dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while removing the games. \nDo you want to try again?" 8 70
            case $? in
             0)
               removeGame 
             ;;
             1)
               exitMenu removeGame
             ;;
    
             esac
          fi
         ;;
       1)
          exitMenu removeGame
         ;;
    
       esac
    else
      dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "There are no games installed. \nClick OK to go back to the menu." 7 70
      customizeMenu
    fi
    ;;
  1)
    exitMenu removeGame
    ;;
    
  255)
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Error, the command was not found" 5 50
    exit -1
    ;;
esac
customizeMenu
}

function installEclipse(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Install eclipse" --yesno "The process will now install eclipse. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing eclipse'
        sudo chroot ~/liveubuntu/custom sudo apt-get install eclipse
        if [ $? == 0 ]
            then echo 'Eclipse has been installed succesfully'
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing eclipse. \nDo you want to try again?" 8 70
            case $? in
             0)
               installEclipse 
             ;;
             1)
               exitMenu installEclipse
             ;;
    
             esac
            
        fi
         ;;
       1)
          exitMenu installEclipse
         ;;
    
       esac
    
customizeMenu
}
function installScribes(){
  resumeFrom installScribes addFirefoxPlugin 
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install Scribes" --yesno "The process will now install the scribes text editor. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading scribes'
        sudo chroot ~/liveubuntu/custom sudo wget http://launchpad.net/scribes/0.4/scribes-milestone1/+download/scribes-0.4-dev-build954.tar.bz2
        if [ $? == 0 ]
            then echo 'Extracting and installing scribes'
                  sudo chroot ~/liveubuntu/custom sudo tar xjf scribes-0.4-dev-build954.tar.bz2
                  checkMenu removeScribes
                  sudo chroot ~/liveubuntu/custom cd scribes-0.4-dev-build954
                  checkMenu removeScribes
                  sudo chroot ~/liveubuntu/custom sudo ./configure
                  checkMenu removeScribes
                  sudo chroot ~/liveubuntu/custom sudo make
                  checkMenu removeScribes
                  sudo chroot ~/liveubuntu/custom sudo make install
                  if [ $? == 0 ]
                       then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Scribes has been installed succesfully" 5 50
                  else
                       dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while downloading scribes. \nDo you want to try again?" 8 70
                  case $? in
                    0)
                    installScribes 
                    ;;
                    1)
                    exitMenu installScribes
                    ;;
    
                  esac
            
                  fi   
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while downloading scribes. \nDo you want to try again?" 8 70
            case $? in
             0)
               installScribes 
             ;;
             1)
               exitMenu installScribes
             ;;
    
             esac
            
        fi
         ;;
       1)
          exitMenu installScribes
         ;;
    
       esac
    
customizeMenu
}
function addFirefoxPlugin(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install Firefox flash-plugin" --yesno "The process will now install the flash plugin. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing the flash plugin'
        sudo chroot ~/liveubuntu/custom sudo apt-get install flashplugin-nonfree
        if [ $? == 0 ]
            then echo 'The flash plugin has been installed succesfully'
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing the flashplugin. \nDo you want to try again?" 8 70
            case $? in
             0)
               addFirefoxPlugin 
             ;;
             1)
               exitMenu addFirefoxPlugin
             ;;
    
             esac
            
        fi
         ;;
       1)
          exitMenu addFirefoxPlugin
         ;;
    
       esac
    
customizeMenu
}
function addPackage(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install a package" --yesno "The process will now let you install a package. \nDo you want to proceed?" 8 70
  case $? in
       0)
        dialog --backtitle 'Ubuntu 12.04 Customization' --title "install a package" --inputbox "Enter a package name." 8 70 2> $choose
        PACKAGE=$(< $choose) 
        sudo chroot ~/liveubuntu/custom sudo apt-get install $PACKAGE
        if [ $? == 0 ]
            then echo 'The package $PACKAGE has been installed succesfully'
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing the package. \nDo you want to try again?" 8 70
            case $? in
             0)
               addFirefoxPlugin 
             ;;
             1)
               exitMenu addFirefoxPlugin
             ;;
    
             esac
            
        fi
         ;;
       1)
          exitMenu addPackage
         ;;
    
       esac
    
customizeMenu
}
function removePackage(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "remove a package" --yesno "The process will now let you remove a package. \nDo you want to proceed?" 8 70
  case $? in
       0)
        dialog --backtitle 'Ubuntu 12.04 Customization' --title "install a package" --inputbox "Enter a package name." 8 70 2> $choose
        rmPACKAGE=$(< $choose)
        
        sudo chroot ~/liveubuntu/custom sudo dpkg --get-selections | grep -v deinstall | grep $rmPACKAGE
        if [ $? == 0 ]
            then sudo chroot ~/liveubuntu/custom sudo apt-get remove --purge --assume-yes $rmPACKAGE
                if [ $? == 0 ]
                   then echo 'The package $rmPACKAGE has been removed succesfully'
                else
                   dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while removing the package. \nDo you want to try again?" 8 70
                     case $? in
                        0)
                         removePackage 
                        ;;
                        1)
                        exitMenu removePackage
                        ;;
    
                        esac
            
                fi
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The package selected is not installed. \nDo you want to try with another?" 8 70
          case $? in
             0)
               removePackage 
             ;;
             1)
               exitMenu removePackage
             ;;
    
             esac
         fi
        
        
         ;;
       1)
          exitMenu addPackage
         ;;
    
       esac
    
customizeMenu
}
function addWireshark(){
   
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Wireshark" --yesno "The process will now install Wireshark. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing the wireshark'
        sudo chroot ~/liveubuntu/custom sudo apt-get install wireshark
        if [ $? == 0 ]
            then echo 'Wireshark has been installed succesfully'
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing wireshark. \nDo you want to try again?" 8 70
            case $? in
             0)
               addWireshark 
             ;;
             1)
               exitMenu addWireshark
             ;;
    
             esac
            
        fi
         ;;
       1)
          exitMenu addWireshark
         ;;
    
       esac
    
customizeMenu
}
function changeBack(){
  resumeFrom changeBack 
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Change Background" --yesno "The process will now enable you to change the background. \nDo you want to proceed?" 8 70
            
      case $? in
        0)
          IMAGE=$(dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Select an image to set as background" --fselect "home/" 8 60)
          echo $IMAGE 
          if [ -f "$IMAGE" ]
             then sudo chroot ~/liveubuntu/custom sudo gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set -t string /desktop/gnome/background$IMAGE /usr/share/backgrounds$IMAGE
           if [ $? == 0 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The backgroung has been changed." 8 80
           else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while changing the background. \nDo you want to try again?" 8 70
            case $? in
             0)
               changeBack 
             ;;
             1)
               exitMenu changeBack
             ;;
    
             esac
            
            fi
         else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The file you selected is not valid \nDo you want to try again?" 8 70
            case $? in
             0)
               changeBack 
             ;;
             1)
               exitMenu changeBack
             ;;
    
             esac
            
            
          fi
         ;;
       1)
          exitMenu changeBack
         ;;
    
       esac
customizeMenu
}
function clean() {
  dialog --backtitle "Ubuntu 12.04 Customization" --title "Clean" --clear --msgbox "The process will now clean the system" 5 50
  sudo chroot ~/liveubuntu/custom sudo apt-get clean
  check clean
  sudo chroot ~/liveubuntu/custom sudo rm -rf /tmp/*
  check clean
  sudo chroot ~/liveubuntu/custom sudo rm -f /etc/hosts /etc/resolv.conf
  check clean
  sudo chroot ~/liveubuntu/custom sudo umount /proc/
  check clean
  sudo chroot ~/liveubuntu/custom sudo umount /sys/
  check clean
  dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "System has been cleaned." 5 50
  setupIso
}
function setupIso() {
dialog --backtitle "Ubuntu 12.04 Customization" --title "Clean" --clear --msgbox "The process will now setup the new customized ISO file" 5 50
sudo chmod +w ~/liveubuntu/cd/casper/filesystem.manifest
check setupIso
sudo chroot ~/liveubuntu/custom sudo dpkg-query -W --showformat='${Package} ${Version}\n' > ~/liveubuntu/cd/casper/filesystem.manifest
check setupIso
sudo cp ~/liveubuntu/cd/casper/filesystem.manifest ~/liveubuntu/cd/casper/filesystem.manifest-desktop
check setupIso
sudo mksquashfs ~/liveubuntu/custom ~/liveubuntu/cd/casper/filesystem.squashfs
check setupIso
sudo rm ~/liveubuntu/cd/md5sum.txt
check setupIso
sudo -s (cd ~/liveubuntu/cd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)
check setupIso
}

function customizeMenu() {
dialog --backtitle 'Ubuntu 12.04 Customization' --title "Choose an option" --menu "Choose a task or end the customization." 14 65 6 1 "Remove games" 2 "Install eclipse" 3 "Install scribes editor" 4 "Install flash-plugin for Firefox" 5 "Install wireshark network tool" 6 "Install a package" 7 "Remove a package" 8 "Change default background" 9 "End customization" 2> $choose
     WHAT=$(< $choose)
     case $WHAT in
       1) removeGame ;;
       2) installEclipse ;;
       3) installScribes ;;
       4) addFirefoxPlugin ;;
       5) addWireshark ;;
       6) addPackage ;;
       7) removePackage ;;
       8) changeBack ;;
       9) clean ;; 
       *)  exitFrom customizeMenu ;;
       255)  exitFrom customizeMenu ;;
esac

}

#Procedure to exit from any process whenever the user wants to 
function exitFrom(){
if test $? -ne 0   
         then 
            dialog --backtitle "Ubuntu 12.04 Customization" --title "ERROR" --clear --yesno "Do you really want to exit?" 6 60
            case $? in
            0)
            dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Goodbye :-)" 5 50
            exit -1
            ;;
            1)
            $1
            ;;
    
            255)
            dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Error, the command was not found" 5 50
            exit -1
            ;;
            esac
fi
}
function exitMenu(){
if test $? -ne 0   
         then 
            dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --yesno "Do you really want to go back to the menu?" 6 60
            case $? in
            0)
            customizeMenu
            ;;
            1)
            $1
            ;;
    
            255)
            dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Error, the command was not found" 5 50
            exit -1
            ;;
            esac
fi
}
function check(){
         if [ $? == 0 ]
            then echo 
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while doing the last step. \nPlease make sure your internet connection is working. \n Do you want to try again?" 8 70
            case $? in
             0)
               $1 
             ;;
             1)
               exitFrom $1
             ;;
    
             esac
          fi
}
function checkMenu(){
         if [ $? == 0 ]
            then echo 
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while doing the last step. \nPlease make sure your internet connection is working. \n Do you want to try again?" 8 70
            case $? in
             0)
               $1 
             ;;
             1)
               exitMenu $1
             ;;
    
             esac
          fi
}
#Procedure to resume the operations from the last point
function resumeFrom() {
  cd ~
  ls | grep -q functionsLog.txt
  if test $? -ne 0
    then touch functionsLog.txt
  fi
  
  grep $1 functionsLog.txt
  if test $? -ne 0   
     then 
       log $1
  else
       $2
  fi 

}

function log(){
  echo "$1" >> functionsLog.txt
}


clean
exit 0


