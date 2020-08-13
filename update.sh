#!/bin/bash
# this File is part of OpenVPN-WebAdmin - (c) 2020 OpenVPN-WebAdmin
#
# NOTICE OF LICENSE
#
# GNU AFFERO GENERAL PUBLIC LICENSE V3
# that is bundled with this package in the file LICENSE.md.
# It is also available through the world-wide-web at this URL:
# https://www.gnu.org/licenses/agpl-3.0.en.html
#
# @fork Original Idea and parts in this script from: https://github.com/Chocobozzz/OpenVPN-Admin
#
# @author    Wutze
# @copyright 2020 OpenVPN-WebAdmin
# @link			https://github.com/Wutze/OpenVPN-WebAdmin
# @see				Internal Documentation ~/doc/
# @version		1.3.0
# @todo			new issues report here please https://github.com/Wutze/OpenVPN-WebAdmin/issues

# debug
#set -x



## Fix Debian 10 Fehler
export PATH=$PATH:/usr/sbin:/sbin

## set static vars
THIS_NEW_VERSION="1.3.0"
config="config.conf"
coltable=/opt/install/COL_TABLE
BACKTITLE="OVPN-Admin [UPDATE]"
updpath="/var/lib/ovpn-admin/"
updfile="config.ovpn-admin.upd"
base_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## init screen
# Find the rows and columns will default to 80x24 if it can not be detected
screen_size=$(stty size 2>/dev/null || echo 24 80)
rows=$(echo "${screen_size}" | awk '{print $1}')
columns=$(echo "${screen_size}" | awk '{print $2}')

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))
h=$(( r - 7 ))

# The script is part of a larger script collection, so this entry exists.
# If the color table file exists
if [[ -f "${coltable}" ]]; then
  # source it
  source ${coltable}
# Otherwise,
else
  # Set these values so the installer can still run in color
  COL_NC='\e[0m' # No Color
  COL_LIGHT_GREEN='\e[1;32m'
  COL_LIGHT_RED='\e[1;31m'
  COL_BLUE='\e[94m'
  COL_YELLOW='\e[0;33m'
  TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
  CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
  INFR="[${COL_YELLOW}▸${COL_NC}]"
  INFL="[${COL_YELLOW}◂${COL_NC}]"
  DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
  OVER="\\r\\033[K"
fi

#
#  description: intercepts errors and displays them as messages
#  name: control_box
#  @param $? + Description
#  @return Message OK or Exit Script
#  
control_box(){
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
      print_out 1 "Update: ${2}"
  else
      print_out 0 "Update: ${2}"
      exit
  fi
}
#
#  description: Intercept and display errors
#  name: control_script
#  @param $?
#  @return continue script or or exit when error with exit 100
#  
control_script(){
  if [ ! $? -eq 0 ]
  then
  print_out 0 "Error ${1}"
  exit 100
  fi
}
#
#  description: formats the notes and messages in an appealing form
#  name: print_out
#  @param [1|0|i|d|r] [Text]]
#  @return formated Text with red cross, green tick, "i"nfo, "d"one Message or need input with "r"
#  
print_out(){
  case "${1}" in
    1)
    echo -e " ${TICK} ${2}"
    ;;
    0)
    echo -e " ${CROSS} ${2}"
    ;;
    i)
    echo -e " ${INFR} ${2}"
    ;;
    d)
    echo -e " ${DONE} ${2}"
    ;;
    r)	read -rsp " ${2}"
    echo ""
    ;;
  esac
}

sel_lang(){
  # Split System-Variable $LANG
  var1=${LANG%.*}
  ## Select Language to install
  var2=$(whiptail --backtitle "${BACKTITLE}" --title "Select Language" --menu "Select your language" ${r} ${c} ${h} \
    "AUTO" " Automatic" \
    "de_DE" " Deutsch" \
    "en_EN" " Englisch" \
    "fr_FR" " Français" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    print_out 0 "Exit select language"
    exit
  elif [ $RET -eq 0 ]; then
    case "$var2" in
      AUTO) source "installation/lang/$var1"
      ;;
      de_DE) source "installation/lang/$var2"
      ;;
      en_EN) source "installation/lang/$var2"
      ;;
      fr_FR) source "installation/lang/$var2"
      ;;
      *) source "installation/lang/de_DE"
      ;;
    esac
  fi
}
## Intro with colored Logo
intro(){
  clear
  NOW=$(date +"%Y")
	echo -e "${COL_LIGHT_RED}
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
${COL_BLUE}        ◢■◤
      ◢■◤
    ◢■◤  ${COL_LIGHT_RED} O P E N V P N - ${COL_NC}W E B A D M I N${COL_LIGHT_RED} - S E R V E R${COL_BLUE}
  ◢■◤                         【ツ】 © 10.000BC - ${NOW}
◢■■■■■■■■■■■■■■■■■■■■◤             ${COL_LIGHT_RED}L   I   N   U   X
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
        ${COL_BLUE}https://github.com/Wutze/OpenVPN-WebAdmin${COL_NC}
"
}

#
#  description: you can only install with root privileges, check this
#  name: check_user
#  @param $?
#  @return continue script or or exit when no root user
#  
check_user(){
  # Must be root to install
  local str="Root user check"
  if [[ "${EUID}" -eq 0 ]]; then
    # they are root and all is good
    print_out 1 "${str}"
  else
    print_out 0 "${str}"
    print_out i "${COL_LIGHT_RED}${USER01}${COL_NC}"
    print_out i "${USER02}"
    print_out 0 "${USER03}"
    exit 1
  fi
}

if_updatefile_exist(){
  if [[ -f "${updpath}${updfile}" ]]; then
    # go vars from install.files if exist
    source ${updpath}${updfile}
    # load database pw if exist
    # These variables certainly work
    if [[ -f "/etc/openvpn/scripts/config.sh" ]]; then
      source /etc/openvpn/scripts/config.sh
    fi
    print_out 1 "Setup config loaded"
  else
    # when the update file not exist, you have a older version
    print_out i "Version older than 1.1.0"
    print_out i "load only /etc/openvpn/scripts/config.sh"
    if [[ -f "/etc/openvpn/scripts/config.sh" ]]; then
      source /etc/openvpn/scripts/config.sh
      print_out i "Openvpn Script Config loaded"
    else
      print_out 0 "No openvpn script config found. Is there even a working installation?"
      print_out i "Please read the update.info.md in doc folder!"
      exit;
    fi
  fi
}

# The machine_id is only stored to detect if the system has been
# fundamentally changed at any time. This can be a move to new hardware,
# which usually involves a new installation of the operating system.
# Since usually only the webroot is copied, often no nodejs and yarn are
# installed on the new server. However, since these two packages are
# required, any errors that may occur will be fixed at the same time.

verify_setup(){
  LOCALMACHINEID=$( cat /etc/machine-id )
  if [ -n "$PASS" ]; then
    DBPASS=$PASS
    WEBROOT="/srv/www/"
    BASEPATH="openvpn-admin"
  fi
  if [ -n "$HOST" ]; then DBHOST=$HOST; fi
  if [ -n "$DB" ]; then DBNAME=$DB; fi
  if [ -n "$INSTALLEDVERSION" ]; then VERSION=$INSTALLEDVERSION; fi

  UPDATEINFSUM="
${UPDATEINF02} ↠ ${LOCALMACHINEID}

${UPVERSIO}: ${VERSION}
${NEVERSIO}: ${THIS_NEW_VERSION}
${UPDBHOST}: ${DBHOST}
${UPDBUSER}: ${DBUSER}
${UPDBNAME}: ${DBNAME}
${UPDBPASS}: ${DBPASS}
${UPWEBDIR}: ${BASEPATH}
${UPWEBROO}: ${WEBROOT}
${UPPATHOW}: ${WWWOWNER}
${UPMASHID}: ${MACHINEID}
${INSTALLD}: ${INSTALLDATE}

${UPDATAOK}
"
  
  sel=$(whiptail --backtitle "${BACKTITLE}" --title "${UPSEL00}" --yesno "${UPDATEINFSUM}" ${r} ${c} 3>&1 1>&2 2>&3)
  
  if [ $? = 0 ]; then
      print_out 1 "Update: Inputs ok"
      fix_error_1
  else
      print_out i "Update: get inputs"
      setup_questions
  fi
}

create_setup_new_user(){
  ADMIN=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN08}" ${r} ${c} --title "${SETVPN08}" 3>&1 1>&2 2>&3)
  control_box $? "new Admin"
  ADMINPW=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN09}" ${r} ${c} --title "${SETVPN09}" 3>&1 1>&2 2>&3)
  control_box $? "new Admin Password"
  ## all Users now User, not Admin!
  mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME -e "UPDATE user SET gid = '2'; "
  control_script "set all Users to Group User"
  print_out 1 "All Users now Group User"
  mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME -e "INSERT INTO user (user_id, user_pass, gid, user_enable) VALUES ('${ADMIN}', encrypt('${ADMINPW}'),'1','1');"
  control_script "Insert new Webadmin"
  mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME -e "INSERT INTO user (user_id, user_pass, gid, user_enable) VALUES ('${ADMIN}-user', encrypt('${ADMINPW}'),'2','1');"
  control_script "Insert new User"
  print_out 1 "setting up MySQL OK"
  print_out i "Admin-Login now with $ADMIN and our new Password!"
  print_out i "Control and reconfigure all users after the update!"
}

#
# create the backup from database and webfiles
#
make_backup(){
  if [[ -d "/opt/ovpn-backup/" ]]; then
    print_out 1 "backup path exist"
  else
    mkdir /opt/ovpn-backup/
    control_script "mkdir backup path"
    print_out 1 "backup path created"
  fi

  date=$(date '+%Y-%m-%d')
  tar cfz /opt/ovpn-backup/$date-archiv.tar.gz --exclude=node_modules --exclude=ADOdb $WEBROOT$BASEPATH
  control_script "create tar"
  print_out 1 "Backup Webfolder ok"
  cp $WEBROOT$BASEPATH/include/config.php /opt/ovpn-backup/$date-config.php
  
  print_out i "Insert Password MySQL Database!"
  mysqldump --opt -Q -u $DBUSER -p$DBPASS -h $DBHOST $DBNAME > /opt/ovpn-backup/$date-dump.sql
  control_script "create db dump"
  print_out 1 "Backup Database ok"
  
}

## Fixed a bug in the installation script that saved the wrong BASEPATH of the Webroot (up to version 1.1.1)
fix_error_1(){
  if [[ ! -d "$WEBROOT$BASEPATH" ]]; then
    BASEPATH=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN12}" ${r} ${c} openvpn-admin --title "${SETVPN12}" 3>&1 1>&2 2>&3)
    control_box $? "fix error Web-Basepath to $BASEPATH"
  fi
}

setup_questions(){

  DBHOST=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN04}" ${r} ${c} ${DBHOST} --title "DB Host" 3>&1 1>&2 2>&3)
  control_box $? "DB-Host"
  DBNAME=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN10}" ${r} ${c} ${DBNAME} --title "DB Name" 3>&1 1>&2 2>&3)
  control_box $? "DB-Name"
  DBUSER=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN06}" ${r} ${c} ${DBUSER} --title "DB-User" 3>&1 1>&2 2>&3)
  control_box $? "MySQL Username"
  DBPASS=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN07}" ${r} ${c} ${DBPASS} --title "DB Password" 3>&1 1>&2 2>&3)
  control_box $? "MySQL User PW"
  WEBROOT=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN11}" ${r} ${c} ${WEBROOT} --title "${SETVPN11}" 3>&1 1>&2 2>&3)
  control_box $? "Web-Root"
  BASEPATH=$(whiptail --backtitle "${BACKTITLE}" --inputbox "${SETVPN12}" ${r} ${c} ${BASEPATH} --title "${SETVPN12}" 3>&1 1>&2 2>&3)
  control_box $? "Web-Basepath"

  verify_setup
  
  if [[ $0 == 0 ]]; then
    setup_options
  fi
}

start_update_new_version(){
  openvpn_admin=$WEBROOT$BASEPATH
  # wenn alte Version - vor 1.1.0 - dann lösche das alte Verzeichnis
  # es wird neu angelegt
  rm -r $openvpn_admin
  print_out 1 "delete old Webfolder"
  mkdir $openvpn_admin
  control_script "create new Webfolder"

  cp -r "$base_path/wwwroot/"{index.php,favicon.ico,package.json,js,include,css,images,data} "$openvpn_admin"
  control_script "install new files"
  print_out i "Install third party module yarn"
  cd $openvpn_admin
  yarn install
  control_script "yarn install"
  print_out i "Install third party module ADOdb"
  git clone https://github.com/ADOdb/ADOdb ./include/ADOdb
  control_script "ADODb install"
  chown -R www-data $openvpn_admin
  control_script "Set access rights webfolder"
  print_out 1 "Set access rights webfolder"
  if [[ -f "$base_path/installation/sql/$THIS_NEW_VERSION-ovpnadmin.update.sql" ]]; then
    mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME < $base_path/sql/$THIS_NEW_VERSION-ovpnadmin.update.sql
    control_script "execute Database Updates"
    mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME < $base_path/sql/adodb.sql
    print_out 1 "Update Database ok"
    create_setup_new_user
  else
    print_out i "no changes to the database necessary"
  fi

  {
  echo "<?php
/**
 * this File is part of OpenVPN-WebAdmin - (c) 2020 OpenVPN-WebAdmin
 *
 * NOTICE OF LICENSE
 *
 * GNU AFFERO GENERAL PUBLIC LICENSE V3
 * that is bundled with this package in the file LICENSE.md.
 * It is also available through the world-wide-web at this URL:
 * https://www.gnu.org/licenses/agpl-3.0.en.html
 *
 * @fork Original Idea and parts in this script from: https://github.com/Chocobozzz/OpenVPN-Admin
 *
 * @author    Wutze
 * @copyright 2020 OpenVPN-WebAdmin
 * @link			https://github.com/Wutze/OpenVPN-WebAdmin
 * @see				Internal Documentation ~/doc/
 * @version		1.2.0
 * @todo			new issues report here please https://github.com/Wutze/OpenVPN-WebAdmin/issues
 */

(stripos(\$_SERVER['PHP_SELF'], basename(__FILE__)) === false) or die('access denied?');"
  echo ""
  echo ""
  echo "\$dbhost=\"$DBHOST\";"
  echo "\$dbuser=\"$DBUSER\";"
  echo "\$dbname=\"$DBNAME\";"
  echo "\$dbport=\"3306\";"
  echo "\$dbpass=\"$DBPASS\";"
  echo "\$dbtype=\"mysqli\";"
  echo "\$dbdebug=FALSE;"
  echo "\$sessdebug=FALSE;"

  echo "/* Site-Name */
define('_SITE_NAME',\"OVPN-WebAdmin\");
define('HOME_URL',\"vpn.home\");
define('_DEFAULT_LANGUAGE','en_EN');

/** Login Site */
define('_LOGINSITE','login1');

/** 
 * only for development!
 * please comment out if no longer needed!
 * comment out the \"define function\" to enable
 */
#define('dev','dev/dev.php');
if (defined('dev')){
	include_once('dev/class.dev.php');
}"

  }> $WEBROOT$BASEPATH"/include/config.php"
  control_script "create new config.php"
  print_out 1 "create new config.php"

}

start_update_normal(){
  openvpn_admin=$WEBROOT$BASEPATH
  # simply delete the web directory to keep it clean
  rm -r $openvpn_admin
  print_out 1 "delete old Webfolder"
  mkdir $openvpn_admin
  control_script "create new Webfolder"

  if [ -n "$modules_dev" ] || [ -n "$modules_all" ]; then
    cp -r "$base_path/wwwroot/"{index.php,favicon.ico,package.json,js,include,css,images,data,dev} "$openvpn_admin"
  else
    cp -r "$base_path/wwwroot/"{index.php,favicon.ico,package.json,js,include,css,images,data} "$openvpn_admin"
  fi

  ## move all history folders and osx folder
  cd $WEBROOT
  if [[ ! -d  "vpn/history/osx" ]]; then
    ## rename osx folder
    mv vpn/history/osx-viscosity/ vpn/history/osx
    mv vpn/conf/osx-viscosity/ vpn/conf/osx
    ## move history files
    if [[ -d  "vpn/history/osx" ]]; then
    cp vpn/history/osx/history/* vpn/history/osx/
    rm -r vpn/history/osx/history/
    fi
    if [[ ! -d  "vpn/history/windows" ]]; then
    cp vpn/history/windows/history/* vpn/history/windows/
    rm -r vpn/history/windows/history/
    fi
    if [[ ! -d  "vpn/history/gnu-linux" ]]; then
    cp vpn/history/gnu-linux/history/* vpn/history/gnu-linux/
    rm -r vpn/history/gnu-linux/history/
    fi
    if [[ ! -d  "vpn/history/server" ]]; then
    cp vpn/history/server/history/* vpn/history/server/
    rm -r vpn/history/server/history/
    fi
  fi
  
  if [[ ! -d  "vpn/history/firewall" ]]; then
    mkdir vpn/history/firewall
  fi

  control_script "renew Files"
  print_out i "Update third party module yarn"
  cd $openvpn_admin
  yarn install
  control_script "yarn install"
  print_out i "Install third party module ADOdb"
  git clone https://github.com/ADOdb/ADOdb ./include/ADOdb
  control_script "ADODb install"

  print_out i "Update SQL"
  if [[ -f "$base_path/installation/sql/$THIS_NEW_VERSION-ovpnadmin.update.sql" ]]; then
    mysql -h $DBHOST -u $DBUSER --password=$DBPASS $DBNAME < $base_path/sql/$THIS_NEW_VERSION-ovpnadmin.update.sql
    control_script "execute Database Updates" 
  else
    print_out i "no changes to the database necessary"
  fi
}

check_version(){
  if [ -n "$INSTALLEDVERSION" ]; then VERSION=$INSTALLEDVERSION; fi
  if [ "$(printf '%s\n' "$THIS_NEW_VERSION" "$VERSION" | sort -V | head -n1)" = "$THIS_NEW_VERSION" ]; then 
    print_out i "Installed Version $VERSION greater than or equal to $THIS_NEW_VERSION"
    print_out d "Update is not required"
    exit
  else
    ## Special version due to renaming of several variables
    if [ "$(printf '%s\n' "$THIS_NEW_VERSION" "$VERSION" | sort -V | head -n1)" = "1.1.0"  ]; then
      print_out i "Installed Version $VERSION, this should be installed: $THIS_NEW_VERSION"
      print_out i "Update is required"
      V2=2
      do_select
      #control_box "Set Development"
      return
    fi
    do_select
    return
  fi
}

startDialog(){
  sel=$(whiptail --backtitle "${BACKTITLE}" --title "${UPSEL00}" --yesno "${UPDATEINF01}" ${r} ${c} 3>&1 1>&2 2>&3)
  control_box $? "${UPSEL00}"
}

write_config(){
  if [[ ! -d  "${updpath}" ]]; then
    mkdir $updpath
  fi

  {
  echo "VERSION=\"$THIS_NEW_VERSION\""
  echo "DBHOST=\"$DBHOST\""
  echo "DBUSER=\"$DBUSER\""
  echo "DBNAME=\"$DBNAME\""
  echo "BASEPATH=\"$BASEPATH\""
  echo "WEBROOT=\"$WEBROOT\""
  echo "WWWOWNER=\"www-data\""
  echo "### Is it still the original installed system?"
  echo "MACHINEID=$LOCALMACHINEID"
  echo "INSTALLDATE=\"$(date '+%Y-%m-%d %H:%M:%S')\""
  }> $updpath$updfile

  control_box $? "write config"
  chmod -R 700 $updpath
}

## Since version 1.1.1 new naming convention
function rename_vars(){
  sed -i "s/\$host/\$dbhost/" "./include/config.php"
  sed -i "s/\$port/\$dbport/" "./include/config.php"
  sed -i "s/\$db/\$dbname/" "./include/config.php"
  sed -i "s/\$user/\$dbuser/" "./include/config.php"
  sed -i "s/\$pass/\$dbpass/" "./include/config.php"


  mv vpn/history/osx-viscosity/ vpn/history/osx

}

install_version_2(){
  V2="YES"

}


do_select(){
	sel=$(whiptail --title "${SELECT_A}" --checklist --separate-output "${SELECT_B}:" ${r} ${c} ${h} \
    "11" "${SELECT11} " off \
    "12" "${SELECT12} " off \
    "20" "${SELECT20} " off \
    3>&1 1>&2 2>&3)
  control_box $? "select"

  while read -r line;
  do
      case $line in
          11) modules_dev="1"
              MOD_ENABLE="1"
          ;;
          12) modules_firewall="1"
              MOD_ENABLE="1"
          ;;
          20) modules_all="1"
              MOD_ENABLE="1"
          ;;
          *)
          ;;
      esac
  done < <(echo "$sel")
}

write_webconfig(){

cp /opt/ovpn-backup/$date-config.php $WEBROOT$BASEPATH/include/config.php
control_script "Copy web.config.php"

if [ -n "$modules_dev" ] || [ -n "$modules_all" ]; then
  echo "
/** 
 * only for development!
 * please comment out if no longer needed!
 * comment in the \"define function\" to enable
 */
if(file_exists(\"dev/dev.php\")){
	define('dev','dev/dev.php');
}
if (defined('dev')){
	include('dev/class.dev.php');
}
" >> $WEBROOT$BASEPATH"/include/module.config.php"
MOD_ENABLE="1"
fi

if [ -n "$modules_firewall" ] || [ -n "$modules_all" ]; then
  echo "
define('firewall',TRUE);
" >> $WEBROOT$BASEPATH"/include/module.config.php"
MOD_ENABLE="1"
fi

print_out i "Config and Module Config written"
}



## first information to update
# you must say yes to continue!
# all other inputs will break this script
main(){

  # select language german or english
  sel_lang  
  # main logo
  intro
  if_updatefile_exist
  check_version

  # first dialog for informations
  startDialog

  verify_setup

  ## create backup files and database
  print_out i "Backup - this may take a little moment"
  make_backup

  ## make update files and database
  if [ -n "$VERSION" ]; then
    start_update_normal
  else
    start_update_new_version
  fi

  write_config
  write_webconfig
  print_out 1 "Configs written"
  chown -R "$WWWOWNER:$WWWOWNER" "$WEBROOT$BASEPATH"
  chown -R "$WWWOWNER:$WWWOWNER" $WEBROOT/vpn
  print_out 1 "set file rights"
}

### Start Script

main


### finish script and call messages
print_out d "Yeahh! Update ready. 【ツ】"
print_out i "Have Fun!"
print_out i "${SETFIN04}"
print_out i "${AUPDATE01}"

if [ -n "$MOD_ENABLE" ]; then
  print_out i "${MOENABLE0}"
  print_out i "${MOENABLE1}"
fi


exit


### Hinweise
## umbenennen vpn conf ordner in osx --- selbiges mit history - ok
## umschreiben variablen config.php - ok
