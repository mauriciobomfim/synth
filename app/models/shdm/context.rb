require 'ostruct'
require 'node_decorator'
require 'query_builder'


module CustomExceptions
  silence_warnings do
    MissingContextParameterValue  = Class.new(ArgumentError)
    ContextParameterValueMismatch = Class.new(ArgumentError)
  end
end

SHDM::Context
SHDM::ContextParameter

class SHDM::Context
  
  property SHDM::context_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::context_title
  property SHDM::context_query
  property SHDM::context_parameters, 'rdfs:range' => SHDM::ContextParameter
  property SHDM::context_in_context_class, 'rdfs:range' => SHDM::InContextClass, 'owl:inverseOf' => SHDM::in_context_class_context
  
  before_destroy :remove_dependents
  after_create   :add_context_index

  def new(parameters_values={})
    ContextInstance.new(parameters_values, self)
  end
  
  def url(parameters={}, node=nil)
    url = "/execute/context/#{CGI::escape(self.uri)}"
    url << "?node=#{CGI::escape(node.to_s)}" unless node.nil?
    if parameters.is_a?(Hash) && !parameters.empty?
      parameters.merge!(parameters){|i,v| v.respond_to?(:uri) ? { "resource" => v.uri } : v }
      url << "#{node.nil? ? '?' : '&'}#{parameters.to_query}" 
    end
    url
  end
  
  #Runtime instance of a navigation context holding its own parameters values, nodes etc.
  class ContextInstance
    include CustomExceptions
    
    attr_reader :context, :parameters_values
    
    alias :parameters :parameters_values
    
    def initialize(parameters_values, context)
      @context            = context
      @parameters_values  = HashWithIndifferentAccess.new(parameters_values)
                        
      expected_parameters = @context.context_parameters.map{|p| p.context_parameter_name.first }
      received_parameters = @parameters_values.keys.map{|p| p.to_s}
      missing_parameters  = expected_parameters - received_parameters      
      raise MissingContextParameterValue, "Missing parameters: #{missing_parameters.join(', ')}" unless missing_parameters.empty?
      
      #TODO: check parameter types      
      #expected_parameters_types = {}; @people_context.context_parameters.each{|p| 
      #  expected_parameters_types[p.context_parameter_name.first.to_sym] = p.context_parameter_class.first }
      #mismatch_parameters_types = {}; expected_parameters_types.each_pair{|k,v| 
      #  mismatch_parameters_types[k] = v unless @parameters_values[k].is_a? v }
      #raise ContextParameterValueMismatch, "Parameters values mismatch, expected: #{mismatch_parameters_types.inspect}" unless mismatch_parameters_types.empty?
      
    end

    def url(*params)
      if params.size == 2
        parameters = params.first
        node       = params.last
      elsif params.size == 1
        parameters = self.parameters 
        node       = params.first
      else
        parameters = {}
        node       = nil
      end        
      context.url(parameters, node)
    end

    def selects(&block)
      q = QueryBuilder.new
      q.selects(&block)
      q.execute
    end

    def resources
      variables = @parameters_values.map{|i,v| "#{i} = @parameters_values[#{i.inspect}]"}.join("\n")
      query = @context.context_query.first
      @resources ||= instance_eval(variables + " \n " + query)  
      if @resources.is_a?(String)
        @resources = ActiveRDF::FederationManager.execute(@resources)  
      end
      return @resources
    end

    def nodes
      @nodes ||= resources.map do |resource|
        NodeDecorator.new(resource, self)
      end
    end
  
    def index

      if self.shdm::context_index.first
        @index ||= self.shdm::context_index.first.new(@parameters_values)
      end

      label_expression = "
        label = self.rdfs::label
        unless label.nil? || label.to_a.empty?
          label
        else
          self.compact_uri
        end
      "
      # Runtime representation of an Index. It should not be an instance of RDFS::Resource, so I'm using an OpenStruct object. 
      @index ||= SHDM::ContextIndex::ContextIndexInstance.new(@parameters_values, OpenStruct.new({ 
                :index_name => ['__default_context_index__'],
                :context_index_context => [ @context ],
                :index_attributes => [
                  OpenStruct.new({ 
                    :classes => [SHDM::ContextAnchorNavigationAttribute],
                    :navigation_attribute_name => ['item'],
                    :navigation_attribute_position => [1],
                    :context_anchor_navigation_attribute_label_expression => [label_expression],
                    :context_anchor_navigation_attribute_target_context => [ @context ],
                    :context_anchor_navigation_attribute_target_parameters => @parameters_values.keys.map{|p| 
                        OpenStruct.new({ :navigation_attribute_parameter_name => [p.to_s],
                        :navigation_attribute_parameter_value_expression => [ lambda { @parameters_values[p] } ] 
                          })},
                    :context_anchor_navigation_attribute_target_node_expression => ['self']
                  })
                ]
            }))

      @index
    end
 
    def method_missing(method_name, *args, &block)
      @context.send(method_name.to_sym, *args, &block)
    end

  end  
  
  protected
  
  def remove_dependents
    self.context_parameters.each{|cp| cp.destroy}
    InContextClass.find_by.in_context_class_context(self).execute.each{|icc| icc.destroy}
  end
    
  def add_context_index
    label_expression = "
      label = self.rdfs::label
      unless label.nil? || label.to_a.empty?
        label
      else
        self.compact_uri
      end
    "
    context_anchor = SHDM::ContextAnchorNavigationAttribute.create({
      :navigation_attribute_name => "Default Label",
      :navigation_attribute_index_position => "1",
      :context_anchor_navigation_attribute_label_expression => label_expression,
      :context_anchor_navigation_attribute_target_context => self,
      :context_anchor_navigation_attribute_target_node_expression => "self"
    })
    
    context_index = SHDM::ContextIndex.create({
      :index_name => "#{self.shdm::context_name}Idx",
      :index_title => "#{self.shdm::context_title} Idx",
      :context_index_context => self,
      :context_anchor_attributes => context_anchor
    })
    self.shdm::context_index = context_index
    self.save
  end
  
end

class SHDM::ContextParameter
  property SHDM::context_parameter_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::context_parameter_class
  property SHDM::parameter_context, 'rdfs:range' => SHDM::Context, 'owl:inverseOf' => SHDM::context_parameters
end

# anyContext is a meta context used to create InContextClasses for any context.
anyContext = SHDM::Context.new(SHDM::anyContext)
anyContext.shdm::context_name = 'Any'
