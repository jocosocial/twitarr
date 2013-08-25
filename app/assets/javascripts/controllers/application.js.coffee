Twitarr.ApplicationController = Ember.Controller.extend
  login_user: null
  login_admin: false
  friends: []

  init: ->
    $.getJSON('user/username').done (data) =>
      if data.status is 'ok'
        @login data.user
      else
        @transitionToRoute 'announcements' if @get('currentPath') is 'posts.mine'

  logout: ->
    $.getJSON('user/logout').done (data) =>
      if data.status is 'ok'
        @set 'login_user', null
        @set 'login_admin', false
        @set 'friends', []
        @transitionToRoute 'announcements' if @get('currentPath') is 'posts.mine'

  login: (user) ->
    @set 'login_user', user.username
    @set 'login_admin', user.is_admin
    @set 'friends', user.friends

  logged_in: (->
    @get('login_user')?
  ).property('login_user')

