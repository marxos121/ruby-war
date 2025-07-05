$suits = {
    :club =>"♣",
    :diamond => "♦",
    :heart => "♥",
    :spade => "♠"
}

$ranks = {
    :ace => "A",
    :two => "2",
    :three => "3",
    :four => "4",
    :five => "5",
    :six  => "6",
    :seven => "7",
    :eight => "8",
    :nine  => "9",
    :ten   => "10",
    :jack  => "J",
    :queen => "Q",
    :king  => "K"
}

$rank_val = {
    :ace => 13,
    :two => 1,
    :three => 2,
    :four => 3,
    :five => 4,
    :six  => 5,
    :seven => 6,
    :eight => 7,
    :nine  => 8,
    :ten   => 9,
    :jack  => 10,
    :queen => 11,
    :king  => 12
}


class Card 
    @@built = {}
    @@loaded = false

    include Saveable

    private_class_method :new
    attr_reader :rank, :suit 

    def self.get(r, s)
        k = $ranks[r] + $suits[s]
        @@built[k] ||= new(r, s)
    end
    
    def initialize(r, s)
        @rank = r
        @suit = s
    end
    
    def key
        $ranks[@rank] + $suits[@suit]
    end

    def to_s
        key
    end

    def self.dump_built
        @@built.values.map { |card| [card.rank, card.suit] }
    end

    def self.load_built(array)
        @@built = {}
        array.each do |rank, suit|
            get(rank, suit)
        end
        @@loaded = true
    end

    private
    def save_state
        {
            built: Card.dump_built
        }
    end

    private
    def load_state(state)
        return if @@loaded

        Card.load_built(state[:built])
    end
end

class Deck
    def initialize
        @deck = []
        @shuffled = false
    end

    def build_deck
        $suits.each_key do |suit|
            $ranks.each_key do |rank|
                @deck << Card.get(rank, suit)
            end
        end
        @shuffled = false
    end

    def add_card(card)
        deck.add(card)
    end

    def shuffle
        @deck = @deck.shuffle
        @shuffled = true
    end

    def take_random(count: 1)
        shuffle unless @shuffled
        @deck.pop(count)
    end
end
