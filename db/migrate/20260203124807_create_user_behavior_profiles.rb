class CreateUserBehaviorProfiles < ActiveRecord::Migration[8.1]
  def up
    # Create the enum type
    execute <<-SQL
      CREATE TYPE mode AS ENUM ('UPI', 'CARD', 'NETBANKING');
    SQL

    create_table :user_behavior_profiles, id: false do |t|
      t.integer :user_id, primary_key: true, null: false
      t.decimal :average_transaction_amount, precision: 15, scale: 2
      t.decimal :max_transaction_amount_seen, precision: 15, scale: 2
      t.integer :average_number_of_transactions_per_day
      t.column :registered_payment_modes, :mode, array: true, default: '{}', null: false
      t.time :usual_transaction_start_hour
      t.time :usual_transaction_end_hour
      t.integer :total_transactions, default: 0, null: false
      t.integer :allowed_transactions, default: 0, null: false

      t.timestamps
    end

    add_foreign_key :user_behavior_profiles, :users, column: :user_id, on_delete: :cascade
    add_index :user_behavior_profiles, :user_id, unique: true
  end

  def down
    drop_table :user_behavior_profiles

    # Drop the enum type
    execute <<-SQL
      DROP TYPE IF EXISTS mode;
    SQL
  end
end
