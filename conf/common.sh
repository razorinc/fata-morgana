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


function os_debug_log() {
   [ -z "$_DEBUG_HOOKS ]  ||  return 0
   echo "!DEBUG! :$SHLVL: $cartridge_name->$hook_name $@"

}  #  End of function  os_debug_log.


function os_source_config() {
   cfg=${1:-""}
   [ -n "$_DEBUG_HOOKS ]  &&  os_debug_log "os_source_config($cfg)"

   if test -n "$cfg" -a -f "$cfg"; then
      source "$cfg"
      return $?
   fi

   return 0

}  #  End of function  os_source_config.


function os_setup_environment() {
   [ -n "$_DEBUG_HOOKS ]  &&  os_debug_log "os_setup_environment($@)"

   #  Load all the configuration files in.
   for f in openshift.conf openshift_cluster.conf openshift_node.conf; do
      os_source_config "${os_cfgdir}/$f" 
   done

   os_source_config "${1:-"/tmp"}/${app_env_config_file:-"app.env"}"

}  #  End of function  os_setup_environment.


function die() {
   rc=${1:-255}
   [ -z "$2" ]  ||  echo "Error: $2 - exitcode=$rc"
   [ -z "$2" ]  ||  logger -p user.notice  "Error: $2 - exitcode=$rc"
   exit $rc

}  #  End of function  die.


function os_print_hook_usage() {
   local hook_info=${1:-"$cartridge_name->$hook_name}
   echo "Usage: $0  <app-guid>  <component-guid>"
   echo "   $hook_info"
   exit 1

}  #  End of function  os_print_hook_usage.


function os_initialize_hook_env() {
   hook_name=$(basename "$0")

   if test -z "$cartridge_name"; then
      cartridge_name=$(basename "$(cd -P -- `dirname "$0"`/../.." && pwd -P)")
   fi

   [ -n "$_DEBUG_HOOKS ]  &&  os_debug_log "os_initialize_hook_env($@)"

   if test -n "$_TRACE_HOOKS"; then
      set -x
      echo "!TRACE! :$SHLVL: $cartridge_name->$hook_name $@"
   fi

   os_setup_environment "${OPENSHIFT_APP_HOME_DIR:-"."}/${app_config_subdir}"

   application_guid=$1
   component_guid=$2

   openshift_profile=${OPENSHIFT_PROFILE:-"express"}

}  #  End of function  os_initialize_hook_env.

