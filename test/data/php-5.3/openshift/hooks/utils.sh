#!/bin/bash
#
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

#
# Functions.
#
function php_ensure_pear_env() {
   cfg_dir=${1:-"."}
   pear_root="$cfg_dir/phplib/pear"
   pearrc="${OPENSHIFT_APP_HOME_DIR:-"."}/.pearrc"

   [ ! -f "$pearrc" ]  &&  pear config-create "$pear_root" "$pearrc"

   [ -z "`pear -c "$pearrc" config-get php_ini`" ]  ||  return 0
   pear -c "$pearrc" config-set php_ini "$cfg_dir/etc/conf/php.ini"

} #  End of function  php_ensure_pear_env.


function php_resolve_dependencies() {
   cfg_dir=${1:-"."}
   phpdeps=$cfgdir/php-dependencies

   #  Ensure pear environment was configured.
   php_ensure_pear_env "$cfg_dir"

   #  Install deps as needed.
   [ -f "$phpdeps" ]  ||  return 0

   for dep in `cat "$phpdeps"`; do
      if pear list "$dep" > /dev/null; then
         [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "Upgrading $dep ..."
         pear upgrade "$dep"
      else
         [ -n "$_DEBUG_HOOKS" ]  &&  os_log_debug "Installing $dep ..."
         pear install "$dep"
      fi
   done

} #  End of function  php_resolve_dependencies.


#
# _on_load():
#
[ -n "`type -t os_log_debug`"]  &&  os_log_debug "completed sourcing utils.sh"

