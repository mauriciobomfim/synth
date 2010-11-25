#require 'swui/interface'

class ConcreteInterfacesController < ApplicationController
  
  def index
    @concrete_interfaces = SWUI::ConcreteInterface.find_all
  end
    
  # GET /concrete_interfaces/1
  # GET /concrete_interfaces/1.xml
  def show
    @concrete_interface = SWUI::ConcreteInterface.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @concrete_interface }
    end
  end

  # GET /concrete_interfaces/new
  # GET /concrete_interfaces/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @concrete_interface }
    end
  end

  # GET /concrete_interfaces/1/edit
  def edit
    @concrete_interface  = SWUI::ConcreteInterface.find(params[:id])
  end

  # POST /concrete_interfaces
  # POST /concrete_interfaces.xml
  def create
    
    @concrete_interface = SWUI::ConcreteInterface.create(params[:concrete_interface])
    
    respond_to do |format|
      if @concrete_interface.save
        flash[:notice] = 'Concrete Interface was successfully created.'
        format.html { redirect_to(concrete_interfaces_url) }
        format.xml  { render :xml => @concrete_interface, :status => :created, :location => @concrete_interface }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @concrete_interface.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /concrete_interfaces/1
  # PUT /concrete_interfaces/1.xml
  def update
		@concrete_iterface = SWUI::ConcreteInterface.find(params[:id])

    respond_to do |format|
      if @concrete_iterface.update_attributes(params[:concrete_interface])
        flash[:notice] = 'Concrete Interface was successfully updated.'
        format.html { redirect_to(concrete_interfaces_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @concrete_iterface.errors, :status => :unprocessable_entity }
      end
    end
	
  end

  # DELETE /concrete_interfaces/1
  # DELETE /concrete_interfaces/1.xml
  def destroy
    @concrete_interface = SHDM::ConcreteInterface.find(params[:id])
    @concrete_interface.destroy

    respond_to do |format|
      format.html { redirect_to(concrete_interfaces_url) }
      format.xml  { head :ok }
    end
  end
 
end
