require 'test_helper'

class ExecuteControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  
  test "external operation" do
     SHDM::Operation.create("operation_name" => "external", "operation_code" =>'@value = 1+1; render :text => "<body>#{@value}</body>"', "operation_type" => "external")

     get :external
     assert_response :success
     assert_not_nil assigns(:value)
     assert_select 'body', "2"
  end

  test "external operation failure" do
    SHDM::Operation.create("operation_name" => "external", "operation_code" =>'a', "operation_type" => "external")
    get :external
    assert_response :success
  end
  
end
