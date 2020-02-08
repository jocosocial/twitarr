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
    upload_schedule: ->
      @transitionToRoute('schedule.upload')

Twitarr.ScheduleTodayController = Twitarr.ScheduleDayController.extend()

Twitarr.ScheduleMetaPartialController = Twitarr.Controller.extend
  followable: (->
    @get('logged_in') and not @get('model.following')
  ).property('logged_in', 'model.following')

  actions:
    follow: ->
      @get('model').follow()
    unfollow: ->
      @get('model').unfollow()

Twitarr.ScheduleDetailController = Twitarr.Controller.extend
  editable: (->
    @get('role_tho')
  ).property('application.login_role')

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
      window.location.replace("#{Twitarr.api_path}/event/#{@get('model.id')}/ical")

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

Twitarr.ScheduleUploadController = Twitarr.Controller.extend
  schedule_upload_url: (->
    "#{Twitarr.api_path}/user/schedule"
  ).property()

  setupUpload: (->
    Ember.run.scheduleOnce('afterRender', @, =>
      $('#scheduleupload').fileupload
        dataType: 'json'
        dropZone: $('#schedule-upload-div')
        add: (e, data) =>
          @send('start_upload')
          data.submit()
        always: =>
          @send('end_upload')
        done: (e, data) =>
          @send('file_uploaded', data.result)
        fail: (e, data) ->
          if data.jqXHR?.responseJSON?.error?
            alert data.jqXHR.responseJSON.error
          else
            alert 'An upload has failed!'
    )
  )

  actions:
    file_uploaded: (data) ->
      if data.status is 'ok'
        alert 'Upload successful!'
        @transitionToRoute('events')
    start_upload: ->
      @get('application').send('start_upload')
    end_upload: ->
      @get('application').send('end_upload')


getUsableTimeValue = -> d = new Date(); d.toISOString().replace('Z', '').replace(/:\d{2}\.\d{3}/, '')
