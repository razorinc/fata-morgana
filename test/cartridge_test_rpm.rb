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

require 'test/unit'
require 'openshift-sdk'

class CartridgeTest < Test::Unit::TestCase
  def setup
    #first cleanup yum
    system("yum remove -y openshift-cartridge-php")
    system("yum -C clean all")
    system("rm -rf /var/tmp/yum-*")
    system("rm -rf /tmp/openshift-feature-*")
    system("rm -f data/php-5.3/openshift/php.spec")
    
    #build and register rpm
    system("../bin/opm-control-to-spec #{Dir.getwd}/data/php-5.3")
    system("../bin/opm-create-rpm #{Dir.getwd}/data/php-5.3 2>&1 > /dev/null")
    system("../bin/add-to-repo #{Dir.getwd}/data/php-5.3")
    config = Openshift::SDK::Config.instance
    rpm_repo = config.get('rpm_repo')
    openshift_repo =<<-EOF
[openshift]
name=Openshift Repo
baseurl=file://#{rpm_repo}
enabled=1
gpgcheck=0
EOF
    f = File.open("/etc/yum.repos.d/openshift.repo","w")
    f.write(openshift_repo)
    f.close
  end
  
  def teardown
    system("rm -rf *.rpm")
  end
  
  def test_from_rpm
    system("yum remove -q -y openshift-cartridge-php")
    rpm = Openshift::SDK::Model::RPM.from_system("openshift-cartridge-php")
    c = Openshift::SDK::Model::Cartridge.from_rpm(rpm)
    assert_equal("openshift-cartridge-php",c.name)
    assert_equal(false,c.is_installed)
    assert_equal(["php >= 5.3.2", "php < 5.4.0", "php-pdo", "php-gd", "php-xml", "php-mysql", "php-pgsql", "php-pear"].sort,c.requires.sort)
    assert_equal(["php", "php(version) = 5.3.2"].sort,c.provides_feature.sort)
    
    system("yum install -q -y openshift-cartridge-php")
    rpm = Openshift::SDK::Model::RPM.from_system("openshift-cartridge-php")
    c = Openshift::SDK::Model::Cartridge.from_rpm(rpm)
    assert_equal("openshift-cartridge-php",c.name)
    assert_equal("/opt/openshift/cartridges/openshift-cartridge-php-1.0.0",c.package_path)
    assert_equal(true,c.is_installed)
    assert_equal(["php >= 5.3.2", "php < 5.4.0", "php-pdo", "php-gd", "php-xml", "php-mysql", "php-pgsql", "php-pear"].sort,c.requires.sort)
    assert_equal("/opt/openshift/cartridges",c.package_root)
    assert_equal(["php", "php(version) = 5.3.2"].sort,c.provides_feature.sort)
  end
  
end
