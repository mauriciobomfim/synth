require 'test_helper'

class IndexTest < ActiveSupport::TestCase
  
end

class ContextIndexTest < ActiveSupport::TestCase
  
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
      'shdm:index_name'    				 => 'People Index Name', 
      'shdm:index_title'   				 => 'People Index Title',
      'shdm:context_index_context' => @people_context 
    )
    @friends_of_index = SHDM::ContextIndex.create( 
      'shdm:index_name'   => 'FriendsOfIndex', 
      'shdm:index_title'  => 'Friends of Index', 
      'shdm:context_index_context' => @friends_of 
    )
    
    #IndexAttributes
    @name_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     								  => 'name',
    	'shdm:computed_navigation_attribute_value_expression' => '"Name: #{self.name}"',
    	'shdm:navigation_attribute_index_position' 						=> 1    	
    )
		@people_index.index_attributes << @name_attribute
		
    @age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     => 'age',
    	'shdm:computed_navigation_attribute_value_expression'    => '"Age: #{self.age}"',
    	'shdm:navigation_attribute_index_position' => 2
    )
		@people_index.index_attributes << @age_attribute
		
    @name_age_attribute = SHDM::ComputedNavigationAttribute.create(
      'shdm:navigation_attribute_name'     => 'name_age',
    	'shdm:computed_navigation_attribute_value_expression'    => '"#{name} - #{age}"',
    	'shdm:navigation_attribute_index_position' => 3    	
    )
		@people_index.index_attributes << @name_age_attribute
    
    #Instances
    @people_index_instance = @people_index.new
    @friends_of_john       = @friends_of_index.new(:person => @john)
    @friends_of_mauricio   = @friends_of_index.new(:person => @mauricio)
        
  end

  test "must get index_name" do
    assert_equal ['People Index Name'], @people_index.shdm::index_name
    assert_equal ['People Index Name'], @people_index.index_name
    assert_equal ['FriendsOfIndex'],    @friends_of_index.shdm::index_name
    assert_equal ['FriendsOfIndex'],    @friends_of_index.index_name
  end
  
  test "must responds to index_name as index_name" do
    assert_equal ['People Index Name'], @people_index.shdm::index_name
    assert_equal ['People Index Name'], @people_index.index_name
    assert_equal ['FriendsOfIndex'],    @friends_of_index.shdm::index_name
    assert_equal ['FriendsOfIndex'],    @friends_of_index.index_name
  end
  
  test "must get index_title" do
    assert_equal ['People Index Title'], @people_index.shdm::index_title
    assert_equal ['People Index Title'], @people_index.index_title
    assert_equal ['Friends of Index'],   @friends_of_index.shdm::index_title
    assert_equal ['Friends of Index'],   @friends_of_index.index_title
  end
  
  test "must responds to index_title as index_title" do
    assert_equal ['People Index Title'], @people_index.shdm::index_title
    assert_equal ['People Index Title'], @people_index.index_title
    assert_equal ['Friends of Index'],   @friends_of_index.shdm::index_title
    assert_equal ['Friends of Index'],   @friends_of_index.index_title
  end
  
  test "must get rdfs:label same as index_title" do
    assert_equal ['People Index Title'], @people_index.rdfs::label
    assert_equal ['People Index Title'], @people_index.label
    assert_equal ['Friends of Index'],   @friends_of_index.rdfs::label
    assert_equal ['Friends of Index'],   @friends_of_index.label
  end
  
  test "must get context_index_context" do
    assert_equal [ @people_context ], @people_index.shdm::context_index_context
    assert_equal [ @people_context ], @people_index.context_index_context
    assert_equal [ @friends_of ],     @friends_of_index.shdm::context_index_context
    assert_equal [ @friends_of ],     @friends_of_index.context_index_context
  end
  
  test "instance name must be equals to index name" do
    assert_equal @people_index_instance.shdm::index_name,  @people_index.shdm::index_name
    assert_equal @people_index_instance.index_name,        @people_index.index_name
    assert_equal @friends_of_john.shdm::index_name,        @friends_of_index.shdm::index_name
    assert_equal @friends_of_mauricio.index_name,          @friends_of_index.index_name
  end
  
  test "instance title must be equals to index title" do
    assert_equal @people_index_instance.shdm::index_title,  @people_index.shdm::index_title
    assert_equal @people_index_instance.index_title,        @people_index.index_title
    assert_equal @friends_of_john.shdm::index_title,        @friends_of_index.shdm::index_title
    assert_equal @friends_of_mauricio.index_title,          @friends_of_index.index_title
  end
  
  test "instance context must be equals to index context" do
    assert_equal @people_index_instance.shdm::context_index_context,  @people_index.shdm::context_index_context
    assert_equal @people_index_instance.context_index_context,        @people_index.context_index_context
    assert_equal @friends_of_john.shdm::context_index_context,        @friends_of_index.shdm::context_index_context
    assert_equal @friends_of_mauricio.context_index_context,          @friends_of_index.context_index_context
  end
  
  test "index instances must be different" do
    assert_not_equal @people_index_instance, @friends_of_mauricio
  end
  
  test "index instances's base index must be different" do
    assert_not_equal @people_index_instance.index, @friends_of_john.index 
  end
  
  test "index instances's base index must be equal" do
    assert_equal @friends_of_mauricio.index, @friends_of_john.index 
  end
    
  test "must get index context parameters" do
    assert_equal [ @person_parameter ], @friends_of_index.context_index_context.first.context_parameters
  end  

  test "must get index context instance parameters values" do
    assert_equal({ :person => @john },      @friends_of_john.context_instance.parameters_values)
    assert_equal({ :person => @mauricio },  @friends_of_mauricio.context_instance.parameters_values)
  end
  
  test "must get context index instance resources" do
    assert_equal [ @john, @mauricio, @daniel ], @people_index_instance.nodes.map{|v| v.resource}
  end

  test "must get context index instance nodes" do
    for node in @people_index_instance.nodes do
      assert node.is_a?(NodeDecorator)
    end
  end
  
  test "must get parameterized index's context instance resources" do    
     assert_equal [ @daniel, @mauricio ], @friends_of_john.nodes.map{|v| v.resource}
     assert_equal [], @friends_of_mauricio.nodes.map{|v| v.resource}
  end
  
  test "must get parameterized index's context instance nodes" do    
    for node in @friends_of_john.nodes do
      assert node.is_a?(NodeDecorator)
    end
  end
  
  test "must raise an error when a index's context parameter value is missing" do
    assert_raise(CustomExceptions::MissingContextParameterValue) do 
      @friends_of_index.new
    end
  end
  
  test "must not raise error when a index's context parameter value is passed" do
    assert_nothing_raised do 
      @friends_of_index.new(:person => @mauricio) 
    end
  end
  
  test "must get index_attributes" do
    assert_equal [ @name_attribute, @age_attribute, @name_age_attribute ], @people_index.index_attributes
  end

  test "must get index entries" do
    for entry in @people_index_instance.entries do
      assert entry.is_a? IndexEntryDecorator
    end
  end

  test "entry must get the index attribute value" do
    assert_equal [ 'Name: john', 'Name: mauricio', 'Name: daniel' ], @people_index_instance.entries.map{ |e| e.name.value }
  end

end
