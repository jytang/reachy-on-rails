class Round < ApplicationRecord
  belongs_to :game
  serialize :scores, Hash
end
