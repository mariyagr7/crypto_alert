require "rails_helper"
require "sidekiq/testing"

RSpec.describe AlertsController, type: :controller do
  let(:user) { User.create!(email: "test@example.com") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
    AlertCheckerWorker.clear
  end

  describe "POST #create" do
    context "with valid params" do
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

      it "creates a new alert" do
        expect {
          post :create, params: valid_params
        }.to change { user.alerts.count }.by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("ok")

        # check Redis and worker scheduling
        alert = user.alerts.last
        expect(Redis.current.sismember("active_symbols", alert.symbol)).to be true
        # Note: testing Sidekiq enqueue
        expect(AlertCheckerWorker.jobs.size).to eq(1)
        expect(AlertCheckerWorker.jobs.last['args']).to include(alert.id)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          alert: {
            symbol: "", # missing
            direction: "sideways", # invalid
            threshold: -1
          }
        }
      end

      it "does not create an alert and returns errors" do
        expect {
          post :create, params: invalid_params
        }.not_to change { user.alerts.count }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
                                    "Symbol can't be blank",
                                    "Direction is not included in the list",
                                    "Threshold must be greater than 0"
                                  )
      end
    end
  end
end