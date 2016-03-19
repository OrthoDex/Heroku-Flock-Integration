require "rails_helper"

class ChatOpsFakeModel
  include ChatOpsPatterns

  def initialize(string)
    @info   = chat_deployment_request(string)
    @string = string
  end

  def matches
    @matches ||= @info.deploy_pattern.match(@string)
  end

  def valid?
    matches
  end
end

RSpec.describe ChatOpsPatterns, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  it "has a deploy:info command" do
    expect(ChatOpsFakeModel.new("ping")).to_not be_valid
    expect(ChatOpsFakeModel.new("image me pugs")).to_not be_valid
  end

  it "handles simple deployment" do
    model = ChatOpsFakeModel.new("deploy hubot")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to be_nil
    expect(model.matches[5]).to be_nil
    expect(model.matches[6]).to be_nil
    expect(model.matches[7]).to be_nil
  end

  it "handles ! operations" do
    model = ChatOpsFakeModel.new("deploy! hubot")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to eql("!")
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to be_nil
    expect(model.matches[5]).to be_nil
    expect(model.matches[6]).to be_nil
    expect(model.matches[7]).to be_nil
  end

  it "handles custom tasks" do
    model = ChatOpsFakeModel.new("deploy:migrate hubot")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy:migrate")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to be_nil
    expect(model.matches[5]).to be_nil
    expect(model.matches[6]).to be_nil
    expect(model.matches[7]).to be_nil
  end

  it "handles deploying branches" do
    model = ChatOpsFakeModel.new("deploy hubot/mybranch")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to eql("mybranch")
    expect(model.matches[5]).to be_nil
    expect(model.matches[6]).to be_nil
    expect(model.matches[7]).to be_nil
  end

  it "handles deploying to environments" do
    model = ChatOpsFakeModel.new("deploy hubot to production")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to be_nil
    expect(model.matches[5]).to eql("production")
    expect(model.matches[6]).to be_nil
    expect(model.matches[7]).to be_nil
  end

  it "handles deploying to environments with hosts" do
    model = ChatOpsFakeModel.new("deploy hubot to production/fe1,fe2")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to be_nil
    expect(model.matches[5]).to eql("production")
    expect(model.matches[6]).to eql("fe1,fe2")
    expect(model.matches[7]).to be_nil
  end

  # rubocop:disable Metrics/LineLength
  it "handles deploying branches to environments with hosts" do
    model = ChatOpsFakeModel.new("deploy hubot/atmos/branch to production/fe1,fe2")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to eql("atmos/branch")
    expect(model.matches[5]).to eql("production")
    expect(model.matches[6]).to eql("fe1,fe2")
    expect(model.matches[7]).to be_nil
  end

  it "handles deploying branches to environments with hosts plus yubikeys" do
    model = ChatOpsFakeModel.new("deploy hubot/atmos/branch to production/fe1,fe2 ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to eql("atmos/branch")
    expect(model.matches[5]).to eql("production")
    expect(model.matches[6]).to eql("fe1,fe2")
    expect(model.matches[7]).to eql("ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
  end

  it "handles deploying branches to environments with hosts plus authenticator tokens" do
    model = ChatOpsFakeModel.new("deploy hubot/atmos/branch to production/fe1,fe2 123456")
    pending "nfi what's up"
    expect(model).to be_valid
    expect(model.matches[1]).to eql("deploy")
    expect(model.matches[2]).to be_nil
    expect(model.matches[3]).to eql("hubot")
    expect(model.matches[4]).to eql("atmos/branch")
    expect(model.matches[5]).to eql("production")
    expect(model.matches[6]).to eql("fe1,fe2")
    expect(model.matches[7]).to eql("123456")
  end

  it "doesn't match on malformed yubikeys" do
    model = ChatOpsFakeModel.new("deploy hubot/atmos/branch to production/fe1,fe2 burgers")
    expect(model).to_not be_valid
  end

  it "doesn't match typos" do
    model = ChatOpsFakeModel.new("deploy hubot/atmos/branch tos taging")
    expect(model).to_not be_valid
  end
  # rubocop:enable Metrics/LineLength
end
