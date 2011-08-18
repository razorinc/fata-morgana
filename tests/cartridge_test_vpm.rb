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
require 'vostok-sdk'

class CartridgeTest < Test::Unit::TestCase  
  def test_from_vpm
    c = Vostok::SDK::Cartridge.from_vpm("data/php-5.3")
    assert_equal("php",c.name)
    assert_equal("data/php-5.3",c.package_path)
    assert_equal(["php >= 5.3.2", "php < 5.4.0", "php-pdo", "php-gd", "php-xml", "php-mysql", "php-pgsql", "php-pear"].sort,c.requires.sort)
    assert_equal("data",c.package_root)
    assert_equal(["php", "php(version) = 5.3.2"].sort,c.provides_feature.sort)
  end
end
