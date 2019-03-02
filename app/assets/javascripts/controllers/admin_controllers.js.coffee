Twitarr.AdminProfileController = Twitarr.Controller.extend
  errors: Ember.A()
  roles: [
    {label: "Admin", value: "admin"},
    {label: "THO", value: "tho"},
    {label: "Moderator", value: "moderator"},
    {label: "User", value: "user"},
    {label: "Muted", value: "muted"},
    {label: "Banned", value: "banned"}
  ]

  is_banned: (->
    @get('model.role') is 'banned'
  ).property('model.role')

  is_muted: (->
    @get('model.role') is 'muted'
  ).property('model.role')

Twitarr.AdminUploadScheduleController = Twitarr.Controller.extend
  schedule_upload_url: (->
    "#{Twitarr.api_path}/admin/schedule"
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
        alert('Upload successful!')
    start_upload: ->
      @get('application').send('start_upload')
    end_upload: ->
      @get('application').send('end_upload')

AdminSectionsController = Twitarr.Controller.extend
  errors: Ember.A()
