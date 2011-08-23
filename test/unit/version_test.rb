#!/usr/bin/ruby
#
# Test the Openshift SDK VERSION string
#
require 'test_helper'

class TestVersion < Test::Unit::TestCase

  def test_leading_space
    assert_no_match(/^\s+/, 
                    Openshift::SDK::VERSION, 
                    "Version string must not have leading white space"
                    )
  end

  def test_trailing_space
    assert_no_match(/\s+$/,
                    Openshift::SDK::VERSION,
                    "Version string must not have trailing white space"
                    )
  end

  def test_version_pattern
    assert_match(/^(\d+)\.(\d+)$/, 
                 Openshift::SDK::VERSION,
                 "Version string must be of the form N.N"
                 )
  end
end

