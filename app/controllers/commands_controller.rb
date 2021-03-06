class CommandsController < ApplicationController
  load_and_authorize_resource

  layout proc { |controller| controller.request.xhr? ? 'popup' : 'application' }
  # GET /commands
  # GET /commands.xml
  def index
    @commands = Command.accessible_by(current_ability).all(:conditions => { :exitstatus => nil})

    respond_to do |format|
      format.xml  { render :xml => @commands }
    end
  end

  # GET /commands/1
  # GET /commands/1.xml
  def show
    @command = Command.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @command }
    end
  end

  # PUT /commands/1
  # PUT /commands/1.xml
  def update
    @command = Command.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      if @command.update_attributes(params[:command].except(:updated_at))
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @command.errors, :status => :unprocessable_entity }
      end
    end
  end

end
