Ember.Handlebars.helper 'pretty_message_count', (message_count, count_is_unread) ->
	'' + message_count + (if count_is_unread then ' new' else '') + (if message_count > 1 then ' messages' else ' message')
