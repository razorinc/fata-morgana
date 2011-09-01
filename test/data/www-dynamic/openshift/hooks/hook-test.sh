#!/bin/bash

declare -A  g_subst_map

function init_substitution_map() {
   for k in `env | grep "^OPENSHIFT_" | cut -f1 -d '='`; do
      g_subst_map[$k]="${!k}"
   done

   return 0
}  #  End of function  init_substitution_map.

source $(cd -P -- "$(dirname -- "$0")" && pwd -P)/common.sh
os_initialize_hook_env $@
echo "General variables: "
echo "   hook-name = $hook_name"
echo "   hook-dir  = $hook_dir"
echo "   cart-name = $cartridge_name"
echo "   app-name  = $application_name"
echo "   app-guid  = $application_guid"
echo "   profile   = $openshift_profile"

init_substitution_map
echo "Map variables: "
for k in ${!g_subst_map[@]}; do 
   echo "   $k = ${g_subst_map[$k]}"
done

