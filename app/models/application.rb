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
      FileUtils.cp_r("defaults/bigowlim", app.path + "/db")
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
    #ActiveRDF::Namespace.clear
    ActiveRDF::Namespace.load_defaults
       
    dbconfig       = { 
      #:type       => :jena, 
      :type        => :sesame, 
      #:model      => "main", 
      #:ontology   => :owl, 
      #:reasoner   => :owl_micro, 
      #:owlim      => "#{path}/db/owlim"
      #:file       => "#{path}/db"
      :backend     => "bigowlim",
      :location    => "#{path}/db/bigowlim",
      #:inferencing => true,
      :ruleset     => "owl-horst"
    }
    
    @db         = ActiveRDF::ConnectionPool.add_data_source dbconfig
    @db.enabled = true

    #@db.add_ontology("synth", File.join(RAILS_ROOT, "defaults", "synth.owl"), :rdfxml)
  end
  
  def load_defaults
    ActiveRDF::FederationManager.invalidates_cache
    $page_cache.clear unless $page_cache.nil?
    SHDM::Operation.load_external_operations
    @db.load_namespaces
  end
  
  def shutdown
    @db.instance_variable_get("@db").getRepository.shutDown
  end
  
  def activate
    Application.active.shutdown
    File.open(ACTIVE_FILE_PATH, 'w') {|f| f.write(name) }
    @@active = self
    start
    load_defaults
  end
  
  def path
    "#{APPLICATIONS_PATH}/#{name}"
  end
  
  def destroy
    shutdown
    FileUtils.mv(path, "#{APPLICATIONS_PATH}/.#{name}")
  end

end
