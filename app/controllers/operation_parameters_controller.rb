#require 'shdm/operation'

class OperationParametersController < ApplicationController

  # GET /operations
  # GET /operations.xml
  def index
    @operation_parameters = SHDM::OperationParameter.find_all    
  end
  
  def index
    @operation_parameters = SHDM::OperationParameter.find_all

    respond_to do |format|
      format.html 
      format.json { render :json => @operation_parameters.to_jqgrid_json([:id, :operation_parameter_name, :parameter_operation], 
                                                         1, @operation_parameters.size + 1, @operation_parameters.size) }   
    end
  end

  def post_data
    if params[:oper] == "del"
      ActiveRDF::FederationManager.delete(SHDM::OperationParameter.find(params[:id]), :p)
    else
      operation_parameter = { :operation_parameter_name => params[:operation_parameter_name], :parameter_operation => "http://#{params[:parameter_operation]}" }
      if params[:id] == "_empty"
        SHDM::OperationParameter.create(operation_parameter)
      else
        SHDM::OperationParameter.find(params[:id]).update_attributes(operation_parameter)
      end
    end
    render :nothing => true
  end

  # GET /operations/1
  # GET /operations/1.xml
  def show
    @operation_parameter = SHDM::OperationParameter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @operation_parameter }
    end
  end

  # GET /operations/new
  # GET /operations/new.xml
  def new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @operation_parameter }
    end
  end

  # GET /operations/1/edit
  def edit
    @operation_parameter  = SHDM::OperationParameter.find(params[:id])
  end

  # POST /operations
  # POST /operations.xml
  def create
    @operation_parameter = SHDM::OperationParameter.create(params[:operation_parameter])
    @operation_parameter.parameter_operation = SHDM::Operation.find(params[:operation_parameter][:parameter_operation])
    respond_to do |format|
      if @operation_parameter.save
        flash[:notice] = 'Operation was successfully created.'
        format.html { redirect_to :action => 'show', :id => @operation_parameter }
        format.xml  { render :xml => @operation_parameter, :status => :created, :location => @operation_parameter }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @operation_parameter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /operations/1
  # PUT /operations/1.xml
  def update
    @operation_parameter = SHDM::OperationParameter.find(params[:id])

    respond_to do |format|
      if @operation_parameter.update_attributes(params[:operation_parameter])
        flash[:notice] = 'Operation was successfully updated.'
        format.html { redirect_to :action => 'show', :id => @operation_parameter }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @operation_parameter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /operations/1
  # DELETE /operations/1.xml
  def destroy
    @operation_parameter = SHDM::OperationParameter.find(params[:id])
    @operation_parameter.destroy

    respond_to do |format|
      format.html { redirect_to(operations_url) }
      format.xml  { head :ok }
    end
  end  

end
