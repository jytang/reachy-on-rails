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
      params.require(:round).permit(:wind, :number, :bonus, :riichi,
        {:scores => game.players })
    end
end
