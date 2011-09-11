#require 'shdm/index'

class IndexesController < ApplicationController

  # GET /indexes
  # GET /indexes.xml
  def index
    @indexes = SHDM::Index.alpha    
  end

  # GET /indexes/1
  # GET /indexes/1.xml
  def show
    @index = SHDM::Index.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @index }
    end
  end

  # GET /indexes/new
  # GET /indexes/new.xml
  def new
    @contexts = SHDM::Context.find_all.map{ |v| [ v.context_name.first, v.uri ] }.delete_if{|v| v.first == "Any"}
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @index }
    end
  end

  # GET /indexes/1/edit
  def edit
    @index  = SHDM::Index.find(params[:id])
    @contexts = SHDM::Context.find_all.map{ |v| [ v.context_name.first, v.uri ] }.delete_if{|v| v.first == "Any"}
  end

  # POST /indexes
  # POST /indexes.xml
  def create
    context_url = params[:index].delete(:context_index_context)
    params[:index][:context_index_context] = SHDM::Context.find(context_url)
    @index = SHDM::ContextIndex.create(params[:index])
    
    respond_to do |format|
      if @index.save
        flash[:notice] = 'Index was successfully created.'
        format.html { redirect_to :action => 'edit', :id => @index }
        format.xml  { render :xml => @index, :status => :created, :location => @index }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @index.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /indexes/1
  # PUT /indexes/1.xml
  def update
    @index = SHDM::ContextIndex.find(params[:id])

    context_url = params[:index].delete(:context_index_context)
    params[:index][:context_index_context] = SHDM::Context.find(context_url)

    respond_to do |format|
      if @index.update_attributes(params[:index])
        flash[:notice] = 'Index was successfully updated.'
        format.html { redirect_to(indexes_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @index.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /indexes/1
  # DELETE /indexes/1.xml
  def destroy
    @index = SHDM::Index.find(params[:id])
    @index.destroy

    respond_to do |format|
      format.html { redirect_to(indexes_url) }
      format.xml  { head :ok }
    end
  end

  def get_resource_attributes
    attrs = params[:id] ? RDFS::Resource.find(params[:id]).attributes : {}
    attrs.each{ |k, v| attrs[k] = v.to_s }
    render :json => attrs
  end
  
  def get_resource_children_attributes
    render :json => children_attributes(params[:id], params[:children_attribute])
  end
  
  def computed_attributes
    jqgrid_children_index('computed_attributes', [:id, 
      :navigation_attribute_name, 
      :computed_navigation_attribute_value_expression, 
      :navigation_attribute_index_position])
  end
  
  def computed_attributes_post_data
    jqgrid_children_post_data(SHDM::ComputedNavigationAttribute, 'computed_attributes')
  end
  
	def index_anchor_attributes
    jqgrid_children_index('index_anchor_attributes', [:id, 
      :navigation_attribute_name, 
      :index_anchor_navigation_attribute_label_expression, 
       Proc.new {|attr| attr.index_anchor_navigation_attribute_target_index.first.index_name }, 
      :navigation_attribute_index_position])
  end
  
  def index_anchor_attributes_post_data
    jqgrid_children_post_data(SHDM::IndexAnchorNavigationAttribute, 'index_anchor_attributes')
  end
  
  def context_anchor_attributes
    jqgrid_children_index('context_anchor_attributes', [:id, 
      :navigation_attribute_name, 
      :context_anchor_navigation_attribute_label_expression, 
      Proc.new {|attr| attr.context_anchor_navigation_attribute_target_context.first.context_name }, 
      :context_anchor_navigation_attribute_target_node_expression, 
      :navigation_attribute_index_position])
  end
  
  def context_anchor_attributes_post_data
    jqgrid_children_post_data(SHDM::ContextAnchorNavigationAttribute, 'context_anchor_attributes')
  end
  
  def navigation_attribute_index_parameters
	jqgrid_children_index('index_anchor_navigation_attribute_target_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def navigation_attribute_index_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'index_anchor_navigation_attribute_target_parameters')
  end
	
	def navigation_attribute_context_parameters
	jqgrid_children_index('context_anchor_navigation_attribute_target_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def navigation_attribute_context_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'context_anchor_navigation_attribute_target_parameters')
  end
	
	#INDEX ATTRIBUTES

  def index_attributes
    jqgrid_children_index('index_index_attributes', [:id, 
      :navigation_attribute_name, 
       Proc.new {|attr| attr.index_navigation_attribute_index.first.index_name },
       :navigation_attribute_index_position])
  end
  
  def index_attributes_post_data
    jqgrid_children_post_data(SHDM::IndexNavigationAttribute, 'index_index_attributes')
  end
  
  def index_navigation_attribute_index_parameters
	jqgrid_children_index('index_navigation_attribute_index_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def index_navigation_attribute_index_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'index_navigation_attribute_index_parameters')
  end
  
  def pre_conditions
    jqgrid_children_index('index_pre_conditions', [:id, :pre_condition_name, :pre_condition_expression, :pre_condition_failure_handling])
  end
  
  def pre_conditions_post_data
    jqgrid_children_post_data(SHDM::PreCondition, 'index_pre_conditions')
  end  
	
end
