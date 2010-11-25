require 'test_helper'

class InContextClass < ActiveSupport::TestCase

  def setup

    #Resources
    ActiveRDF::Namespace.register :foaf, 'http://foaf#'

    FOAF::Person
    eval %{
    class FOAF::Person
      property FOAF::name
      property FOAF::age
      property FOAF::knows, 'rdfs:range' => FOAF::Person
    end
    }

    @mauricio = FOAF::Person.create('http://base#mauricio', :name => 'mauricio', :age => 31)
    @daniel   = FOAF::Person.create('http://base#daniel', :name => 'daniel')
    @john     = FOAF::Person.create('http://base#john', :name => 'john', :age => 21, :knows => [ @mauricio, @daniel ])
    
    #Contexts
    @people_context = SHDM::Context.create( 
      'shdm:context_name'  => 'People Name', 
      'shdm:context_title' => 'People Title', 
      'shdm:context_query' => 'ActiveRDF::ResourceQuery.new(FOAF::Person).execute'
    )   
    @friends_of = SHDM::Context.create( 
      'shdm:context_name'  => 'FriendsOf', 
      'shdm:context_title' => 'Friends of', 
      'shdm:context_query' => '@parameters_values[:person].foaf::knows'
    )
    @person_parameter = SHDM::ContextParameter.create(
      'shdm:context_parameter_name'  => 'person',
      'shdm:context_parameter_class' => 'FOAF::Person'
    )          
    @friends_of.shdm::context_parameters << @person_parameter
    
    #Indexes
    @people_index = SHDM::ContextIndex.create( 
      'shdm:context_index_name'    => 'People Index Name', 
      'shdm:context_index_title'   => 'People Index Title',
      'shdm:context_index_context' => @people_context 
    )
    @friends_of_index = SHDM::ContextIndex.create( 
      'shdm:context_index_name'  => 'FriendsOfIndex', 
      'shdm:context_index_title' => 'Friends of Index', 
      'shdm:context_index_context' => @friends_of 
    )
    
    #IndexAttributes
    @name_attribute = SHDM::IndexAttribute.create(
      'shdm:index_attribute_name'     => 'name',
    	'shdm:index_attribute_value'    => '"Name: #{self.name}"',
    	'shdm:index_attribute_position' => 1,
    	'shdm:index_attribute_index'    => @people_index
    )
    @age_attribute = SHDM::IndexAttribute.create(
      'shdm:index_attribute_name'     => 'age',
    	'shdm:index_attribute_value'    => '"Age: #{self.age}"',
    	'shdm:index_attribute_position' => 2,
    	'shdm:index_attribute_index'    => @people_index
    )
    @name_age_attribute = SHDM::IndexAttribute.create(
      'shdm:index_attribute_name'     => 'name_age',
    	'shdm:index_attribute_value'    => '"#{name} - #{age}"',
    	'shdm:index_attribute_position' => 3,
    	'shdm:index_attribute_index'    => @people_index
    )

    #NavigationAttributeParameters
    @person_nav_attribute_parameter = SHDM::NavigationAttributeParameter.create(
      'shdm:navigation_attribute_parameter_name'  => 'person',
      'shdm:navigation_attribute_parameter_value' => 'self'
    )

    #IndexNavigationAttributes
    @friends_nav_attribute = SHDM::IndexNavigationAttribute.create(
      'shdm:navigation_attribute_name'                   => 'friends',
      'shdm:index_navigation_attribute_index'            => @friends_of_index,
      'shdm:index_navigation_attribute_index_parameters' => @person_nav_attribute_parameter
    )

    #ContextAnchorNavigationAttributes
    @friends_of_context_anchor_nav_attribute = SHDM::ContextAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                             => 'friends_of_anchor',
      'shdm:context_anchor_navigation_attribute_label_expression'  => '"Friends of #{name}"',
      'shdm:context_anchor_navigation_attribute_target_context'    => @friends_of,
      'shdm:context_anchor_navigation_attribute_target_parameters' => @person_nav_attribute_parameter,
      'shdm:context_anchor_navigation_attribute_target_node_expression' => 'self'
    )
    
    #IndexAnchorNavigationAttributes
    @friends_of_index_anchor_nav_attribute = SHDM::IndexAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                           => 'friends_of_index_anchor',
      'shdm:index_anchor_navigation_attribute_label_expression'  => '"Friends of #{name} index"',
      'shdm:index_anchor_navigation_attribute_target_index'      => @friends_of_index,
      'shdm:index_anchor_navigation_attribute_target_parameters' => @person_nav_attribute_parameter
    )
    
    #AnchorNavigationAttributes
    @google_anchor_nav_attribute = SHDM::AnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                     => 'google_anchor',
      'shdm:anchor_navigation_attribute_label_expression'  => '"Find #{name} in google"',
      'shdm:anchor_navigation_attribute_target_expression' => '"http://www.google.com/search?q=#{name}"'      
    )

    #ComputedNavigationAttributes
    @birth_year_nav_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'                      => 'birth_year',
      'shdm:computed_navigation_attribute_value_expression' => 'Date.today.year - self.age'
    )
    
    #InContextClass
    @person_in_people_context = SHDM::InContextClass.create(
      'shdm:in_context_class_class'                 => FOAF::Person,
#     'shdm:in_context_class_context'               => @people_context,
      'shdm:in_context_class_navigation_attributes' => @friends_nav_attribute
    )
    @people_context.context_in_context_class = @person_in_people_context
    
    #Instances
    @people_context_instance = @people_context.new
    @friends_of_john     = @friends_of.new(:person => @john)
    @friends_of_mauricio = @friends_of.new(:person => @mauricio)
        
  end

  #Testing InContextClass
  test "must get InContextClass class" do
    assert_equal [ FOAF::Person ], @person_in_people_context.in_context_class_class.to_ary
    assert_equal [ FOAF::Person ], @person_in_people_context.shdm::in_context_class_class.to_ary
  end
  
  test "must get InContextClass context" do
    assert_equal [ @people_context ], @person_in_people_context.in_context_class_context
    assert_equal [ @people_context ], @person_in_people_context.shdm::in_context_class_context
  end
  
  test "must get InContextClass navigation_attributes" do
    assert_equal [ @friends_nav_attribute ], @person_in_people_context.in_context_class_navigation_attributes
    assert_equal [ @friends_nav_attribute ], @person_in_people_context.shdm::in_context_class_navigation_attributes
  end
  
  #Testing IndexNavigationAttribute
  test "must get IndexNavigationAttribute name" do
    assert_equal [ 'friends' ], @friends_nav_attribute.navigation_attribute_name
    assert_equal [ 'friends' ], @friends_nav_attribute.shdm::navigation_attribute_name
  end
  
  test "must get IndexNavigationAttribute index" do
    assert_equal [ @friends_of_index ], @friends_nav_attribute.index_navigation_attribute_index
    assert_equal [ @friends_of_index ], @friends_nav_attribute.shdm::index_navigation_attribute_index
  end
  
  test "must get IndexNavigationAttribute index_parameters" do
    assert_equal [ @person_nav_attribute_parameter ], @friends_nav_attribute.index_navigation_attribute_index_parameters
    assert_equal [ @person_nav_attribute_parameter ], @friends_nav_attribute.shdm::index_navigation_attribute_index_parameters
  end
  
  #Testing ContextAnchorNavigationAttribute
  test "must get ContextAnchorNavigationAttribute name" do
    assert_equal [ 'friends_of_anchor' ], @friends_of_context_anchor_nav_attribute.navigation_attribute_name
    assert_equal [ 'friends_of_anchor' ], @friends_of_context_anchor_nav_attribute.shdm::navigation_attribute_name
  end
  
  test "must get ContextAnchorNavigationAttribute label expression" do
    assert_equal [ '"Friends of #{name}"' ], @friends_of_context_anchor_nav_attribute.context_anchor_navigation_attribute_label_expression
    assert_equal [ '"Friends of #{name}"' ], @friends_of_context_anchor_nav_attribute.shdm::context_anchor_navigation_attribute_label_expression
  end
  
  test "must get ContextAnchorNavigationAttribute target context" do
    assert_equal [ @friends_of ], @friends_of_context_anchor_nav_attribute.context_anchor_navigation_attribute_target_context
    assert_equal [ @friends_of ], @friends_of_context_anchor_nav_attribute.shdm::context_anchor_navigation_attribute_target_context
  end
  
  test "must get ContextAnchorNavigationAttribute target parameters" do
    assert_equal [ @person_nav_attribute_parameter ], @friends_of_context_anchor_nav_attribute.context_anchor_navigation_attribute_target_parameters
    assert_equal [ @person_nav_attribute_parameter ], @friends_of_context_anchor_nav_attribute.shdm::context_anchor_navigation_attribute_target_parameters
  end
  
  test "must get ContextAnchorNavigationAttribute target node expression" do
    assert_equal [ 'self' ], @friends_of_context_anchor_nav_attribute.context_anchor_navigation_attribute_target_node_expression
    assert_equal [ 'self' ], @friends_of_context_anchor_nav_attribute.shdm::context_anchor_navigation_attribute_target_node_expression
  end
  
  #Testing IndexAnchorNavigationAttribute
  test "must get IndexAnchorNavigationAttribute name" do
    assert_equal [ 'friends_of_index_anchor' ], @friends_of_index_anchor_nav_attribute.navigation_attribute_name
    assert_equal [ 'friends_of_index_anchor' ], @friends_of_index_anchor_nav_attribute.shdm::navigation_attribute_name
  end
  
  test "must get IndexAnchorNavigationAttribute label expression" do
    assert_equal [ '"Friends of #{name} index"' ], @friends_of_index_anchor_nav_attribute.index_anchor_navigation_attribute_label_expression
    assert_equal [ '"Friends of #{name} index"' ], @friends_of_index_anchor_nav_attribute.shdm::index_anchor_navigation_attribute_label_expression
  end
  
  test "must get IndexAnchorNavigationAttribute target index" do
    assert_equal [ @friends_of_index ], @friends_of_index_anchor_nav_attribute.index_anchor_navigation_attribute_target_index
    assert_equal [ @friends_of_index ], @friends_of_index_anchor_nav_attribute.shdm::index_anchor_navigation_attribute_target_index
  end
  
  test "must get IndexAnchorNavigationAttribute target parameters" do
    assert_equal [ @person_nav_attribute_parameter ], @friends_of_index_anchor_nav_attribute.index_anchor_navigation_attribute_target_parameters
    assert_equal [ @person_nav_attribute_parameter ], @friends_of_index_anchor_nav_attribute.shdm::index_anchor_navigation_attribute_target_parameters
  end
  
  #Testing AnchorNavigationAttribute
  test "must get AnchorNavigationAttribute name" do
    assert_equal [ 'google_anchor' ], @google_anchor_nav_attribute.navigation_attribute_name
    assert_equal [ 'google_anchor' ], @google_anchor_nav_attribute.shdm::navigation_attribute_name
  end

  test "must get AnchorNavigationAttribute label_expression" do
    assert_equal [ '"Find #{name} in google"' ], @google_anchor_nav_attribute.anchor_navigation_attribute_label_expression
    assert_equal [ '"Find #{name} in google"' ], @google_anchor_nav_attribute.shdm::anchor_navigation_attribute_label_expression
  end

  test "must get AnchorNavigationAttribute target_expression" do
    assert_equal [ '"http://www.google.com/search?q=#{name}"' ], @google_anchor_nav_attribute.anchor_navigation_attribute_target_expression
    assert_equal [ '"http://www.google.com/search?q=#{name}"' ], @google_anchor_nav_attribute.shdm::anchor_navigation_attribute_target_expression
  end

  #Testing ComputedNavigationAttribute
  test "must get ComputedNavigationAttribute name" do
    assert_equal [ 'birth_year' ], @birth_year_nav_attribute.navigation_attribute_name
    assert_equal [ 'birth_year' ], @birth_year_nav_attribute.shdm::navigation_attribute_name
  end

  test "must get ComputedNavigationAttribute value expression" do
    assert_equal [ 'Date.today.year - self.age' ], @birth_year_nav_attribute.computed_navigation_attribute_value_expression
    assert_equal [ 'Date.today.year - self.age' ], @birth_year_nav_attribute.shdm::computed_navigation_attribute_value_expression
  end

  #Testing NavigationAttributeParameter
  test "must get NavigationAttributeParameter name" do
    assert_equal [ 'person' ], @person_nav_attribute_parameter.navigation_attribute_parameter_name
    assert_equal [ 'person' ], @person_nav_attribute_parameter.shdm::navigation_attribute_parameter_name
  end

  test "must get NavigationAttributeParameter value" do
    assert_equal [ 'self' ], @person_nav_attribute_parameter.navigation_attribute_parameter_value
    assert_equal [ 'self' ], @person_nav_attribute_parameter.shdm::navigation_attribute_parameter_value
  end
  
end
