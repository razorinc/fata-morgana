# from openshift tests

require 'openshift-sdk'

Given /^an accepted node$/ do

end

Given /^there are no cartridges installed$/ do
  # cartridge dir does not exist, or contains no directories
  begin
    cart_dir = Dir.new("/usr/libexec/li/cartridges")
    if cart_dir.count > 0
      raise Exception.new "there are cartridges installed"
    end
  rescue Errno::ENOENT
    # an exception means there's no directory, so no carts
  end

end

Given /^the (\S+) cartridge( not)? installed$/ do | cart_type, negate |
  pending # express the regexp above with the code you wish you had
end

Given /^a yum repository$/ do
  #pending # express the regexp above with the code you wish you had
end

Given /^the (\S+) package is available in the yum repository$/ do | cart_type |
  pending # express the regexp above with the code you wish you had
end

When /^I check the presence of the (\S+) cartridge$/ do | cart_type |
  @cartridge = Openshift::SDK::Model::Cartridge.new cart_type
end

When /^I ask what package provides the (\S+) feature$/ do | cart_type |
  pending # express the regexp above with the code you wish you had
end

When /^I request the (\S+) cartridge$/ do | cart_type |
  pending # express the regexp above with the code you wish you had
end

Then /^I find that the (\S+) cartridge is( not)? installed$/ do | cart_type, negate |
  @cartridge.is_installed.should be (negate == nil), "cartridge #{cart_type} should#{negate} be installed"
end

Then /^I find that the (\S+) package is( not)? present$/ do | pkg_name, negate |
  pending # express the regexp above with the code you wish you had
end

Then /^I am given the name of the (\S+) package$/ do | cart_type |
  pending # express the regexp above with the code you wish you had
end
