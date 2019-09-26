Twitarr.MultiplePhotoUploadMixin = Ember.Mixin.create
  init: ->
    @_super()
    @set 'photo_ids', Ember.A()
    @set 'errors', Ember.A()

  photos: (->
    Twitarr.Photo.create({id: id}) for id in @get('photo_ids')
  ).property('photo_ids.[]')

  setupUpload: (->
    Ember.run.scheduleOnce('afterRender', @, =>
      $('#fileupload').fileupload(
        dataType: 'json'
        dropZone: $('#photo-upload-div')
        add: (e, data) =>
          if (data.files[0].size > 20000000)
            alert 'File exceeds maximum file size of 20MB'
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
        @get('photo_ids').pushObject data.photo?.id

    remove_photo: (id) ->
      @get('photo_ids').removeObject id
