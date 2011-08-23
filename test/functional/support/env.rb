#
# Create the environment needed for testing cartridge management tools
#

# The location of the tests can be determined from the location of this file.
$test_root = __FILE__.sub(%r|/support/env.rb|, '')
$test_tmp = $test_root + '/tmp'
$test_data = $test_root + '/data'

# add $test_root/../../lib to the path
$LOAD_PATH << File.dirname(File.dirname($test_root)) + '/lib'

$yum_config_file = $test_data + '/yum.conf'


