Twitarr.SeamailMeta = Ember.Object.extend
  id: null
  users: []
  message_count: 0
  subject: null
  timestamp: null
  count_is_unread: false

Twitarr.SeamailMeta.reopenClass
  list: (as_mod) ->
    $.getJSON("#{Twitarr.api_path}/seamail?as_mod=#{as_mod}").then (data) =>
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
  get: (id, as_mod) ->
    $.getJSON("#{Twitarr.api_path}/seamail/#{id}?as_mod=#{as_mod}").then (data) =>
      @create(data.seamail)

  new_message: (seamail_id, text, as_mod) ->
    $.post("#{Twitarr.api_path}/seamail/#{seamail_id}?as_mod=#{as_mod}", { text: text }).then (data) =>
      data.seamail_message = Twitarr.SeamailMessage.create(data.seamail_message) if data.seamail_message?
      data

  new_seamail: (users, subject, text, as_mod) ->
    $.post("#{Twitarr.api_path}/seamail?as_mod=#{as_mod}", { users: users, subject: subject, text: text }).then (data) =>
      data.seamail = Twitarr.Seamail.create(data.seamail) if data.seamail?
      data

Twitarr.SeamailMessage = Ember.Object.extend
  id: null
  author: null
  text: null
  timestamp: null
