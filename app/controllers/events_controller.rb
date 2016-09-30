class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :check_private_event_users, only: [:show]
  before_action :authenticate_user!, only: [:new]
  before_action :check_user_event, only: [:edit, :destroy]

  # GET /events
  # GET /events.json
  def index
    @events = Event.where(private: false).all
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @add_user = UserEvent.new
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    @event.createdby = current_user.id
    @event.invitecode = [*('A'..'Z'),*('0'..'9')].shuffle[0,5].join

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:name, :start_date, :finish_date, :start_location, :end_location, :private)
    end

    # Checks if user owns the event to edit and destroy event
    def check_user_event
      if !current_user.present? || current_user.id != @event.createdby
        redirect_to @event, notice: 'You dont have permissions to edit this event.'
      end
    end

    # Checks if the event is private and only allow creator or people who joined to see the event
    def check_private_event_users
      if !current_user.present? || @event.private && current_user.id != @event.createdby
        if !@event.users.include?(current_user)
          redirect_to events_path, notice: 'You dont have permissions to view this event.'
        end
      end
    end
end
