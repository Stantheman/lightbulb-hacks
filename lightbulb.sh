#!/bin/bash

# MIT License
# 
# Copyright (c) 2018 Stan Schwertly
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

wakeup_word="HF-A11ASSISTHREAD"
socat_bin="/usr/local/bin/socat"

bulb_port=48899

# to be set later
ip_address="unset"
mac_address="unset"
model="unset"

function log() {
  if [ -z $DEBUG ]; then
    return
  fi
  echo $*
}

function wakeup_bulb() {
  log "waking up bulb..."

  socat_target="UDP4-DATAGRAM:255.255.255.255:${bulb_port},broadcast,sourceport=54321"
  if [ ! -z $1 ]; then
    socat_target="UDP4-DATAGRAM:$1:$bulb_port,sourceport=54321"
	log "sending non-broadcast packet to $1"
  else
    log "sending broadcast packet to 255.255.255.255"
  fi

  response=$(echo -ne "$wakeup_word" | sudo $socat_bin - $socat_target)

  if [ $? -ne 0 ]; then
    log "failed to wake bulb, exiting"
	exit 0;
  fi

  ip_address=$(echo $response | cut -d, -f1)
  mac_address=$(echo $response | cut -d, -f2)
  model=$(echo $response | cut -d, -f3)
}

function enter_edit_mode() {
  echo -ne "+ok" | sudo $socat_bin -t 1 - UDP4-SENDTO:$ip_address:$bulb_port,sourceport=54322
}

function get_ntp_server() {
  enter_edit_mode
  echo -ne "AT+NTPSER\r" | sudo socat -t 1 - UDP4-SENDTO:$ip_address:$bulb_port,sourceport=54322;
}

function get_web_password() {
  enter_edit_mode
  echo -ne "AT+WEBU\r" | sudo $socat_bin -t 1 - UDP4-SENDTO:$ip_address:$bulb_port,sourceport=54322;
}

function get_wireless_networks() {
  enter_edit_mode
  echo -ne "AT+WSCAN\r" | sudo $socat_bin -t 1 - UDP4-SENDTO:$ip_address:$bulb_port,sourceport=54322;
}

log "1) spam the network to get the right IP"
wakeup_bulb

log "2) hit the bulb's IP directly"
wakeup_bulb $ip_address

log "3) get the ntp server setting"
get_ntp_server

log "4) get the web pass"
get_web_password

log "5) get wirless networks"
get_wireless_networks
