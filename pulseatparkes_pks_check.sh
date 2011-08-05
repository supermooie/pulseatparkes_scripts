#!/bin/bash
#
# pulseatparkes_pks_check.sh
#
# This script checks network status, 
# data mounts and appropriate software are 
# present at Parkes servers prior to a P@P session
# An alert is given if any of the above fail the test.
#
#

epp_host="herschel.atnf.csiro.au"
data_dir="/nfs/PKCCC3_1"
ssh_port="22"
log_dir="`pwd`/logs"
log_file="${log_dir}/`date +%F+%R`.log"
datafiles_ext_rf=".rf"
datafiles_ext_sf=".sf"
datafiles_ext_cf=".cf"

runfrom_host="lagavulin"

#Usage

function usage() {

  echo
  echo "pulseatparkes_pks_check usage:"
  echo "    ->This script checks network, sshd, data mounts and psrchive tools status on Parkes servers prior to P@P session."
  echo

}


#Check for log directory - if it doesn't exist, create one

function check_log_dir() {

  if [ ! -d $log_dir ]; then
    echo "####    Log directory '$log_dir' does not exist. Creating one."
    mkdir $log_dir
  fi
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" > $log_file
  echo >> $log_file
  echo "Pulse@Parkes session: Parkes check log" >> $log_file
  echo >> $log_file
  echo "HOSTNAME: `hostname`" >> $log_file
  echo "DATE: `date +%F+%R`" >> $log_file
  echo >> $log_file
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $log_file
  echo >> $log_file

}


#Check network status - is herschel reachable

function check_network() {

  cmd_ping=`ping -c 1 $epp_host > /dev/null`

  $cmd_ping

  if [ $? -eq 0 ]; then
    echo "****    OK: Host '$epp_host' is reachable." >> $log_file
  else
    echo "####    WARNING: Host '$epp_host' is not reachable." >> $log_file
  fi

}  


#Check sshd daemon is running

function check_sshd() {
  nc -z $epp_host $ssh_port

  if [ $? -eq 0 ]; then
    echo "****    OK: SSH accessible on $epp_host." >> $log_file
  else
    echo "####    WARNING: SSH NOT accessible on $epp_host." >> $log_file
  fi 
}


#Check data mount

function check_data_mount() {
  if [ -d $data_dir ]; then
    echo "****    OK: P@P data directory '$data_dir' exists." >> $log_file
  else 
    echo "####    WARNING: $data_dir does not exist." >> $log_file
  fi
}


#Check psrchive tools are present

function check_psrchive_tools() {

  vap -h > /dev/null

  if [ $? -eq 0 ]; then
    echo "****    OK: vap is present." >> $log_file
  else
    echo "####    WARNING: vap is dead." >> $log_file
  fi

  pav -h > /dev/null

  if [ $? -eq 0 ]; then
    echo "****    OK: pav is present." >> $log_file
  else
    echo "####    WARNING: pav is dead." >> $log_file
  fi   

}


#Print log to screen

function print_log() {

  cat $log_file
  echo
  echo "This has been saved to '$log_file'."
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}

if [[ $(hostname) != "$runfrom_host" ]]; then
  echo "Must be run from '$runfrom_host'."
  exit 1
fi

#Run
usage
check_log_dir
check_network
check_sshd
check_data_mount
check_psrchive_tools
print_log
