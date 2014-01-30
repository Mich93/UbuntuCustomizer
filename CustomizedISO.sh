
choose=/tmp/answ 


#dialog that welcomes the user
function welcome() {
dialog --backtitle "Ubuntu 12.04 Customization" --title "Welcome" --clear --yesno "Welcome to the Ubuntu 12.04 customization process created by Stefano Mich. \nDo you want to procede with the customization?\n " 9 80
            case $? in
            0)
            checkResume
            
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
            dialog --backtitle 'Ubuntu 12.04 Customization' --title "Folder name" --inputbox "Enter the name of the folder which will be stored in the home and will contain all the data" 8 90 2> $choose
        if [ $? == 0 ]
            then fold=$(< $choose)
        else exitFrom selectIso
        fi
            
            ;;
            1)
            exitFrom selectIso
            ;;
    
            255)
            exitFrom selectIso
            ;;
            esac 
          
        
            
    fi
writeForResume selectIso
}

#Procedure to mount the ubuntu system in a temporary folder
function mountSystem(){
resumeFrom mountSystem copyFolders
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now extract and mount the ubuntu system in a temporary folder. \nDo you want to procede?" 8 70
case $? in
  0)
    cd /tmp
    mkdir $fold
    sudo mount -o loop $FILE /tmp/$fold
    check mountSystem
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "System mounted succesfully" 5 50
    checkCtrlC mountSystem
   
    ;;
  1)
    exitFrom mountSystem
    ;;
    
  255)
    exitFrom mountSystem
    ;;
esac
writeForResume mountSystem
}

#Procedure that copies the mounted system in the home folder and organizes the directories
function copyFolders(){
resumeFrom copyFolders copySquash
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now create a folder called $fold in your home and then two folders in it: one called custom, which will contain the customized image and one called cd which will contain the original image. \nDo you want to procede?" 8 90
case $? in
    0)
      cd $HOME
      echo "Creating the folders" 
      mkdir $fold
      cd $fold
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
writeForResume copyFolders
}
function copySquash(){
    resumeFrom copySquash moveRoot
    rsync --exclude=/casper/filesystem.squashfs -a /tmp/$fold/ ~/$fold/cd
    if [ $? == 127 ]
       then
        dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The package rsync is missing but necessary to continue. \nDo   you want to install it now?" 8 70
        case $? in
        0)
         sudo apt-get install rsync
         dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "rsync has been succesfully installed" 5 50
         checkCtrlC copySquash
         ;;
        1)
         exitFrom copySquash
         ;;
    
        255)
         exitFrom copySquash
         ;;
         esac
    else
      echo ""
    fi   
    
        
    sudo modprobe squashfs
    sudo mount -t squashfs -o loop /tmp/$fold/casper/filesystem.squashfs ~/$fold/squashfs/
    dialog --infobox "Copying the system in custom, where you will find the future customized image\n Please wait, it will take around 3 minutes" 6 60 ; sleep 5
    case $? in
         255)
         exitFrom copySquash
         ;;
    esac
    sudo cp -a ~/$fold/squashfs/* ~/$fold/custom
    sudo cp /etc/resolv.conf ~/$fold/custom/etc
    sudo cp /etc/hosts ~/$fold/custom/etc
        
    dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Operation completed succesfully" 5 50
    checkCtrlC copySquash
  

writeForResume copySquash  
}
#Procedure that moves the root to the custom folder
function moveRoot(){
resumeFrom moveRoot enableRepo
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now move the root to custom, so that we can work on our future customized file. \nDo you want to proceed?" 8 70
case $? in
  0)
    sudo chroot ~/$fold/custom sudo mount -t proc none /proc/
    check moveRoot
    sudo chroot ~/$fold/custom sudo mount -t  sysfs none /sys/
        
    if [ $? == 0 ]
      then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Operation completed succesfully. Click OK to continue" 7 70
      checkCtrlC moveRoot
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
writeForResume moveRoot
}

#Procedure that enables all the possible repositories
function enableRepo(){
resumeFrom enableRepo customizeMenu
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Enable repository" --yesno "The process will now enable universe and multiverse repository. \nDo you want to proceed?" 8 70
            
      case $? in
        0)
          sudo chroot ~/$fold/custom sudo apt-get install libqt4-dbus libqt4-network libqt4-xml libasound2
          sudo chroot ~/$fold/custom sudo dpkg --configure -a
          sudo chroot ~/$fold/custom sudo locale-gen us_US
          sudo rm -f ~/$fold/custom/etc/apt/sources.list
           echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
           echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb http://us.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
           echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
           echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" | sudo tee -a ~/$fold/custom/etc/apt/sources.list
          sudo chroot ~/$fold/custom sudo apt-get update
          dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The repository has been enabled succesfully" 5 50
          checkCtrlC enableRepo
         ;;
       1)
          exitMenu enableRepo
         ;;
    
       esac
dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Well done! We are now ready for customizing Ubuntu. \nClick Ok to continue with the customization" 8 80
writeForResume enableRepo
}
#Procedure that removes the game packages
function removeGame(){
dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Remove games" --yesno "The process will now check for the presence of games. \nDo you want to proceed?" 8 70
case $? in
  0)
    sudo chroot ~/$fold/custom dpkg --get-selections | grep games
    if [ $? == 0 ]
      then dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The process will now remove the game packages. \nDo you want to proceed?" 8 70
      case $? in
        0)
          sudo chroot ~/$fold/custom sudo locale-gen us_US
          sudo chroot ~/$fold/custom sudo apt-get remove --purge gnome-games*
          checkMenu removeGame
          sudo chroot ~/$fold/custom sudo dpkg --get-selections | grep games
          if [ $? == 1 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The game packages has been removed." 5 50
            checkCtrlC removeGame
          else 
             dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Error" --yesno "There has been an error while removing the games. \nDo you want to try again?" 8 70
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
      checkCtrlC mountSystem
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
#Procedure that install eclipse
function installEclipse(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Install eclipse" --yesno "The process will now install eclipse. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing eclipse'
        sudo chroot ~/$fold/custom sudo apt-get install eclipse
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
#Procedure that install Netbeans
function installNetbeans(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install Scribes" --yesno "The process will now install the scribes text editor. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing Netbeans'
        sudo chroot ~/$fold/custom sudo apt-get install netbeans
        if [ $? == 0 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Netbeans has been installed succesfully" 5 50
            checkCtrlC installNetbeans
        else
           dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing Netbeans. \nDo you want to try again?" 8 70
              case $? in
                 0)
                 installNetbeans 
                 ;;
                 1)
                 exitMenu installNetbeans
                 ;;
    
                 esac
            
                fi   
         ;;
       1)
          exitMenu installNetbeans
         ;;
       255)
         exitMenu installNetbeans
         ;;
    
       esac
    
customizeMenu
}
#Procedure that installs the flash plugin for Firefox
function addFirefoxPlugin(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install Firefox flash-plugin" --yesno "The process will now install the flash plugin. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing the flash plugin'
        sudo chroot ~/$fold/custom sudo apt-get install flashplugin-nonfree
        if [ $? == 0 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The flash plugin has been installed succesfully" 5 50 
            checkCtrlC addFirefoxPlugin
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
#Procedure that let the user install a package
function addPackage(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "install a package" --yesno "The process will now let you install a package. \nDo you want to proceed?" 8 70
  case $? in
       0)
        dialog --backtitle 'Ubuntu 12.04 Customization' --title "install a package" --inputbox "Enter a package name." 8 70 2> $choose
        if [ $? == 0 ]
            then PACKAGE=$(< $choose)
        else exitMenu addPackage
        fi
        sudo chroot ~/$fold/custom sudo dpkg --get-selections | grep -v deinstall | grep $PACKAGE
        if [ $? == 0 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "The package is already installed. \nDo you want to try with another one ?" 8 70
            case $? in
             0)
               addPackage
             ;;
             1)
               exitMenu addPackage
             ;;
    
             esac
        else 
           sudo chroot ~/$fold/custom sudo apt-get install $PACKAGE
           if [ $? == 0 ]
              then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The package has been installed succesfully." 8 80
              checkCtrlC addPackage
           else
              dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing the package. \nDo you want to try again?" 8 70
            case $? in
             0)
               addPackage 
             ;;
             1)
               exitMenu addPackage
             ;;
             255)
               exitMenu addPackage
             ;;
    
             esac
            fi
        fi
         ;;
       1)
          exitMenu addPackage
         ;;
       255)
          exitMenu addPackage
         ;;
    
       esac
    
customizeMenu
}
#Procedure that shows the packages to the user  and let him remove one
function removePackage(){
  
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "remove a package" --yesno "The process will now let you remove a package. \nDo you want to proceed?" 8 70
  case $? in
       0)
        sudo chroot ~/$fold/custom sudo dpkg --get-selections | grep -v deinstall > ~/$fold/custom/packages.txt
        dialog --backtitle 'Ubuntu 12.04 Customization' --title "Packages installed. /n Click Esci to continue and input the package you want to remove." --textbox ~/$fold/custom/packages.txt 40 100
        dialog --backtitle 'Ubuntu 12.04 Customization' --title "remove a package" --inputbox "Enter a package name." 8 70 2> $choose
        if [ $? == 0 ]
            then rmPACKAGE=$(< $choose)
        else exitMenu removePackage
        fi
        
        sudo chroot ~/$fold/custom sudo dpkg --get-selections | grep -v deinstall | grep $rmPACKAGE
        if [ $? == 0 ]
            then sudo chroot ~/$fold/custom sudo apt-get remove --purge --assume-yes $rmPACKAGE
                if [ $? == 0 ]
                   then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The package has been removed succesfully." 8 80
                   checkCtrlC removePackage
                else
                   dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while removing the package. \nDo you want to try again?" 8 70
                     case $? in
                        0)
                         removePackage 
                        ;;
                        1)
                        exitMenu removePackage
                        ;;
                        255)
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
              255)
               exitMenu removePackage
              ;;
             esac
         fi
        
        
         ;;
       1)
          exitMenu removePackage
         ;;
    
       esac
sudo rm -f ~/$fold/custom/packages.txt    
customizeMenu
}
#Procedure that let the user install wireshark
function addWireshark(){
   
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Wireshark" --yesno "The process will now install Wireshark. \nDo you want to proceed?" 8 70
  case $? in
       0)
        echo 'Downloading and installing the wireshark'
        sudo chroot ~/$fold/custom sudo apt-get install wireshark
        if [ $? == 0 ]
            then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Wireshark network toll has been installed succesfully." 8 80
            checkCtrlC addWireshark
        else
            dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while installing wireshark. \nDo you want to try again?" 8 70
            case $? in
             0)
               addWireshark 
             ;;
             1)
               exitMenu addWireshark
             ;;
             255)
               exitMenu addWireshark
             ;;
                            
    
             esac
            
        fi
         ;;
       1)
          exitMenu addWireshark
         ;;
       255)
           exitMenu addWireshark          
         ;;
                  
       esac
    
customizeMenu
}
#Procedure that let the user change the background
function changeBack(){
  resumeFrom changeBack 
  dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Change Background" --yesno "The process will now enable you to change the background. \nDo you want to proceed?" 8 70
            
      case $? in
        0)
          choose=$(dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "Select an image to set as background" --fselect "/home/stefano/Scaricati/" 8 60)
           if [ $? == 0 ]
            then   sudo chroot ~/$fold/custom sudo gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set -t string /desktop/gnome/background$choose /usr/share/backgrounds$choose
               if [ $? == 0 ]
                  then dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The backgroung has been changed." 8 80
                  checkCtrlC changeBack
               else
                      dialog --backtitle "Ubuntu 12.04 Customization" --stdout --title "" --yesno "There has been an error while changing the background. \nDo you want to try again?" 8 70
                   case $? in
                     0)
                     changeBack 
                     ;;
                     1)
                     exitMenu changeBack
                     ;;
                     255)
                     exitMenu changeBack
                     ;;
        
                     esac
            
                 fi
          else exitMenu changeBack
          fi
          
         ;;
       1)
          exitMenu changeBack
         ;;
       255)
          exitMenu changeBack
         ;;
    
       esac
customizeMenu
}
#Procedure that cleans the system
function clean() {
  resumeFrom clean
  dialog --backtitle "Ubuntu 12.04 Customization" --title "Clean" --clear --msgbox "The process will now clean the system" 6 60
  checkCtrlC clean
  sudo chroot ~/$fold/custom sudo apt-get clean
  check clean
  sudo chroot ~/$fold/custom sudo rm -rf /tmp/*
  check clean
  sudo chroot ~/$fold/custom sudo rm -f /etc/hosts /etc/resolv.conf
  check clean
  sudo chroot ~/$fold/custom sudo umount /proc/
  
  sudo chroot ~/$fold/custom sudo umount /sys/
  
  dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "System has been cleaned." 6 60
  checkCtrlC clean
  setupIso
}
#Procedure that sets up the new ISO
function setupIso() {
   resumeFrom setupIso
   dialog --backtitle "Ubuntu 12.04 Customization" --title "Setup ISO file" --clear --msgbox "The process will now setup the new customized ISO file" 7 70
   checkCtrlC setupIso
   sudo chmod +w ~/$fold/cd/casper/filesystem.manifest
   check setupIso
   sudo chroot ~/$fold/custom sudo dpkg-query -W --showformat='${Package} ${Version}\n' > ~/$fold/cd/casper/filesystem.manifest
   check setupIso
   sudo cp ~/$fold/cd/casper/filesystem.manifest ~/$fold/cd/casper/filesystem.manifest-desktop
   check setupIso
   sudo mksquashfs ~/$fold/custom ~/$fold/cd/casper/filesystem.squashfs
   check setupIso
   sudo rm ~/$fold/cd/md5sum.txt
   check setupIso
   cd ~/$fold/cd/
   find . -type f -print0 | sudo xargs -0 md5sum > md5sum.txt
   cd ~/$fold/cd && sudo find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt
   check setupIso
   dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The new ISO has been set up correctly. \nClick OK to  continue with the creation of the ISO" 7 70
   checkCtrlC setupIso
  createIso
}

#Procedure that creates the final customized ISO file
function createIso() {
   resumeFrom createIso
   dialog --backtitle "Ubuntu 12.04 Customization" --title "ISO creation" --clear --msgbox "The process will now let you create the new customized ISO file" 6 60
   dialog --backtitle 'Ubuntu 12.04 Customization' --title "Name the ISO" --inputbox "Enter your username." 8 70 2> $choose
        if [ $? == 0 ]
            then USER=$(< $choose)
        else exitFrom createIso
        fi
   dialog --backtitle 'Ubuntu 12.04 Customization' --title "Name the ISO" --inputbox "Enter the name for your new ISO." 8 70 2> $choose
        if [ $? == 0 ]
            then ISO=$(< $choose)
        else exitFrom createIso
        fi
   dialog --backtitle 'Ubuntu 12.04 Customization' --title "Save the ISO" --inputbox "Enter the path where you want to save the ISO.\nThe starting folder is the home, so leave it blank if you want to save the ISO in the home" 8 80 2> $choose
        if [ $? == 0 ]
            then ISOpath=$(< $choose)
        else exitFrom createIso
        fi
   cd ~/$ISOpath     
   cd ~/$fold/cd && sudo mkisofs -r -V "Ubuntu-$USER" -b isolinux/isolinux.bin -c isolinux/boot.cat -cache-inodes -J -l -no-emul-boot -boot-load-size 4 -boot-info-table -o ~/$ISO.iso .
    check createIso
   dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "The new ISO has been created correctly and has been saved in the home as $ISO-amd64.iso" 8 80
   checkCtrlC createIso
dialog --backtitle "Ubuntu 12.04 Customization" --title "Confirmation" --clear --msgbox "Congratulation! You have completed  the Ubuntu Customization!" 8 80
}


function customizeMenu() {
   dialog --backtitle 'Ubuntu 12.04 Customization' --title "Choose an option" --menu "Choose a task or end the customization." 14 65 6 1 "Remove games" 2 "Install Eclipse" 3 "Install Netbeans" 4 "Install flash-plugin for Firefox" 5 "Install wireshark network tool" 6 "Install a package" 7 "Remove a package" 8 "Change default background" 9 "End customization" 2> $choose
     if [ $? == 0 ]
            then WHAT=$(< $choose)
        else exitFrom customizeMenu
        fi
     case $WHAT in
       1) changeBack;;
       2) addPackage ;;
       3) installNetbeans ;;
       4) addFirefoxPlugin ;;
       5) addWireshark ;;
       6) installEclipse ;;
       7) removePackage ;;
       8) removeGame ;;
       9) clean ;; 
       *)  exitFrom customizeMenu ;;
       255)  exitFrom customizeMenu ;;
esac

}

#Procedure to exit from any process whenever the user wants to 
function exitFrom(){

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

}
#Procedure to exit from the customize menu
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
#Procedure that checks the correctness of the last operation done
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
#Procedure that manages to exit the programm when an ctrl+c has been pressed
function checkCtrlC(){
        
        if test $? -ne 0   
         then
            
            exitFrom $1 
        
          fi  
}
#Procedure that checks the correctness of the operation done in the Menu
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
  if test $? -eq 0   
     then 
       $2
        
  fi 

}
#Procedure that writes the name of the function in the log
function writeForResume() {
    
  grep $1 functionsLog.txt
  if test $? -ne 0   
     then 
       log $1 
  fi 

}
#Procedure that checks if the user has already started the customization.
function checkResume() {
  cd ~
  ls | grep -q functionsLog.txt
  if test $? -eq 0
    then dialog --backtitle "Ubuntu 12.04 Customization" --title "Resume" --clear --yesno "It seems like you already started the customization process. \nDo you want to start from the point in which you exit?\n " 9 80
             case $? in
             0)
               resumeFrom selectIso 
             ;;
             1)
             cd ~
             rm -f functionsLog.txt
             selectIso
             ;;
             esac
  fi

  

}


#Procedure that writes the name of the function in the log
function log(){
  echo "$1" >> functionsLog.txt
}


welcome
mountSystem
copyFolders
copySquash
moveRoot
enableRepo
customizeMenu

exit 0


