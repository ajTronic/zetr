#!/usr/bin/env bash
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

printf "Installing zetr...\n"

sudo -v

wget https://github.com/ajTronic/zetr/releases/download/untagged-020ebe47e85a454a86ef/zetr

sudo mv zetr /usr/local/bin/zetr
chmod +x /usr/local/bin/zetr

clear
printf "${Red}         _        
 _______| |_ _ __ 
|_  / _ \ __| '__|
 / /  __/ |_| |   
/___\___|\__|_|   
                  \n
${Color_Off}"
printf "Setup complete.\n"
printf "${Yellow}Usage${Color_Off}: ${Red}zetr${Color_Off}\n\n"
printf "${Blue}h:${Color_Off} move tetronimo right
${Blue}l:${Color_Off} move tetronimo left
${Blue}j:${Color_Off} move tetronimo down
${Blue}k:${Color_Off} rotate tetronimo clockwise
${Blue}o:${Color_Off} rotate tetronimo anticlockwise
${Blue}<space>:${Color_Off} hard drop\n
${Color_Off}"
printf "May the blocks fall ever in your favour. Enjoy!\n"