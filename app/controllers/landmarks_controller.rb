#require 'shdm/landmark'

class LandmarksController < ApplicationController

  # GET /landmarks
  # GET /landmarks.xml
  def index
    @landmarks = SHDM::Landmark.alpha(SHDM::landmark_position)
  end

  # GET /landmarks/1
  # GET /landmarks/1.xml
  def show
    @landmark = SHDM::Landmark.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @landmark }
    end
  end

  # GET /landmarks/new
  # GET /landmarks/new.xml
  def new
    @indexes  = SHDM::Index.find_all.map{|v| [v.index_name, v.uri]}
    @contexts = SHDM::Context.find_all.map{|v| [v.context_name, v.uri]}
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @landmark }
    end
  end

  # GET /landmarks/1/edit
  def edit
    @landmark             = SHDM::Landmark.find(params[:id])
    @indexes              = SHDM::Index.find_all.map{|v| [v.index_name, v.uri]}
    @contexts             = SHDM::Context.find_all.map{|v| [v.context_name, v.uri]}
    @navigation_attribute = @landmark.landmark_navigation_attribute.first
    @index_anchor         = @navigation_attribute.is_a?(SHDM::IndexAnchorNavigationAttribute)
    @context_anchor       = @navigation_attribute.is_a?(SHDM::ContextAnchorNavigationAttribute)
  end

  # POST /landmarks
  # POST /landmarks.xml
  def create
    landmark_type = params[:landmark].delete(:type)
    @landmark = SHDM::Landmark.create(params[:landmark])    
    if landmark_type == 'index_anchor'
      params[:index_anchor_navigation_attribute][:index_anchor_navigation_attribute_target_index] = SHDM::Index.new(params[:index_anchor_navigation_attribute][:index_anchor_navigation_attribute_target_index])
      navigation_attribute = SHDM::IndexAnchorNavigationAttribute.create(params[:index_anchor_navigation_attribute])
    else
      params[:context_anchor_navigation_attribute][:context_anchor_navigation_attribute_target_context] = SHDM::Context.new(params[:context_anchor_navigation_attribute][:context_anchor_navigation_attribute_target_context])
      navigation_attribute = SHDM::ContextAnchorNavigationAttribute.create(params[:context_anchor_navigation_attribute])
    end    
    @landmark.landmark_navigation_attribute = navigation_attribute.save
    
    respond_to do |format|
      if @landmark.save
        flash[:notice] = 'Landmark was successfully created.'
        format.html { redirect_to :action => 'edit', :id => @landmark}
        format.xml  { render :xml => @landmark, :status => :created, :location => @landmark }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @landmark.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /landmarks/1
  # PUT /landmarks/1.xml
  def update
   @landmark = SHDM::Landmark.find(params[:id])

   respond_to do |format|
     if @landmark.update_attributes(params[:landmark])
       navigation_attribute = @landmark.landmark_navigation_attribute.first

       if navigation_attribute.is_a?(SHDM::IndexAnchorNavigationAttribute)
         params[:navigation_attribute][:index_anchor_navigation_attribute_target_index] = SHDM::Index.new(params[:navigation_attribute][:index_anchor_navigation_attribute_target_index])
       elsif navigation_attribute.is_a?(SHDM::ContextAnchorNavigationAttribute)
         params[:navigation_attribute][:context_anchor_navigation_attribute_target_context] = SHDM::Context.new(params[:navigation_attribute][:context_anchor_navigation_attribute_target_context])
       end    
       
       navigation_attribute.update_attributes(params[:navigation_attribute])
       
       flash[:notice] = 'Landmark was successfully updated.'
          format.html { redirect_to(landmarks_url) }
          format.xml  { head :ok }
       else
         format.html { render :action => "edit" }
         format.xml  { render :xml => @landmark.errors, :status => :unprocessable_entity }
       end
     end
  end

  # DELETE /landmarks/1
  # DELETE /landmarks/1.xml
  def destroy
    @landmark = SHDM::Landmark.find(params[:id])
    @landmark.landmark_navigation_attribute.each{|v| v.destroy}
    @landmark.destroy

    respond_to do |format|
      format.html { redirect_to(landmarks_url) }
      format.xml  { head :ok }
    end
  end
  
  def get_resource_attributes
    attrs = params[:id] ? RDFS::Resource.find(params[:id]).attributes : {}
    attrs.each{ |k, v| attrs[k] = v.to_s }
    render :json => attrs
  end
  
  def target_index_parameters
     jqgrid_children_index('index_anchor_navigation_attribute_target_parameters', [:id, :navigation_attribute_parameter_name, :navigation_attribute_parameter_value_expression])
  end
  
  def target_index_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'index_anchor_navigation_attribute_target_parameters')
  end
  
  def target_context_parameters
     jqgrid_children_index('context_anchor_navigation_attribute_target_parameters', [:id, :navigation_attribute_parameter_name, :navigation_attribute_parameter_value_expression])
  end
  
  def target_context_parameters_post_data
    jqgrid_children_post_data(SHDM::NavigationAttributeParameter, 'context_anchor_navigation_attribute_target_parameters')
  end
   
end
