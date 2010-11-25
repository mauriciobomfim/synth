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
end

class SHDM::IndexNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::index_navigation_attribute_index,            'rdfs:range' => SHDM::Index
  property SHDM::index_navigation_attribute_index_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter
  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.index_navigation_attribute_index_parameters.each{|ia| ia.destroy}
  end
	
end

class SHDM::ContextAnchorNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::context_anchor_navigation_attribute_label_expression
  property SHDM::context_anchor_navigation_attribute_target_node_expression
  property SHDM::context_anchor_navigation_attribute_target_context, 'rdfs:range' => SHDM::Context
  property SHDM::context_anchor_navigation_attribute_target_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter
  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.context_anchor_navigation_attribute_target_parameters.each{|ia| ia.destroy}
  end
end

class SHDM::IndexAnchorNavigationAttribute; sub_class_of SHDM::NavigationAttribute
  property SHDM::index_anchor_navigation_attribute_label_expression
  property SHDM::index_anchor_navigation_attribute_target_index, 'rdfs:range' => SHDM::Index
  property SHDM::index_anchor_navigation_attribute_target_parameters, 'rdfs:range' => SHDM::NavigationAttributeParameter       
  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.index_anchor_navigation_attribute_target_parameters.each{|ia| ia.destroy}
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