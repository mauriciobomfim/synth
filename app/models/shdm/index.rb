require 'index_entry_decorator'

SHDM::Index
SHDM::ContextIndex
SHDM::QueryIndex
SHDM::IndexParameter
SHDM::NavigationAttribute

class SHDM::Index
  
  property SHDM::index_name
  property SHDM::index_title, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::index_attributes, 'rdfs:range' => SHDM::NavigationAttribute #TODO: change the name to navigation_attributes and subproperties
  
  property SHDM::index_index_attributes, 'rdfs:range'    => SHDM::IndexNavigationAttribute, 'rdfs:subPropertyOf' => SHDM::index_attributes	
	property SHDM::computed_attributes, 'rdfs:range'       => SHDM::ComputedNavigationAttribute, 'rdfs:subPropertyOf' => SHDM::index_attributes
	property SHDM::index_anchor_attributes, 'rdfs:range'   => SHDM::IndexAnchorNavigationAttribute, 'rdfs:subPropertyOf' => SHDM::index_attributes
  property SHDM::context_anchor_attributes, 'rdfs:range' => SHDM::ContextAnchorNavigationAttribute, 'rdfs:subPropertyOf' => SHDM::index_attributes

  before_destroy :remove_dependents
  
  def url(parameters={})
    url = "/execute/index/#{CGI::escape(self.uri)}"
    if parameters.is_a?(Hash) && !parameters.empty?
      parameters.merge!(parameters){|i,v| v.respond_to?(:uri) ? { "resource" => v.uri } : v }
      url << "?#{parameters.to_query}" 
    end
    url
  end
    
  protected
  
  def remove_dependents
    self.index_attributes.each{|ia| ia.destroy}
  end

end

class SHDM::ContextIndex;  sub_class_of(SHDM::Index)

  property SHDM::context_index_context, 'rdfs:range' => SHDM::Context
                                          
  def new(parameters_values={})
    ContextIndexInstance.new(parameters_values, self)
  end
 
  def base_context
    self.shdm::context_index_context.first
  end
 
  class ContextIndexInstance
    
    attr_reader :index, :context_instance, :parameters_values
    
    alias :parameters :parameters_values
    
    def initialize(parameters_values, index)
      @index = index
      @parameters_values = HashWithIndifferentAccess.new(parameters_values)
      @context_instance = context_index_context.first.new(parameters_values)
    end
    
    def url(params=nil)
      index.url(parameters)
    end
    
    def nodes
      context_instance.resources #getting resources instead of node for performance reasons
    end
    
    def entries
      @entries ||= nodes.map do |node|
        IndexEntryDecorator.new(node, self)
      end      
    end

    def method_missing(method_name, *args, &block)
      @index.send(method_name.to_sym, *args, &block)
    end
    
  end
  
end

#TODO: QueryIndex
#class SHDM::QueryIndex
#  
#  property SHDM::query_index_name, 'rdfs:subPropertyOf'  => SHDM::index_name
#  property SHDM::query_index_title, 'rdfs:subPropertyOf' => SHDM::index_title
#  property SHDM::query_index_query, 'rdfs:subPropertyOf' => SHDM::index_query
#  property SHDM::query_index_attributes, :range          => SHDM::IndexAttribute, 'rdfs:subPropertyOf' => SHDM::index_attributes
#  property SHDM::query_index_parameters, :range          => SHDM::IndexParameter
#
#  sub_class_of(SHDM::Index)
#  
#  def new(parameters_values={})
#    QueryIndexInstance.new(parameters_values, self)
#  end
#  
#  class QueryIndexInstance
#    
#    attr_reader :index, :parameters_values
#    
#    def initialize(parameters_values, index)
#      @index = query_index
#      @parameters_values = parameters_values
#            
#      expected_parameters = @query_index.query_index_parameters.map{|p| p.index_parameter_name.first }
#      received_parameters = @parameters_values.keys.map{|p| p.to_s}
#      missing_parameters = expected_parameters - received_parameters      
#      raise NoQueryIndexParameterValueError, "Missing parameters: #{missing_parameters.join(', ')}" unless missing_parameters.empty?
#      
#      #TODO: check parameter types      
#    end
#    
#    def nodes
#      instance_eval(@index.query_index_query.first)
#    end
#
#    def method_missing(method_name, *args, &block)
#      @index.send(method_name.to_sym, *args, &block)
#    end
#    
#  end
#  
#end

class SHDM::IndexParameter
  property SHDM::index_parameter_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::index_parameter_class
  property SHDM::index_parameter_index, 'rdfs:range' => SHDM::ContextIndex, 'owl:inverseOf' => SHDM::navigation_context_index_parameters
end


#anyIndex = SHDM::Index.new(SHDM::anyIndex)
#anyIndex.shdm::index_name = 'Any'
