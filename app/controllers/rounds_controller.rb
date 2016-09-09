class RoundsController < ApplicationController
  include Reachy
  def create
    @game = Game.find(params[:game_id])
    @round = @game.rounds.create(round_params(@game))
    redirect_to game_path(@game)
  end

  def destroy
    @game = Game.find(params[:game_id])
    @round = @game.rounds.find(params[:id])
    @round.destroy
    redirect_to game_path(@game)
  end

  private
    def round_params(game)
      ret_params = { :wind => "S", :number => 1, :bonus => 2, :riichi => 3, :scores => @game.rounds.last.scores }

      # Get user input params and make round hash
      type = params[:type]
      winner = [ params[:winner] ]
      loser = params[:loser]
      han = params[:score][:han]
      fu = params[:score][:fu]
      tenpai_players = params[:tenpai_players]

      # Current round details
      old_round = @game.rounds.last
      old_wind = old_round.wind
      old_number = old_round.number
      old_bonus = old_round.bonus
      old_riichi = old_round.riichi
      old_scores = old_round.scores

      num_players = @game.players.length

      # Determine dealer
      case old_number
      when 1
        dealer = @game.players[0]
      when 2
        dealer = @game.players[1]
      when 3
        dealer = @game.players[2]
      when 4
        dealer = @game.players[3]
      end

      dealer_won = winner.include?(dealer)

      # Case-by-case on type of win
      case type
      when "tsumo"
        puts "TSUMO"
        losers = @game.players
        losers -= winner

        settlement = Reachy::Scoring::get_tsumo(dealer_won, [han.to_i, fu.to_i])

        # Calculate bonus and riichi
        total_bonus = old_bonus * Reachy::Scoring::P_BONUS
        each_bonus = total_bonus / losers.length
        total_riichi = old_riichi * Reachy::Scoring::P_RIICHI

        # Update scores using old round
        new_scores = old_scores

        w = winner[0]
        new_scores[w] += if dealer_won then settlement["nondealer"] * losers.length
                      else settlement["dealer"] + settlement["nondealer"] * (losers.length - 1) end
        new_scores[w] += total_bonus
        new_scores[w] += total_riichi

        losers.each do |l|
          new_scores[l] -= settlement[l == dealer ? "dealer" : "nondealer"]
          new_scores[l] -= each_bonus
        end

        new_wind = old_wind
        new_number = old_number
        new_bonus = old_bonus + 1
        new_riichi = 0

        # Adjust round wind and number if dealer did not win
        if not dealer_won then
          new_wind = (old_wind == "E" ? "S" : "W") if old_number == num_players
          new_number = old_number == num_players ? 1 : old_number + 1
          new_bonus = 0
        end

        # Update old round entry's scores
        old_round.update(riichi: 0, scores: new_scores)

      when "ron"
        puts "RON"
        puts loser
        puts han
        puts fu
      when "ryuukyoku"
        puts "RYUUKYOKU"
        puts tenpai_players.length
      when "noten"
      when "chombo"
        puts "CHOMBO"
        puts loser
      when "reset"
      end

      ret = { :wind => new_wind, :number => new_number, :bonus => new_bonus, :riichi => new_riichi, :scores => new_scores }
      return ret
    end
end
