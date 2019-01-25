Twitarr.UploadView = Ember.View.extend
  templateName: 'upload'
  needs: ['application']

  didInsertElement: ->
    $('#fileupload').fileupload
      dataType: 'json'
      dropZone: $('#photo-upload-div')
      add: (e, data) =>
        if (data.files[0].size > 10000000)
          alert 'File exceeds maximum file size of 10MB'
          return false
        @get('controller').send('start_upload')
        data.submit()
      always: =>
        @get('controller').send('end_upload')
      done: (e, data) =>
        @get('controller').send('file_uploaded', data.result)
      fail: (e, data) ->
        if(data.jqXHR && data.jqXHR.responseJSON && data.jqXHR.responseJSON.error)
          alert "Upload failed: #{data.jqXHR.responseJSON.error}"
        else
          alert 'An upload has failed!'

#    $('#photo-upload-div').click ->
#      $('#fileupload').click()
