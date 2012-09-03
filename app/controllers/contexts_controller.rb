#require 'shdm/context'

class ContextsController < ApplicationController

  # GET /contexts
  # GET /contexts.xml
  def index
    @contexts = SHDM::Context.alpha
    @contexts.delete(SHDM::anyContext)
  end

  # GET /contexts/1
  # GET /contexts/1.xml
  def show
    @context = SHDM::Context.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @context }
    end
  end

  # GET /contexts/new
  # GET /contexts/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @context }
    end
  end

  # GET /contexts/1/edit
  def edit
    @context  = SHDM::Context.find(params[:id])
  end

  # POST /contexts
  # POST /contexts.xml
  def create
    @context = SHDM::Context.create(params[:context])
    
    respond_to do |format|
      if @context.save
        flash[:notice] = "Context was successfully created. The Index '#{@context.context_name}Idx' was automatically created."
        format.html { redirect_to :action => 'edit', :id => @context }
        format.xml  { render :xml => @context, :status => :created, :location => @context }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @context.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contexts/1
  # PUT /contexts/1.xml
  def update
    @context = SHDM::Context.find(params[:id])

    respond_to do |format|
      if @context.update_attributes(params[:context])
        flash[:notice] = 'Context was successfully updated.'
        format.html { redirect_to(contexts_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @context.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contexts/1
  # DELETE /contexts/1.xml
  def destroy
    @context = SHDM::Context.find(params[:id])
    @context.destroy

    respond_to do |format|
      format.html { redirect_to(contexts_url) }
      format.xml  { head :ok }
    end
  end
  
  def context_parameters
    jqgrid_children_index('context_parameters', [:id, :context_parameter_name])
  end
  
  def get_resource_attributes
    attrs = params[:id] ? RDFS::Resource.find(params[:id]).attributes : {}
    render :json => attrs
  end
  
  def context_parameters_post_data
    jqgrid_children_post_data(SHDM::ContextParameter, 'context_parameters')
  end
  
  def pre_conditions
    jqgrid_children_index('context_pre_conditions', [:id, :pre_condition_name, :pre_condition_expression, :pre_condition_failure_handling])
  end
  
  def pre_conditions_post_data
    jqgrid_children_post_data(SHDM::PreCondition, 'context_pre_conditions')
  end
  
end
