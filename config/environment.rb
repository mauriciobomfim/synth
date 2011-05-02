tbegin = Time.now
time_begin = tbegin.to_i
# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  #config.gem "json-jruby"
  #config.gem "uuidtools"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  config.frameworks -= [ :active_record ]#, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

$QUERY_DEBUG = true

# Query caching: caches any query on federation manager. 
# All cache is invalidated on any changes on database.
# IMPORTANT: If you enable the caching, clone ActiveRDF::Query results 
# before use changing iterators (e.g. map and sort). 
# For instance: instead of RDFS::Resource.find_all.map{|v| v.to_s} 
# use RDF::Resource.find_all.clone.map{|v| v.to_s}
$ENABLE_QUERY_CACHING = true

require 'active_rdf'
require 'app/models/application.rb'

Application.active.start

#loading order matters
models = []
models << Dir["#{RAILS_ROOT}/app/models/rdfs/**.rb"]
models << Dir["#{RAILS_ROOT}/app/models/shdm/**.rb"]
models << Dir["#{RAILS_ROOT}/app/models/swui/**.rb"]
models << Dir["#{RAILS_ROOT}/app/models/**.rb"].reject{|d| d.match(/application\.rb/)}
models.flatten.each { |model| require model }

Application.active.load_defaults

time_end = Time.now.to_i
time_total = time_end - time_begin

def tempo(sec)
 min = (sec/60)
 sec_min = min * 60
 rest_sec = (sec - sec_min)
 "#{min.to_s.rjust(2,'0')}:#{rest_sec.to_s.rjust(2,'0')}"
end

puts "Demorou:#{tempo(time_total)}"


#jena_memory = { :type => :jena, :model => "hyperde", :ontology => :owl, :reasoner => :owl }

#jena_tdb   = { :type => :jena, :model => "tdb", :ontology => :owl, :reasoner => :owl_micro, :tdb => "#{RAILS_ROOT}/applications/iswc2010/db/" }
#
#jena_derby  = { :type => :jena, :model => "hyperde", :ontology => :owl, :reasoner => :owl, :lucene => true, :database  => { :url => 'jdbc:derby:/Users/mauriciobomfim/Dropbox/Mestrado/hyperde_mauricio/db/hyperde;create=true', :type => "Derby", :username => "", :password => ""} }
#
#with_hsqldb = { :type => :jena, :model => "hyperde", :ontology => :owl, :reasoner => :owl, :database  => { :url => 'jdbc:hsqldb:file:/Users/mauriciobomfim/Dropbox/Mestrado/hyperde_mauricio/db/hsql/hyperde;create=true', :type => "HSQL", :username => "sa", :password => ""} }
#
#with_mysql  = { :type => :jena, :model => "hyperde", :ontology => :owl, :reasoner => :owl, :database  => { :url => 'jdbc:mysql://localhost/hyperde', :type => "MySQL", :username => "root", :password => ""} }
#
#ng4j_with_derby  = { :type => :ng4j, :model => "hyperde", :ontology => :owl, :reasoner => :owl }
#
#sesame = { :type => :sesame , :backend => 'native', :location => "#{RAILS_ROOT}/db/sesame" }
#sesame = { :type => :sesame , :location => "#{RAILS_ROOT}/db/sesame", :inferencing  => true }
#


#ActiveRDF::Namespace.register(:dr, "http://www.tecweb.inf.puc-rio.br/ontologies/dr#")
#ActiveRDF::Namespace.register(:foaf, "http://xmlns.com/foaf/0.1/")
#ActiveRDF::Namespace.register(:bibo, "http://purl.org/ontology/bibo/")
#ActiveRDF::Namespace.register(:swrc, "http://swrc.ontoware.org/ontology#")
#ActiveRDF::Namespace.register(:sioc, "http://rdfs.org/sioc/types#")

#main_data_source.load("file:#{RAILS_ROOT}/db/dr.rdf")
#main_data_source.load("file:#{RAILS_ROOT}/db/jena_persistence/hyperde", :into => :default_model)
#main_data_source.load("file:#{RAILS_ROOT}/db/foaf.rdf")
#main_data_source.load("file:#{RAILS_ROOT}/db/bibo.xml.owl")
#main_data_source.load("file:#{RAILS_ROOT}/db/lattes.n3", :format => :n3)
#main_data_source.load("file:#{RAILS_ROOT}/db/conferences.rdf.xml")