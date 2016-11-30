require "rails_helper"

RSpec.describe "SlashHeroku /actions", type: :request do
  it "404s if the incoming action isn't from slack" do
    post "/actions", params: { payload: JSON.dump(token: "rando-token") }

    expect(status).to eql(404)
    response_body = JSON.parse(body)
    expect(response_body).to eql({})
  end

  it "204s the incoming action is from slack" do
    u = create_atmos
    payload = action_params.merge(
      token: "secret-slack-token",
      team: { id: u.slack_team_id, domain: "heroku" },
      user: { id: u.slack_user_id, name: "atmos" }
    )
    expect do
      post "/actions", params: { payload: JSON.dump(payload) }
    end.to change(Action, :count).by(1)

    expect(status).to eql(204)
  end
end
