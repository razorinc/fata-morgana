require 'test/unit'
require 'vostok-sdk'

class CartridgeTest < Test::Unit::TestCase  
  def test_from_vpm
    c = Vostok::SDK::Cartridge.from_vpm("data/php-5.3")
    assert_equal("php",c.name)
    assert_equal("data/php-5.3",c.package_path)
    assert_equal(["php >= 5.3.2", "php < 5.4.0", "php-pdo", "php-gd", "php-xml", "php-mysql", "php-pgsql", "php-mbstring", "php-pear"].sort,c.requires.sort)
    assert_equal("data",c.package_root)
    assert_equal(["php", "php(version) = 5.3.2"].sort,c.provides_feature.sort)
  end
end