SHDM::NavigationAttribute
SHDM::ComputedNavigationAttribute
SHDM::IndexNavigationAttribute
SHDM::AnchorNavigationAttribute
SHDM::ContextAnchorNavigationAttribute
SHDM::IndexAnchorNavigationAttribute
SHDM::NavigationAttributeParameter

class SHDM::NavigationAttribute
  property SHDM::navigation_attribute_name, 'rdfs:subPropertyOf' => RDFS::label
	property SHDM::navigation_attribute_index_position, 'rdfs:range' => XSD::integer
  property SHDM::navigation_attribute_parent
end

class SHDM::IndexNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::index_navigation_attribute_index,            'rdfs:range' => SHDM::Index
  property SHDM::index_navigation_attribute_index_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter

  after_create   :add_default_parameters  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.index_navigation_attribute_index_parameters.each{|ia| ia.destroy}
  end

  def add_default_parameters
    index = self.shdm::index_navigation_attribute_index.first
    for parameter in index.shdm::context_index_context.first.shdm::context_parameters do
      parameter_name = parameter.shdm::context_parameter_name.first
      current_parameter = SHDM::NavigationAttributeParameter.create(
        :navigation_attribute_parameter_name => parameter_name,  
        :navigation_attribute_parameter_value_expression => "self")
      self.shdm::index_navigation_attribute_index_parameters << current_parameter
      current_parameter.save
    end
  end

end

class SHDM::ContextAnchorNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::context_anchor_navigation_attribute_label_expression
  property SHDM::context_anchor_navigation_attribute_target_node_expression
  property SHDM::context_anchor_navigation_attribute_target_context, 'rdfs:range' => SHDM::Context
  property SHDM::context_anchor_navigation_attribute_target_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter

  after_create   :add_default_parameters
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.context_anchor_navigation_attribute_target_parameters.each{|ia| ia.destroy}
  end

  def add_default_parameters
    target_context   = self.shdm::context_anchor_navigation_attribute_target_context.first
    for parameter in target_context.shdm::context_parameters do
      parameter_name = parameter.shdm::context_parameter_name.first
      current_parameter = SHDM::NavigationAttributeParameter.create(
        :navigation_attribute_parameter_name => parameter_name,  
        :navigation_attribute_parameter_value_expression => value_expression(parameter_name))
      self.shdm::context_anchor_navigation_attribute_target_parameters << current_parameter
      current_parameter.save        
    end
  end

  def value_expression(name)
    target_context   = self.shdm::context_anchor_navigation_attribute_target_context.first
    parent = self.shdm::navigation_attribute_parent.first
    if parent.base_context == target_context
      value_expression = "p[:#{name}]"
    else
      value_expression = "self"
    end
  end

end

class SHDM::IndexAnchorNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::index_anchor_navigation_attribute_label_expression
  property SHDM::index_anchor_navigation_attribute_target_index, 'rdfs:range' => SHDM::Index
  property SHDM::index_anchor_navigation_attribute_target_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter       
  
  after_create   :add_default_parameters
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.index_anchor_navigation_attribute_target_parameters.each{|ia| ia.destroy}
  end
 
  def add_default_parameters
    target_index   = self.shdm::index_anchor_navigation_attribute_target_index.first
    for parameter in target_index.shdm::context_index_context.first.shdm::context_parameters do
      parameter_name = parameter.shdm::context_parameter_name.first
      current_parameter = SHDM::NavigationAttributeParameter.create(
        :navigation_attribute_parameter_name => parameter_name,  
        :navigation_attribute_parameter_value_expression => value_expression(parameter_name))
      self.shdm::index_anchor_navigation_attribute_target_parameters << current_parameter
      current_parameter.save
    end
  end

  def value_expression(name)
    target_index = self.shdm::index_anchor_navigation_attribute_target_index.first
    parent = self.shdm::navigation_attribute_parent.first
    if parent == target_index || parent.base_context == target_index.base_context
      value_expression = "p[:#{name}]"
    else
      value_expression = "self"
    end
  end
         
end

class SHDM::AnchorNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::anchor_navigation_attribute_label_expression
  property SHDM::anchor_navigation_attribute_target_expression
end

class SHDM::ComputedNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::computed_navigation_attribute_value_expression
end

class SHDM::NavigationAttributeParameter
  property SHDM::navigation_attribute_parameter_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::navigation_attribute_parameter_value_expression
end
