#!/bin/bash
#
# pulseatparkes_eppg_check.sh
#
# This script checks network status, 
# data mounts, folder permissions and Apache status 
# at Epping servers prior to a P@P session
# An alert is given if any of the above fail the test.
#
#

host="127.0.0.1"
data_dir="/home/lozza"
http_port="80"
log_dir="$data_dir/logs"
log_file="`date +%F+%R`.log"


#Usage

function usage() {

  echo
  echo "pulseatparkes_eppg_check usage:"
  echo "    ->This script checks network status, data mounts, folder permissions and apache status on Epping servers prior to P@P session."
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
  echo "Pulse@Parkes session: Epping check log" >> $log_file
  echo >> $log_file
  echo "HOSTNAME: `hostname`" >> $log_file
  echo "DATE: `date +%F+%R`" >> $log_file
  echo >> $log_file
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $log_file
  echo >> $log_file

}


#Check network status - is Epping server reachable

function check_network() {

  cmd_ping=`ping -c 1 $host > /dev/null`

  $cmd_ping

  if [ $? -eq 0 ]; then
    echo "****    OK: Host '$host' is reachable." >> $log_file
  else
    echo "####    WARNING: Host '$host' is not reachable." >> $log_file
  fi

}  


#Check httpd daemon is running, and correct port is open

function check_httpd() {

  cmd_httpd=`ps -C httpd > /dev/null`

  $cmd_httpd

  if [ $? -eq 0 ]; then
    echo "****    OK: httpd server is running." >> $log_file

    exec 3<> /dev/tcp/127.0.0.1/$http_port

    if [ $? -eq 0 ]; then
      echo "****    OK: port $http_port is open." >> $log_file
    else
      echo "####    WARNING: port $http_port is closed." >> $log_file
    fi
    
  else
    echo "####    WARNING: httpd is dead." >> $log_file
  fi

}


#Check data mount and folder permissions (755)

function check_data_mount() {

  if [ -d $data_dir ]; then
    echo "****    OK: P@P data directory '$data_dir' exists." >> $log_file
    
    cmd=`ls -la $data_dir | awk 'NR==2 {print$1}'`
    dir_permissions='drwxr-xr-x'

    if [ $cmd == $dir_permissions ]; then
      echo "****    OK: P@P data directory '$data_dir' permissions are set to 755." >> $log_file
    else
      echo "####    WARNING: $data_dir permissions are incorrect. Please set permissions to 755." >> $log_file
    fi
  else 
    echo "####    WARNING: $data_dir does not exist." >> $log_file
  fi

}


#Print log to screen

function print_log() {

  cat $log_file
  echo
  echo "This has been saved to '$log_file'."
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}


#Run
usage
check_log_dir
check_network
check_httpd
check_data_mount
print_log
