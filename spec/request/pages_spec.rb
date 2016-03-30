require "rails_helper"

RSpec.describe "Pages", type: :request do
  before do
  end

  it "has a support page" do
    get "/support"
    expect(status).to eql(200)
  end

  it "has an install page" do
    get "/install"
    expect(status).to eql(200)
  end

  it "redirects to the configured privacy policy" do
    get "/privacy"
    expect(status).to eql(302)
    expect(headers["Location"])
      .to eql("https://www.example.com/privacy.html")
  end
end
