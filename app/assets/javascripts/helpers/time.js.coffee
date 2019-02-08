Twitarr.PrettyTimeHelper = Ember.Helper.helper((params) ->
  moment(params[0]).format('llll')
)

Twitarr.PrettyTimestampHelper = Ember.Helper.helper((params) ->
  new Ember.Handlebars.SafeString("<span class='timestamp' title='#{moment(params[0]).format('llll')}'>#{moment(params[0]).fromNow(true)} ago</span>")
)

Twitarr.PrettyTimestampLabeledHelper = Ember.Helper.helper((params) ->
  new Ember.Handlebars.SafeString("<span class='timestamp' title='#{moment(params[0]).format('llll')}'>#{params[1]}: #{moment(params[0]).fromNow(true)} ago</span>")
)

Twitarr.PrettyTimespanHelper = Ember.Helper.helper((params) ->
  if params[1]
    new Ember.Handlebars.SafeString("<span class='timestamp'>#{moment(params[0]).format('LT')} - #{moment(params[1]).format('LT')}</span>")
  else
    new Ember.Handlebars.SafeString("<span class='timestamp'>#{moment(params[0]).format('LT')}</span>")
)