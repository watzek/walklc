json.extract! team, :id, :name, :private, :hexcolor, :invitecode, :created_at, :updated_at
json.url team_url(team, format: :json)