require 'dsl'

class QueryDSL < DSL
    
  def type(type)
    @conditions['type'] = type
  end
  
  def order(*s)
    @order = s
  end
  
  def reverse_order(*s)
    @reverse_order = s
  end
  
  def datasets(*datasets)
    @datasets = datasets
  end
  
  def like(text)
    { :regex => /#{text}/ }
  end
  
  def limit(lim)
    @limit = lim
  end
  
  def a(type)
    type(type)
  end
  
  def method_missing(method_name, arg=nil)
    unless arg.nil?
      unless @current_namespace.nil?
        @conditions[@current_namespace] << [ method_name.to_s, arg ]
        @current_namespace = nil
      else
        @conditions[method_name.to_s] = arg
      end
    else
      @conditions[method_name.to_s] ||= []
      @current_namespace = method_name.to_s
      self
    end
  end

end

#melhor criar a representação da query e depois instanciar.
class QueryBuilder

  attr_reader :query

  def initialize
    @conditions = {}
  end
  
  def execute
    @query ||= ActiveRDF::ResourceQuery.new(@conditions['type'] || RDFS::Resource)

    for property, value in @conditions.reject{|i,v| i == 'type'} do
      if value.is_a?(Array)
        for v in value do
          @query.send(property).send(v.first, v.last)
        end
      else
        @query.send(property, value)
      end
    end
    
    @query.sort(*@order) unless @order.nil?
    
    @query.reverse_sort(*@reverse_order) unless @reverse_order.nil?
    
    @query.limit(@limit) unless @limit.nil?
    
    @query.datasets(*@datasets) unless @datasets.nil?
    
    @query.execute    
  end

  dsl_method :selects => QueryDSL
  

end

