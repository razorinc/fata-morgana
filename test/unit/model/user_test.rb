require 'test_helper'

module Openshift::SDK::Model
  class UserTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def setup
      application = Application.new("testapp")
      application.guid = "12345678901234567890"
      @user = User.new application
    end

    def model
      @user
    end

    def test_create_user_success
      User.any_instance.expects(:shellCmd).returns(["","",0])
      User.any_instance.expects(:get_uid).returns("101")
      assert_not_nil @user
      @user.create!
      assert_equal @user.uid,"101"
      assert_equal @user.name,"a12345678"
    end

    def test_create_user_failure
      User.any_instance.expects(:shellCmd).returns(["","This is a simulated failure",1])
      User.any_instance.expects(:get_uid).returns("id: a12345678: No such user\n")
      assert_not_nil @user
      assert_raise(UserCreationException){ @user.create! }
    end
     

    def test_delete_user_success
      User.any_instance.expects(:shellCmd).returns(["","",0])
      User.any_instance.expects(:get_uid).returns("101")
      assert_not_nil @user
      @user.delete!
    end

    def test_delete_user_failure
      User.any_instance.expects(:shellCmd).returns(["","This is a simulated failure",1])
      User.any_instance.expects(:get_uid).returns("id: a12345678: No such user\n")
      assert_not_nil @user
      assert_raise(UserDeletionException){ @user.delete! }
    end
  end
end
