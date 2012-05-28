print "Loading sqlite3..."
require 'sqlite3'
print "mongo_mapper..."
require 'mongo_mapper'
puts "activerecord..."
require 'active_record'

puts "Loading Models..."
# Load all the MongoMapper models
$LOAD_PATH << "."
Dir["mongomodels/*.rb"].map{|f| require f }
Dir["activerecordmodels/*.rb"].map{|f| require f }

puts "Connecting to databases..."
# Connect to MongoDB
MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
MongoMapper.connection.drop_database("conversion")      # Wipe the database first
MongoMapper.database = "conversion"
# Connect to SQLite3
ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => "hvz.sqlite3")

# Convert each Game
ARModels::Game.all.each do |game|
    puts "Converting #{game.short_name}..."
    #TODO: worry about time zones.
    mongo_game = MongoModels::Game.create(name: game.short_name, starts: game.game_begins, ends: game.game_ends)

    # Convert all the players in that game.
    player_map = {}
    game.registrations.each do |registration|
        mongo_registration = MongoModels::Player.create({
            game: mongo_game._id,
            name: registration.person.name,
            card_code: registration.card_code,
            wants_oz: registration.wants_oz,
            is_off_campus: registration.is_off_campus,
            caseid: registration.person.caseid
        })
        player_map[registration.id] = mongo_registration._id
    end

    # Create the missions in that game.
    mission_map = {}
    game.missions.each do |mission|
        mongo_mission = MongoModels::Mission.create(start: mission.start, end: mission.end, title: mission.title, description: mission.description, storyline: mission.storyline)
        mission_map[mission.id] = mongo_mission._id
    end

    # Now all players are in the mapping, start working on the other stuff.
    game.registrations.each do |registration|
        mongo_registration = MongoModels::Player.find(player_map[registration.id])

        ##########################################################################
        # OZ REVEAL
        ##########################################################################
        if registration.is_oz
            mongo_registration.events << MongoModels::BecomeOZEvent.new({
                datetime: game.oz_reveal
            })
            mongo_registration.save!
        end

        ##########################################################################
        # TAGS
        ##########################################################################
        tag_map = {}
        # Process that player's tagged events.
        registration.taggedby.each do |tag|
            admin = ARModels::Registration.find_by_person_id_and_game_id(tag.admin_id, game.id)
            mongo_registration.events << MongoModels::TaggedByEvent.new({
                tagger: (player_map[tag.tagger_id] if tag.tagger_id),
                admin: (player_map[admin.id] if admin),
                datetime: tag.datetime
            })
            tag_map[tag.id] = mongo_registration.events.last._id
        end

        # Process that player's tags
        registration.tagged.each do |tag|
            admin = ARModels::Registration.find_by_person_id_and_game_id(tag.admin_id, game.id)
            mongo_registration.events << MongoModels::TaggedEvent.new({
                taggee: (player_map[tag.tagee_id] if tag.tagee_id),
                admin: (player_map[admin.id] if admin),
                datetime: tag.datetime
            })
            tag_map[tag.id] = mongo_registration.events.last._id
        end

        ##########################################################################
        # FEEDS
        ##########################################################################
        registration.feeds.each do |feed|
            mongo_registration.events << MongoModels::FeedEvent.new({
                tag: (tag_map[feed.tag_id] if feed.tag_id),
                mission: (mission_map[feed.mission_id] if feed.mission_id),
                datetime: feed.datetime
            })
        end

        ##########################################################################
        # ATTENDANCES
        ##########################################################################
        registration.missions.each do |attendance|
            mongo_registration.events << MongoModels::AttendanceEvent.new({
                mission: mission_map[attendance.mission_id],
                datetime: attendance.created_at
            })
        end

        ##########################################################################
        # BONUS CODES
        ##########################################################################
        registration.bonus_codes.each do |bonus_code|
            mongo_registration.events << MongoModels::BonusCodeEvent.new({
                bonus_code: MongoModels::BonusCode.new(code: bonus_code.code, points: bonus_code.points),
                datetime: bonus_code.updated_at
            })
        end

        ##########################################################################
        # CHECK INS
        ##########################################################################
        registration.check_ins.each do |check_in|
            mongo_registration.events << MongoModels::CheckInEvent.new({
                hostname: check_in.hostname,
                datetime: check_in.created_at
            })
        end

        mongo_registration.save!
    end
end

=begin
# Load the games
games = db.execute("select short_name, game_begins, game_ends, id from games;")
game_map = {}
Game.delete_all
games.each do |g|
    new = Game.create({:name => g[0], :starts => g[1], :ends => g[2]})
    game_map[g[3]] = new._id
end

# Load the players
Player.delete_all
players = db.execute("select r.id, r.game_id, p.caseid 
                     from registrations r, people p 
                     where p.id == r.person_id")
player_map = {}
players.each do |p|
  new = Player.create({:game => game_map[p[1].to_i], :caseid => p[2]})
  player_map[p[0]] = new._id
end
=end
