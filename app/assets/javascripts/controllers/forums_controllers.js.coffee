Twitarr.ForumsDetailController = Twitarr.Controller.extend Twitarr.MultiplePhotoUploadMixin,
  has_new_posts: (->
    for post in @get('model.forum.posts')
      return true if post.timestamp > @get('model.forum.latest_read')
    false
  ).property('model.forum.posts', 'model.forum.latest_read')

  calculate_first_unread_post: (->
    for post in @get('model.forum.posts')
      if post.timestamp > @get('model.forum.latest_read')
        post.set('first_unread', true)
        return
  ).observes('model.forum.posts', 'model.forum.latest_read')

  has_next_page: (->
    @get('model.next_page') isnt null or undefined
  ).property('model.next_page')

  has_prev_page: (->
    @get('model.prev_page') isnt null or undefined
  ).property('model.prev_page')
  
  actions:
    new: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.Forum.new_post(@get('model.forum.id'), @get('model.new_post'), @get('photo_ids')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @set 'model.new_post', ''
          @get('errors').clear()
          @get('photo_ids').clear()
          @send 'reload'
      )        
    next_page: ->
      return if @get('model.next_page') is null or undefined
      @transitionToRoute('forums.detail', @get('model.next_page'))
    prev_page: ->
      return if @get('model.prev_page') is null or undefined
      @transitionToRoute('forums.detail', @get('model.prev_page'))

Twitarr.ForumsPostPartialController = Twitarr.Controller.extend
  actions:
    like: ->
      @get('model').react('like')
    unlike: ->
      @get('model').unreact('like')
    edit: ->
      @transitionToRoute('forums.edit', @get('model.forum_id'), @get('model.id'))
    page: ->
      alert @get('model.page')
    delete: ->
      self = this
      @get('model').delete(@get('forum_id'), @get('id')).fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else
          alert 'Post could not be deleted. Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        if response.thread_deleted
          @transitionToRoute('forums.page', 0)
        else
          self.get('target.target.router').refresh();
      )

  likeable: (->
    @get('logged_in') and not @get('model.user_likes')
  ).property('logged_in', 'model.user_likes')

  editable: (->
    @get('logged_in') and (@get('model.author.username') is @get('login_user') or @get('role_tho'))
  ).property('logged_in', 'model.author.username', 'login_user', 'controllers.application.login_role')

  deleteable: (->
    @get('logged_in') and (@get('model.author.username') is @get('login_user') or @get('role_moderator'))
  ).property('logged_in', 'model.author.username', 'login_user', 'controllers.application.login_role')

Twitarr.ForumsNewController = Twitarr.Controller.extend Twitarr.MultiplePhotoUploadMixin,
  actions:
    new: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.Forum.new_forum(@get('subject'), @get('text'), @get('photo_ids')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Forum could not be added. Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @set 'subject', ''
          @set 'text', ''
          @get('errors').clear()
          @get('photo_ids').clear()
          @transitionToRoute('forums.detail', response.forum.id, 0)
      )

Twitarr.ForumsPageController = Twitarr.Controller.extend
  has_next_page: (->
    @get('model.next_page') isnt null or undefined
  ).property('model.next_page')

  has_prev_page: (->
    @get('model.prev_page') isnt null or undefined
  ).property('model.prev_page')

  actions:
    next_page: ->
      return if @get('model.next_page') is null or undefined
      @transitionToRoute 'forums.page', @get('model.next_page')
    prev_page: ->
      return if @get('model.prev_page') is null or undefined
      @transitionToRoute 'forums.page', @get('model.prev_page')
    create_forum: ->
      @transitionToRoute 'forums.new'

Twitarr.ForumsMetaPartialController = Twitarr.Controller.extend
  posts_sentence: (->
    post_word = 'post'
    post_word = 'posts' if @get('model.posts') > 1
    if @get('model.new_posts') != undefined
      "#{@get('model.posts')} #{post_word}, #{@get('model.new_posts')} <b class=\"highlight\">new</b>"
    else
      "#{@get('model.posts')} #{post_word}"
  ).property('model.posts', 'model.new_posts') 

Twitarr.ForumsEditController = Twitarr.Controller.extend
  errors: Ember.A()
  photo_ids: Ember.A()

  photos: (->
    pics = @get('photo_ids')
    if pics
      Twitarr.Photo.create({id: id}) for id in pics
    else
      []
  ).property('photo_ids.@each')

  actions:
    cancel: ->
      window.history.back()
    
    save: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.ForumPost.edit(@get('model.forum_id'), @get('model.id'), @get('model.text'), @get('photo_ids')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @get('errors').clear()
          @set 'posting', false
          window.history.back()
      )

    file_uploaded: (data) ->
      if data.photo?.id
        @get('photo_ids').pushObject(data.photo.id)

    remove_photo: (id) ->
      @get('photo_ids').removeObject(id)