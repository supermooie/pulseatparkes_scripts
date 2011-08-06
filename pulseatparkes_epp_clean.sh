#!/bin/bash
#
# pulseatparkes_eppg_clean.sh
#
# Author: Lawrence Toomey
# Date: July 2011
#
# This script checks pulse@parkes session data 
# for age, and prompts deletion of files > 30 days old
#

data_dir=$1
log_file="$data_dir/`date +%F+%R`_clean.log"
max_age=30


#Usage

function usage() {

  echo
  echo "pulseatparkes_eppg_clean"
  echo
  echo "    ->This script checks pulse@parkes session data on Epping servers for age," 
  echo "      and prompts deletion of files > $max_age days old."
  echo
  echo "      Usage: pulseatparkes_eppg_clean.sh </path/to/data_directory>"
  echo 

}

 
#Check data directory exists and contains files

function check_datadir_contents() {

  if [ -d $data_dir ]; then
    if [ "$(ls -A $data_dir)" ]; then
      echo
      echo "'$data_dir' contains the following files:"
      echo
      ls -lA $data_dir
      echo
    else
      echo "'$data_dir' is empty! Exiting...nothing to do."
      echo
      exit
    fi
  else
    echo "ERROR: '$data_dir' does not exist!"
    echo
    exit
  fi

}


#Find files older than $max_age days, excluding log files

function find_old_files() {

  cmd_log=`find $data_dir/* -mtime $max_age -not -name '*.log' > $log_file`

  $cmd_log

  if [ ! -s $log_file ]; then
    echo "There are no files greater than $max_age days old...exiting."
    echo
    rm $log_file
    exit
  else
    echo "The following files are greater than $max_age days old:"
    echo 
    cat $log_file
    echo
  fi

}


#Delete old files

function delete_old_files() {

  echo "Do you wish to delete these files (y/n)?"
  read input 

  if [ "$input" == "y" ]; then
    for line in $(<$log_file)
    do
      rm $line
    done
    echo
    echo "Complete. Deleted files are listed in '$log_file'."
    echo
  else
    echo "Exiting."
    echo
    rm $log_file 
    exit
  fi

}


#Run

usage
if [ $# -gt 1 ]; then
  echo "pulseatparkes_eppg_clean: ERROR: too many arguments"
  echo
  exit
fi

if [ $# -lt 1 ]; then
  exit
else
  check_datadir_contents
  find_old_files
  delete_old_files
fi
