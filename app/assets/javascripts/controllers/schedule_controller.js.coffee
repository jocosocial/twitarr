Twitarr.ScheduleDayController = Twitarr.ObjectController.extend
  today_text: (->
    moment(@get('today')).format('ddd MMM Do')
  ).property('today')
  next_day_text: (->
    moment(@get('next_day')).format('ddd >')
  ).property('next_day')
  prev_day_text: (->
    moment(@get('prev_day')).format('< ddd')
  ).property('prev_day')

  actions:
    next_day: ->
      @transitionToRoute 'schedule.day', @get('next_day')
    prev_day: ->
      @transitionToRoute 'schedule.day', @get('prev_day')

Twitarr.ScheduleTodayController = Twitarr.ScheduleDayController.extend()

Twitarr.ScheduleMetaPartialController = Twitarr.ObjectController.extend
  followable: (->
    @get('logged_in') and not @get('following')
  ).property('logged_in', 'following')

  unfollowable: (->
    @get('logged_in') and @get('following')
  ).property('logged_in', 'following')

  actions:
    follow: ->
      Ember.run =>
        @get('model').follow()
    unfollow: ->
      Ember.run =>
        @get('model').unfollow()

Twitarr.ScheduleDetailController = Twitarr.ObjectController.extend
  editable: (->
    @get('login_admin')
  ).property('login_admin')

  actions:
    follow: ->
      @get('model').follow()
    unfollow: ->
      @get('model').unfollow()
    edit: ->
      @transitionToRoute 'schedule.edit', @get('id')
    delete: ->
      if(confirm("Are you sure you want to delete this event?"))
        r=@get('model').delete()
        @transitionToRoute 'schedule' if r
    ical: ->
      window.location.replace("#{Twitarr.api_path}/event/#{@get('id')}/ical")

Twitarr.ScheduleEditController = Twitarr.ObjectController.extend
  errors: Ember.A()

  actions:
    save: ->
      return if @get('posting')
      @set 'posting', true
      Twitarr.Event.edit(@get('id'), @get('description'), @get('location'), @get('start_time'), @get('end_time')).fail((response) =>
        @set 'posting', false
        if response.responseJSON.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Event could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          @transitionToRoute 'schedule.detail', @get('id')
      )

getUsableTimeValue = -> d = new Date(); d.toISOString().replace('Z', '').replace(/:\d{2}\.\d{3}/, '')