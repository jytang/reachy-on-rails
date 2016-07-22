class PlayersValidator < ActiveModel::Validator
  def validate(record)
    if not record.players.present?
      record.errors[:base] << "No players"
    elsif record.players.length != 3 and record.players.length != 4
      record.errors[:base] << "3 or 4 players only"
    elsif not record.players.all? {|p| not p.blank? }
      record.errors[:base] << "Empty player field(s)"
    elsif record.players.uniq.length != record.players.length
      record.errors[:base] << "Non-unique players"
    end
  end
end

class Game < ApplicationRecord
  validates :name, presence: true,
                   uniqueness: true,
                   length: { minimum: 1 }
  has_many :rounds, dependent: :destroy
  serialize :players, Array
  validates_with PlayersValidator

  def self.clone_last_round
    new_round = rounds.last.dup
    rounds << new_round
  end
end
