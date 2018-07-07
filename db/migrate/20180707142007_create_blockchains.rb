class CreateBlockchains < ActiveRecord::Migration
  def up
    create_table :blockchains do |t|
      t.integer :block_pointer
      t.integer :block_number

      t.timestamps null: false
    end
    execute "ALTER TABLE `blockchains` CHANGE `id` `id` VARCHAR(10) NOT NULL;"
    add_column :currencies, :blockchain_id, :string, default: nil, after: :id, limit: 10
  end

  def down
    drop_table :blockchains
    remove_column :currencies, :blockchain_id
  end
end
