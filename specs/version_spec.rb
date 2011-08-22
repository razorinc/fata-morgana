#
# Check the SDK version
#
# versions should be three numeric fields seperated by two dots with no
# white space, leading, trailing or internal
#
version_re = /^(\d+)\.(\d+)\.(d+)$/

require 'openshift-sdk/version'

describe 'openshift SDK Version' do
  it "should not have leading white space" do
    Openshift::SDK::VERSION.should_not match(/^\s+/)
  end

  it "should not have trailing white space" do
    Openshift::SDK::VERSION.should_not match(/\s+$/)
  end

  it "should match the version pattern" do
    Openshift::SDK::VERSION.should match(version_re)
  end
end
