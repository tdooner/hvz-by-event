# HvZ By Event
An experimental foray at taking CWRU HvZ Source into a schemaless environment,
segregating the state-calculation logic from the backend and moving as much as
possible to the frontend.

# Instructions
Since this is a backend/frontend, getting this whole thing going is not the
easiest. Basically, how you get this stuff working goes something like this:

## Populate MongoDB
1. Run a MongoDB server on 127.0.0.1:27017 (the default)
2. *Acquire a dump of the CaseHvZ database.* I would commit it here but it has
   about 400 people's phone numbers. Name it `hvz.sqlite3`.
3. Run convert.py. Your MongoDB database is now populated!

## Start the Backend
1. Assuming you have a sane ruby/rvm configuration, you should be able to start
   the backend by first installing reqired gems via the `bundle` command.
2. The server is `view_game.rb`. It simply serves up MongoDB models as JSON. If
   you're using anything less than Ruby 1.9.2 you're going to have a bad time.
   *Make sure it starts on port 3000!* The command is: `ruby view_game.rb -p
   3000`

## Start the Frontend
1. All you need is to view `frontend/index.html` somehow.
2. In my experience this
   is most conveniently done with Python's simple HTTP server. In the `frontend`
   directory, run `python -m SimpleHTTPServer`
3. Navigate to [http://localhost:5000](http://localhost:5000) and notice as it
   requests the AJAX JSON from [http://localhost:3000/](http://localhost:3000)
   and displays it with some Backbone magic!!

# Motivation
The primary motivation is speed. Although ActiveRecord is nice, it is not fast.
Over time, the schema for various features has encumbered the state
calculations and made even a task as important as determining "Zombie" vs.
"Human" at any point a difficult calculation.

This is unfortunate.

The secondary motivation is extensibility. With a shared database, all sites
must share the same fate. While this can be desirable, it is better to add
customizability so every schema change or difference doesn't require an altered
schema.

# Solution (?)
This conversion script is a daring expedition into a generalization of a game of
HvZ as a series of events that happen to a player. A Player record will embed
all of its events, thus providing instantaneous lookup of that player's state.
It should be possible to write frontend scripts that can assemble the event
ordering.

## Events
Events are anything that happens to a player. *All event objects happen at a
discrete time in the game, and thus have a datetime property*. It is currently
possible to not have any events -- this would indicate you attended no
missions, were never tagged, and never had to check in.

The events that currently exist:
* `TaggedByEvent` This player was tagged at _datetime_ by _tagger_. If _admin_
  is not null, that admin submitted the tag.
* `TaggedEvent` This player tagged player _tagee_ at _datetime_. If _admin_ is
  not null, that admin submitted the tag.
* `FeedEvent` This player was fed from either _tag_ or _mission_ at _datetime_.
* `AttendanceEvent` This player attended a mission, and the attendance object
  was created at _datetime_.
* `BonusCodeEvent` This player found a cache! The BonusCode object is embedded,
  which contains _code_ and _points_.
* `CheckInEvent` This player checked in at _datetime_ on _hostname_.
* `BecomeOZEvent` This player's original zombie status was revealed at
  _datetime_.

## Multiple types of events?
Maybe it's worthwhile to have different types of events, as long as they are
clearly specified beforehand. I'm thinking of this because of events like
`BecomeOZEvent`. Maybe it is worth making a class _InferredEvent_ which is
simultaneously inferred by the backend and frontend. It's late and I'm not
thinking very well right now so this is an unfiltered idea.
