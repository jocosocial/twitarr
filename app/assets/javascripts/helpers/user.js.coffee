Ember.Handlebars.helper 'user_picture', (username, last_time) ->
  new Ember.Handlebars.SafeString("<img class='profile_photo' src='#{Twitarr.api_path}/user/photo/#{username}?bust=#{last_time}'/>")
  
Ember.Handlebars.helper 'pretty_username', (username, display_name) ->
  if !!display_name && username isnt display_name
    new Ember.Handlebars.SafeString "<span title='@#{username}'>#{display_name} (@#{username})</span>"
  else
    '@' + username

Ember.Handlebars.helper 'display_name_plus_username', (username, display_name) ->
  if !!display_name && username isnt display_name
    "#{display_name} (@#{username})"
  else
    '@' + username
