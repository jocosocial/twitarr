Twitarr.MultiplePhotoUploadMixin = Ember.Mixin.create
  init: ->
    @_super()
    @set 'photo_ids', Ember.A()
    @set 'errors', Ember.A()

  photos: (->
    Twitarr.Photo.create({id: id}) for id in @get('photo_ids')
  ).property('photo_ids.@each')

  actions:
    file_uploaded: (data) ->
      if data.photo?.id
        @get('photo_ids').pushObject data.photo?.id

    remove_photo: (id) ->
      @get('photo_ids').removeObject id