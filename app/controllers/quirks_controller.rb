class QuirksController < ApplicationController
  load_and_authorize_resource
  
  # GET /quirks
  # GET /quirks.xml
  def index
    @search = Quirk.accessible_by(current_ability).public.search(params[:search])
    @quirks = @search.find(:all, :order => 'name')
    if request.xhr?
      render :partial => 'listing'
    else
       respond_to do |format|
         format.html # index.html.erb
         format.xml  { render :xml => @quirks }
         format.json { render :json => @quirks}
       end
     end
  end

  # GET /quirks/1
  # GET /quirks/1.xml
  def show
    @quirk = Quirk.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quirk }
    end
  end

  # GET /quirks/new
  # GET /quirks/new.xml
  def new
    @quirk = Quirk.new()

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quirk }
    end
  end

  # GET /quirks/1/edit
  def edit
    @quirk = Quirk.accessible_by(current_ability).find(params[:id], :include => [:servers])
  end

  # POST /quirks
  # POST /quirks.xml
  def create
    @quirk = Quirk.accessible_by(current_ability).new(params[:quirk])

    respond_to do |format|
      if @quirk.save
        flash[:notice] = 'Quirk was successfully created.'
        format.html { redirect_to(@quirk) }
        format.xml  { render :xml => @quirk, :status => :created, :location => @quirk }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quirk.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quirks/1
  # PUT /quirks/1.xml
  def update
    @quirk = Quirk.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      if @quirk.update_attributes(params[:quirk])
        flash[:notice] = 'Quirk was successfully updated.'
        format.html { redirect_to(@quirk) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quirk.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quirks/1
  # DELETE /quirks/1.xml
  def destroy
    @quirk = Quirk.accessible_by(current_ability).find(params[:id])
    @quirk.destroy

    respond_to do |format|
      format.html { redirect_to(quirks_url) }
      format.xml  { head :ok }
    end
  end
end
