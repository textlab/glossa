//= require ./store
//= require_tree ./models
//= require_tree ./controllers
//= require_tree ./views
//= require_tree ./helpers
//= require_tree ./templates
//= require_tree ./routes
//= require_self

var router = Glossa.router = Glossa.Router.create({
  location: 'hash'
});

Glossa.initialize(router);

