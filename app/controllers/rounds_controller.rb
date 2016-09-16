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

  def reset_last
    # Destroy current round
    @game = Game.find(params[:game_id])
    @round = @game.rounds.last
    @round.destroy

    # Reset last round's scores and riichi sticks.
    last_round = @game.rounds.last
    second_to_last = @game.rounds[-2]

    # Check if last_round is E1
    if not second_to_last then
      start_score = @game.players.length == 3 ? Reachy::Scoring::P_START_3 : Reachy::Scoring::P_START_4
      e1_scores = Hash[ @game.players.map{ |p| [p, start_score] } ]
      last_round.update(riichi: 0, scores: e1_scores)
    else
      last_round.update(riichi: second_to_last.riichi, scores: second_to_last.scores)
    end

    redirect_to game_path(@game)
  end

  private
    def round_params(game)
      # Get user input params
      type = params[:type]
      han = params[:score][:han].to_i
      fu = params[:score][:fu].to_i
      tsumo_winner = params[:tsumo_winner]
      ron_winners = params[:ron_winners]
      ron_loser = params[:ron_loser]
      tenpai_winners = params[:tenpai_winners]
      chombo_loser = params[:chombo_loser]

      # Current round details
      old_round = @game.rounds.last
      old_wind = old_round.wind
      old_number = old_round.number
      old_bonus = old_round.bonus
      old_riichi = old_round.riichi
      old_scores = old_round.scores

      # New round attributes (at first a copy)
      new_scores = old_scores
      new_wind = old_wind
      new_number = old_number
      new_bonus = old_bonus + 1
      new_riichi = old_riichi

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

      # Fix fu value if not divisible by 10 (and not chiitoitsu)
      if fu != 25 and fu % 10 != 0 then
        fu = (fu/10.0).ceil * 10;
      end

      # Case-by-case on type of win
      case type
      when "tsumo"
        puts "TSUMO"

        dealer_won = tsumo_winner == dealer
        tsumo_losers = @game.players - [ tsumo_winner ]

        settlement = Reachy::Scoring::get_tsumo(dealer_won, [han, fu])

        # Calculate bonus and riichi
        total_bonus = old_bonus * Reachy::Scoring::P_BONUS
        each_bonus = total_bonus / tsumo_losers.length
        total_riichi = old_riichi * Reachy::Scoring::P_RIICHI

        # Update scores using old round
        new_scores[tsumo_winner] += if dealer_won then settlement["nondealer"] * tsumo_losers.length
                      else settlement["dealer"] + settlement["nondealer"] * (tsumo_losers.length - 1) end
        new_scores[tsumo_winner] += total_bonus
        new_scores[tsumo_winner] += total_riichi

        tsumo_losers.each do |l|
          new_scores[l] -= settlement[l == dealer ? "dealer" : "nondealer"]
          new_scores[l] -= each_bonus
        end

        # Adjust round wind and number if dealer did not win
        if not dealer_won then
          new_wind = (old_wind == "E" ? "S" : "W") if old_number == num_players
          new_number = old_number == num_players ? 1 : old_number + 1
          new_bonus = 0
        end

        new_riichi = 0

        # Update old round entry's scores
        old_round.update(riichi: 0, scores: new_scores)

      when "ron"
        puts "RON"

        dealer_won = ron_winners.include?(dealer)

        total_bonus = old_bonus * Reachy::Scoring::P_BONUS
        total_riichi = old_riichi * Reachy::Scoring::P_RIICHI
        each_riichi = total_riichi / ron_winners.length

        # TODO: Support multiple ron hand values
        ron_winners.each do |w|
          settlement = Reachy::Scoring::get_ron(w == dealer, [han, fu])
          new_scores[w] += settlement
          new_scores[w] += each_riichi
          new_scores[w] += total_bonus

          new_scores[ron_loser] -= settlement
          new_scores[ron_loser] -= total_bonus
        end

        # Adjust round wind and number if dealer did not win
        if not dealer_won then
          new_wind = (old_wind == "E" ? "S" : "W") if old_number == num_players
          new_number = old_number == num_players ? 1 : old_number + 1
          new_bonus = 0
        end

        new_riichi = 0

        # Update old round entry's scores
        old_round.update(riichi: 0, scores: new_scores)

      when "tenpai"
        puts "TENPAI"

        # Change to next dealer if current dealer not in tenpai
        if not tenpai_winners or not tenpai_winners.include?(dealer) then
          new_wind = (old_wind == "E" ? "S" : "W") if old_number == num_players
          new_number = old_number == num_players ? 1 : old_number + 1
        end

        if tenpai_winners then
          if tenpai_winners.length < num_players
            tenpai_losers = @game.players - tenpai_winners
            total = num_players==4 ? Reachy::Scoring::P_TENPAI_4 : Reachy::Scoring::P_TENPAI_3
            paym = total / tenpai_losers.length
            recv = total / tenpai_winners.length
            tenpai_winners.each do |w|
              new_scores[w] += recv
            end
            tenpai_losers.each do |l|
              new_scores[l] -= paym
            end
            # Update old round entry's scores
            old_round.update(scores: new_scores)
          end
        end

        # Add bonus stick and keep riichi sticks

      when "chombo"
        puts "CHOMBO"

        chombo_winners = @game.players - [ chombo_loser ]
        dealer_flag = chombo_loser == dealer

        settlement = Reachy::Scoring::get_chombo(dealer_flag)
        new_scores[chombo_loser] -= if dealer_flag then settlement["nondealer"] * chombo_winners.length
                                else settlement["dealer"] + settlement["nondealer"] * (chombo_winners.length - 1) end
        chombo_winners.each do |w|
          new_scores[w] += settlement[w==dealer ? "dealer" : "nondealer"]
        end

        # Update old round entry's scores
        old_round.update(scores: new_scores)

      when "reset"
        # Nothing required, add bonus stick and keep riichi sticks
      end

      ret = { :wind => new_wind, :number => new_number, :bonus => new_bonus, :riichi => new_riichi, :scores => new_scores }
      return ret
    end
end
