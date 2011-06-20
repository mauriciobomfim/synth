ActiveRDF::Namespace.register(:symph, "http://symph#")
ActiveRDF::Namespace.register(:synth, "http://synth#")

SYMPH::Ontology

class SYMPH::Ontology
  
   ONTOLOGY_DIRECTORY = 'ontologies'
  
   property SYMPH::ontology_name, 'rdfs:subPropertyOf' => RDFS::label
   property SYMPH::ontology_description
   property SYMPH::ontology_file_name
   property SYMPH::ontology_file_notation
   property SYMPH::ontology_active
   
   def active?
     self.ontology_active.first == "true" ? true : false
   end
   
   def activate
     puts "activating the ontology '#{self.ontology_name.first}': #{location}"
     ActiveRDF::FederationManager.add_ontology(self.ontology_name.first, location, self.ontology_file_notation.first)     
     self.ontology_active = 'true'
   end
   
   def disable
     ActiveRDF::FederationManager.remove_ontology(self.ontology_name.first)
     self.ontology_active = 'false'
   end
   
   def location
     file_location = File.join(RAILS_ROOT, Application.active.path + '/' + ONTOLOGY_DIRECTORY, self.ontology_file_name.first)
     file_location
   end
   
   def self.save(ontology)
     file_name =  ontology['datafile'].original_filename
     
     FileUtils.mkdir_p(Application.active.path + '/' + ONTOLOGY_DIRECTORY)
     
     # create the file path
     path = File.join(Application.active.path + '/' + ONTOLOGY_DIRECTORY, file_name)
     # write the file
     begin
       
       File.open(path, "wb") { |f| f.write(ontology['datafile'].read) }
     
       self.create({
         :ontology_name => ontology[:ontology_name],
         :ontology_description => ontology[:ontology_description],
         :ontology_file_name => file_name,
         :ontology_file_notation => ontology[:ontology_file_notation],
         :ontology_active => 'false'
       })
            
     rescue
       false
     end
   end
 
end