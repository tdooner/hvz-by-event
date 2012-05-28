define(["player"], function() {
  return Backbone.Model.extend({
    eventsBefore: function(time) {
      _.filter(this.get('events'), function(ev) {
        ev.datetime <= time
      });
    },
    stateAt: function(time) {
      
    },
    stateHistory: function(game) {
      human_start = 0;
      zombie_start = _.find(this.get('events'), function(ev) {
        ev._type === "MongoModels::BecomeOZEvent" || 
        ev._type === "MongoModels::TaggedByEvent"
      });
    }
  });
});
