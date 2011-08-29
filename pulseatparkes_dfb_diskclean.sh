#!/bin/bash
#
# pulseatparkes_dfb_diskclean.sh
#
# Author: Lawrence Toomey
# Date: August 2011
#
# This script checks dfb data files are backed up on DLT at Parkes
# and copied to Epping, prior to deletion from Parkes data disk.
#
# Note: Must be from run herschel (Epping).
#
#

epp_user="pulsar"
pks_user="pulsar"
epp_host="tycho.atnf.csiro.au"
pks_host="lagavulin.atnf.csiro.au"
corr_user="corr"
corr_host="pkccc3.atnf.csiro.au"
corr_data_dir_path="/data1"
corr_data_dir="${1}_1"
local_host="herschel.atnf.csiro.au"
runfrom_host="herschel"
local_dir=`pwd`
script=$(basename $0)
dat_dir="${local_dir}/${script}_dats"
log_dir="${local_dir}/${script}_logs"
log_file="${log_dir}/`date +%F+%R`_deleted.log"
ta_summary="TAsummary.csh"

case $1 in
  PDFB2)
    dfb="dfb2"
    ;;

  PDFB3)
    dfb="dfb3"
    ;;

  PDFB4)
    dfb="dfb4"
    ;;
esac

DFB_UPPER=$1

epp_dat="SF_epp_$dfb.dat"
pks_dat="SF_pks_$dfb.dat"
dlt_dat="SF_DLT_$dfb.dat"
eppcp_dat="${dat_dir}/SF_eppcp_$dfb.dat"
pksbk_dat="${dat_dir}/SF_pksbk_$dfb.dat"
del_dat="SF_del_$dfb.dat"

#
#Turn on debugging
#
#set -o xtrace


#
#Usage
#

function usage() {

  echo
  echo "pulseatparkes_dfb_diskclean"
  echo
  echo "    ->This script checks dfb data files are backed up on DLT at Parkes and copied to Epping, prior to deletion from Parkes data disk."
  echo
  echo "      Usage: pulseatparkes_dfb_diskclean.sh <PDFB#>"
  echo
  echo

  if [[ $(hostname) != "$runfrom_host" ]]; then
    echo "      Note: Must be run from '$runfrom_host'."
    echo
    exit 1
  fi

}


#
#Function to display appropriate messages
#

function get_msg() {

  msgtype=$1
  msgname=$2
  msgbool=$3
  msgarg=$4

  case $msgtype in
    init)
      case $msgname in
        arg_chk_dir)
          echo "Checking host '$msgarg' for required directories and executables..." ;;    

        arg_chk_network_sts)
          echo "Checking network status..." ;;

        arg_chk_dat_dir)
          echo "Checking for TAsummary.sh output files in $dat_dir..." ;;

        arg_disk_list)
          echo "Gathering file list from $msgarg..." ;;

        arg_compare_dat_msg)
          echo "Comparing TAsummary output files in $dat_dir..." ;;

        arg_delete_msg)
          echo "Do you wish to delete these files from Parkes disk (y/n)?" ;;

        arg_host_status)
          case $msgbool in
            1)
              echo "  WARNING: Host '$msgarg' is not reachable...exiting."
              echo
              exit 1 ;;

            0)
              echo "  OK: Host '$msgarg' is reachable." ;;
          esac ;;
      esac ;;

    exist)
      case $msgname in
        arg_dir_exist)
          case $msgbool in
            1)
              if [ "$msgarg" == "$dat_dir" ]; then
                echo "  Creating '$dat_dir'. This directory will contain TAsummary .dat files."
              fi

              if [ "$msgarg" == "$log_dir" ]; then
                echo "  Creating '$log_dir'. This directory will contain logs listing deleted files."
              fi ;;

            0)
              if [ "$msgarg" == "$dat_dir" ]; then
                echo "  OK: Dat directory '$dat_dir' exists."
              fi

              if [ "$msgarg" == "$log_dir" ]; then
                echo "  OK: Log directory '$log_dir' exists."
              fi ;;
          esac ;;

        arg_file_exist)
          case $msgbool in
            1)
              echo "  WARNING: '$msgarg' does not exist." ;;

            0)
              echo "  OK: '$msgarg' exists." ;;
          esac ;;

        arg_script_exist)
          case $msgbool in
            1)
              echo "  WARNING: Executable '$msgarg' does not exist. Please ensure '$msgarg' is in your 'PATH'...exiting."
              echo
              exit 1 ;;

            0)
              echo "  OK: Executable '$msgarg' exists." ;;
          esac ;;

        arg_dat_exist)
          case $msgbool in
            1)
              echo "  Please ensure all 3 of the following files are present:"
              echo
              echo "    $epp_dat"
              echo "    $pks_dat"
              echo "    $dlt_dat"
              echo
              echo "Exiting." ;;

            0)
              echo "  OK: The following 3 files are present:"
              echo
              echo "    $epp_dat"
              echo "    $pks_dat"
              echo "    $dlt_dat" ;;
          esac ;;
      esac ;;

    error)
      case $msgname in     
        arg_ssh)
          echo "  WARNING: ssh to host '$msgarg' and/or associated command failed...exiting" ;;
      esac ;;

    wrapup) 
      case $msgname in  
        arg_compare_dat_lists)
          case $msgbool in
            1)
              echo "  WARNING: A mismatch exists between files at Epping and Parkes. Please check disk contents before continuing." ;;

            0)
              echo "  OK: The following files have already been copied to Epping and backed up to Parkes DLT:" ;;
          esac ;;
 
        arg_complete)
          echo "  Complete." ;;
  
        arg_delete_list)
          echo "The following files have been deleted from ${corr_user}@${corr_host}:${corr_data_dir_path}/${corr_data_dir}" ;;

        arg_delete_log)
          echo "Deleted files are listed in '$log_file'." ;;
      esac ;;
  esac

}


#
#Check network status - are Epping and Parkes servers reachable
#

function check_network() {

  get_msg init arg_chk_network_sts
  echo

  for arg in $@
  do
    ping -c 1 $arg > /dev/null
    exit_status=$?
    get_msg init arg_host_status $exit_status $arg
  done
  echo

}


#
#ssh control
#

function start_ssh() {

  ssh_type=$1
  user=$2
  host=$3
 
  case $ssh_type in
    access)
      cmd=$4
      arg=$5

      ssh ${user}@${host} $cmd > /dev/null

      exit_status=$?
      if [ "$arg" == "" ]; then
        if [ $exit_status -eq 1 ]; then
          echo
          exit 1
        else
          get_msg wrapup arg_complete $exit_status
        fi
      else
        get_msg exist arg_file_exist $exit_status $arg
        if [ $exit_status -eq 1 ]; then
          echo
          exit 1
        fi
      fi ;;

    copy)
      infile=$4
      host_dir=$5
      scp $infile ${user}@${host}:${host_dir} > /dev/null ;;
  esac

  if [ ! $? -eq 0 ]; then
    get_msg error arg_ssh 1 $host
    echo
    exit 1
  fi
  
}


#
#Check existence of required directories and scripts
#

function check_file_exists() {

  loc=$1
  filetype=$2

  case $loc in
    $local_host)
      get_msg init arg_chk_dir 0 $loc
      echo

      for arg in ${@:3}
      do
        case $filetype in
          dir)
            if [ ! -d $arg ]; then
              get_msg exist arg_dir_exist 1 $arg
              mkdir $arg
            else
              get_msg exist arg_dir_exist 0 $arg
            fi ;; 
   
          script)
            which $arg > /dev/null
            exit_status=$?

            get_msg exist arg_script_exist $exit_status $arg ;;
        esac
      done ;;

    $corr_host|$pks_host)
      get_msg init arg_chk_dir 0 $loc
      echo

      filetype=$2
      user=$3
      host=$loc
      arg=$4

      case $filetype in
        dir)
          cmd="if ( -d ${corr_data_dir_path}/${arg} ) then; echo ''; endif" ;;

        script)
          cmd="which $arg"
        echo $cmd
          ;;
      esac 

      start_ssh access $user $host "$cmd" $arg ;;
  esac
  echo

}


#
# Check Epping data disk and Parkes data disk and DLT, and copy TAsummary output
# to local directory
#

function get_disk_list() {

  user=$1
  host=$2

  get_msg init arg_disk_list 0 $host
  echo

  if [ "$host" == "$epp_host" ]; then 
    cmd="TAsummary.csh $DFB_UPPER; scp $epp_dat $local_host:$dat_dir"
  fi

  #if [ "$host" == "$corr_host" ]; then
    #cmd="cd $corr_data_dir_path/$corr_data_dir; TAsummary.csh $dfb; scp $pks_dat $dlt_dat $local_host:$local_dir"
  #fi

  if [ "$host" == "$pks_host" ]; then 
    cmd="TAsummary.csh $DFB_UPPER; scp $pks_dat $dlt_dat $local_host:$dat_dir"
  fi

  start_ssh access $user $host "$cmd"
  echo

}


#
#Check dat directory contains 3 TAsummary output files
#

function check_dat_dir() {

  get_msg init arg_chk_dat_dir
  echo

  for i in $dat_dir/$epp_dat $dat_dir/$pks_dat $dat_dir/$dlt_dat
  do
    if [ ! -f "$i" ]; then
      get_msg exist arg_file_exist 1 $i
    fi
  done

  if [ ! -f "$dat_dir/$epp_dat" ] || [ ! -f "$dat_dir/$pks_dat" ] || [ ! -f "$dat_dir/$dlt_dat" ]; then
    echo
    get_msg exist arg_dat_exist 1
    exit 1
  else
    get_msg exist arg_dat_exist 0
    echo
  fi

}


#
#Compare TAsummary output files in local directory
#

function compare_dat_lists() {

  get_msg init arg_compare_dat_msg
  echo

  # Check copied from pks to epp
  for file in `awk '{print$1}' $dat_dir/$pks_dat`; do
    grep $file $dat_dir/$epp_dat >> $eppcp_dat
  done

  # Comparing files copied to Epping and DLT files.
  for file in `awk '{print$1}' $eppcp_dat`; do
    grep $file $dat_dir/$dlt_dat >> $pksbk_dat
  done

  mv $pksbk_dat $dat_dir/$del_dat
  get_msg wrapup arg_compare_dat_lists 0
  echo
  rm $eppcp_dat

}


#
#Delete files from Parkes disk on confirmation
#

function delete_files() {

  cmd_del="cd $corr_data_dir_path/$corr_data_dir; awk '{print $1}' < $del_dat | xargs -n 100 echo rm; echo rm $del_dat"
 
  get_msg init arg_delete_msg
  read input
  echo

  if [ "$input" == "y" ] || [ "$input" == "yes" ]; then
    start_ssh copy $corr_user $corr_host "$dat_dir/$del_dat" "$corr_data_dir_path/$corr_data_dir"
    start_ssh access $corr_user $corr_host "$cmd_del"
    echo
    #get_msg wrapup arg_delete_list
    echo
    cat $dat_dir/$del_dat > $log_file
    echo
    get_msg wrapup arg_delete_log
    echo
    #rm $dat_dir/*.dat
    exit 1
  else
    echo "Exiting."
    echo
    #rm $dat_dir/*.dat
    exit 1
  fi

}


#
#Run
#

usage

if [ $# -gt 1 ]; then
  echo "pulseatparkes_dfb_diskclean: ERROR: too many arguments"
  echo
  exit 1
fi

if [ $# -lt 1 ]; then
  exit
elif [ "$1" = "PDFB2" -o "$1" = "PDFB3" -o "$1" = "PDFB4" ]; then
  check_network $epp_host $pks_host
  check_file_exists $local_host dir $dat_dir $log_dir
  check_file_exists $local_host script $ta_summary
  check_file_exists $corr_host dir $corr_user $corr_data_dir
  check_file_exists $pks_host script $pks_user $ta_summary
  get_disk_list $epp_user $epp_host
  get_disk_list $pks_user $pks_host
  check_dat_dir
  compare_dat_lists

  exit
else
  echo "pulseatparkes_dfb_diskclean: ERROR: Supplied argument must be 'PDFB2', 'PDFB3' or 'PDFB4'."
  echo
  exit 1
fi


