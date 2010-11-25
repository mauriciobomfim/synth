require 'test_helper'

class IndexAttributeTest < ActiveSupport::TestCase
  def setup    
    
    #Contexts
    @people_context = SHDM::Context.create( 
      'shdm:context_name'  => 'People Name', 
      'shdm:context_title' => 'People Title', 
      'shdm:context_query' => 'ActiveRDF::ResourceQuery.new(FOAF::Person).execute'
    )
    
    #Indexes
    @people_index = SHDM::ContextIndex.create( 
      'shdm:context_index_name'    => 'People Index Name', 
      'shdm:context_index_title'   => 'People Index Title',
      'shdm:context_index_context' => @people_context 
    )
    
    #IndexAttributes
    @person_attribute_parameter = SHDM::IndexAttributeParameter.create(
      'shdm:index_attribute_parameter_name'  => 'person',
      'shdm:index_attribute_parameter_value' => 'self'
    )    
    @index_attribute = SHDM::IndexAttribute.create(
      'shdm:index_attribute_name'     => 'index attribute',
    	'shdm:index_attribute_value'    => '"Name: #{self.name}"'
    )    
    @anchor_attribute = SHDM::AnchorIndexAttribute.create(
      'shdm:index_attribute_name'              => 'anchor index attribute',
      'shdm:index_attribute_value'             => '"Click: #{self.name}"',
      'shdm:anchor_index_attribute_target_expression' => '"http://www.google.com/search?q=#{self.name}"'
    )
    @context_anchor_attribute = SHDM::ContextAnchorIndexAttribute.create(
      'shdm:index_attribute_name'                             => 'context anchor index attribute',
      'shdm:index_attribute_value'                            => '"Context Node: #{self.name}"',
      'shdm:context_anchor_index_attribute_target_context'    => @people_context,
      'shdm:context_anchor_index_attribute_target_parameters' => @person_attribute_parameter
    )
    @index_anchor_attribute = SHDM::IndexAnchorIndexAttribute.create(
      'shdm:index_attribute_name'                           => 'index anchor index attribute',
      'shdm:index_attribute_value'                          => '"Index Node: #{self.name}"',
      'shdm:index_anchor_index_attribute_target_index'      => @people_index,
      'shdm:index_anchor_index_attribute_target_parameters' => @person_attribute_parameter
    )
         
  end
  
  #Testing IndexAttribute
  
  test "must get IndexAttribute index_attribute_name" do
    assert_equal ['index attribute'], @index_attribute.index_attribute_name
    assert_equal ['index attribute'], @index_attribute.shdm::index_attribute_name
  end

  test "must get IndexAttribute index_attribute_value" do
    assert_equal ['"Name: #{self.name}"'], @index_attribute.index_attribute_value
    assert_equal ['"Name: #{self.name}"'], @index_attribute.shdm::index_attribute_value
  end

  #Testing AnchorIndexAttribute
  
  test "must get AnchorIndexAttribute index_attribute_name" do
    assert_equal ['anchor index attribute'], @anchor_attribute.index_attribute_name
    assert_equal ['anchor index attribute'], @anchor_attribute.shdm::index_attribute_name
  end

  test "must get AnchorIndexAttribute index_attribute_value" do
    assert_equal ['"Click: #{self.name}"'], @anchor_attribute.index_attribute_value
    assert_equal ['"Click: #{self.name}"'], @anchor_attribute.shdm::index_attribute_value
  end
  
  test "must get AnchorIndexAttribute anchor_index_attribute_target_expression" do
    assert_equal ['"http://www.google.com/search?q=#{self.name}"'], @anchor_attribute.anchor_index_attribute_target_expression
    assert_equal ['"http://www.google.com/search?q=#{self.name}"'], @anchor_attribute.shdm::anchor_index_attribute_target_expression
  end
  
  #Testing ContextAnchorIndexAttribute
  
  test "must get ContextAnchorIndexAttribute index_attribute_name" do
    assert_equal ['context anchor index attribute'], @context_anchor_attribute.index_attribute_name
    assert_equal ['context anchor index attribute'], @context_anchor_attribute.shdm::index_attribute_name
  end
  
  test "must get ContextAnchorIndexAttribute index_attribute_value" do
    assert_equal ['"Context Node: #{self.name}"'], @context_anchor_attribute.index_attribute_value
    assert_equal ['"Context Node: #{self.name}"'], @context_anchor_attribute.shdm::index_attribute_value
  end
  
  test "must get ContextAnchorIndexAttribute context_anchor_index_attribute_target_context" do
    assert_equal [ @people_context ], @context_anchor_attribute.context_anchor_index_attribute_target_context
    assert_equal [ @people_context ], @context_anchor_attribute.shdm::context_anchor_index_attribute_target_context
  end
  
  test "must get ContextAnchorIndexAttribute context_anchor_index_attribute_target_parameters" do
    assert_equal [ @person_attribute_parameter ], @context_anchor_attribute.context_anchor_index_attribute_target_parameters
    assert_equal [ @person_attribute_parameter ], @context_anchor_attribute.shdm::context_anchor_index_attribute_target_parameters
  end
  
  #Testing IndexAnchorIndexAttribute
  
  test "must get IndexAnchorIndexAttribute index_attribute_name" do
    assert_equal ['index anchor index attribute'], @index_anchor_attribute.index_attribute_name
    assert_equal ['index anchor index attribute'], @index_anchor_attribute.shdm::index_attribute_name
  end
  
  test "must get IndexAnchorIndexAttribute index_attribute_value" do
    assert_equal ['"Index Node: #{self.name}"'], @index_anchor_attribute.index_attribute_value
    assert_equal ['"Index Node: #{self.name}"'], @index_anchor_attribute.shdm::index_attribute_value
  end
  
  test "must get IndexAnchorIndexAttribute index_anchor_index_attribute_target_index" do
    assert_equal [ @people_index ], @index_anchor_attribute.index_anchor_index_attribute_target_index
    assert_equal [ @people_index ], @index_anchor_attribute.shdm::index_anchor_index_attribute_target_index
  end
  
  test "must get IndexAnchorIndexAttribute index_anchor_index_attribute_target_parameters" do
    assert_equal [ @person_attribute_parameter ], @index_anchor_attribute.index_anchor_index_attribute_target_parameters
    assert_equal [ @person_attribute_parameter ], @index_anchor_attribute.shdm::index_anchor_index_attribute_target_parameters
  end
  
  #Testing IndexAttributeParameter
  
  test "must get IndexAttributeParameter name" do
     assert_equal ['person'], @person_attribute_parameter.index_attribute_parameter_name
     assert_equal ['person'], @person_attribute_parameter.shdm::index_attribute_parameter_name
  end
  
  test "must get IndexAttributeParameter value" do
     assert_equal ['self'], @person_attribute_parameter.index_attribute_parameter_value
     assert_equal ['self'], @person_attribute_parameter.shdm::index_attribute_parameter_value
  end
  
end
