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

os_cfgdir=${OPENSHIFT_CONFIG_DIR:-"/etc/openshift"}


function os_print_message() {
   level=${1:-"UNKNOWN"}
   shift
   echo "-${level}- :$SHLVL: $cartridge_name->$hook_name $@" >&1

}  #  End of function  os_print_message.


function os_log_debug() {
   [ -z "$_DEBUG_HOOKS" ]  &&  return 0
   os_print_message "DEBUG" "$@"

}  #  End of function  os_log_debug.


function os_log_notice() {
   os_print_message "NOTICE" "$@"
   logger -p user.notice "$cartridge_name->$0 $@"

}  #  End of function  os_log_notice.


function os_source_config() {
   cfg=${1:-""}
   [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "os_source_config($cfg)"

   if test -n "$cfg" -a -f "$cfg"; then
      source "$cfg"
      return $?
   fi

   return 0

}  #  End of function  os_source_config.


function os_setup_environment() {
   [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "os_setup_environment($@)"

   #  Load all the configuration files in.
   for f in openshift.conf openshift_cluster.conf openshift_node.conf; do
      os_source_config "${os_cfgdir}/$f" 
   done

   os_source_config "${1:-"/tmp"}/${app_env_config_file:-"app.env"}"

}  #  End of function  os_setup_environment.


function os_get_userifaddr() {
   local uid ifaddr
   uid=`id -u $1`
   ifaddr=`printf "127.05.%d.%d" $((uid/256)) $((uid % 256))`
   printf "%s" $ifaddr

}  #  End of function  os_get_userifaddr.


function os_print_hook_usage() {
   local hook_info hook_params 
   hook_info=${1:-"$cartridge_name->$hook_name"}
   hook_params=${2:-"<application-name>  [ <application-guid> ]"}
   echo "Usage: $0  $hook_params" >&2
   echo "   $hook_info" >&2
   exit 1

}  #  End of function  os_print_hook_usage.


function os_initialize_env() {
   hook_name=$(basename "$0")
   hook_dir=$(cd -P "`dirname "$0"`" && pwd -P)

   if [ -z "$cartridge_name" ]; then
      cartridge_name=$(basename "$(cd -P "`dirname "$0"`/../.." && pwd -P)")
   fi

   [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "os_initialize_env($@)"
   [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "hook dir = $hook_dir"

   if [ -n "$_TRACE_HOOKS" ]; then
      set -x
      echo "-TRACE- :$SHLVL: $cartridge_name->$hook_name $@" >&1
   fi

   os_setup_environment "${OPENSHIFT_APP_HOME_DIR:-"."}/${app_config_subdir}"

   application_name=$1
   application_guid=$2

   openshift_profile=${OPENSHIFT_PROFILE:-"express"}

   #  Ensure enviornment is initialized.
   _os_ensure_env

}  #  End of function  os_initialize_env.


function die() {
   rc=${1:-255}
   shift
   if [ -n "$@" ]; then
      echo "-ERROR- :$SHLVL: $cartridge_name->$hook_name $@ - exitcode=$rc" >&2
      os_log_notice "Exiting due to error :$@: exitcode=$rc"
   fi

   exit $rc

}  #  End of function  die.



#
#  Internal functions.
#
function _os_get_missing_vars() {
   missing_vars=""
   for v in OPENSHIFT_CONFIG_DIR  OPENSHIFT_PROFILE                   \
            OPENSHIFT_APP_GUID OPENSHIFT_COMPONENT_GUID               \
            OPENSHIFT_APP_TYPE OPENSHIFT_APP_HOME_DIR                 \
            OPENSHIFT_APP_REPO_DIR OPENSHIFT_APP_PROD_DIR; do
      [ -z "${!v}" ]  &&  missing_vars="$missing_vars $v"
   done

   echo $missing_vars
   return 0

}  #  End of function  _os_get_missing_vars.


function _os_ensure_env() {
   if [ -z "`_os_get_missing_vars`" ]; then
      application_guid=${application_guid:-$OPENSHIFT_APP_GUID}
      return 0;
   fi

   while read envline; do
      [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "os_ensure_env: $envline"
      if [ "${line:0:6}" != "export" ]; then
         os_print_message "ERROR" "opm-get-hook-env: Invalid setting '$envline'"
      else
         $envline;
      fi
   done < <(opm-get-hook-env $application_name $cartridge_name $hook_name)

   application_guid=${application_guid:-$OPENSHIFT_APP_GUID}
   vars404=$(_os_get_missing_vars)
   [ -n "$vars404" ]  &&  die 2 "Invalid hook context - missing $vars404"
   return 0 

}  #  End of function  _os_ensure_env.


#
#  source_main(): Ensure environment.
#
# os_hook_cmd="$(basename "$0") $@"
os_initialize_env $@
[ -z "$_DEBUG_HOOKS" ]  ||  os_log_debug "completed initializing hook env"


