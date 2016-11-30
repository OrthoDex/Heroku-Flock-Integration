require "rails_helper"

RSpec.describe "SlashHeroku /message_actions", type: :request do
  it "404s if the incoming action isn't from slack" do
    post "/message_actions",
      params: { payload: JSON.dump(token: "rando-token") }

    expect(status).to eql(404)
    response_body = JSON.parse(body)
    expect(response_body).to eql({})
  end

  it "204s the incoming action is from slack" do
    post "/message_actions",
      params: { payload: JSON.dump(token: "secret-slack-token") }

    expect(status).to eql(204)
  end
end
