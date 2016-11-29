class ActivitiesController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:pushnotification]

  def verifysub
    if params[:verify] == "5517775dc1f07abc29d53661f0089bb9a14070de696cf21a490c3038b4297295"
      head :no_content
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def pushnotification
      push_data = ActiveSupport::JSON.decode(request.body.read)
      user_id = push_data[0]["subscriptionId"]
      head :no_content
      update_activity(user_id)
  end

  private

  def update_activity(user_id)
    @user = User.where(id: user_id).first

    client = @user.fitbit_client
    user_tmz = @user.identity_for("fitbit").timezone
    goal = daily_goal(client)
    today = Date.today.in_time_zone(user_tmz).to_date.strftime("%Y-%m-%d")
    start_date = @user.subscription.earliest_date
    all_steps = find_steps(client, start_date, today)

    all_steps.each do |past_day|
        date = past_day["dateTime"]
        steps = past_day["value"]
        goal_met = goal_ach(goal, steps)
        @activity = Activity.find_by(entry_date: date, user_id: @user.id)

        if @activity
          @activity.steps = steps
          @activity.goal_met = goal_met
          @activity.save
        else
          # create an entry fot that date
          @user.activities.create(entry_date: date, steps: steps, goal: goal, goal_met: goal_met)
        end
    end

  end

  def find_steps(client, start_date, end_date)
    output_steps = client.activity_time_series(resource: 'steps', start_date: start_date, end_date: end_date)
    hash = JSON.parse(output_steps.to_json)
    past_steps = hash["activities-steps"]
    return past_steps
  end

  def goal_ach(goal, steps)
    if goal < steps
      goal_met = true
    else
      goal_met = false
    end
    return goal_met
  end

  def daily_goal(client)
    output_goals = client.goals('daily')
    hash = JSON.parse(output_goals.to_json)
    goal = hash["goals"]["steps"].to_f
    return goal
  end

end
