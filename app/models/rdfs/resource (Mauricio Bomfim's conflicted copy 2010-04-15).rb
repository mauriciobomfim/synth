require 'uuidtools'

ActiveRDF::Namespace.register :base, 'http://base#'
ActiveRDF::Namespace.register :shdm, 'http://shdm#'

module RDFSClass
  
  def self.append_features(base)
    base.extend(ClassMethods)
    base.class_eval { @accessors = {} }
    super
  end
  
  module ClassMethods
  
    def property(resource, options = {})
      
      property_name = ActiveRDF::Namespace.localname(resource)
      
      property               = RDF::Property.create(resource, options)
      property.rdfs::domain << self
      property.rdfs::label  << property_name if property.rdfs::label.empty?

      property
    end

    def create(resource=nil, options={})
      
      if resource.is_a? Hash
        options = resource
        resource = self.new(ActiveRDF::Namespace.lookup(:base, UUIDTools::UUID.timestamp_create.to_s))
      else
        resource = RDFS::Resource.new(resource)      
      end
                  
      options.each_pair {|property_name, value|
        property_name = property_name.to_s
        match = property_name.match(/^([a-z]+)::?(.+)/) #checking if the property is composed by a namespace
      
        if match
          property = resource.send(match[1]).send(match[2])          
        else
          property = resource.send(property_name)
        end
        
        property << (property.range.first.respond_to?(:new) ? property.range.first.new(value) : value) #creates a rdfs:resource based on property's range using the value as attribute for new
      }
      
      resource
    end
        
    def sub_class_of(rdfs_class)
      self.subClassOf << rdfs_class
    end    

    def before_add_property(property, &block)
      define_method "before_add_property_#{property.to_s}".to_sym, &block
    end
    
    def after_add_property(property, &block)
      define_method "after_add_property_#{property.to_s}".to_sym, &block
    end
    
  end
  
  
end

class RDFS::Resource
  include RDFSClass
  
  def update_attributes(options)    
    options.each_pair {|property_name, value|
      property_name = property_name.to_s
      match = property_name.match(/^([a-z]+)::?(.+)/) #checking if the property is composed by a namespace
  
      if match
        property = self.send(match[1]).send(match[2])          
      else
        property = self.send(property_name)
      end
      
      #creates a rdfs:resource based on property's range using the value as attribute for new
      property.replace( (property.range.first.respond_to?(:new) ? property.range.first.new(value) : value) )
      
    }
  end
  
  def errors
    []
  end
  
  def id
    uri
  end
  
  def destroy
    ActiveRDF::FederationManager.delete(:s, :p, self)
    ActiveRDF::FederationManager.delete(self, :p)
  end
  
  def attributes
    attributes = {}
    for attribute in self.direct_predicates.map {|v| v.label ? v.label.first : nil }.compact do
      attributes[attribute] = self.send(attribute).first
    end
    attributes['id'] = id
    attributes
  end
  
end
