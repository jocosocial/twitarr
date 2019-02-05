Twitarr.ApplicationController = Ember.Controller.extend
  login_user: null
  login_admin: false
  alerts: false
  display_name: null
  read_only: false
  uploads_pending: 0
  photo_upload_path: "#{Twitarr.api_path}/photo"

  has_uploads_pending: (->
    @get('uploads_pending')
  ).property('uploads_pending')

  setup: (->
    $.ajax("#{Twitarr.api_path}/user/whoami", dataType: 'json', cache: false).done (data) =>
      if data.status is 'ok'
        @login data.user
        if data.need_password_change
          @transitionToRoute('user')
          alert('You need to change your password before you continue')
    # this reloads the page once per day - may solve some javascript issues
    Ember.run.later ->
      window.location.reload()
    , 1000 * 60 * 60 * 24
  ).on('init')

  actions:
    menu_toggle: ->
      @menu_toggle()

    menu_close: ->
      @menu_toggle()

    search: (text)->
      @search(text)
      $('.top-bar-search-text').val('')
      $('.top-bar-search-text').blur()

    go_to_star_feed: ->
      @transitionToRoute 'stream.star_page', Math.ceil(new Date().valueOf() + 1000)

  menu_toggle: ->
    $('#side-menu').animate { width: 'toggle' }, 100

  search: (text) ->
    text = @get('text')
    text = " " if text == undefined
    @transitionToRoute('search.results', encodeURI(text))

  login: (user) ->
    Ember.run =>
      @set 'login_user', user.username
      @set 'login_admin', user.is_admin
      @set 'display_name', user.display_name
    @tick()

  logout: ->
    Ember.run =>
      @set 'login_user', null
      @set 'login_admin', false
      @set 'display_name', null
      @set 'alerts', false
    clearTimeout(@timer)

  tick: ->
    return unless @get('logged_in')
    $.ajax("#{Twitarr.api_path}/alerts/check", dataType: 'json', cache: false).done (data) =>
      if data.status is 'ok'
        Ember.run =>
          @set('email_count', data.user_alerts.seamail_unread_count)
          @set('posts_count', data.user_alerts.unnoticed_mentions)
          @set('alerts', data.user_alerts.unnoticed_alerts)
    @timer = setTimeout (=> @tick()), 60000

  logged_in: (->
    @get('login_user')?
  ).property('login_user')

Twitarr.ApplicationController.reopenClass
  sm_photo_path: (photo) ->
    "#{Twitarr.api_path}/photo/small_thumb/#{photo}"

  md_photo_path: (photo) ->
    "#{Twitarr.api_path}/photo/medium_thumb/#{photo}"

  full_photo_path: (photo) ->
    "#{Twitarr.api_path}/photo/full/#{photo}"

Twitarr.PhotoViewController = Twitarr.ObjectController.extend
  photo_path: (->
    path = @get('model').get('constructor').toString()
    if path == 'Twitarr.User' || path == 'Twitarr.UserProfile'
      "#{Twitarr.api_path}/user/photo/#{@get('username')}?full=true"
    else
      if(@get('animated'))
        Twitarr.ApplicationController.full_photo_path(@get('id'))
      else
        Twitarr.ApplicationController.md_photo_path @get('id')
  ).property('username', 'animated', 'id')

  actions:
    open_full: ->
      path = @get('model').get('constructor').toString()
      if path == 'Twitarr.User' || path == 'Twitarr.UserProfile'
        window.open "#{Twitarr.api_path}/user/photo/#{@get('username')}?full=true"
      else
        window.open Twitarr.ApplicationController.full_photo_path(@get('id'))

Twitarr.PhotoMiniController = Twitarr.ObjectController.extend
  sm_photo_path: (->
    if(@get('animated'))
      "background: url('#{Twitarr.ApplicationController.sm_photo_path @get('id')}') no-repeat center center black;"
    else
      Twitarr.ApplicationController.sm_photo_path @get('id')
  ).property('photo')

Twitarr.AlertsController = Twitarr.ObjectController.extend
  reset_alerts: (->
    @set 'controllers.application.alerts', false
  ).on('init')

Twitarr.TagController = Twitarr.Controller.extend()

Twitarr.StarredController = Twitarr.ObjectController.extend
  actions:
    save: (user) ->
      user.save().then (response) =>
        if response.status is 'ok'
          alert 'Comment was saved.'
        else
          alert response.status

Twitarr.TimeController = Twitarr.ObjectController.extend

  server_time: (->
    @get('time')
  ).property('time')

  device_time: (->
    moment().format('MMMM Do, h:mm a')
  ).property()