require "byebug"
require "yaml"
$directions = [-1, 0, 1].repeated_permutation(2).to_a.reject { |el| el == [0,0] }


class Game
  def initialize(height = 9, width = 9, bombs = 10)
    @height = height
    @width = width
    @bombs = bombs
    @board = Board.new(@height, @width, @bombs)
  end

  # move - {pos:[x,y], move_type: :flag or :reveal}

  def play
    loop do
      render_game(@board.tiles)
      result = @board.update(get_user_move)
      if result
        reveal_all
        print_ending_message(result)
        break
      end
    end
  end

  def reveal_all
    render_game(@board.tiles, true)
  end

  def render_game(board, full_render = false)
    board.each_slice(@width) do |row|
      row.each do |tile|
        if full_render
          if tile.bomb
            print "B "
          else
            print number_render(tile)
          end
        else
          case
          when tile.flagged
            print "F "
          when !tile.revealed
            print ". "
          else
            print number_render(tile)
          end
        end
      end
      print "\n"
    end
  end

  def number_render(tile)
    if tile.number == 0
      "_ "
    else
      tile.number.to_s + " "
    end
  end

  def get_user_move
    puts "move where"
    move = {}
    move[:pos] = gets.chomp.split(",").map { |digit| digit.to_i }
    puts "what move"
    move[:move_type] = gets.chomp.downcase == "f" ? :flag : :reveal
    puts "save/load game?"
    case gets.chomp.downcase
    when "s"
      save
    end
    move
  end

  # def get_user_move
  # end

  def save
      File.open("minesweeper.yml", "w") do |f|
        f.puts @board.to_yaml
      end

  end

  def load
    return if !File.exists?("minesweeper.yml")
    @board = YAML.load_file("minesweeper.yml")
  end

  def print_ending_message(result)
    if result == :win
      puts 'YOU WIN!!!!!!'
    else
      puts 'BOOOM!!!!'
    end
  end
end

class Board
  attr_accessor :height, :width, :tiles

  def initialize(height, width, bombs)
    @height = height
    @width = width
    @bombs = bombs
    create_board
  end

  def [](pos0, pos1)
    @tiles[pos0 + pos1 * @width]
    # allows us to pass [x, y] to 1 dimentional tiles
  end

  def update(move)
    if move[:move_type] == :flag
      self[*move[:pos]].flagged = !self[*move[:pos]].flagged
      if @tiles.all? { |tile| tile.flagged == tile.bomb }
        return :win
      end
      return nil
    end
    return :lose if self[*move[:pos]].bomb
    reveal_board(move[:pos])
  end

  def legal_move?(pos)
    (0...@width).include?(pos[0]) && (0...@height).include?(pos[1])
  end

  private

  def reveal_board(pos)
    queue = [self[*pos]]
    until queue.empty?
      current_tile = queue.shift
      next if current_tile.number > 0
      $directions.each do |direction|
        new_pos = [current_tile.pos[0] + direction[0], current_tile.pos[1] + direction[1]]
        next if !legal_move?(new_pos)
        new_tile = self[*new_pos]
        if !new_tile.revealed
          new_tile.revealed = true
          queue << new_tile
        end
      end
    end
    nil
  end

  def create_board
    @tiles = []
    (0...@height * @width).each { |i| @tiles << Tile.new(i, self) }
    (0...@tiles.length).to_a.shuffle[0...@bombs].each do |bomb_loc|
      @tiles[bomb_loc].bomb = true
    end
    @tiles.each do |loc|
      loc.create_number
    end
  end
end

class Tile
  attr_accessor :bomb, :revealed, :pos, :number, :flagged

  def initialize(location, board)
    @bomb = false
    @revealed = false
    @flagged = false
    @board = board
    @location = location
    @pos = [location % @board.width, location / @board.width]
  end

  def create_number
    #create number based on how many bombs
    @number = $directions.count do |direction| # summing up num of bombs
      new_pos = [pos[0] + direction[0], pos[1] + direction[1]]
      @board.legal_move?(new_pos) ? @board[*new_pos].bomb : false
    end
  end

  def reveal
    @revealed = true
  end
end
