require 'test_helper'

class LandmarkTest < ActiveSupport::TestCase
  
  def setup
    
    #Contexts
    @people_context = SHDM::Context.create( 
      'shdm:context_name'  => 'People Name', 
      'shdm:context_title' => 'People Title', 
      'shdm:context_query' => 'ActiveRDF::ResourceQuery.new(FOAF::Person).execute'
    )
    
    #Indexes
    @people_index = SHDM::ContextIndex.create( 
      'shdm:index_name'    				 => 'People Index Name', 
      'shdm:index_title'   				 => 'People Index Title',
      'shdm:context_index_context' => @people_context 
    )
    
    #ContextAnchorNavigationAttributes
    @context_anchor_attribute = SHDM::ContextAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                            => 'People Context Landmark',
      'shdm:context_anchor_navigation_attribute_label_expression' => '"People Context"',
      'shdm:context_anchor_navigation_attribute_target_context'   => @people_context
    )
    
    #IndexAnchorNavigationAttributes
    @index_anchor_attribute = SHDM::IndexAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                          => 'People Index Landmark',
      'shdm:index_anchor_navigation_attribute_label_expression' => '"People Index"',
      'shdm:index_anchor_navigation_attribute_target_index'     => @people_index
    )
    
    #Context Landmarks
    @context_landmark = SHDM::Landmark.create(
      'shdm:landmark_name'                 => 'People Context Landmark',
      'shdm:landmark_position'             => 1,
      'shdm:landmark_navigation_attribute' => @context_anchor_attribute
    )

    #Index Landmarks
    @index_landmark = SHDM::Landmark.create(
      'shdm:landmark_name'                 => 'People Index Landmark',
      'shdm:landmark_position'             => 2,
      'shdm:landmark_navigation_attribute' => @index_anchor_attribute
    )
    
  end
    
  #Testing Context Landmark
    
  test 'must get context landmark_name' do
    assert_equal ['People Context Landmark'], @context_landmark.landmark_name
    assert_equal ['People Context Landmark'], @context_landmark.shdm::landmark_name
  end

  test 'must get context landmark_position' do
    assert_equal [1], @context_landmark.landmark_position
    assert_equal [1], @context_landmark.shdm::landmark_position
  end

  test 'must get context landmark label' do
    assert_equal 'People Context', @context_landmark.label
  end
  
  test 'must get context landmark target url' do
    assert_equal @people_context.url, @context_landmark.target_url
  end
  
  test 'must get context landmark target url with parameters' do
    @context_anchor_attribute.context_anchor_navigation_attribute_target_parameters = SHDM::NavigationAttributeParameter.create(
      'shdm:navigation_attribute_parameter_name' => 'ParameterName',
      'shdm:navigation_attribute_parameter_value_expression' => 'self.class'
    )
    assert_equal @people_context.url('ParameterName' => 'Hash'), @context_landmark.target_url
  end
  
  #Testing Index Landmark
  
  test 'must get index landmark_name' do
    assert_equal ['People Index Landmark'], @index_landmark.landmark_name
    assert_equal ['People Index Landmark'], @index_landmark.shdm::landmark_name
  end

  test 'must get index landmark_position' do
    assert_equal [2], @index_landmark.landmark_position
    assert_equal [2], @index_landmark.shdm::landmark_position
  end

  test 'must get index landmark label' do
    assert_equal 'People Index', @index_landmark.label
  end
  
  test 'must get index landmark target url' do
    assert_equal @people_index.url, @index_landmark.target_url
  end
  
  test 'must get index landmark target url with parameters' do
    @index_anchor_attribute.index_anchor_navigation_attribute_target_parameters = SHDM::NavigationAttributeParameter.create(
      'shdm:navigation_attribute_parameter_name' => 'ParameterName',
      'shdm:navigation_attribute_parameter_value_expression' => 'self.class'
    )
    assert_equal @people_index.url('ParameterName' => 'Hash'), @index_landmark.target_url
  end
    
end
