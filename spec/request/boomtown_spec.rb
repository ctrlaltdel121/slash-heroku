require "rails_helper"

RSpec.describe "SlashHeroku /boomtown", type: :request do
  it "500s on /boomtown" do
    expect do
      get "/boomtown"
    end.to raise_error(CoalCar::BoomtownError)
  end
end
