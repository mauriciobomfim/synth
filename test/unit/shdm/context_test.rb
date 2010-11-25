require 'test_helper'

class ContextTest < ActiveSupport::TestCase
 
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
    
    #ContextParameters
    @person_parameter = SHDM::ContextParameter.create(
      'shdm:context_parameter_name'  => 'person',
      'shdm:context_parameter_class' => 'FOAF::Person'
    )          
    @friends_of.shdm::context_parameters << @person_parameter
      
    #Instances
    @people_context_instance = @people_context.new
    @friends_of_john     = @friends_of.new(:person => @john)
    @friends_of_mauricio = @friends_of.new(:person => @mauricio)
  end
  
  test "must get context name" do
    assert_equal ['People Name'], @people_context.shdm::context_name
    assert_equal ['People Name'], @people_context.context_name
    assert_equal ['FriendsOf'],   @friends_of.shdm::context_name
    assert_equal ['FriendsOf'],   @friends_of.context_name
  end
  
  test "must get context title" do
    assert_equal ['People Title'], @people_context.shdm::context_title
    assert_equal ['People Title'], @people_context.context_title
    assert_equal ['Friends of'],   @friends_of.shdm::context_title
    assert_equal ['Friends of'],   @friends_of.context_title
  end
  
  test "must get context query" do
    assert_equal ['ActiveRDF::ResourceQuery.new(FOAF::Person).execute'],  @people_context.shdm::context_query
    assert_equal ['ActiveRDF::ResourceQuery.new(FOAF::Person).execute'],  @people_context.context_query
    assert_equal ['@parameters_values[:person].foaf::knows'],             @friends_of.shdm::context_query
    assert_equal ['@parameters_values[:person].foaf::knows'],             @friends_of.context_query
  end

  test "instance name must be equals to context name" do
    assert_equal @people_context_instance.shdm::context_name,  @people_context.shdm::context_name
    assert_equal @people_context_instance.context_name,        @people_context.context_name
    assert_equal @friends_of_john.shdm::context_name,          @friends_of.shdm::context_name
    assert_equal @friends_of_mauricio.context_name,            @friends_of.context_name
  end

  test "instance title must be equals to context title" do
    assert_equal @people_context_instance.shdm::context_title, @people_context.shdm::context_title
    assert_equal @people_context_instance.context_title,       @people_context.context_title
    assert_equal @friends_of_john.shdm::context_title,         @friends_of.shdm::context_title
    assert_equal @friends_of_mauricio.context_title,           @friends_of.context_title
  end

  test "instance query must be equals to context query" do
    assert_equal @people_context_instance.shdm::context_query, @people_context.shdm::context_query
    assert_equal @people_context_instance.context_query,       @people_context.context_query
    assert_equal @friends_of_john.shdm::context_query,         @friends_of.shdm::context_query
    assert_equal @friends_of_mauricio.context_query,           @friends_of.context_query
  end

  test "context instances must be different" do
    assert_not_equal @people_context_instance, @friends_of_instance 
  end
  
  test "context instances's base context must be different" do
    assert_not_equal @people_context_instance.context, @friends_of_john.context 
  end
  
  test "context instances's base context must be equal" do
    assert_equal @friends_of_mauricio.context, @friends_of_john.context 
  end

  test "must get context parameters" do
    assert_equal [ @person_parameter ], @friends_of.context_parameters
  end
  
  test "must get context instance parameters values" do
    assert_equal({ :person => @john },      @friends_of_john.parameters_values)
    assert_equal({ :person => @mauricio },  @friends_of_mauricio.parameters_values)
  end

  test "must get context instance node's resource" do
    assert_equal [ @john, @mauricio, @daniel ], @people_context_instance.nodes.map{|v| v.resource}
  end
  
  test "must get context instance nodes" do    
    for node in @people_context_instance.nodes
      assert node.is_a?(NodeDecorator)
    end
  end
  
  test "must get parameterized context instance node's resource" do    
     assert_equal [ @daniel, @mauricio ], @friends_of_john.nodes.map{|v| v.resource}
     assert_equal [], @friends_of_mauricio.nodes.map{|v| v.resource}
  end
  
  test "must get parameterized context instance nodes" do    
    for node in @friends_of_john.nodes
      assert node.is_a?(NodeDecorator)
    end
  end
  
  test "must raise an error when a context parameter value is missing" do
    assert_raise(CustomExceptions::MissingContextParameterValue) do 
      @friends_of.new
    end
  end
  
  test "must not raise error when a context parameter value is passed" do
    assert_nothing_raised do 
      @friends_of.new(:person => @mauricio) 
    end
  end
    
  #TODO: testing Context.new.url  
  
  #TODO: checking parameter type
  #test "must raise ContextParameterValueMismatch" do
  #  @people_context.shdm::context_parameters << @person_parameter
  #  assert_raise(ContextParameterValueMismatch){ @people_context.new(:person => 1) }
  #end
  
end
