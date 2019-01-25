Twitarr.User = Ember.Object.extend
  save: ->
    post_data = { 
      display_name: @get('display_name'), 
      email: @get('email'), 
      room_number: @get('room_number'), 
      real_name: @get('real_name'),
      pronouns: @get('pronouns'),
      home_location: @get('home_location')
    }

    if @get('current_password') and @get('new_password') and @get('confirm_password')
      if @get('new_password') != @get('confirm_password')
        alert "New Password and Confirm New Password do not match!"
        return
      post_data["current_password"] = @get('current_password')
      post_data["new_password"] = @get('new_password')

    $.post("#{Twitarr.api_path}/user/profile", post_data).fail (response) -> 
      alert JSON.parse(response.responseText).status;

Twitarr.User.reopenClass
  get: ->
    $.getJSON("#{Twitarr.api_path}/user/whoami").then (data) =>
      @create(data.user)

Twitarr.UserMeta = Ember.Object.extend
  username: null
  display_name: null
  email: null
  room_number: null
  real_name: null
  pronouns: null
  home_location: null
  number_of_tweets: null
  number_of_mentions: null
  starred: null
  # TODO: this is an interesting idea, but don't have time now
#  current_location: null
#  location_timestamp: null

  star: ->
    $.getJSON("#{Twitarr.api_path}/user/profile/#{@get('username')}/star").then (data) =>
      if(data.status == 'ok')
        @set('starred', data.starred)
      else
        alert data.status

Twitarr.UserProfile = Twitarr.UserMeta.extend
  recent_tweets: []

  objectize: (->
    @set('recent_tweets', Ember.A(Twitarr.StreamPost.create(tweet)) for tweet in @get('recent_tweets'))
  ).on('init')

Twitarr.UserProfile.reopenClass
  get: (username) ->
    $.getJSON("#{Twitarr.api_path}/user/profile/#{username}").then (data) =>
      alert(data.status) unless data.status is 'ok'
      @create data.user 

Twitarr.UserNew = Ember.Object.extend
  post_data: {}

Twitarr.UserNew.reopenClass
  load: () ->
    $.getJSON("#{Twitarr.api_path}/text/welcome").then (data) =>
      @create data

  save: (registration_code, new_username, display_name, new_password) -> 
    post_data = { 
      new_username: new_username,
      display_name: display_name,
      new_password: new_password,
      registration_code: registration_code
    }

    return $.post("#{Twitarr.api_path}/user/new", post_data)

Twitarr.UserLogin = Ember.Object.extend
  username: null
  password: null

Twitarr.UserLogin.reopenClass
  login: (username, password) ->
    post_data = {
      username: username,
      password: password
    }

    return $.post("#{Twitarr.api_path}/user/auth", post_data)

Twitarr.UserForgotPassword = Ember.Object.extend
  username: null
  registration_code: null
  new_password: null
  confirm_password: null

Twitarr.UserForgotPassword.reopenClass
  resetPassword: (username, registration_code, new_password) ->
    post_data = {
      username: username,
      registration_code: registration_code,
      new_password: new_password
    }

    return $.post("#{Twitarr.api_path}/user/reset_password", post_data)