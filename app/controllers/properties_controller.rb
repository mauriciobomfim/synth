class PropertiesController < ResourcesController
  def index
    show
  end
    
  def show
    @domain_classes = domain_properties
    @meta_classes   = meta_properties
    @resource       = params[:id].nil? ? ( @domain_classes.first.nil? ? @meta_classes.first : @domain_classes.first ): RDFS::Resource.new(params[:id])
    render :template => 'resources/show'
  end    
  
  private
  def domain_properties(options={})
    excluded_namespaces = [:xsd, :rdf, :rdfs, :owl, :shdm, :swui, :symph, :void]
    RDF::Property.find_all(options).reject{ |c| excluded_namespaces.include?(ActiveRDF::Namespace.prefix(c))  }.sort{|a,b| a.compact_uri <=> b.compact_uri }
  end
  
  def meta_properties(options={})
    included_namespaces = [:rdf, :rdfs, :owl, :shdm, :swui, :symph, :void]
    RDF::Property.find_all(options).select{ |c| included_namespaces.include?(ActiveRDF::Namespace.prefix(c))  }.sort{|a,b| a.compact_uri <=> b.compact_uri }
  end
end