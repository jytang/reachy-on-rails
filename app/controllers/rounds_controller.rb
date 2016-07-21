class RoundsController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @rounds = @game.rounds
  end
end
