class CreateTransactions < ActiveRecord::Migration[8.1]
  def up
    # Create the enum types
    execute <<-SQL
      CREATE TYPE trigger_factors AS ENUM (
        'AMOUNT_DEVIATION',
        'FREQUENCY_SPIKE',
        'NEW_MODE',
        'TIME_ANOMALY'
      );
    SQL

    execute <<-SQL
      CREATE TYPE transaction_decision AS ENUM (
        'ALLOW',
        'FLAG',
        'BLOCK'
      );
    SQL

    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.column :mode, :mode, null: false
      t.integer :risk_score, null: false
      t.column :triggered_factors, :trigger_factors, array: true, default: '{}', null: false
      t.column :decision, :transaction_decision, null: false
      t.integer :amount_deviation_score, null: false
      t.integer :frequency_deviation_score, null: false
      t.integer :mode_deviation_score, null: false
      t.integer :time_deviation_score, null: false

      t.timestamps
    end


    add_index :transactions, :created_at
    add_index :transactions, :decision
  end

  def down
    drop_table :transactions

    # Drop the enum types
    execute <<-SQL
      DROP TYPE IF EXISTS transaction_decision;
    SQL

    execute <<-SQL
      DROP TYPE IF EXISTS trigger_factors;
    SQL
  end
end
