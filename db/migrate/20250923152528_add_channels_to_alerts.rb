class AddChannelsToAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :alerts, :channels, :string, array: true, default: [], null: false
  end
end
