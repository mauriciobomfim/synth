#require 'shdm/context'

class ContextsController < ApplicationController

  # GET /contexts
  # GET /contexts.xml
  def index
    @contexts = SHDM::Context.find_all
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
        flash[:notice] = 'Context was successfully created.'
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
  
  def context_parameters_post_data
    jqgrid_children_post_data(SHDM::ContextParameter, 'context_parameters')
  end
  
end
