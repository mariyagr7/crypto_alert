class AlertsController < ApplicationController
  before_action :authenticate_user!

  def create
    alert = current_user.alerts.build(alert_params)

    if alert.save
      Redis.current.sadd("active_symbols", alert.symbol)
      alert.update_column(:next_check_at, Time.current)
      AlertCheckerWorker.perform_async(alert.id)

      render json: { id: alert.id, status: "ok" }, status: :created
    else
      render json: { errors: alert.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def alert_params
    params.require(:alert).permit(
      :symbol, :direction, :threshold,
      :check_interval_seconds, :cooldown_seconds
    )
  end
end
