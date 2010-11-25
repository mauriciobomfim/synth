require 'node_attribute_factory'

#Decorates a resource with IndexEntry behavior
class IndexEntryDecorator

  include ActionView::Helpers

  attr_reader :node, :index, :parameters_values, :attributes_names, :attributes_hash

  alias :parameters :parameters_values

  # in fact it should return the same node, with the new properties and methods. 
  def initialize(node, index)
    @node              = node
    @index             = index
    @parameters_values = index.parameters_values
        
    @sorted_attributes = @index.index_attributes.sort{|a,b| a.navigation_attribute_index_position.first <=> b.navigation_attribute_index_position.first }
    @attributes_names  = @sorted_attributes.map { |attribute| attribute.navigation_attribute_name.first }
    @attributes_hash   = Hash.new 
    
    for attribute in @index.index_attributes.each do 
      @attributes_hash[attribute.navigation_attribute_name.first] = NodeAttributeFactory.create(attribute, self) 
    end    
    
  end
  
  def uri
    @node.uri
  end
  alias :to_s :uri
  
  #responds to attribute's name and returns the NodeAttribute instance  
  def method_missing(method_name, *args, &block)
    attribute = method_name.to_s
    if @attributes_names.include?(attribute)      
      @attributes_hash[attribute]
    else
      @node.send(method_name, *args, &block)
    end
  end
        
end