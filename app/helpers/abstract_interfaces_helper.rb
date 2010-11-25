module AbstractInterfacesHelper
  def display_type(interface)
    interface_types = interface.classes
    
    interface_type = case 
      when interface_types.include?(SWUI::ContextInterface)
        "Context Interface"
      when interface_types.include?(SWUI::IndexInterface)
        "Index Interface"
      when interface_types.include?(SWUI::ComponentInterface)
        "Component Interface"
      else
        "Generic Interface"
    end
  end
end