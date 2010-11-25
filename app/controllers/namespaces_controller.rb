class NamespacesController < ApplicationController
  
  def index
    @namespaces = ActiveRDF::Namespace.all
  end
    
  # GET /namespaces/new
  # GET /namespaces/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @namespace }
    end
  end

  # POST /namespaces
  # POST /namespaces.xml
  def create
    @namespace = ActiveRDF::Namespace.register(params[:namespace][:prefix].to_sym, params[:namespace][:uri])
    
    respond_to do |format|
      flash[:notice] = 'Namespace was successfully created.'
      format.html { redirect_to :action => :index }
      format.xml  { render :xml => @namespace, :status => :created, :location => @namespace }
    end
  end

  # DELETE /namespaces/1
  # DELETE /namespaces/1.xml
  def destroy
    @namespace = ActiveRDF::Namespace.remove(params[:id].to_sym)
     
    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml  { head :ok }
    end
  end
 
end