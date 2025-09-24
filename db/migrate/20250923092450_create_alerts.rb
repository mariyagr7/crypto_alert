class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts, id: :bigserial do |t|
      t.bigint :user_id
      t.string :symbol, null: false
      t.string :direction, null: false
      t.decimal :threshold, precision: 30, scale: 10, null: false
      t.integer :check_interval_seconds, null: false, default: 60
      t.integer :cooldown_seconds, null: false, default: 300
      t.datetime :last_triggered_at
      t.decimal :last_triggered_price, precision: 30, scale: 10
      t.datetime :next_check_at
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :alerts, :symbol
  end
end
