class Game < ApplicationRecord
  validates :name, presence: true,
                   uniqueness: true,
                   length: { minimum: 1 }
  has_many :rounds
  serialize :players, Array
end
