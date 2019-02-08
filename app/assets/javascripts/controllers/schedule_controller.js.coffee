Twitarr.ScheduleDayController = Twitarr.Controller.extend
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
      @transitionToRoute('schedule.day', @get('model.next_day'))
    prev_day: ->
      @transitionToRoute('schedule.day', @get('model.prev_day'))

Twitarr.ScheduleTodayController = Twitarr.ScheduleDayController.extend()

Twitarr.ScheduleMetaPartialController = Twitarr.Controller.extend
  followable: (->
    @get('logged_in') and not @get('model.following')
  ).property('logged_in', 'model.following')

  unfollowable: (->
    @get('logged_in') and @get('model.following')
  ).property('logged_in', 'model.following')

  actions:
    follow: ->
      @get('model').follow()
    unfollow: ->
      @get('model').unfollow()

Twitarr.ScheduleDetailController = Twitarr.Controller.extend
  editable: (->
    @get('role_tho')
  ).property('controllers.application.login_role')

  actions:
    follow: ->
      @get('model').follow()
    unfollow: ->
      @get('model').unfollow()
    edit: ->
      @transitionToRoute('schedule.edit', @get('model.id'))
    delete: ->
      if(confirm("Are you sure you want to delete this event?"))
        r=@get('model').delete()
        @transitionToRoute 'schedule' if r
    ical: ->
      window.location.replace("#{Twitarr.api_path}/event/#{@get('id')}/ical")

Twitarr.ScheduleEditController = Twitarr.Controller.extend
  errors: Ember.A()

  actions:
    save: ->
      return if @get('posting')
      @set 'posting', true
      Twitarr.Event.edit(@get('model.id'), @get('model.description'), @get('model.location'), @get('model.start_time'), @get('model.end_time')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Event could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          @transitionToRoute 'schedule.detail', @get('model.id')
      )

getUsableTimeValue = -> d = new Date(); d.toISOString().replace('Z', '').replace(/:\d{2}\.\d{3}/, '')