Twitarr.StreamViewController = Twitarr.Controller.extend Twitarr.SinglePhotoUploadMixin,
  parent_link_visible: true

  logged_in_visible: (->
    @get('logged_in')
  ).property('logged_in')

  actions:
    handleKeyDown: (v,e) ->
      @send('new') if e.ctrlKey and e.keyCode == 13

    show_new_post: ->
      @set 'new_post_visible', true

    cancel: ->
      @set 'new_post_visible', false

    new: ->
      if @get('application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('model.posting')
      @set 'model.posting', true
      Twitarr.StreamPost.reply(@get('model.id'), @get('model.reply_text'), @get('photo_id')).fail((response) =>
        @set 'model.posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'model.posting', false
          @set 'model.reply_text', @get('model.base_reply_text')
          @set 'photo_id', null
          [p, ...] = response.stream_post['parent_chain']
          @send 'reload'
      )

Twitarr.StreamPageController = Twitarr.Controller.extend Twitarr.SinglePhotoUploadMixin,
  new_post_visible: false

  new_post_button_visible: (->
    @get('logged_in') and not @get('new_post_visible')
  ).property('logged_in', 'new_post_visible')

  actions:
    handleKeyDown: (v,e) ->
      @send('new') if e.ctrlKey and e.keyCode == 13

    show_new_post: ->
      @set 'new_post_visible', true

    cancel: ->
      @set 'new_post_visible', false

    new: ->
      if @get('application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('model.posting')
      @set 'model.posting', true
      Twitarr.StreamPost.new_post(@get('model.new_post'), @get('photo_id')).fail((response) =>
        @set 'model.posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'model.posting', false
          @set 'model.new_post', null
          @set 'photo_id', null
          @set 'new_post_visible', false
          @send 'reload'
      )

    next_page: ->
      @transitionToRoute 'stream.page', @get('model.next_page')

Twitarr.StreamStarPageController = Twitarr.Controller.extend Twitarr.SinglePhotoUploadMixin,
  actions:
    next_page: ->
      @transitionToRoute('stream.star_page', @get('model.next_page'))

Twitarr.StreamPostPartialController = Twitarr.Controller.extend
  actions:
    like: ->
      @get('model').react('like')
    unlike: ->
      @get('model').unreact('like')
    delete: ->
      if confirm('Are you sure you want to delete this post?')
        @get('model').delete()
        @get('target.target.router').refresh()
    view: ->
      @transitionToRoute('stream.view', @get('model.id'))
    edit: ->
      @transitionToRoute('stream.edit', @get('model.id'))
    view_thread: ->
      @transitionToRoute('stream.view', @get('model.parent_id') or @get('model.id'))
    toggle_locked: ->
      @get('model').toggle_locked().then((response) =>
        @get('target.target.router').refresh()
      )

  show_parent: (->
    @get('parentController').get('parent_link_visible') && @get('parent_chain')
  ).property('parent_chain', 'new_post_visible')

  locked: (->
    @get('model.locked')
  ).property('model.locked')

  replyable: (->
    @get('logged_in') and (not @get('model.locked') or @get('role_moderator'))
  ).property('logged_in', 'application.login_role', 'model.locked')

  editable: (->
    @get('logged_in') and ((@get('model.author.username') is @get('login_user') and not @get('model.locked')) or @get('role_tho'))
  ).property('logged_in', 'model.author.username', 'login_user', 'application.login_role')

  likeable: (->
    @get('logged_in') and not @get('model.user_likes') and (not @get('model.locked') or @get('role_moderator'))
  ).property('logged_in', 'model.user_likes')

  unlikeable: (->
    @get('logged_in') and @get('model.user_likes') and (not @get('model.locked') or @get('role_moderator'))
  ).property('logged_in', 'model.user_likes')

  deleteable: (->
    @get('logged_in') and ((@get('model.author.username') is @get('login_user') and not @get('model.locked')) or @get('role_moderator'))
  ).property('logged_in', 'model.author.username', 'login_user', 'application.login_role')

Twitarr.StreamEditController = Twitarr.Controller.extend Twitarr.SinglePhotoUploadMixin,
  errors: Ember.A()

  photos: (->
    photo_id = @get('model.photo.id')
    if photo_id
      [ Twitarr.Photo.create { id: photo_id } ]
    else
      []
  ).property('model.photo_id')

  actions:
    handleKeyDown: (v,e) ->
      @send('save') if e.ctrlKey and e.keyCode == 13

    save: ->
      if @get('application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('model.posting')
      @set 'model.posting', true
      Twitarr.StreamPost.edit(@get('model.id'), @get('model.text'), @get('model.photo_id')).fail((response) =>
        @set 'model.posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'model.posting', false
          @transitionToRoute 'stream.view', @get('model.id')
      )

    file_uploaded: (data) ->
      if data.photo?.id
        @set('model.photo_id', data.photo.id)
        @set('model.photo', Twitarr.Photo.create {id: data.photo.id})

    remove_photo: ->
      @set 'model.photo_id', null
      @set 'model.photo', null
