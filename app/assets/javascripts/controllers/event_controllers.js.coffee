Twitarr.EventsDayController = Twitarr.Controller.extend
  today_text: (->
    moment(@get('model.today')).format('ddd MMM Do')
  ).property('model.today')
  next_day_text: (->
    moment(@get('model.next_day')).format('ddd >')
  ).property('model.next_day')
  prev_day_text: (->
    moment(@get('model.prev_day')).format('< ddd')
  ).property('model.prev_day')

  actions:
    next_day: ->
      @transitionToRoute('events.day', @get('model.next_day'))
    prev_day: ->
      @transitionToRoute('events.day', @get('model.prev_day'))

Twitarr.EventsTodayController = Twitarr.EventsDayController.extend()
