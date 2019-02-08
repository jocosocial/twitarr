Twitarr.PrettyMessageCountHelper = Ember.Helper.helper((params) ->
	'' + params[0] + (if params[1] then ' new' else '') + (if params[0] > 1 then ' messages' else ' message')
)
