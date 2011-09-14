#!/bin/bash

source $(cd -P -- "$(dirname -- "$0")" && pwd -P)/common.sh
[ $# -ge 1 ]  ||  os_print_hook_usage

echo "General variables: "
echo "   hook-name = $hook_name"
echo "   hook-dir  = $hook_dir"
echo "   cart-name = $cartridge_name"
echo "   app-name  = $application_name"
echo "   app-guid  = $application_guid"
echo "   profile   = $openshift_profile"

init_substitution_map
echo "Map variables: "
for k in ${!os_vars_map[@]}; do
   echo "   $k = ${os_vars_map[$k]}"
done

