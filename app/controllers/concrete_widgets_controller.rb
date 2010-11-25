#require 'swui/concrete_widget'

class ConcreteWidgetsController < ApplicationController
  
  def index
    @concrete_widgets = ActiveRDF::Query.new.distinct(:s).where(:s,RDF::type,SWUI::ConcreteWidget).sort(SWUI::concrete_widget_name).execute
  end
    
  # GET /concrete_widgets/1
  # GET /concrete_widgets/1.xml
  def show
    @concrete_widget = SWUI::ConcreteWidget.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @concrete_widget }
    end
  end

  # GET /concrete_widgets/new
  # GET /concrete_widgets/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @concrete_widget }
    end
  end

  # GET /concrete_widgets/1/edit
  def edit
    @concrete_widget  = SWUI::ConcreteWidget.find(params[:id])
  end

  # POST /concrete_widgets
  # POST /concrete_widgets.xml
  def create
    class_name = params[:concrete_widget].delete(:type)
    
    klass      = eval(class_name)    
    @concrete_widget = klass.create(params[:concrete_widget])
    
    respond_to do |format|
      if @concrete_widget.save
        flash[:notice] = 'ConcreteWidget was successfully created.'
        format.html { redirect_to(concrete_widgets_url) }
        format.xml  { render :xml => @concrete_widget, :status => :created, :location => @concrete_widget }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @concrete_widget.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /concrete_widgets/1
  # PUT /concrete_widgets/1.xml
  def update

    concrete_widget = SWUI::ConcreteWidget.find(params[:id])
    concrete_widget.destroy
    
    class_name = params[:concrete_widget].delete(:type)

    klass      = eval(class_name)
    @concrete_widget = klass.create(concrete_widget, params[:concrete_widget])
    
    respond_to do |format|
      if @concrete_widget.save
        flash[:notice] = 'Concrete Widget was successfully updated.'
        format.html { redirect_to(concrete_widgets_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @concrete_widget.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /concrete_widgets/1
  # DELETE /concrete_widgets/1.xml
  def destroy
    @concrete_widget = SWUI::ConcreteWidget.find(params[:id])
    @concrete_widget.destroy

    respond_to do |format|
      format.html { redirect_to(concrete_widgets_url) }
      format.xml  { head :ok }
    end
  end
 
end
