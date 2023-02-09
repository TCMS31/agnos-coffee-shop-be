class CreateCustomers < ActiveRecord::Migration[6.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.index %i[name email], unique: true
      t.timestamps
    end
  end
end
