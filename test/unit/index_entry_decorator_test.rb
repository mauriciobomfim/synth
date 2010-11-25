require 'test_helper'

class IndexEntryDecoratorTest < ActiveSupport::TestCase
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
    @daniel   = FOAF::Person.create('http://base#daniel'  , :name => 'daniel')
    @john     = FOAF::Person.create('http://base#john'    , :name => 'john', :age => 21, :knows => [ @mauricio, @daniel ])

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
      
    #NavigationAttributes 
    @name_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     => 'name',
			'shdm:navigation_attribute_index_position' => 1,
    	'shdm:computed_navigation_attribute_value_expression'    => '"Name: #{self.name}"'
    )
		@people_index.index_attributes << @name_attribute
		
    @age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     => 'age',
			'shdm:navigation_attribute_index_position' => 2,
    	'shdm:computed_navigation_attribute_value_expression'    => '"Age: #{self.age}"'    	
    )
		@people_index.index_attributes << @age_attribute
		
    @name_age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     => 'name_age',
			'shdm:navigation_attribute_index_position' => 3,
    	'shdm:computed_navigation_attribute_value_expression'    => '"#{name} - #{age}"'    	
    )
		@people_index.index_attributes << @name_age_attribute
		
    @name_anchor_attribute = SHDM::AnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                     => 'name_anchor',
			'shdm:navigation_attribute_index_position'           => 4,  
      'shdm:anchor_navigation_attribute_label_expression'  => '"Click: #{self.name}"',          
      'shdm:anchor_navigation_attribute_target_expression' => '"http://www.google.com/search?q=#{self.name}"'    
    ) 
		@people_index.index_attributes << @name_anchor_attribute
		
    @person_attribute_parameter = SHDM::NavigationAttributeParameter.create(
      'shdm:navigation_attribute_parameter_name'  => 'person',
      'shdm:navigation_attribute_parameter_value_expression' => 'self'      
    )
		
    @friends_of_context_anchor_attribute = SHDM::ContextAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                             => 'friends_of_context_anchor_attribute',
      'shdm:navigation_attribute_index_position'                   => 5,
			'shdm:context_anchor_navigation_attribute_label_expression'  => '"Friends of (context): #{self.name}"',            
      'shdm:context_anchor_navigation_attribute_target_context'    => @friends_of,  
      'shdm:context_anchor_navigation_attribute_target_parameters' => @person_attribute_parameter
    )
		@people_index.index_attributes << @friends_of_context_anchor_attribute
		
    @friends_of_index_anchor_attribute = SHDM::IndexAnchorNavigationAttribute.create(
      'shdm:navigation_attribute_name'                           => 'friends_of_index_anchor_attribute',
      'shdm:navigation_attribute_index_position'                 => 6,
			'shdm:index_anchor_navigation_attribute_label_expression'  => '"Friends of (index): #{self.name}"',            
      'shdm:index_anchor_navigation_attribute_target_index'      => @friends_of_index,
      'shdm:index_anchor_navigation_attribute_target_parameters' => @person_attribute_parameter
    )
		@people_index.index_attributes << @friends_of_index_anchor_attribute
    
    #Instances
    @people_index_instance = @people_index.new
    @friends_of_john       = @friends_of_index.new(:person => @john)
    @friends_of_mauricio   = @friends_of_index.new(:person => @mauricio)
    
    @mauricio_entry = IndexEntryDecorator.new(@mauricio, @people_index)
    @john_entry     = IndexEntryDecorator.new(@john, @people_index)
  end
  
  test "must get attributes names" do
    expected_names = [ 
      'name', 
      'age', 
      'name_age', 
      'name_anchor', 
      'friends_of_context_anchor_attribute', 
      'friends_of_index_anchor_attribute' 
    ]
    assert_equal expected_names, @mauricio_entry.attributes_names
  end
  
  test "must include 'name' attribute" do
    assert @mauricio_entry.attributes_names.include?('name')
  end
  
  test "must get the node value when attribute is missing" do
    assert_equal [ @mauricio, @daniel ], @john_entry.knows
  end
  
  # Testing IndexEntryAttribute
  
  test "must get the index attribute 'name' value" do
    assert_equal 'Name: mauricio', @mauricio_entry.name.value
    assert_equal 'Name: john', @john_entry.name.value
  end
  
  test "must get the index attribute 'age' value" do
    assert_equal 'Age: 31', @mauricio_entry.age.value
    assert_equal 'Age: 21', @john_entry.age.value
  end  
  
  test "must get the index attribute 'name_age' value" do
    assert_equal 'mauricio - 31', @mauricio_entry.name_age.value
    assert_equal 'john - 21', @john_entry.name_age.value
  end
  
  # Testing AnchorIndexEntryAttribute
  
  test "must get the anchor index attribute 'name_anchor' label" do
    assert_equal 'Click: mauricio', @mauricio_entry.name_anchor.label
    assert_equal 'Click: john', @john_entry.name_anchor.label
  end
  
  test "must get the anchor index attribute 'name_anchor' target" do
    assert_equal 'http://www.google.com/search?q=mauricio', @mauricio_entry.name_anchor.target
    assert_equal 'http://www.google.com/search?q=john', @john_entry.name_anchor.target
  end
  
  # Testing ContextAnchorIndexEntryAttribute
  
  test "must get the context anchor index attribute friends_of_context_anchor_attribute label" do
    assert_equal 'Friends of (context): mauricio', @mauricio_entry.friends_of_context_anchor_attribute.label
    assert_equal 'Friends of (context): john', @john_entry.friends_of_context_anchor_attribute.label
  end
  
  test "must get the context anchor index attribute friends_of_context_anchor_attribute target" do
    assert_equal "/navigation/context/#{@friends_of}?person=#{CGI::escape('http://base#mauricio')}", @mauricio_entry.friends_of_context_anchor_attribute.target_url
    assert_equal "/navigation/context/#{@friends_of}?person=#{CGI::escape('http://base#john')}", @john_entry.friends_of_context_anchor_attribute.target_url
  end
  
  test "must get the context anchor index attribute friends_of_context_anchor_attribute target_context" do
    assert_equal @friends_of, @mauricio_entry.friends_of_context_anchor_attribute.target_context
    assert_equal @friends_of, @john_entry.friends_of_context_anchor_attribute.target_context
  end
    
  test "must get the context anchor index attribute friends_of_context_anchor_attribute target_parameters" do
    assert_equal({ :person => @mauricio }, @mauricio_entry.friends_of_context_anchor_attribute.target_parameters)
    assert_equal({ :person => @john },     @john_entry.friends_of_context_anchor_attribute.target_parameters)
  end
  
  # Testing IndexAnchorIndexEntryAttribute
  
  test "must get the index anchor index attribute friends_of_index_anchor_attribute label" do
    assert_equal 'Friends of (index): mauricio', @mauricio_entry.friends_of_index_anchor_attribute.label
    assert_equal 'Friends of (index): john', @john_entry.friends_of_index_anchor_attribute.label
  end
  
  test "must get the index anchor index attribute friends_of_index_anchor_attribute target" do
    assert_equal "/navigation/index/#{@friends_of_index}?person=#{CGI::escape('http://base#mauricio')}", @mauricio_entry.friends_of_index_anchor_attribute.target_url
    assert_equal "/navigation/index/#{@friends_of_index}?person=#{CGI::escape('http://base#john')}", @john_entry.friends_of_index_anchor_attribute.target_url
  end
  
  test "must get the index anchor index attribute friends_of_index_anchor_attribute target_index" do
    assert_equal @friends_of_index, @mauricio_entry.friends_of_index_anchor_attribute.target_index
    assert_equal @friends_of_index, @john_entry.friends_of_index_anchor_attribute.target_index
  end
    
  test "must get the index anchor index attribute friends_of_index_anchor_attribute target_parameters" do
    assert_equal({ :person => @mauricio }, @mauricio_entry.friends_of_index_anchor_attribute.target_parameters)
    assert_equal({ :person => @john },     @john_entry.friends_of_index_anchor_attribute.target_parameters)
  end
    
end
