
class HumanPlayer
    attr_reader :hand, :name

    def initialize(name, hand)
        @name = name
        @hand = hand
    end

    def get_card_base(message)
        puts message
        loop do
            input = IO.console.getch

            case input
                when " "
                    return hand.pop
                when "\u0003", "q", "Q"
                    puts "#{name} chose to exit the game."
                    return 'q'
            end
        end
    end
    
    def get_next_card
        get_card_base "Press SPACE to reveal your next card."
    end

    def get_next_card_fd        
        get_card_base "Press SPACE to place your next card face-down."
    end

    private :get_card_base
end

class AIPlayer
    attr_reader :hand, :name

    def initialize(name, hand)
        @name = name
        @hand = hand
    end

    def get_next_card
        puts "Revealing my next card."
        @hand.pop
    end

    def get_next_card_fd
        puts "Placing a card face-down."
        @hand.pop
    end

end