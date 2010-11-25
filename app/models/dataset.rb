ActiveRDF::Namespace.register(:void, "http://rdfs.org/ns/void#")

VOID::Dataset

#class Dataset
#
#  DATASETS_FILE = "#{RAILS_ROOT}/config/datasets.yml"
#  @@datasets = YAML.load_file DATASETS_FILE
#
#  def self.all
#    @@datasets
#  end
#
#  def self.find(id)    
#    @@datasets[id.to_s]
#  end
#
#  def self.add(id, uri)
#    @@datasets[id.to_s] = { 'sparqlEndpoint' => uri }
#    save
#  end
#  
#  def self.delete(id)
#    @@datasets.delete(id)
#    save
#  end
#  
#  private
#  
#  def self.save
#    File.open(DATASETS_FILE, 'w') {|f| f.write(@@datasets.to_yaml) }
#  end
#
#end