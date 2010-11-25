class EffectsController < ApplicationController
  
  def index
    @effects = SWUI::Effect.find_all
  end
    
  # GET /effects/1
  # GET /effects/1.xml
  def show
    @effect = SWUI::Effect.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @effect }
    end
  end

  # GET /effects/new
  # GET /effects/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @effect }
    end
  end

  # GET /effects/1/edit
  def edit
    @effect  = SWUI::Effect.find(params[:id])
  end

  # POST /effects
  # POST /effects.xml
  def create
    
    @effect = SWUI::Effect.create(params[:effect])
    
    respond_to do |format|
      if @effect.save
        flash[:notice] = 'Concrete Interface was successfully created.'
        format.html { redirect_to(effects_url) }
        format.xml  { render :xml => @effect, :status => :created, :location => @effect }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @effect.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /effects/1
  # PUT /effects/1.xml
  def update
		@effect = SWUI::Effect.find(params[:id])

    respond_to do |format|
      if @effect.update_attributes(params[:effect])
        flash[:notice] = 'Concrete Interface was successfully updated.'
        format.html { redirect_to(effects_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @effect.errors, :status => :unprocessable_entity }
      end
    end
	
  end

  # DELETE /effects/1
  # DELETE /effects/1.xml
  def destroy
    @effect = SHDM::Effect.find(params[:id])
    @effect.destroy

    respond_to do |format|
      format.html { redirect_to(effects_url) }
      format.xml  { head :ok }
    end
  end
 
end
