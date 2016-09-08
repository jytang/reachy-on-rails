class RoundsController < ApplicationController
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
      winner = params[:winner]
      han = params[:score][:han]
      fu = params[:score][:fu]

      # Who is dealer?

      # Get next round name

      # Calculate hand value

      return ret_params
    end
end
