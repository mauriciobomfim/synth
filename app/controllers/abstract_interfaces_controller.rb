require "rexml/document"

include REXML

class AbstractInterfacesController < ApplicationController
  
  def index
    @interfaces = SWUI::AbsInterface.alpha(SWUI::interface_name)
  end
    
  # GET /interfaces/1
  # GET /interfaces/1.xml
  def show
    @interface = SWUI::Interface.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @interface }
    end
  end

  # GET /interfaces/new
  # GET /interfaces/new.xml
  def new
    @classes    = RDFS::Class.domain_classes
    @contexts   = SHDM::Context.find_all    
    @indices    = SHDM::Index.find_all
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @interface }
    end
  end

  # GET /interfaces/1/edit
  def edit
    @classes    = RDFS::Class.domain_classes
    @contexts   = SHDM::Context.find_all.reject{|c| c == SHDM::anyContext}
    @indices    = SHDM::Index.find_all
    
    @interface  = SWUI::Interface.find(params[:id])
  end

  # POST /interfaces
  # POST /interfaces.xml
  def create
    class_name = params[:interface].delete(:type)
    context_id = params[:interface].delete(:context_id)
    index_id   = params[:interface].delete(:index_id)
    class_id   = params[:interface].delete(:class_id)

    if class_name == "SWUI::ContextInterface"
      params[:interface][:context]      = SHDM::Context.find(context_id) unless context_id.blank?
      params[:interface][:domain_class] = RDFS::Class.find(class_id) unless class_id.blank?
    elsif class_name == "SWUI::IndexInterface"
      params[:interface][:index]        = SHDM::Index.find(index_id) unless index_id.blank?
    end
    
    klass      = eval(class_name)    
    @interface = klass.create(params[:interface])
    
    respond_to do |format|
      if @interface.save
        flash[:notice] = 'Interface was successfully created.'
        format.html { redirect_to(abstract_interfaces_url) }
        format.xml  { render :xml => @interface, :status => :created, :location => @interface }
      else
        @classes    = RDFS::Class.domain_classes
        @contexts   = SHDM::Context.find_all    
        @indices    = SHDM::Index.find_all
        format.html { render :action => "new" }
        format.xml  { render :xml => @interface.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /interfaces/1
  # PUT /interfaces/1.xml
  def update    
    
    if params["xslt"] == "true" then  # interface edited in XSLT form
      updateXml
      @interface = SWUI::Interface.find(params[:id])
      @interface.concrete_interfaces = params['abs_interface']['concrete_interfaces']
    else
      interface = SWUI::Interface.find(params[:id])
      
      interface.destroy

      class_name = params[:interface].delete(:type)
      context_id = params[:interface].delete(:context_id)
      index_id   = params[:interface].delete(:index_id)
      class_id   = params[:interface].delete(:class_id)

      if class_name == "SWUI::ContextInterface"
        params[:interface][:context]      = SHDM::Context.find(context_id) unless context_id.blank?
        params[:interface][:domain_class] = RDFS::Class.find(class_id) unless class_id.blank?
      elsif class_name == "SWUI::IndexInterface"
        params[:interface][:index]        = SHDM::Index.find(index_id) unless index_id.blank?
      elsif class_name == "SWUI::ComponentInterface"
        params[:interface].delete(:rhet_spec)
      end

      klass      = eval(class_name)
      @interface = klass.create(interface, params[:interface])
      @interface.rdf::type = klass
    
    end
    
    respond_to do |format|
      if @interface.save
        flash[:notice] = 'Interface was successfully updated.'
        format.html { redirect_to(abstract_interfaces_url) }
        format.xml  { head :ok }
      else
        @classes    = RDFS::Class.domain_classes
        @contexts   = SHDM::Context.find_all    
        @indices    = SHDM::Index.find_all
        format.html { render :action => "edit" }
        format.xml  { render :xml => @interface.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /interfaces/1
  # DELETE /interfaces/1.xml
  def destroy
    @interface = SWUI::Interface.find(params[:id])
    @interface.destroy

    respond_to do |format|
      format.html { redirect_to(abstract_interfaces_url) }
      format.xml  { head :ok }
    end
  end

  def xslt
    interface = SWUI::Interface.find(params[:id])
    output = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?> \n \
    <?xml-stylesheet type=\"text/xsl\" href=\"/abstract_interfaces/aixsl\"?> \n"
    begin
          # Exceptions raised by this code will
          # be caught by the following rescue clause
          document = xmlDoc(SWUI::AbstractInterface.preCompile(interface.abstract_spec.first).first)
          root = document.root
          xml = SWUI::AbstractInterface.preCompile(interface.abstract_spec.first).first
          output << xml.gsub("&","&#38;")
          render :xml => output
#    rescue Exception
#          render :nothing => true
    end

  end
  
  def aixsl
    render :aixsl, :content_type => 'application/xml', :layout => false
  end
 
  def css
    interface = SWUI::Interface.find_by.interface_name(params[:id]).execute.first
    if interface.concrete_interfaces.first.nil? or interface.concrete_interfaces.first.strip.empty?
      render :nothing => true
    else
      render :text => interface.concrete_interfaces.first
    end
  end
  
  def htmlTags
    response = ""
    htmlTags = SWUI::HtmlTag.find_all()
    htmlTags.each { |htmlTag|
      response << htmlTag.concrete_widget_name.first
      response << ";"
    }
    render :text => response
  end

  private

  def updateXml
     puts "ENTREIIIIII"
      response=""

      paths = Array.new
      widgetsNames = Array.new
      params.each do |param|
        paramName = param.first
        unless (!paramName.include? "#")
            path = paramName.split("#").first+"#"+paramName.split("#")[1]
            unless paths.include? path
                paths.push(path) 
            end
        end
      end

      interface = SWUI::Interface.find_by.interface_name(params["abs_interface"]["name"]).execute.first
      #params["interface"]                  = interface
      params[:id]                         = interface.uri
      params["abs_interface"]["id"]        = interface.id
      params["abs_interface"]["type"]      = interface.class.to_s
      params["abs_interface"]["rhet_spec"] = interface.rhet_spec.nil? ? "" : interface.rhet_spec.first

      document = xmlDoc(SWUI::AbstractInterface.preCompile(interface.abstract_spec.first).first)

      i = 0;
      paths.each do
        |path|
            document.elements.each(path) do |node|
              if (node.attributes["name"] == path.split("#")[1]) then
                   node.attributes["mapsTo"] = params[path+"#mapsTo"]
                   node.attributes["tagAttributes"] = params[path+"#tagAttributes"]
                   node.attributes["cssClasses"] = params[path+"#cssClasses"]
                   node.attributes["fromAction"] = params[path+"#fromAction"] 
                   node.attributes["fromClass"] = params[path+"#fromClass"] 
                   node.attributes["fromAttribute"] = params[path+"#fromAttribute"] 
                   node.attributes["ordered"] = params[path+"#ordered"]  unless params[path+"#ordered"].nil?||params[path+"#ordered"].empty?
                   node.attributes["defaultContent"] = params[path+"#defaultContent"] 
              end
            end
        i = i + 1;
      end
     new_xml = ""
     document.to_s.each('') { |line| 
        while !(line.chomp.eql? line) do
          line.chomp! # remove blank lines
        end
        line.gsub!(/<\?xml .*\?>/,"")
        new_xml << line  
        new_xml << "\n"
     } 
     params["abs_interface"]["abstract_spec"] = new_xml

   end

   def xmlDoc(xmlContent)
     xml = SWUI::AbstractInterface.preCompile(xmlContent).first
     doc = Document.new xml
     return doc
   end
  

end
