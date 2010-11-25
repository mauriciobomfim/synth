require 'test_helper'

class OperationTest < ActiveSupport::TestCase

  def setup
    @sum = SHDM::Operation.create("operation_name" => "sum", "operation_code" =>"x + y")
    @sum.operation_parameters << SHDM::OperationParameter.create("operation_parameter_name" => "x", "operation_parameter_data_type" => "Integer")
    @sum.operation_parameters << SHDM::OperationParameter.create("operation_parameter_name" => "y", "operation_parameter_data_type" => "Integer")
    @sum.operation_pre_conditions << SHDM::PreCondition.create("pre_condition_name" => "x_less_than_10000", "pre_condition_expression" => "x < 10000")  
    @sum.operation_pre_conditions << SHDM::PreCondition.create("pre_condition_name" => "y_less_than_10000", "pre_condition_expression" => "y < 20000", "pre_condition_failure_handling" => '{:error => "y should be less than 20000"}')
    @sum.operation_post_conditions << SHDM::PostCondition.create("post_condition_name" => "sum_not_equal_10000", "post_condition_expression" => "x + y != 10000") 
    @fixed = SHDM::Operation.create("operation_name" => "fixed", "operation_code" =>"'fixed'")
  end

  test "should get type mismatch error" do
    expected = { :error => "The 'x' parameter type mismatch. It should be Integer, but got String." }
    assert_equal expected, @sum.execute(:x => '1', :y => 2)    
    expected = { :error => "The 'x' parameter type mismatch. It should be Integer, but got NilClass." }
    assert_equal expected, @sum.execute(:y => 1)
  end  
  
  test "should get pre condition failure" do
    assert_equal SHDM::Operation::Errors[:pre_condition_default_failure], @sum.execute(:x => 10000, :y => 2)
    expected = {:error => "y should be less than 20000"}
    assert_equal expected, @sum.execute(:x => 2, :y => 20000)
  end
  
  test "should get pre condition exception" do
    @sum.operation_pre_conditions << SHDM::PreCondition.create("pre_condition_name" => "exception", "pre_condition_expression" => "if") 
    assert_equal SHDM::Operation::Errors[:pre_condition_exception], @sum.execute(:x => 2, :y => 3)
  end
  
  test "should get post condition failure" do
    assert_equal SHDM::Operation::Errors[:post_condition_default_failure], @sum.execute(:x => 5000, :y => 5000)
  end
  
  test "should get post condition exception" do
    @sum.operation_post_conditions << SHDM::PostCondition.create("post_condition_name" => "exception", "post_condition_expression" => "if") 
    assert_equal SHDM::Operation::Errors[:post_condition_exception], @sum.execute(:x => 2, :y => 3)
  end
  
  test "should just work" do
    assert_equal 5, @sum.execute(:x => 2, :y => 3)
    assert_equal 'fixed', @fixed.execute(:ignored => 'ignored')
  end
  
  test "direct access" do
    assert_equal 5, Operations.sum(:x => 2, :y => 3)
  end
  
  test "should raise nomethod error" do
    assert_raise(NoMethodError){ Operations.zero }
  end
  
  test "external operation" do
    op = SHDM::Operation.create("operation_name" => "external", "operation_code" =>"true", "operation_type" => "external")
    eval %{class Op
      include Operations
    end}    
    instance = Op.new
    assert_respond_to instance, :external
    
    op.update_attributes(:operation_type => 'internal')

    assert !instance.respond_to?(:external)
  end
  
  test "external operation combined" do
    SHDM::Operation.create("operation_name" => "external_op", "operation_code" =>"Operations.sum(:x => 2, :y => 3)", "operation_type" => 'external')
    assert 5, ExecuteController.new.external_op
  end  
  
  test "external operation combined with pre exception" do
    internal_op = SHDM::Operation.create("operation_name" => 'internal_op', "operation_code" => 'true')  
    internal_op.operation_pre_conditions << SHDM::PreCondition.create("pre_condition_name" => "exception", "pre_condition_expression" => "if")
    SHDM::Operation.create("operation_name" => "external_op", "operation_code" =>"Operations.internal_op", "operation_type" => 'external')
  
    assert_equal SHDM::Operation::Errors[:pre_condition_exception], ExecuteController.new.external_op
  end

end
