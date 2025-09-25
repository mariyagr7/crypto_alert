require "rails_helper"
require "sidekiq/testing"

RSpec.describe AlertsController, type: :controller do
  let(:user) { User.create!(email: "test@example.com") }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        alert: {
          symbol: "BTCUSDT",
          direction: "up",
          threshold: 65000,
          check_interval_seconds: 30,
          cooldown_seconds: 300
        }
      }
    end

    let(:invalid_params) do
      {
        alert: {
          symbol: "",
          direction: "sideways",
          threshold: -1,
          check_interval_seconds: 10,
          cooldown_seconds: 30
        }
      }
    end

    it "creates an alert with valid params" do
      expect {
        post :create, params: valid_params
      }.to change { user.alerts.count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["id"]).to eq(user.alerts.last.id)
    end

    it "returns errors with invalid params" do
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_an(Array)
    end
  end
end
