class ResourcesController < ApplicationController
  
  def index
    @resources      = params[:type].nil? ? [] : ActiveRDF::ObjectManager.construct_class(params[:type]).find_all
    @current_class_uri = params[:type]
    @domain_classes = RDFS::Class.domain_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @meta_classes   = RDFS::Class.meta_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }  
    render :template => 'resources/index'  
  end
  
  # GET /resources/1
  # GET /resources/1.xml
  def show
    @resource          = RDFS::Resource.new(params[:id])
    @current_class_uri = @resource.classes.first.uri
    @domain_classes    = RDFS::Class.domain_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @meta_classes      = RDFS::Class.meta_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    render :template   => 'resources/show'
  end
 
  def search_resource
    text   = params[:q]
    result = RDFS::Resource.find_by.rdfs::label(:regex => (/#{text}/)).execute
    result.uniq!
    result = result.map{|v| "#{v.rdfs::label.first || v.compact_uri}|#{v.uri}"}
    result = result.join("\n")
    render :text => result
  end
  
  def search_class
    text   = params[:q]
    from_label = RDFS::Class.find_by.rdfs::label(:regex => (/#{text}/)).execute
    from_uri   = ActiveRDF::Query.new.distinct(:s).where(:s,RDF::type,RDFS::Class).regexp(:s, (/#{text}/)).execute
    result = from_label + from_uri
    result.uniq!
    result = result.map{|v| "#{v.compact_uri}|#{v.uri}"}
    result = result.join("\n")
    render :text => result
  end
  
  def search_property
    text   = params[:q]
    from_label = RDF::Property.find_by.rdfs::label(:regex => (/#{text}/)).execute
    from_uri   = ActiveRDF::Query.new.distinct(:s).where(:s,RDF::type,RDF::Property).regexp(:s, (/#{text}/)).execute
    result = from_label + from_uri
    result.uniq!
    result = result.map{|v| "#{v.compact_uri}|#{v.uri}"}
    result = result.join("\n")
    render :text => result
  end
  
  def update_property
    @resource = RDFS::Resource.new(params[:id])
    @property = RDF::Property.new(params[:property], @resource)
    @value    = params[:value]
    original = params[:original]
    
    begin
      URI.parse(@value);
      r = RDFS::Resource.find(@value);
      @value = r.nil? ? @value : r
    rescue
      
    end
        
    begin
      URI.parse(original);
      r = RDFS::Resource.find(original);
      original = r.nil? ? original : r
    rescue
      
    end    
    
    if original == ""               # adding new property value
      @property.add(@value)
    elsif @value.blank?              # delete current property value
      @property.delete(original)
    else                            # update current property value
      @property.delete(original)
      @property.add(@value)
    end
      
   #values   = params[:content].map{|v| 
   #  begin
   #    URI.parse(v); 
   #    r = RDFS::Resource.find(v);
   #    r.nil? ? v : r
   #  rescue
   #    v
   #  end
   #}    
   #property.replace(values)
    render :partial => 'properties'
  end

  # GET /resources/new
  # GET /resources/new.xml
  def new
    @domain_classes    = RDFS::Class.domain_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @meta_classes      = RDFS::Class.meta_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @namespaces        = ActiveRDF::Namespace.all.to_a.sort{|a,b| a.first.to_s <=> b.first.to_s }
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource  = RDFS::Resource.find(params[:id])
  end

  # POST /resources
  # POST /resources.xml
  def create
    
    @resource = RDFS::Resource.new(params[:resource][:id])
    @resource.save
    
    respond_to do |format|
      flash[:notice] = 'Resource was successfully created.'
      format.html { redirect_to :action => 'show', :id => @resource }
      format.xml  { render :xml => @resource, :status => :created, :location => @resource }
    end

  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
		@resource = RDFS::Resource.find(params[:id])

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Concrete Interface was successfully updated.'
        format.html { redirect_to(resources_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
	
  end

  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = RDFS::Resource.find(params[:id])
    type = @resource ? @resource.classes.first.uri : nil
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml  { head :ok }
    end
  end
 
end

class ClassesController < ResourcesController
end
