define(["player_view"], function() {
  return Backbone.View.extend({
    className: "div",
    template: _.template($("#player-template").html()),
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));
      return this;
    }
  });
});
