require 'node_attribute_factory'

#Decorates a resource with InContextClass behavior
class NodeDecorator

  attr_reader :resource, :context, :default_index, :parameters_values, :attributes_names, :attributes_hash

  alias :parameters :parameters_values
  alias :p :parameters_values

  # in fact it should return the same resource, with the new properties and methods. 
  def initialize(resource, context)
    @resource          = resource
    @context           = context
    @default_index     = context.index
    @parameters_values = context.parameters_values
    @attributes        = Array.new
    @attributes_names  = Array.new
    @attributes_hash   = Hash.new
    
    @in_context_classes = Array.new
            
    #Select InContextClass sorted by @resource.classes
    for klass in @resource.classes do
      @in_context_classes += @context.context_in_context_class.to_ary.select { |v| v.in_context_class_class.first == klass }
      @in_context_classes += SHDM::anyContext.context_in_context_class.to_ary.select { |v| v.in_context_class_class.first == klass }
    end
    
    #Set all navigation attributes from all valids in_context_classes
    for in_context_class in @in_context_classes do
      @attributes += in_context_class.in_context_class_navigation_attributes
    end
        
    #Set attributes in reverse order to mantain the class order in case of name confict
    for attribute in @attributes.reverse do
      attribute_name = attribute.navigation_attribute_name.first
      @attributes_names << attribute_name
      @attributes_hash[attribute_name] = NodeAttributeFactory.create(attribute, resource)
    end
    
    @attributes_names.reverse!
    
  end

  def landmarks
    SHDM::Landmark.all
  end
    
  def node_position
    @node_position ||= context.nodes.index(self) || 0
  end
    
  def next_node
    @next_node ||= node_position == context.nodes.size ? nil : context.nodes[node_position + 1]
  end

  def next_node_anchor    
    @next_node_anchor ||= node_position == context.nodes.size ? nil : next_node.anchor
  end
  
  def previous_node_anchor
    @previous_node_anchor ||= node_position == 0 ? nil : previous_node.anchor
  end
    
  def previous_node
    @previous_node ||= node_position == 0 ? nil : context.nodes[node_position - 1]
  end
  
  def anchor
    default_index.entries[node_position].main_anchor
  end
  
  #responds to attribute's name and returns the NodeAttribute instance  
  def method_missing(method_name, *args, &block)
    attribute = method_name.to_s
    if @attributes_names.include?(attribute)      
      @attributes_hash[attribute]
    else
      @resource.send(method_name, *args, &block)
    end
  end

end
