Twitarr.EventMeta = Ember.Object.extend
  id: null
  author: null
  author_display_name: null
  title: null
  location: null
  official: false
  start_time: null
  end_time: null
  following: false

  follow: ->
    $.post("#{Twitarr.api_path}/event/#{@get('id')}/favorite").then (data) =>
      if data.status is 'ok'
        @set('following', true)
      else
        alert data.error || data.errors.join("\n")

  unfollow: ->
    $.ajax("#{Twitarr.api_path}/event/#{@get('id')}/favorite", method: 'DELETE').done (data) =>
      if data.status is 'ok'
        @set('following', false)
      else
        alert data.error || data.errors.join("\n")

Twitarr.EventMeta.reopenClass
  mine: (date = new Date().toISOString().split('T')[0]) ->
    $.getJSON("#{Twitarr.api_path}/event/mine/#{date}").then (data) =>
      {events: Ember.A(@create(event)) for event in data.events, today: data.today, prev_day: data.prev_day, next_day: data.next_day }

  all: (date = new Date().toISOString().split('T')[0]) ->
    $.getJSON("#{Twitarr.api_path}/event/all/#{date}").then (data) =>
      {events: Ember.A(@create(event)) for event in data.events, today: data.today, prev_day: data.prev_day, next_day: data.next_day }

Twitarr.Event = Twitarr.EventMeta.extend
  description: null

  delete: ->
    $.ajax("#{Twitarr.api_path}/event/#{@get('id')}", method: 'DELETE', async: false, dataType: 'json', cache: false).done (data) =>
      if(!data)
        alert("Successfully deleted")
        true
      else
        alert data.status
        false

Twitarr.Event.reopenClass
  get: (event_id) ->
    $.getJSON("#{Twitarr.api_path}/event/#{event_id}").then (data) =>
      @create(data)

  get_edit: (event_id) ->
    $.getJSON("#{Twitarr.api_path}/event/#{event_id}").then (data) =>
      g = @create(data)
      # Format the time to a usable format for the front-end.
      g.start_time = moment.utc(g.start_time).local().format().slice(0, -6)
      g.end_time = moment.utc(g.end_time).local().format().slice(0, -6) if g.end_time
      g

  edit: (event_id, description, location, start_time, end_time) ->
    $.ajax("#{Twitarr.api_path}/event/#{event_id}",
      method: 'PUT',
      data: {description: description, location: location, start_time: start_time, end_time: end_time}).then (data) =>
    data.event = @create(data.event) if data.event?
    data
