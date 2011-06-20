class ApplicationsController < ApplicationController
  
  def index
    @applications = Application.all
  end
    
  # GET /namespaces/new
  # GET /namespaces/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @application }
    end
  end

  # POST /namespaces
  # POST /namespaces.xml
  def create

    Application.create(params[:application][:name])
    
    respond_to do |format|
      flash[:notice] = 'Application was successfully created.'
      format.html { redirect_to :action => :index }
      format.xml  { render :xml => @application, :status => :created, :location => @application }
    end
  end
  
  def activate
    Application.new(params[:id]).activate
    redirect_to :action => :index
  end
 
  def destroy
    Application.new(params[:id]).destroy
    redirect_to :action => :index
  end
  
  def shutdown
    Application.active.shutdown
    redirect_to :action => :index
  end
 
end