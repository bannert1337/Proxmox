#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ______              __    ____  _____ _____
  / ____/_______  ____/ /   / __ \/ ___// ___/
 / /_  / ___/ _ \/ __  /   / /_/ /\__ \ \__ \ 
/ __/ / /  /  __/ /_/ /   / _, _/___/ /___/ / 
/_/   /_/   \___/\__,_/   /_/ |_|/____//____/  
                                               
EOF
}
header_info
echo -e "Loading..."
APP="FreshRSS"
var_disk="4"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /var/www/FreshRSS ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -sL https://api.github.com/repos/FreshRSS/FreshRSS/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop apache2
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE}"
  wget -q https://github.com/FreshRSS/FreshRSS/archive/${RELEASE}.tar.gz
  tar -xzf ${RELEASE}.tar.gz
  cp -r FreshRSS-${RELEASE}/* /var/www/FreshRSS/
  rm -rf FreshRSS-${RELEASE} ${RELEASE}.tar.gz
  chown -R www- /var/www/FreshRSS/
  find /var/www/FreshRSS/ -type d -exec chmod 755 {} \;
  find /var/www/FreshRSS/ -type f -exec chmod 644 {} \;
  chmod -R 777 /var/www/FreshRSS/data/
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start apache2
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}/p/${CL} \n"
echo -e "Please complete the installation through the web interface."
echo -e "Make sure to create a database before starting the web installation process."