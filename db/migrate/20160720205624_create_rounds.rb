class CreateRounds < ActiveRecord::Migration[5.0]
  def change
    create_table :rounds do |t|
      t.string :wind
      t.integer :number
      t.integer :bonus
      t.integer :riichi
      t.references :game, foreign_key: true
      t.text :scores

      t.timestamps
    end
  end
end
