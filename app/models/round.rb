class Round < ApplicationRecord
  belongs_to :game
  serialize :scores, Hash

  def name
    (wind.present? ? (wind + number.to_s) : "") +
      ((bonus.present? and bonus > 0) ? ("B" + bonus.to_s) : "") +
      ((riichi.present? and riichi > 0) ? ("R" + riichi.to_s) : "")
  end
end
