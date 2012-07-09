RDFS::Class
class RDFS::Class
  def class_name
    name = ActiveRDF::ObjectManager.construct_class(self).name
#    name.gsub(/^([^:]+)::/, "#{$1.downcase}:")
  end
  
  def self.domain_classes(options={})
    excluded_namespaces = [:xsd, :rdf, :rdfs, :owl, :shdm, :swui, :symph, :void]
    (RDFS::Class.find_all(options).reject{ |c| excluded_namespaces.include?(ActiveRDF::Namespace.prefix(c))  } +
    OWL::Class.find_all(options).reject{ |c| excluded_namespaces.include?(ActiveRDF::Namespace.prefix(c))  }).uniq
  end
  
  def self.meta_classes(options={})
    included_namespaces = [:rdf, :rdfs, :owl, :shdm, :swui, :symph, :void]
    (RDFS::Class.find_all(options).select{ |c| included_namespaces.include?(ActiveRDF::Namespace.prefix(c))  } +
    OWL::Class.find_all(options).select{ |c| included_namespaces.include?(ActiveRDF::Namespace.prefix(c))  }).uniq
  end
  
  def alpha(property=RDFS::label)
    ActiveRDF::Query.new.distinct(:s).where(:s,RDF::type,self).sort(property).execute
  end
  
  def self.subclasses
    ActiveRDF::Query.new.distinct(:s).where(:s, RDFS::subClassOf, self).execute
  end  
  
end
