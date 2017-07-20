class ServersController < ApplicationController
  load_and_authorize_resource

VALID_SORT = {
  'name' => 'servers.hostname',
  'usage' => 'servers.usage DESC'
}
  # GET /servers
  # GET /servers.xml
  def index
   #@search = Server.accessible_by(current_ability).search(params[:search]).relation
   #@servers = @search.scoped(:order => 'servers.hostname', :include => [:backup_server]).paginate(:page => params[:page], :per_page => 31)
   sortorder = VALID_SORT[params[:sort]] || VALID_SORT.first[1]
   puts "Sort order: #{sortorder}"
   @search = Server.accessible_by(current_ability).search(params[:search])
   @servers = @search.result.order(sortorder).includes([:backup_server]).page(params[:page]).per(31)

   if request.xhr?
     render :partial => 'listing'
   else
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @servers.to_xml( :include => [:backup_jobs]) }
        format.json { render :json => @servers.to_json(:include => [:backup_jobs])}
        format.csv { render :text => Server.to_csv(@servers) }
      end
    end
  end

  # GET /servers/1
  # GET /servers/1.xml
  def show
    @server = Server.accessible_by(current_ability).find(params[:id], :include => [:quirk_details => :quirk])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end

  # GET /servers/new
  # GET /servers/new.xml
  def new
    @server = Server.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @server }
    end
  end

  # GET /servers/1/edit
  def edit
    @server = Server.accessible_by(current_ability).find(params[:id])
  end

  # POST /servers
  # POST /servers.xml
  def create
    @server = Server.new(params[:server])

    respond_to do |format|
      if @server.save
        flash[:notice] = 'Server was successfully created.'
        format.html { redirect_to(@server) }
        format.xml  { render :xml => @server, :status => :created, :location => @server }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /servers/1
  # PUT /servers/1.xml
  def update
    @server = Server.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      if @server.update_attributes(params[:server])
        flash[:notice] = 'Server was successfully updated.'
        format.html { redirect_to(@server) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /servers/1
  # DELETE /servers/1.xml
  def destroy
    @server = Server.accessible_by(current_ability).find(params[:id])
    @server.destroy

    respond_to do |format|
      format.html { redirect_to(servers_url) }
      format.xml  { head :ok }
    end
  end

  JOB_STAT_SIZE_ITEMS = [ :current_size, :xfr_size, :list_size, :net_recv, :net_sent ]
  JOB_STAT_COUNT_ITEMS = [ :inodes, :n_reg, :n_dir, :n_lnk, :n_spc, :n_xfr ]
  JOB_STAT_TIMING_ITEMS = [ :time_rsync, :time_other, :time_snap ]
  JOB_STAT_ITEMS = {
    'size' => JOB_STAT_SIZE_ITEMS,
    'count' => JOB_STAT_COUNT_ITEMS,
    'timing' => JOB_STAT_TIMING_ITEMS,
  }
  def job_stats
    items = JOB_STAT_ITEMS[params[:subset]]
    #raise "Unknown subset #{params[:subset]}" unless items
    @server = Server.accessible_by(current_ability).find(params[:id], :include => [:backup_jobs => :backup_job_stats])
    stats = @server.backup_jobs.order(:updated_at).map{|j| j.backup_job_stats}.select{|s| s}
    out = []
    items.each do |i|
      elm = {}
      elm["key"] = i.to_s
      elm["values"] = []
      stats.sort { |a,b| a.created_at <=> b.created_at }.each do|s|
        time = s.created_at.to_i * 1000
        elm["values"] << [ time, s[i] ]
      end
      out << elm
    end

    respond_to do |format|
      #format.html # show.html.erb
      #format.xml  { render :xml => @server }
      format.json  { render :json => out }
    end
  end

end
