require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  
  def setup
    
    ActiveRDF::Namespace.register :foaf, 'http://foaf#'
    
    FOAF::Person    
    eval %{
    class FOAF::Person
      property FOAF::name
      property FOAF::age
      property FOAF::knows, 'rdfs:range' => FOAF::Person
    end
    }
    
    @mauricio = FOAF::Person.create(:name => 'mauricio', :age => 31).save
    @john = FOAF::Person.create(:name => 'john', :age => 21, :knows => @mauricio).save
  
  end
  
  test "should get properties values" do
    assert_equal ['mauricio'], @mauricio.name
    assert_equal ['mauricio'], @mauricio.foaf::name
    assert_equal [31], @mauricio.age
    assert_equal [31], @mauricio.foaf::age
    assert_equal ['john'], @john.name
    assert_equal ['john'], @john.foaf::name
    assert_equal [21], @john.age
    assert_equal [21], @john.foaf::age
  end
  
  test "should get empty association" do
    assert @mauricio.knows.empty?
  end
  
  test "should get resource association" do
    assert_equal @mauricio, @john.knows.first
  end
  
end
