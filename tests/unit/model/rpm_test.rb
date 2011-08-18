require 'test_helper'

module Vostok::SDK::Model
  class RPMTest < Test::Unit::TestCase
    def test_from_system_not_installed
      RPM.expects(:is_installed?).returns(false)
      assert_nil RPM.from_system("httpd")
    end

    def test_from_system
      # Mock the repoquery output
      RPM.expects(:is_installed?).returns(true)
      RPM.any_instance.expects(:query_info).returns("Summary:  summary\nVersion:   1.2.3\nArchitecture:   x86_64")
      RPM.any_instance.expects(:query_dependencies).returns("Finding blah\n  dependency: 1\n dependency: 2\n  provider: blah")
      RPM.any_instance.expects(:query_provides).returns("config(something)\n webserver")
      RPM.any_instance.expects(:query_file_data).returns("/control.spec\n/descriptor.json\n/hooks/1\n/hooks/2")

      # Do the verifications
      rpm = RPM.from_system("httpd")
      assert_not_nil rpm
      assert_equal 'httpd', rpm.name
      assert_equal 'summary', rpm.summary
      assert_equal '1.2.3', rpm.version
      assert_equal ['1', '2'], rpm.dependencies
      assert_equal ['config(something)', 'webserver'], rpm.provides
      assert_equal '/control.spec', rpm.control
      assert_equal '/descriptor.json', rpm.descriptor
      assert_equal ['/hooks/1', '/hooks/2'], rpm.hooks
    end
  end
end
