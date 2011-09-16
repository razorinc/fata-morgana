require 'test_helper'

module Openshift::SDK::Model
  class RPMTest < Test::Unit::TestCase
    def test_from_system_not_installed
      RPM.expects(:is_installed?).returns(false)
      RPM.any_instance.expects(:query_info).returns("Summary:  summary\nVersion:   1.2.3\nArchitecture:   x86_64".split("\n"))
      RPM.any_instance.expects(:query_dependencies).returns("Finding blah\n  dependency: 1\n dependency: 2\n  provider: blah".split("\n"))
      RPM.any_instance.expects(:query_provides).returns("config(something)\n webserver".split("\n"))
      RPM.any_instance.expects(:query_file_data).returns(nil)

      rpm = RPM.from_system("httpd")
      assert_not_nil rpm
      assert_equal 'httpd', rpm.name
      assert_equal 'summary', rpm.summary
      assert_equal '1.2.3', rpm.version
      assert_equal ['1', '2'], rpm.dependencies
      assert_equal ['config(something)', 'webserver'], rpm.provides
      assert_equal nil, rpm.manifest
      assert_equal [], rpm.hooks
    end

    def test_from_system
      # Mock the repoquery output
      RPM.expects(:is_installed?).returns(true)
      RPM.any_instance.expects(:query_info).returns("Summary:  summary\nVersion:   1.2.3\nArchitecture:   x86_64".split("\n"))
      RPM.any_instance.expects(:query_dependencies).returns("Finding blah\n  dependency: 1\n dependency: 2\n  provider: blah".split("\n"))
      RPM.any_instance.expects(:query_provides).returns("config(something)\n webserver".split("\n"))
      RPM.any_instance.expects(:query_file_data).returns("/manifest.yml\n/hooks/1\n/hooks/2".split("\n"))

      # Do the verifications
      rpm = RPM.from_system("httpd")
      assert_not_nil rpm
      assert_equal 'httpd', rpm.name
      assert_equal 'summary', rpm.summary
      assert_equal '1.2.3', rpm.version
      assert_equal ['1', '2'], rpm.dependencies
      assert_equal ['config(something)', 'webserver'], rpm.provides
      assert_equal '/manifest.yml', rpm.manifest
      assert_equal ['/hooks/1', '/hooks/2'], rpm.hooks
    end
    
    def teardown
      Mocha::Mockery.instance.stubba.unstub_all
    end
  end
end
