class GamesController < ApplicationController
  include Reachy

  def index
    @games = Game.all
  end

  def show
    @game = Game.find(params[:id])
    @rounds = @game.rounds

    # Makes a Round object that symbolizes initial state of game
    @init_round = Round.new
    start_score = @game.players.length == 3 ? Reachy::Scoring::P_START_3 : Reachy::Scoring::P_START_4
    @init_round.scores = Hash[ @game.players.map{ |p| [p.downcase, start_score] } ]
  end

  def new
    @game = Game.new # so error validation check doesn't crash
  end

  def edit
    @game = Game.find(params[:id])
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      flash[:notice] = 'Game created.'
      redirect_to @game
    else
      render 'new'
    end
  end

  def update
    @game = Game.find(params[:id])

    if @game.update(game_params)
      redirect_to @game
    else
      render 'edit'
    end
  end

  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    redirect_to games_path
  end

  private
    def game_params
      params.require(:game).permit(:name, :players => [])
    end
end
