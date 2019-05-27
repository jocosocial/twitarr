Twitarr.SinglePhotoUploadMixin = Ember.Mixin.create
  init: ->
    @_super()
    @set 'photo_id', null
    @set 'errors', Ember.A()

  photos: (->
    photo_id = @get('photo_id')
    if photo_id
      [ Twitarr.Photo.create { id: photo_id } ]
    else
      []
  ).property('photo_id')

  setupUpload: (->
    Ember.run.scheduleOnce('afterRender', @, =>
      $('#fileupload').fileupload(
        dataType: 'json'
        dropZone: $('#photo-upload-div')
        add: (e, data) =>
          if (data.files[0].size > 10000000)
            alert 'File exceeds maximum file size of 10MB'
            return false
          @send('start_upload')
          data.submit()
        always: =>
          @send('end_upload')
        done: (e, data) =>
          @send('file_uploaded', data.result)
        fail: (e, data) ->
          if(data.jqXHR && data.jqXHR.responseJSON && data.jqXHR.responseJSON.error)
            alert "Upload failed: #{data.jqXHR.responseJSON.error}"
          else
            alert 'An upload has failed!'
      )
      $('#photo-upload-div').click ->
        $('#fileupload').click()
    )
  )

  actions:
    file_uploaded: (data) ->
      if data.photo?.id
        @set('photo_id', data.photo.id)

    remove_photo: ->
      @set 'photo_id', null
