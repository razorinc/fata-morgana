#--
# Copyright 2010 Red Hat, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#++
#

declare -A  os_vars_map
os_cfgdir=${OPENSHIFT_CONFIG_DIR:-"/opt/openshift/conf"}


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


function os_get_external_ipaddr() {
   local ifaddr eth0_info

   if test -f "/etc/libra/node_data.conf"; then
      ifaddr=`sh -c "source /etc/libra/node_data.conf; echo \\\$public_ip"`
   elif test -f "/var/spool/ec2/meta-data/public-ipv4"; then
      ifaddr=`cat /var/spool/ec2/meta-data/public-ipv4`
   fi

   if test -z "$ifaddr"; then
     eth0_info=`/sbin/ifconfig eth0 | grep 'inet addr:'`
     ifaddr=`echo $eth0_info | sed "s#\s*inet addr:\([0-9\.]\+\)\(.*\)#\1#"`
   fi

   printf "%s" $ifaddr

}  #  End of function  os_get_external_ipaddr.


function os_init_var_map() {
   local cfg_dir mapinfo
   cfg_dir=${OPENSHIFT_HOOK_CONTEXT:-"."}
   os_vars_map["$cartridge_name:CONFIGURATION_DIR"]="$cfg_dir"

   for k in `env | grep "^OPENSHIFT_" | cut -f1 -d '='`; do
      os_vars_map[$k]="${!k}"
   done

   mapinfo="keys:[${!g_subst_map[@]}], values:[${g_subst_map[*]}]"
   os_log_debug "os_init_var_map($1) = $mapinfo"
   return 0

}  #  End of function  os_init_var_map.


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

   # FIXME: Turn on debugging if env has it - too chatty right now ...
   # [ "DEBUG" == "$log_level" ]  &&  _DEBUG_HOOKS=${_DEBUG_HOOKS:-"1"}

   application_name=$1
   application_guid=$2

   openshift_profile=${OPENSHIFT_PROFILE:-"express"}

   #  Ensure enviornment is initialized.
   _os_ensure_env

   #  And finally initialize variable hash.
   os_init_var_map

}  #  End of function  os_initialize_env.


function os_copy_from_template() {
   local src dest substitutions
   src=${1:-""}
   dest=${2:-""}

   [ ! -f "$src" ]  &&  os_log_notice "$FUNCNAME - missing '$src'"  &&  return 1
   [ -z "$dest" ]   &&  os_log_notice "$FUNCNAME - invalid dest"  &&  return 1

   substitutions=""
   for k in ${!os_vars_map[@]}; do
      substitutions="$substitutions; s#\${$k}#${os_vars_map[$k]}#g;"
   done

   if test "$src" = "$dest"; then
      sed -i "${substitutions}" "$dest"
   else
      sed "${substitutions}" "$src" >  "$dest"
   fi

   return $?

}  #  End of function  os_copy_from_template.


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
   for v in OPENSHIFT_CONFIG_DIR  OPENSHIFT_PROFILE  OPENSHIFT_APP_GUID  \
            OPENSHIFT_HOOK_CONTEXT  OPENSHIFT_APP_HOME_DIR               \
            OPENSHIFT_APP_DEV_DIR  OPENSHIFT_APP_REPO_DIR                \
            OPENSHIFT_APP_PROD_DIR; do
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


