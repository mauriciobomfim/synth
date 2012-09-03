class NodeAttribute

  attr_accessor :navigation_attribute, :resource

  def initialize(navigation_attribute, resource)
     @navigation_attribute = navigation_attribute
     @resource = resource
  end

  def target_url
    ""
  end
end

class IndexNodeAttribute < NodeAttribute
  
  def value
    index.new(parameters)
  end
  
  def index
    @navigation_attribute.index_navigation_attribute_index.first
  end
  
  def parameters
    parameters_hash = Hash.new
    for parameter in @navigation_attribute.index_navigation_attribute_index_parameters do
      value = @resource.instance_eval(parameter.navigation_attribute_parameter_value_expression.first)
      parameters_hash[parameter.navigation_attribute_parameter_name.first.to_sym] = value
    end
    parameters_hash
  end
  
end

class ContextAnchorNodeAttribute < NodeAttribute

  def label
    expression = @navigation_attribute.context_anchor_navigation_attribute_label_expression.first.to_s
    begin
      @resource.instance_eval(expression)
    rescue
      "There is some error in your Context Anchor label expression: #{expression}"
    end
  end

  def target_url
    target_context.url(target_parameters, target_node)
  end

  def target_context
    @navigation_attribute.context_anchor_navigation_attribute_target_context.first
  end
  
  def target_node
		target_node_expression = @navigation_attribute.context_anchor_navigation_attribute_target_node_expression.first || ""
    @resource.instance_eval(target_node_expression)
  end

  def target_parameters
    parameters_hash = Hash.new
    for parameter in @navigation_attribute.context_anchor_navigation_attribute_target_parameters do
      value_expression = parameter.navigation_attribute_parameter_value_expression.first
      value = value_expression.is_a?(Proc) ? value_expression.call : @resource.instance_eval(value_expression)
      parameters_hash[parameter.navigation_attribute_parameter_name.first.to_sym] = value
    end
    parameters_hash
  end

end

class IndexAnchorNodeAttribute < NodeAttribute

  def label
    expression = @navigation_attribute.index_anchor_navigation_attribute_label_expression.first.to_s
    begin    
      @resource.instance_eval(expression)
    rescue
      "There is some error in your Index Anchor label expression: #{expression}"
    end      
  end

  def target_url
    target_index.url(target_parameters)
  end

  def target_index
    @navigation_attribute.index_anchor_navigation_attribute_target_index.first
  end

  def target_parameters
    parameters_hash = Hash.new
    for parameter in @navigation_attribute.index_anchor_navigation_attribute_target_parameters do
      value_expression = parameter.navigation_attribute_parameter_value_expression.first
      value = value_expression.is_a?(Proc) ? value_expression.call : @resource.instance_eval(value_expression)
      parameters_hash[parameter.navigation_attribute_parameter_name.first.to_sym] = value      
    end
    parameters_hash
  end

end

class AnchorNodeAttribute < NodeAttribute

  def label
    @resource.instance_eval(@navigation_attribute.anchor_navigation_attribute_label_expression.first)
  end
  
  def target
    @resource.instance_eval(@navigation_attribute.anchor_navigation_attribute_target_expression.first)
  end

end

class ComputedNodeAttribute < NodeAttribute

  def value
    expression = @navigation_attribute.computed_navigation_attribute_value_expression.first.to_s
    begin
      @resource.instance_eval(expression)
    rescue
      "There is some error in your Computed Attribute expression: #{expression}"
    end
  end
  
  def label
    value
  end

end

class NodeAttributeFactory
  
  def self.create(navigation_attribute, node)
   
    klasses = navigation_attribute.classes
  
    klass = case 
    when klasses.include?(SHDM::IndexNavigationAttribute)
      IndexNodeAttribute
    when klasses.include?(SHDM::AnchorNavigationAttribute)
      AnchorNodeAttribute
    when klasses.include?(SHDM::ContextAnchorNavigationAttribute)
      ContextAnchorNodeAttribute
    when klasses.include?(SHDM::IndexAnchorNavigationAttribute)
      IndexAnchorNodeAttribute
    when klasses.include?(SHDM::ComputedNavigationAttribute)
      ComputedNodeAttribute
    else
      NodeAttribute
    end
  
    klass.new(navigation_attribute, node)
  
  end
  
end
