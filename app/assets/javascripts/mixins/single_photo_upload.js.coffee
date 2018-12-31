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

  actions:
    file_uploaded: (data) ->
      if data.files[0]?.photo
        @set('photo_id', data.files[0].photo)
      else
        alert "Error: " + data.files[0]?.status

    remove_photo: ->
      @set 'photo_id', null