#require 'shdm/operation'

class OperationsController < ApplicationController

  # GET /operations
  # GET /operations.xml
  def index
    @operations = SHDM::Operation.find_all    
  end

  # GET /operations/1
  # GET /operations/1.xml
  def show
    @operation = SHDM::Operation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @operation }
    end
  end

  # GET /operations/new
  # GET /operations/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @operation }
    end
  end

  # GET /operations/1/edit
  def edit
    @operation  = SHDM::Operation.find(params[:id])
  end

  # POST /operations
  # POST /operations.xml
  def create
    @operation = SHDM::Operation.create(params[:operation])
    
    respond_to do |format|
      if @operation.save
        flash[:notice] = 'Operation was successfully created.'
        format.html { redirect_to :action => 'edit', :id => @operation }
        format.xml  { render :xml => @operation, :status => :created, :location => @operation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @operation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /operations/1
  # PUT /operations/1.xml
  def update
    @operation = SHDM::Operation.find(params[:id])

    respond_to do |format|
      if @operation.update_attributes(params[:operation])
        flash[:notice] = 'Operation was successfully updated.'
        format.html { redirect_to(operations_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @operation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /operations/1
  # DELETE /operations/1.xml
  def destroy
    @operation = SHDM::Operation.find(params[:id])
    @operation.destroy

    respond_to do |format|
      format.html { redirect_to(operations_url) }
      format.xml  { head :ok }
    end
  end
  
  def operation_parameters
    jqgrid_children_index('operation_parameters', [:id, :operation_parameter_name, :operation_parameter_data_type])
  end
  
  def operation_parameters_post_data
    jqgrid_children_post_data(SHDM::OperationParameter, 'operation_parameters')
  end
  
  def pre_conditions
    jqgrid_children_index('operation_pre_conditions', [:id, :pre_condition_name, :pre_condition_expression, :pre_condition_failure_handling])
  end
  
  def pre_conditions_post_data
    jqgrid_children_post_data(SHDM::PreCondition, 'operation_pre_conditions')
  end
  
  def post_conditions
    jqgrid_children_index('operation_post_conditions', [:id, :post_condition_name, :post_condition_expression])
  end
  
  def post_conditions_post_data
    jqgrid_children_post_data(SHDM::PostCondition, 'operation_post_conditions')
  end
  
end
