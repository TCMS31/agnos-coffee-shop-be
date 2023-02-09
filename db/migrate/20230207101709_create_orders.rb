class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.integer :customer_id, null: false
      t.float :total_amount, default: 0.0
      t.datetime :notification_sent_at

      t.timestamps
    end
  end
end
