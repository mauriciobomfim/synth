SWUI::ConcreteWidget
SWUI::HtmlTag
SWUI::RichControl

class SWUI::ConcreteWidget

	property SWUI::concrete_widget_name, 'rdfs:subPropertyOf' => RDFS::label
  property SWUI::legalAbstractWidgs

  def save
    self.legalAbstractWidgs = self.legalAbstractWidgs.join(",") unless self.legalAbstractWidgs.nil?
    super
  end

end

class SWUI::HtmlTag; sub_class_of SWUI::ConcreteWidget

	property SWUI::legalTags

end

class SWUI::RichControl; sub_class_of SWUI::ConcreteWidget

	property SWUI::dependencies
	property SWUI::htmlCode
	property SWUI::jsCode
  property SWUI::cssCode

end