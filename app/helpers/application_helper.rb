# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def controller_label
    { 
      'abstract_interfaces' => 'Interfaces',
      'concrete_interfaces' => 'Style Sheets'
    }
  end
  
  def tab_hash
    tab_hash = {}
    for index, value in tab_index_hash do
      value.each{|v| tab_hash[v] = index}      
    end
    tab_hash
  end
  
  def tab_index_hash
    { "home"       => [ "applications" ],
      "domain"     => [ "ontologies", "namespaces", "datasets","resources", "classes", "properties" ],
      "navigation" => [ "contexts", "indexes", "landmarks", "in_context_classes"],
      "interface"  => [ "abstract_interfaces", "concrete_interfaces", "concrete_widgets", "effects" ],
      "behavior"   => [ "operations" ]
    }
  end

  def tab_index
    tab_index = [ "home" , "domain", "navigation", "interface", "behavior" ]
  end
  
  def selected_tab
    tab_index.index(tab_hash[controller_name])
  end
  
  def selected_vertical_tab
    tab_index_hash[tab_hash[controller_name]].index(controller_name)
  end

  def tab_url_for(controller)    
    controller = controller.to_s
    (tab_hash[controller_name] == controller) ? "##{controller}" : "/#{controller}"
  end
  
  def vertical_tab_url_for(controller)    
    controller = controller.to_s
    (controller_name == controller) ? "##{controller}" : "/#{controller}"
  end

  def include(interface_name)
    interface = SWUI::Interface.find_by.interface_name(interface_name).execute.first

    unless interface.nil?
      @controller.send(:render_to_string, :inline => interface.abstract_spec.first)
    else
      "'#{interface_name}' included interface does not exist."
    end
    
    #@controller.send(:render_to_string, :inline => get_interface_spec(interface_name))
  end
  
end
