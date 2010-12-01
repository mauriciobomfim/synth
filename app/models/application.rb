class Application

  APPLICATIONS_PATH = "applications"
  ACTIVE_FILE_NAME  = "active"
  ACTIVE_FILE_PATH  = "#{APPLICATIONS_PATH}/#{ACTIVE_FILE_NAME}"

  attr_accessor :name, :db

  def self.all
    Dir.entries(APPLICATIONS_PATH).reject{|app| [ACTIVE_FILE_NAME].include?(app) || app.match(/^\./) }.map{ |name| new(name) }
  end

  def self.find(name)
    self.all.select{|app| name == app.name}.first
  end

  def self.create(name)
    
    if name.match(/^\./)
      raise "Can not start with '.'"
    end
    
    if name.blank?
      raise "Can not be blank."
    end
    
    if name == ACTIVE_FILE_NAME
      raise "You can not use '#{ACTIVE_FILE_NAME}' as an application name."
    end
    
    if self.find(name).nil?
      app = new(name)
      FileUtils.mkdir_p(app.path)
      FileUtils.mkdir_p(app.path + "/db")
      FileUtils.mkdir_p(app.path + "/ontologies")
      FileUtils.cp("defaults/main", app.path + "/db")
    else
      raise "'#{name}' has been taken."
    end
  end
  
  def self.active
    @@active ||= self.all.select{|app| app.active?}.first
  end
  
  def initialize(name)
    @name = name
  end

  def active?
    File.read(ACTIVE_FILE_PATH).chomp == name
  end
  
  def start
    ActiveRDF::ConnectionPool.clear
    ActiveRDF::Namespace.clear
    ActiveRDF::Namespace.load_defaults    
       
    dbconfig = { 
      :type => :jena, 
      :model => "main", 
      :ontology => :owl, 
      :reasoner => :owl_micro, 
      :file => "#{path}/db" 
    }
    
    @db         = ActiveRDF::ConnectionPool.add_data_source dbconfig
    @db.enabled = true

    @db.add_ontology("synth", "file:" + File.join(RAILS_ROOT, "defaults", "synth.owl"), :rdfxml)
  end
  
  def load_defaults
    SYMPH::Ontology.load_active_ontologies
    SHDM::Operation.load_external_operations
  end
  
  def activate
    File.open(ACTIVE_FILE_PATH, 'w') {|f| f.write(name) }
    @@active = self
    start
    load_defaults
  end
  
  def path
    "#{APPLICATIONS_PATH}/#{name}"
  end
  
  def destroy
    FileUtils.mv(path, "#{APPLICATIONS_PATH}/.#{name}")
  end

end
