Twitarr.StreamViewController = Twitarr.ObjectController.extend Twitarr.SinglePhotoUploadMixin,
  parent_link_visible: true

  logged_in_visible: (->
    @get('logged_in')
  ).property('logged_in')

  actions:
    show_new_post: ->
      @set 'new_post_visible', true

    cancel: ->
      @set 'new_post_visible', false

    new: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.StreamPost.reply(@get('id'), @get('reply_text'), @get('photo_id')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          @set 'reply_text', @get('base_reply_text1')
          @set 'photo_id', null
          [p, ...] = response.stream_post['parent_chain']
          @send 'reload'
      )

Twitarr.StreamPageController = Twitarr.ObjectController.extend Twitarr.SinglePhotoUploadMixin,
  new_post_visible: false

  new_post_button_visible: (->
    @get('logged_in') and not @get('new_post_visible')
  ).property('logged_in', 'new_post_visible')

  actions:
    show_new_post: ->
      @set 'new_post_visible', true

    cancel: ->
      @set 'new_post_visible', false

    new: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.StreamPost.new_post(@get('new_post'), @get('photo_id')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          @set 'new_post', null
          @set 'photo_id', null
          @set 'new_post_visible', false
          @send 'reload'
      )

    next_page: ->
      @transitionToRoute 'stream.page', @get('next_page')

Twitarr.StreamStarPageController = Twitarr.ObjectController.extend Twitarr.SinglePhotoUploadMixin,
  actions:
    next_page: ->
      @transitionToRoute 'stream.star_page', @get('next_page')

Twitarr.StreamPostPartialController = Twitarr.ObjectController.extend
  actions:
    like: ->
      @get('model').react('like')
    unlike: ->
      @get('model').unreact('like')
    delete: ->
      @get('model').delete()
      @transitionToRoute 'stream'
    view: ->
      @transitionToRoute 'stream.view', @get('id')
    edit: ->
      @transitionToRoute 'stream.edit', @get('id')
    view_thread: ->
      @transitionToRoute 'stream.view', @get('parent_id') or @get('id')

  show_parent: (->
    @get('parentController').get('parent_link_visible') && @get('parent_chain')
  ).property('parent_chain', 'new_post_visible')

  editable: (->
    @get('logged_in') and (@get('author.username') is @get('login_user') or @get('login_admin'))
  ).property('logged_in', 'author.username', 'login_user', 'login_admin')

  unlikeable: (->
    @get('logged_in') and @get('user_likes')
  ).property('logged_in', 'user_likes')

  likeable: (->
    @get('logged_in') and not @get('user_likes')
  ).property('logged_in', 'user_likes')

  deleteable: (->
    @get('logged_in') and (@get('author.username') is @get('login_user') or @get('login_admin'))
  ).property('logged_in', 'author.username', 'login_user', 'login_admin')

Twitarr.StreamEditController = Twitarr.ObjectController.extend
  errors: Ember.A()

  photos: (->
    photo_id = @get('photo.id')
    if photo_id
      [ Twitarr.Photo.create { id: photo_id } ]
    else
      []
  ).property('photo_id')

  actions:
    save: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.StreamPost.edit(@get('id'), @get('text'), @get('photo_id')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          @transitionToRoute 'stream.view', @get('id')
      )

    file_uploaded: (data) ->
      if data.photo?.id
        @set('photo_id', data.photo.id)
        @set('photo', Twitarr.Photo.create {id: data.photo.id})

    remove_photo: ->
      @set 'photo_id', null
      @set 'photo', null