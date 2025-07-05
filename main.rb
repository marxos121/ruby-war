require "io/console"
require_relative "saveable"
require_relative "card"
require_relative "players"

class War
    attr_reader :active

    include Saveable

    def initialize
        @players = []
        @at_war = []
        @card_pool = []
        @current_player = 0

        @deck = Deck.new
        @active = false
        @game_stage = "menu"
    end

    def handle_exit
        if @active
            choice = ""
            while choice != "y" && choice != "n" do
                puts "\nThe game is still in progress. Would you like to save it? [Y/n]: "
                choice = IO.console.getch
                choice.downcase!
            end

            if choice == "y"
                save
            end
        end
        exit
    end

    def print_header
        system("clear") || system("cls")

        puts "================================================================================"
        puts "================================================================================"
        puts "============================  WELCOME TO WAR  =================================="
        puts "================================================================================"
        puts "================================================================================\n\n"
    end

    def prepare
        print_header
        
        can_load = File.exist?("war_save.dat")

        if can_load
            puts "There's a saved game, you can load it by pressing L.\n"
            puts "You can also press ENTER to start a new game, or Q to quit."
        else
            puts "Press ENTER to play or Q to quit."
        end

        was_loaded = false
        loop do
            input = IO.console.getch

            case input
            when "\n", "\r"
                break
            when "l", "L"
                if can_load
                    load
                    game_loop
                    was_loaded = true
                    break
                end
            when "q", "Q"
                handle_exit
            end
        end

        return if was_loaded

        print_header

        player_count = 0
        print "\t\t\t\tWar it is then...\n\n"
        while player_count < 2 || player_count > 13 do
            print "Enter the number of players (2-13): "
            player_count = gets.chomp.to_i
        end

        print_header
        print "\t\t\t\tWar it is then..."

        @players = Array.new(player_count)
        @deck.build_deck

        cards_per_player = 52 / player_count
        for i in 0..player_count - 1 do
            puts "\n\nCreating player #{i + 1}/#{player_count}."
            player_type = ""
            while player_type != "y" && player_type != "Y" && player_type != "n" && player_type != "N" do
                print "\tFirst things first, is it a human player? [Y/n]: "
                player_type = gets.chomp
            end
            
            if player_type == "y" || player_type == "Y"
                print "\tSplendid! What's your name? "
                player_type = "human"
            else
                print "\tAlright, let's give it a name. Even a bot needs one. "
                player_type = "bot"
            end

            player_name = gets.chomp
            while @players.index{|p| p && p.name == player_name } do
                print "\tSorry, somebody's already using this name. Please, choose a different one: "
                player_name = gets.chomp
            end

            cards = @deck.take_random(count: cards_per_player)
            
            if player_type == "human"
                @players[i] = HumanPlayer.new(player_name, cards)
            else
                @players[i] = AIPlayer.new(player_name, cards)
            end
        end

        @active = true
        puts "\nIt's time to play the game!\n\n"
    end

    def play_round
        @game_stage = "round"
        reset_status
        first_stage

        if @at_war.length > 1 
            @game_stage = "war"
            reset_status
            war_stage
        end
    end

    def finish
        if File.exist?("war_save.dat")
            File.delete("war_save.dat")
        end

        puts "\n#{@players[0].name} prevails! Congratulations to the winner!\n\nPress any key to go back to the Main Menu."
        IO.console.getch
    end

    def first_stage
        @at_war = []

        puts "\n==================================\n\tCards in hand:"
        for i in 0..@players.length - 1 do
            puts " > #{@players[i].name}: #{@players[i].hand.length}"
        end
        puts "==================================\n"

        while @current_player < @players.length do
            puts "It's #{@players[@current_player].name}'s turn."
            input = @players[@current_player].get_next_card

            if input == 'q'
                handle_exit
            end

            @vals[@current_player] = input

            puts "It's #{input}!\n-----------"
            if @highest_rank < $rank_val[input.rank]
                @highest_rank = $rank_val[input.rank]
            end

            @current_player += 1
        end

        @card_pool = @vals
        for i in 0..@vals.length - 1 do
            if $rank_val[@vals[i].rank] == @highest_rank
                @at_war << i
            end
        end
    end

    def war_stage
        puts "========= It's war time! ========="
        for i in 0..@at_war.length - 2 do
            print "#{@players[@at_war[i]].name} vs. "
        end
        puts @players[@at_war[@at_war.length - 1]].name

        while @at_war.length > 1 do
            while @current_player < @at_war.length do
                player_index = @at_war[@current_player]

                puts "It's #{@players[player_index].name}'s turn."
                current_card = @players[player_index].get_next_card_fd

                if current_card == 'q'
                    handle_exit
                end

                @current_player += 1

                if !current_card
                    puts "Oh no! Player #{@players[player_index].name} is out of cards!"
                    next
                end

                @card_pool << current_card

                current_card = "q"
                while current_card == "q" do
                    current_card = @players[player_index].get_next_card
                end

                if !current_card
                    puts "Oh no! Player #{@players[player_index].name} is out of cards!"
                    next
                end

                @card_pool << current_card
                @vals[player_index] = current_card
                puts "It's #{current_card}!\n-----------"

                if @highest_rank < $rank_val[current_card.rank]
                    @highest_rank = $rank_val[current_card.rank]
                end
            end
            
            @at_war = @at_war.filter{|el| @vals[el] && ($rank_val[@vals[el].rank] == @highest_rank) }
            reset_status
        end
    end

    def reset_status
        @vals = Array.new(@players.length)
        @highest_rank = 0
        @current_player = 0
    end

    def check_state
        @card_pool.each{|card| @players[@at_war[0]].hand.unshift(card)}
        puts "\n#{@players[@at_war[0]].name} wins the battle, collecting #{@card_pool.length} cards."

        for p in @players do
            if p.hand.empty?
                puts "#{p.name} is out of cards! Game over for you!"
                @players.delete(p)
            end
        end

        if @players.length <= 1
            @active = false
        end
    end

    private
    def save_state
        {
            cards_built: Card.dump_built,
            players: @players,
            deck: @deck,
            stage: @game_stage,
            at_war: @at_war,
            current_player: @current_player,
            vals: @vals,
            highest_rank: @highest_rank
        }
    end

    private
    def load_state(state)
        @players = state[:players]
        @deck = state[:deck]
        @game_stage = state[:stage]
        @current_player = state[:current_player]
        @vals = state[:vals]
        @at_war = state[:at_war]
        @highest_rank = state[:highest_rank]
        Card.load_built(state[:cards_built])

        @active = true
        loaded_stage = @game_stage

        if @game_stage == "first_stage"
            first_stage
        end

        if @at_war.length > 1
            @game_stage = "war"
        end

        if @game_stage == "war"
            if loaded_stage == "first_stage"
                reset_status
            end
            war_stage
        end

        finish_round

        game_loop
    end
end

class Context
    def initialize(strat)
        @strategy = strat
    end

    def play 
        # Actual game loop
        while @strategy.active do
            @strategy.play_round
            @strategy.check_state
        end
    end

    def start
        while true do
            @strategy.prepare
            play
            @strategy.finish
        end
    end
end


Context.new(War.new()).start
