import com.hp.hpl.jena.tdb.*;
import com.hp.hpl.jena.tdb.TDBLoader;
import com.hp.hpl.jena.tdb.store.*;
import com.hp.hpl.jena.*;
import com.hp.hpl.jena.query.*;
import com.hp.hpl.jena.rdf.model.*;
import com.hp.hpl.jena.vocabulary.DC;

import com.ontotext.trree.OwlimSchemaRepository; 
import org.openrdf.repository.sail.SailRepository; 
import org.openrdf.repository.RepositoryConnection; 
import com.ontotext.jena.SesameDataset;
import java.io.*;
import java.util.*;


public class Reading{
  public static void main(String args[]){
      /*System.out.println("Creating database");
      Dataset ds = TDBFactory.createDataset("DB") ;
      Model model = ds.getDefaultModel() ;
      //TDBLoader.load(ds, "file:/Users/mauriciobomfim/Projects/workspace/synth/main.rdf", true);
      model.read("file:/Users/mauriciobomfim/Projects/workspace/synth/main.rdf", "RDF/XML") ;
      //TDB.sync(ds) ;
      System.out.println("DONE") ;
      System.exit(0) ;*/
   
        OwlimSchemaRepository schema = new OwlimSchemaRepository();
        // set the data folder where BigOWLIM will persist its data 
        schema.setDataDir(new File("./local-sotrage"));
        // configure BigOWLIM with some parameters 
        schema.setParameter("storage-folder", "./"); 
        schema.setParameter("repository-type", "file-repository"); 
        schema.setParameter("ruleset", "rdfs");
        // wrap it into a Sesame SailRepository 
        SailRepository repository = new SailRepository(schema);
        // initialize 
        
        try{
        repository.init(); 
        RepositoryConnection connection = repository.getConnection();
        // finally, create the DatasetGraph instance 
        SesameDataset dataset = new SesameDataset(connection);

        Model model = ModelFactory.createModelForGraph(dataset.getDefaultGraph()); 
        Resource r1 = model.createResource("http://example.org/book#1") ; 
        Resource r2 = model.createResource("http://example.org/book#2") ;
        r1.addProperty(DC.title, "SPARQL - the book").addProperty(DC.description, "A book about SPARQL") ;
        r2.addProperty(DC.title, "Advanced techniques for SPARQL") ;

        // Query string. 
        //String queryString = "PREFIX dc: <"+DC.getURI()+">\n" + "SELECT ?title WHERE {?x dc:title ?title}"; 
        String queryString = "SELECT ?s WHERE {?s ?p ?o}"; 
        System.out.println(queryString);
        Query query = QueryFactory.create(queryString);
        // Create a single execution of this query, apply to a model 
        // which is wrapped up as a Dataset
        QueryExecution qexec = QueryExecutionFactory.create(query, dataset.asDataset()); 
        // then fetch the results 
       
          // Assumption: it's a SELECT query. 
          ResultSet rs = qexec.execSelect() ;
          // The order of results is undefined.
          System.out.println("antes for"); 
          for ( ; rs.hasNext() ; ) {
            QuerySolution rb = rs.nextSolution() ; 
            for (Iterator<String> iter = rb.varNames(); iter.hasNext(); ) {
              String name = iter.next(); 
              RDFNode x = rb.get(name) ; 
              if ( x.isLiteral() ) {
                Literal titleStr = (Literal)x ; 
                System.out.print(name+":\t"+titleStr) ;
              } else if ( x.isURIResource()){
                Resource res = (Resource)x; 
                System.out.print(name+":\t"+res.getURI()) ;
              } 
            }
            System.out.println();
          }
        } 
        catch(Exception x){
          System.out.println("falhou");
          x.printStackTrace();
        }

                
      
  }
}


