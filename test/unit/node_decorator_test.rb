require 'test_helper'

class NodetDecoratorTest < ActiveSupport::TestCase
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
    @name_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     									=> 'name',
			'shdm:navigation_attribute_index_position' 						=> 1,
    	'shdm:computed_navigation_attribute_value_expression' => '"Name: #{self.name}"'    	
    )
		@friends_of_index.index_attributes << @name_attribute
		
    @age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     									=> 'age',
			'shdm:navigation_attribute_index_position'					  => 2,
    	'shdm:computed_navigation_attribute_value_expression' => '"Age: #{self.age}"'   	
    )
		@friends_of_index.index_attributes << @age_attribute
		
    @name_age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     									=> 'name_age',
    	'shdm:navigation_attribute_index_position' 						=> 3,
			'shdm:computed_navigation_attribute_value_expression' => '"#{name} - #{age}"'    	
    )
		@friends_of_index.index_attributes << @name_age_attribute

    #NavigationAttributeParameters
    @person_nav_attribute_parameter = SHDM::NavigationAttributeParameter.create(
      'shdm:navigation_attribute_parameter_name'  => 'person',
      'shdm:navigation_attribute_parameter_value_expression' => 'self'
    )

    #IndexNavigationAttributes
    @friends_nav_attribute = SHDM::IndexNavigationAttribute.create(
      'shdm:navigation_attribute_name'                   => 'friends',
      'shdm:index_navigation_attribute_index'            => @friends_of_index,
      'shdm:index_navigation_attribute_index_parameters' => @person_nav_attribute_parameter
    )  
    @people_nav_attribute =  SHDM::IndexNavigationAttribute.create(
      'shdm:navigation_attribute_name'                   => 'people',
      'shdm:index_navigation_attribute_index'            => @people_index
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
      'shdm:navigation_attribute_name' => 'google_anchor',
      'shdm:anchor_navigation_attribute_label_expression' => '"Find #{name} in google"',
      'shdm:anchor_navigation_attribute_target_expression' => '"http://www.google.com/search?q=#{name}"'      
    )

    #ComputedNavigationAttributes
    @birth_year_nav_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name' => 'birth_year',
      'shdm:computed_navigation_attribute_value_expression' => 'Date.today.year - age.first'
    )
    
    #InContextClass
    @person_in_people_context = SHDM::InContextClass.create(
      'shdm:in_context_class_class'                 => FOAF::Person,
      'shdm:in_context_class_context'               => @people_context,
      'shdm:in_context_class_navigation_attributes' => [ @friends_nav_attribute, @friends_of_context_anchor_nav_attribute, @friends_of_index_anchor_nav_attribute, @birth_year_nav_attribute, @google_anchor_nav_attribute ]
    )    
    @resource_in_people_context = SHDM::InContextClass.create(
      'shdm:in_context_class_class'                 => RDFS::Resource,
      'shdm:in_context_class_context'               => @people_context,
      'shdm:in_context_class_navigation_attributes' => @people_nav_attribute
    )
    
    #Instances
    @people_context_instance = @people_context.new
    @friends_of_john     		 = @friends_of.new(:person => @john)
    @friends_of_mauricio 		 = @friends_of.new(:person => @mauricio)
        
    @mauricio_in_people = NodeDecorator.new(@mauricio, @people_context)
    @john_in_people     = NodeDecorator.new(@john, @people_context)
    
  end
  
  test "must get Node attributes names" do
    expected_names = ["google_anchor", "birth_year", "friends_of_index_anchor", "friends_of_anchor", "friends", "people"]
    assert_equal expected_names, @mauricio_in_people.attributes_names
    assert_equal expected_names, @john_in_people.attributes_names
  end
  
  test "must get the resource value when attribute is missing" do
    assert_equal [ ], @mauricio_in_people.knows
    assert_equal [ @mauricio, @daniel ], @john_in_people.knows
  end
  
  # Testing IndexNodeAttribute
  
  test "must get IndexNodeAttribute 'friends' index" do
    assert_equal @friends_of_index, @mauricio_in_people.friends.index
    assert_equal @friends_of_index, @john_in_people.friends.index
  end
  
  test "must get IndexNodeAttribute 'people' index" do
    assert_equal @people_index, @mauricio_in_people.people.index
    assert_equal @people_index, @john_in_people.people.index
  end
  
  test "must get IndexNodeAttribute 'friends' parameters" do
    assert_equal({ :person => @mauricio }, @mauricio_in_people.friends.parameters)
    assert_equal({ :person => @john }, @john_in_people.friends.parameters)
  end
  
  test "the IndexNodeAttribute 'friends' value must be a ContextIndexInstance" do
    assert @mauricio_in_people.friends.value.is_a?(SHDM::ContextIndex::ContextIndexInstance)
    assert @john_in_people.friends.value.is_a?(SHDM::ContextIndex::ContextIndexInstance)
  end
  
  test "must get IndexNodeAttribute 'friends' value ContextIndexInstance resources" do
    assert_equal [], @mauricio_in_people.friends.value.nodes.map{|v| v.resource}
    assert_equal [ @daniel, @mauricio ], @john_in_people.friends.value.nodes.map{|v| v.resource}
  end

  test "must get IndexNodeAttribute 'friends' value ContextIndexInstance nodes" do
    for node in @john_in_people.friends.value.nodes do
      assert node.is_a?(NodeDecorator)			
    end
  end
	
	test "must get IndexNodeAttribute 'friends' value IndexEntryDecorator" do
    for entry in @john_in_people.friends.value.entries do
      assert entry.is_a?(IndexEntryDecorator)
    end
  end
	
	test "must get IndexNodeAttribute 'friends' value IndexEntryDecorator attributes_names" do
    for entry in @john_in_people.friends.value.entries do
      assert_equal ["name", "age", "name_age"], entry.attributes_names
    end
  end
	
	test "must get IndexNodeAttribute 'friends' value IndexEntryDecorator name" do
    for entry in @john_in_people.friends.value.entries do
      assert ["Name: daniel", "Name: mauricio", "Name: john"].include?(entry.name.value)
    end
  end

  #Testing ContextAnchorNodeAttribute
  test "must get ContextAnchorNodeAttribute 'friends_of_anchor' label" do
    assert_equal 'Friends of mauricio', @mauricio_in_people.friends_of_anchor.label
    assert_equal 'Friends of john', @john_in_people.friends_of_anchor.label
  end

  test "must get ContextAnchorNodeAttribute 'friends_of_anchor' target_context" do
    assert_equal @friends_of, @mauricio_in_people.friends_of_anchor.target_context
    assert_equal @friends_of, @john_in_people.friends_of_anchor.target_context
  end

  test "must get ContextAnchorNodeAttribute 'friends_of_anchor' target_parameters" do
    assert_equal({ :person => @mauricio }, @mauricio_in_people.friends_of_anchor.target_parameters)
    assert_equal({ :person => @john }, @john_in_people.friends_of_anchor.target_parameters)
  end
  
  test "must get ContextAnchorNodeAttribute 'friends_of_anchor' target_url" do
    assert_equal "/navigation/context/#{@friends_of}/#{@mauricio}?person=#{CGI::escape('http://base#mauricio')}", @mauricio_in_people.friends_of_anchor.target_url
    assert_equal "/navigation/context/#{@friends_of}/#{@john}?person=#{CGI::escape('http://base#john')}", @john_in_people.friends_of_anchor.target_url
  end
  
  test "must get ContextAnchorNodeAttribute 'friends_of_anchor' target_node" do
    assert_equal(@mauricio, @mauricio_in_people.friends_of_anchor.target_node)
    assert_equal(@john, @john_in_people.friends_of_anchor.target_node)
  end
  
  #Testing IndexAnchorNodeAttribute
  test "must get IndexAnchorNodeAttribute 'friends_of_index_anchor' label" do
    assert_equal 'Friends of mauricio index', @mauricio_in_people.friends_of_index_anchor.label
    assert_equal 'Friends of john index', @john_in_people.friends_of_index_anchor.label
  end

  test "must get IndexAnchorNodeAttribute 'friends_of_index_anchor' target_index" do
    assert_equal @friends_of_index, @mauricio_in_people.friends_of_index_anchor.target_index
    assert_equal @friends_of_index, @john_in_people.friends_of_index_anchor.target_index
  end

  test "must get IndexAnchorNodeAttribute 'friends_of_index_anchor' target_parameters" do
    assert_equal({ :person => @mauricio }, @mauricio_in_people.friends_of_index_anchor.target_parameters)
    assert_equal({ :person => @john }, @john_in_people.friends_of_index_anchor.target_parameters)
  end
  
  test "must get IndexAnchorNodeAttribute 'friends_of_index_anchor' target_url" do
    assert_equal "/navigation/index/#{@friends_of_index}?person=#{CGI::escape('http://base#mauricio')}", @mauricio_in_people.friends_of_index_anchor.target_url
    assert_equal "/navigation/index/#{@friends_of_index}?person=#{CGI::escape('http://base#john')}", @john_in_people.friends_of_index_anchor.target_url
  end
  
  #Testing AnchorNodeAttribute
  test "must get AnchorNodeAttribute 'google_anchor' label" do
    assert_equal 'Find mauricio in google', @mauricio_in_people.google_anchor.label
    assert_equal 'Find john in google', @john_in_people.google_anchor.label
  end
  
  test "must get AnchorNodeAttribute 'google_anchor' target" do
    assert_equal 'http://www.google.com/search?q=mauricio', @mauricio_in_people.google_anchor.target
    assert_equal 'http://www.google.com/search?q=john', @john_in_people.google_anchor.target
  end
  
  #Testing ComputedNodeAttribute
  test "must get ComputedNodeAttribute 'birth_year' value" do
    assert_equal 1979, @mauricio_in_people.birth_year.value
    assert_equal 1989, @john_in_people.birth_year.value
  end
  
  #TODO: test attributes name's conflicts in class_in_context
  
end
