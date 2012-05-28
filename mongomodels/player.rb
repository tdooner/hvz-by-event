module MongoModels
  class BonusCode
    include MongoMapper::EmbeddedDocument

    key :code, String
    key :points, Integer
  end

  class Event
    include MongoMapper::EmbeddedDocument

    key :datetime, Time
  end
  class TaggedByEvent < Event
      key :tagger
      key :admin
  end
  class TaggedEvent < Event
      key :tagee
      key :admin
  end
  class FeedEvent < Event
      key :tag
      key :mission
  end
  class AttendanceEvent < Event
      key :mission
  end
  class BonusCodeEvent < Event
      one :bonus_code, :class => MongoModels::BonusCode
  end
  class CheckInEvent < Event
      key :hostname
  end
  class BecomeOZEvent < Event
  end

  class Player
    include MongoMapper::Document
    many :events, :class => MongoModels::Event

    key :name, String
    key :card_code, String, :private => true
    key :wants_oz, Boolean, :private => true
    key :is_off_campus, Boolean
    key :caseid, String
    key :game, ObjectId

    def serializable_hash(options={})
        super(:except => keys.map{|k,v| k if v.options[:private]})
    end
  end

  class Game
    include MongoMapper::Document
    many :players, :class => MongoModels::Player

    key :starts, Time
    key :ends, Time
    key :name, String
  end

  class Mission
    include MongoMapper::Document

    key :start, Time
    key :end, Time
    key :title, String
    key :storyline, String
    key :description, String
  end
end
