Twitarr.SeamailMeta = Ember.Object.extend
  id: null
  users: []
  message_count: 0
  subject: null
  timestamp: null
  count_is_unread: false

Twitarr.SeamailMeta.reopenClass
  list: ->
    $.getJSON("#{Twitarr.api_path}/seamail").then (data) =>
      Ember.A(@create(meta)) for meta in data.seamail_meta

Twitarr.Seamail = Ember.Object.extend
  id: null
  messages: []
  subject: null
  timestamp: null

  objectize: (->
    @set('messages', Ember.A(Twitarr.SeamailMessage.create(message)) for message in @get('messages'))
  ).on('init')

Twitarr.Seamail.reopenClass
  get: (id) ->
    $.getJSON("#{Twitarr.api_path}/seamail/#{id}").then (data) =>
      @create(data.seamail)

  new_message: (seamail_id, text) ->
    $.post("#{Twitarr.api_path}/seamail/#{seamail_id}", { text: text }).then (data) =>
      data.seamail_message = Twitarr.SeamailMessage.create(data.seamail_message) if data.seamail_message?
      data

  new_seamail: (users, subject, text) ->
    $.post("#{Twitarr.api_path}/seamail", { users: users, subject: subject, text: text }).then (data) =>
      data.seamail = Twitarr.SeamailMeta.create(data.seamail) if data.seamail?
      data

Twitarr.SeamailMessage = Ember.Object.extend
  id: null
  author: null
  text: null
  timestamp: null
