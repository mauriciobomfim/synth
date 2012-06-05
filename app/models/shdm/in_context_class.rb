SHDM::InContextClass

class SHDM::InContextClass
  property SHDM::in_context_class_class,                      'rdfs:range' => RDFS::Class
  property SHDM::in_context_class_context,                    'rdfs:range' => SHDM::Context, 'owl:inverseOf' => SHDM::context_in_context_class

  property SHDM::in_context_class_navigation_attributes,      'rdfs:range' => SHDM::NavigationAttribute
	
	property SHDM::in_context_class_index_attributes,           'rdfs:range' => SHDM::IndexNavigationAttribute,
	                                                            'rdfs:subPropertyOf' => SHDM::in_context_class_navigation_attributes	

	property SHDM::in_context_class_computed_attributes,        'rdfs:range' => SHDM::ComputedNavigationAttribute, 
	                                                            'rdfs:subPropertyOf' => SHDM::in_context_class_navigation_attributes

	property SHDM::in_context_class_index_anchor_attributes,    'rdfs:range' => SHDM::IndexAnchorNavigationAttribute, 
	                                                            'rdfs:subPropertyOf' => SHDM::in_context_class_navigation_attributes

  property SHDM::in_context_class_context_anchor_attributes,  'rdfs:range' => SHDM::ContextAnchorNavigationAttribute, 
                                                              'rdfs:subPropertyOf' => SHDM::in_context_class_navigation_attributes
  def base_context
    self.shdm::in_context_class_context.first
  end
end
