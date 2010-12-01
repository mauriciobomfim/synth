class ActiveRDF::Query
  
  attr_reader :on_datasets
  
  def datasets(*datasets)
    @on_datasets.concat(datasets).uniq!
    self
  end
  
  def initialize
    @on_datasets = []
    @distinct = false
    @select_clauses = []
    @where_clauses = []
    @filter_clauses = {}
    @sort_clauses = []
    @limits = nil
    @offsets = nil
    @keywords = {}
    @reasoning = nil
    @all_types = false
    @nil_clause_idx = -1
  end
  
end

class Query2FederatedSPARQL < ActiveRDF::Query2SPARQL

  def Query2FederatedSPARQL.translate(query, local=false)

    main_query = super(query)

    unless local
      on_local    = query.on_datasets.delete(:local)
      on_datasets = query.on_datasets.uniq.map{|d| d.to_s.downcase }
      datasets    = on_datasets.map{|d| ActiveRDF::Namespace.lookup(:base, d) }.map{|d| d.sparqlEndpoint.first unless d.sparqlEndpoint.nil? }.compact.uniq
 
      unless datasets.empty?
        
        str = ""
        if query.select?
          distinct = query.distinct? ? "DISTINCT " : ""
          select_clauses = query.select_clauses.collect{|s| construct_clause(s)}
        
          str << "SELECT #{distinct}#{select_clauses.join(' ')} {"
        
          str << "{ #{main_query} } UNION " unless on_local.nil?

          str << datasets.map{|dataset| "{ SERVICE <#{dataset}> { #{main_query} } }"}.join(" UNION ")

          str << "}"
    
          str << "ORDER BY #{order_clauses(query)} " if query.sort_clauses.size > 0
          str << "LIMIT #{query.limits} " if query.limits
          str << "OFFSET #{query.offsets} " if query.offsets
        elsif query.ask?
          str << "ASK { #{where_clauses(query)} } "
        end
        return str
      end
    end
    return main_query
    
  end
  
end
