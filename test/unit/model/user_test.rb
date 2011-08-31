require 'test_helper'

module Openshift::SDK::Model
  class UidUserMapTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests
    
    def model
      UidUserMap.new
    end
    
    def test_reserve_application_user
      Openshift::SDK::Config.any_instance.expects(:get).with("package_root").returns("/opt/openshift/cartridges")
      Openshift::SDK::Config.any_instance.expects(:get).with("app_user_home").returns("/opt/openshift/applications")
      Openshift::SDK::Config.any_instance.expects(:get).with("datasource_type").returns("sqlite")
      Openshift::SDK::Config.any_instance.expects(:get).with("datasource_location").returns("/var/tmp/")      
      application = Application.new("testapp")
      application.guid = "12345678901234567890"
      application.user_group_id = "100"

      Openshift::SDK::Config.any_instance.expects(:get).with("min_user_id").returns("1")
      Openshift::SDK::Config.any_instance.expects(:get).with("max_user_id").returns("2")
      UidUserMap.expects(:find_all_guids).returns(["1"])
      UidUserMap.any_instance.expects(:save!).at_least_once.returns(true)
      User.any_instance.expects(:save!).at_least_once.returns(true)
      
      uguid=UidUserMap.reserve_application_user(application)
    end
  end
  
  class GidApplicationMapTest  < Test::Unit::TestCase
    include ActiveModel::Lint::Tests
    
    def model
      GidApplicationMap.new
    end
    
    def reserve_application_group_test
      Openshift::SDK::Config.any_instance.expects(:get).with("package_root").returns("/opt/openshift/cartridges")
      Openshift::SDK::Config.any_instance.expects(:get).with("app_user_home").returns("/opt/openshift/applications")
      application = Application.new("testapp")
      application.guid = "12345678901234567890"
      
      Openshift::SDK::Config.any_instance.expects(:get).with("min_group_id").returns("1")
      Openshift::SDK::Config.any_instance.expects(:get).with("max_group_id").returns("2")
      GidApplicationMap.expects(:find_all_guids).returns(["1"])
      GidApplicationMap.any_instance.expects(:save!).at_least_once.returns(true)
      
      gid = GidApplicationMap.application_group_test app
      assert_equal gid,"2"
    end
  end
    
  class UserTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def setup
      Openshift::SDK::Config.any_instance.expects(:get).with("package_root").returns("/opt/openshift/cartridges")
      Openshift::SDK::Config.any_instance.expects(:get).with("app_user_home").returns("/opt/openshift/applications")
      application = Application.new("testapp")
      application.guid = "12345678901234567890"
      application.user_group_id = "100"
      @user = User.new application, "100"
    end

    def model
      @user
    end

    def test_create_user_success
      FileUtils.expects(:mkdir_p).at_least_once.returns(true)
      User.any_instance.expects(:shellCmd).at_least_once.returns(["","",0])
      assert_not_nil @user
      @user.create!
      assert_equal @user.uid,"100"
      assert_equal @user.name,"a12345678"
    end

    def test_create_user_failure
      FileUtils.expects(:mkdir_p).at_least_once.returns(true)      
      User.any_instance.expects(:shellCmd).returns(["","This is a simulated failure",1])
      assert_not_nil @user
      assert_raise(UserCreationException){ @user.create! }
    end

    def test_delete_user_success
      User.any_instance.expects(:shellCmd).returns(["","",0])
      assert_not_nil @user
      @user.remove!
    end

    def test_delete_user_failure
      User.any_instance.expects(:shellCmd).returns(["","This is a simulated failure",1])
      assert_not_nil @user
      assert_raise(UserDeletionException){ @user.remove! }
    end
  end
end
