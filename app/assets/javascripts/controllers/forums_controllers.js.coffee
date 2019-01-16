Twitarr.ForumsDetailController = Twitarr.ObjectController.extend Twitarr.MultiplePhotoUploadMixin,
  has_new_posts: (->
    for post in @get('forum.posts')
      return true if post.timestamp > @get('forum.latest_read')
    false
  ).property('forum.posts', 'forum.latest_read')

  calculate_first_unread_post: (->
    for post in @get('forum.posts')
      if post.timestamp > @get('forum.latest_read')
        post.set('first_unread', true)
        return
  ).observes('forum.posts', 'forum.latest_read')

  has_next_page: (->
    @get('next_page') isnt null or undefined
  ).property('next_page')

  has_prev_page: (->
    @get('prev_page') isnt null or undefined
  ).property('prev_page')

  actions:
    new: ->
      if @get('controllers.application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.Forum.new_post(@get('forum.id'), @get('new_post'), @get('photo_ids')).fail((response) =>
        @set 'posting', false
        if response.responseJSON.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @set 'new_post', ''
          @get('errors').clear()
          @get('photo_ids').clear()
          @send 'reload'
      )        
    next_page: ->
      return if @get('next_page') is null or undefined
      @transitionToRoute 'forums.detail', @get('next_page')
    prev_page: ->
      return if @get('prev_page') is null or undefined
      @transitionToRoute 'forums.detail', @get('prev_page')

Twitarr.ForumsPostPartialController = Twitarr.ObjectController.extend
  unlikeable: (->
    @get('logged_in') and @get('user_likes')
  ).property('logged_in', 'user_likes')

  likeable: (->
    @get('logged_in') and not @get('user_likes')
  ).property('logged_in', 'user_likes')

  actions:
    like: ->
      @get('model').like()
    unlike: ->
      @get('model').unlike()

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
        if response.responseJSON.errors?
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
          @transitionToRoute('forums.detail', response.forum_meta.id, 0)
      )

Twitarr.ForumsPageController = Twitarr.ObjectController.extend
  has_next_page: (->
    @get('next_page') isnt null or undefined
  ).property('next_page')

  has_prev_page: (->
    @get('prev_page') isnt null or undefined
  ).property('prev_page')

  actions:
    next_page: ->
      return if @get('next_page') is null or undefined
      @transitionToRoute 'forums.page', @get('next_page')
    prev_page: ->
      return if @get('prev_page') is null or undefined
      @transitionToRoute 'forums.page', @get('prev_page')
    create_forum: ->
      @transitionToRoute 'forums.new'

Twitarr.ForumsMetaPartialController = Twitarr.ObjectController.extend
  posts_sentence: (->
    post_word = 'post'
    post_word = 'posts' if @get('posts') > 1
    if @get('new_posts') != undefined
      "#{@get('posts')} #{post_word}, #{@get('new_posts')} <b class=\"highlight\">new</b>"
    else
      "#{@get('posts')} #{post_word}"
  ).property('posts', 'new_posts') 
