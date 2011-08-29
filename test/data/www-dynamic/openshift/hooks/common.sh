#!/bin/bash
#
# Copyright © 2010 Red Hat, Inc. All rights reserved
#
# This copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the GNU
# General Public License v.2.  This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY expressed or implied, including the
# implied warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.  You should have
# received a copy of the GNU General Public License along with this program;
# if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301, USA. Any Red Hat trademarks that are
# incorporated in the source code or documentation are not subject to the GNU
# General Public License and may only be used or replicated with the express
# permission of Red Hat, Inc.
#

# This file should be outside the test directory hierarchy and in someplace 
# on the system (common). Here for testing.

os_cfgdir=${OPENSHIFT_CONFIG_DIR:-"/etc/openshift"}

function os_source_config() {
   cfg=${1:-""}
   if test -n "$cfg" -a -f "$cfg"; then
      source "$cfg"
      return $?
   fi

   return 0

}  #  End of function  os_source_config.


function os_load_env() {
   declare -r os_platform_type=${OPENSHIFT_PLATFORM_TYPE:-"express"}

   #  Load all the configuration files in.
   for f in openshift.conf openshift_cluster.conf openshift_node.conf; do
      os_source_config "${os_cfgdir}/$f" 
   done

   os_source_config "${OPENSHIFT_APP_CONFIG_DIR}/.app.env"

}  #  End of function  os_load_env.


function die() {
   rc=${1:-255}
   [ -z "$2" ]  ||  echo "Error: $2"
   [ -z "$2" ]  ||  logger -p user.notice  "Error: $2"
   exit $rc

}  #  End of function  die.


function print_usage() {
   echo "Usage: $0 <app-guid> <component-guid>"
   [ -z "$1" ]  ||  echo "$1"
   
   logger -p user.notice  "$0 $@"
   exit 1

}  #  End of function  print_usage.


function os_check_args() {
   while getopts 'd' cmdopt
   do
     case $cmdopt in
        d) set -x      ;;
        ?) return 1 ;;
     esac
   done

   [ $# -eq 2 ]  ||  return 1
   return 0

}  #  End of function  os_check_args. 


#
# _initialize():  Load openshift environment and handle arguments.
#
os_load_env


