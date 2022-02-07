Twitarr.UserPictureHelper = Ember.Helper.helper((params) ->
  new Ember.Handlebars.SafeString("<img class='profile_photo' loading='lazy' src='#{Twitarr.api_path}/user/photo/#{params[0]}?bust=#{params[1]}'/>")
)

Twitarr.PrettyUsernameHelper = Ember.Helper.helper((params) ->
  pronouns = ''
  if params[2]
    pronouns = " (#{params[2]})"
  if !!params[1] && params[0] isnt params[1]
    new Ember.Handlebars.SafeString "<span title='@#{params[0]}'>#{params[1]} (@#{params[0]})#{pronouns}</span>"
  else
    '@' + params[0] + pronouns
)

Twitarr.DisplayNamePlusUsernameHelper = Ember.Helper.helper((params) ->
  if !!params[1] && params[0] isnt params[1]
    "#{params[1]} (@#{params[0]})"
  else
    '@' + params[0]
)
