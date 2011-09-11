#require 'shdm/in_context_class'

class InContextClassesController < ApplicationController

  # GET /in_context_classes
  # GET /in_context_classes.xml
  def index
    @in_context_classes = SHDM::InContextClass.find_all
  end

  # GET /in_context_classes/1
  # GET /in_context_classes/1.xml
  def show
    @in_context_class = SHDM::InContextClass.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @in_context_class }
    end
  end

  # GET /in_context_classes/new
  # GET /in_context_classes/new.xml
  def new
    if params[:show_meta_classes]
      @classes  = RDFS::Class.find_all.map{ |v| [ v.compact_uri , v.uri ] }.sort{|a,b| a.first <=> b.first }
    else
      @classes  = RDFS::Class.domain_classes.map{ |v| [ v.compact_uri , v.uri ] }.sort{|a,b| a.first <=> b.first }
    end
    @contexts = SHDM::Context.find_all.to_a.clone

    #put anyContext on the first place
    anyContext = @contexts.delete(SHDM::anyContext)
    @contexts  = @contexts.map{ |v| [ v.context_name.first, v.uri ] }
    @contexts  = @contexts.sort{ |a,b| a.first <=> b.first }
    @contexts.insert(0, [anyContext.context_name.first, anyContext.uri]) unless anyContext.nil?
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @in_context_class }
    end
  end

  # GET /in_context_classes/1/edit
  def edit
    @in_context_class  = SHDM::InContextClass.find(params[:id])

    unless RDFS::Class.domain_classes.include?(@in_context_class.in_context_class_class.first)
      params[:show_meta_classes] = true
    end

    if params[:show_meta_classes]
      @classes  = RDFS::Class.find_all.map{ |v| [ v.compact_uri , v.uri ] }.sort{|a,b| a.first <=> b.first }
    else
      @classes  = RDFS::Class.domain_classes.map{ |v| [ v.compact_uri , v.uri ] }.sort{|a,b| a.first <=> b.first }
    end
    
    @contexts = SHDM::Context.find_all.to_a.clone

    #put anyContext on the first place
    anyContext = @contexts.delete(SHDM::anyContext)
    @contexts  = @contexts.map{ |v| [ v.context_name.first, v.uri ] }
    @contexts  = @contexts.sort{ |a,b| a.first <=> b.first }
    @contexts.insert(0, [anyContext.context_name.first, anyContext.uri]) unless anyContext.nil?
        
  end

  # POST /in_context_classes
  # POST /in_context_classes.xml
  def create
    class_url   = params[:in_context_class].delete(:in_context_class_class)    
    context_url = params[:in_context_class].delete(:in_context_class_context)

    params[:in_context_class][:in_context_class_class]   = RDFS::Resource.new(class_url)
    params[:in_context_class][:in_context_class_context] = RDFS::Resource.new(context_url)
      
    @in_context_class = SHDM::InContextClass.create(params[:in_context_class])
    
    respond_to do |format|
      if @in_context_class.save
        flash[:notice] = 'InContextClass was successfully created.'
        format.html { redirect_to :action => 'edit', :id => @in_context_class }
        format.xml  { render :xml => @in_context_class, :status => :created, :location => @in_context_class }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @in_context_class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /in_context_classes/1
  # PUT /in_context_classes/1.xml
  def update
    @in_context_class = SHDM::InContextClass.find(params[:id])

    class_url = params[:in_context_class].delete(:in_context_class_class)    
    context_url = params[:in_context_class].delete(:in_context_class_context)

    params[:in_context_class][:in_context_class_class] = SHDM::Context.find(class_url)
    params[:in_context_class][:in_context_class_context] = SHDM::Context.find(context_url)

    respond_to do |format|
      if @in_context_class.update_attributes(params[:in_context_class])
        flash[:notice] = 'InContextClass was successfully updated.'
        format.html { redirect_to(in_context_classes_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @in_context_class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /in_context_classes/1
  # DELETE /in_context_classes/1.xml
  def destroy
    @in_context_class = SHDM::InContextClass.find(params[:id])
    @in_context_class.destroy

    respond_to do |format|
      format.html { redirect_to(in_context_classes_url) }
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
  
  #CONTEXT ANCHOR ATTRIBUTES
  def context_anchor_attributes
    jqgrid_children_index('in_context_class_context_anchor_attributes', [:id, 
      :navigation_attribute_name, 
      :context_anchor_navigation_attribute_label_expression, 
       Proc.new {|attr| attr.context_anchor_navigation_attribute_target_context.first.context_name }, 
      :context_anchor_navigation_attribute_target_node_expression, 
      :navigation_attribute_index_position])
  end
    
  def context_anchor_attributes_post_data
    jqgrid_children_post_data(SHDM::ContextAnchorNavigationAttribute, 'in_context_class_context_anchor_attributes')
  end
  
  def navigation_attribute_context_parameters
	jqgrid_children_index('context_anchor_navigation_attribute_target_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def navigation_attribute_context_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'context_anchor_navigation_attribute_target_parameters')
  end
  
  # INDEX ANCHOR ATTRIBUTES
	def index_anchor_attributes
    jqgrid_children_index('in_context_class_index_anchor_attributes', [:id, 
      :navigation_attribute_name, 
      :index_anchor_navigation_attribute_label_expression, 
       Proc.new {|attr| attr.index_anchor_navigation_attribute_target_index.first.index_name }, 
      :navigation_attribute_index_position])
  end
  
  def index_anchor_attributes_post_data
    jqgrid_children_post_data(SHDM::IndexAnchorNavigationAttribute, 'in_context_class_index_anchor_attributes')
  end
  
  def navigation_attribute_index_parameters
	jqgrid_children_index('index_anchor_navigation_attribute_target_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def navigation_attribute_index_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'index_anchor_navigation_attribute_target_parameters')
  end
      
  # COMPUTED ATTRIBUTES
  def computed_attributes
    jqgrid_children_index('in_context_class_computed_attributes', [:id, 
      :navigation_attribute_name, 
      :computed_navigation_attribute_value_expression, 
      :navigation_attribute_index_position])
  end
  
  def computed_attributes_post_data
    jqgrid_children_post_data(SHDM::ComputedNavigationAttribute, 'in_context_class_computed_attributes')
  end
  
  #INDEX ATTRIBUTES
  def index_attributes
    jqgrid_children_index('in_context_class_index_attributes', [:id, 
      :navigation_attribute_name, 
       Proc.new {|attr| attr.index_navigation_attribute_index.first.index_name }])
  end
  
  def index_attributes_post_data
    jqgrid_children_post_data(SHDM::IndexNavigationAttribute, 'in_context_class_index_attributes')
  end
  
  def index_navigation_attribute_index_parameters
	jqgrid_children_index('index_navigation_attribute_index_parameters', [:id, 
	  :navigation_attribute_parameter_name, 
	  :navigation_attribute_parameter_value_expression])
  end
  
  def index_navigation_attribute_index_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'index_navigation_attribute_index_parameters')
  end
  
	
end
