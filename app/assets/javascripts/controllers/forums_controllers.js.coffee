Twitarr.ForumsDetailController = Twitarr.Controller.extend Twitarr.MultiplePhotoUploadMixin,
  scroll: (->
    Ember.run.scheduleOnce('afterRender', @, =>
      position = $('.scroll_to').offset()
      if(position)
        window.scrollTo(0, position.top - 80)
    )
  )
  
  has_new_posts: (->
    for post in @get('model.forum.posts')
      return true if post.timestamp > @get('model.forum.latest_read')
    false
  ).property('model.forum.posts', 'model.forum.latest_read')

  sticky: (->
    @get('model.forum.sticky')
  ).property('model.forum.sticky')

  locked: (->
    @get('model.forum.locked')
  ).property('model.forum.locked')

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

  current_page: (->
    @get('model.page')
  ).property('model.page')

  page_count: (->
    @get('model.page_count')
  ).property('model.page_count')

  can_reply: (->
    @get('logged_in') and (@get('model.next_page') is null or undefined) and (not @get('model.forum.locked') or @get('role_moderator'))
  ).property('logged_in', 'model.forum.locked', 'application.login_role')
  
  actions:
    handleKeyDown: (v,e) ->
      @send('new') if e.ctrlKey and e.keyCode == 13

    new: ->
      if @get('application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.Forum.new_post(@get('model.forum.id'), @get('model.new_post'), @get('photo_ids'), @get('model.as_mod'), @get('model.as_admin')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'model.errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'model.errors', response.responseJSON.errors
        else
          alert 'Post could not be saved! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @set 'model.new_post', ''
          @set('model.errors', Ember.A())
          @get('photo_ids').clear()
          @send 'reload'
      )        
    next_page: ->
      return if @get('model.next_page') is null or undefined
      @transitionToRoute('forums.detail', @get('model.next_page'))
    prev_page: ->
      return if @get('model.prev_page') is null or undefined
      @transitionToRoute('forums.detail', @get('model.prev_page'))
    load_page: (page) ->
      @transitionToRoute('forums.detail', page-1)
    delete_thread: ->
      if confirm('Are you sure you want to delete this thread?')
        $.ajax("#{Twitarr.api_path}/forums/#{@get('model.forum.id')}", method: 'DELETE').fail((response) =>
          if response.responseJSON?.error?
            alert response.responseJSON.error
          else
            alert 'Post could not be deleted. Please try again later. Or try again someplace without so many seamonkeys.'
        ).then((response) =>
          @transitionToRoute('forums.page', 0)
        )
    toggle_sticky: ->
      $.post("#{Twitarr.api_path}/forum/#{@get('model.forum.id')}/sticky/#{!@get('model.forum.sticky')}").fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else
          alert 'Could not toggle sticky. Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        @set('model.forum.sticky', response.sticky)
      )
    toggle_locked: ->
      $.post("#{Twitarr.api_path}/forum/#{@get('model.forum.id')}/locked/#{!@get('model.forum.locked')}").fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else
          alert 'Could not toggle locked. Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        @set('model.forum.locked', response.locked)
      )

Twitarr.ForumsPostPartialController = Twitarr.Controller.extend
  actions:
    like: ->
      @get('model').react('like').fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else
          alert 'Could not like post. Please try again later. Or try again someplace without so many seamonkeys.'
      )
    unlike: ->
      @get('model').unreact('like').fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else
          alert 'Could not unlike post. Please try again later. Or try again someplace without so many seamonkeys.'
      )
    edit: ->
      @transitionToRoute('forums.edit', @get('model.forum_id'), @get('model.id'))
    delete: ->
      self = this
      if confirm('Are you sure you want to delete this post?')
        @get('model').delete(@get('model.forum_id'), @get('model.id')).fail((response) =>
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
    @get('logged_in') and not @get('model.user_likes') and (not @get('model.thread_locked') or @get('role_moderator'))
  ).property('logged_in', 'model.user_likes')

  unlikeable: (->
    @get('logged_in') and @get('model.user_likes') and (not @get('model.thread_locked') or @get('role_moderator'))
  ).property('logged_in', 'model.user_likes')

  editable: (->
    @get('logged_in') and (@get('model.author.username') is @get('login_user') and not @get('model.thread_locked')) or @get('role_tho')
  ).property('logged_in', 'model.author.username', 'login_user', 'application.login_role')

  deleteable: (->
    @get('logged_in') and (@get('model.author.username') is @get('login_user') and not @get('model.thread_locked')) or @get('role_moderator')
  ).property('logged_in', 'model.author.username', 'login_user', 'application.login_role')

Twitarr.ForumsNewController = Twitarr.Controller.extend Twitarr.MultiplePhotoUploadMixin,
  errors: Ember.A()
  subject: null
  text: null
  photo_ids: Ember.A()
  as_mod: false,
  as_admin: false

  actions:
    handleKeyDown: (v,e) ->
      @send('new') if e.ctrlKey and e.keyCode == 13

    new: ->
      if @get('application.uploads_pending')
        alert('Please wait for uploads to finish.')
        return
      return if @get('posting')
      @set 'posting', true
      Twitarr.Forum.new_forum(@get('subject'), @get('text'), @get('photo_ids'), @get('as_mod'), @get('as_admin')).fail((response) =>
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
          @set 'errors', Ember.A()
          @get('photo_ids').clear()
          @transitionToRoute('forums.detail', response.forum.id, 0)
      )

Twitarr.ForumsPageController = Twitarr.Controller.extend
  queryParams: ['participated']
  participated: false

  has_next_page: (->
    @get('model.next_page') isnt null or undefined
  ).property('model.next_page')

  has_prev_page: (->
    @get('model.prev_page') isnt null or undefined
  ).property('model.prev_page')

  current_page: (->
    @get('model.page')
  ).property('model.page')

  page_count: (->
    @get('model.page_count')
  ).property('model.page_count')

  actions:
    next_page: ->
      return if @get('model.next_page') is null or undefined
      @transitionToRoute 'forums.page', @get('model.next_page'), {queryParams: {participated: @get('participated')}}
    prev_page: ->
      return if @get('model.prev_page') is null or undefined
      @transitionToRoute 'forums.page', @get('model.prev_page'), {queryParams: {participated: @get('participated')}}
    load_page: (page) ->
      @transitionToRoute 'forums.page', page-1, {queryParams: {participated: @get('participated')}}
    create_forum: ->
      @transitionToRoute 'forums.new'
    participated_mode: ->
      if(@get('logged_in') && !@get('participated'))
        @set('participated', true)
        @transitionToRoute('forums.page', 0, {queryParams: {participated: 'true'}})
    all_mode: ->
      if(@get('logged_in') && @get('participated'))
        @set('participated', false)
        @transitionToRoute('forums.page', 0, {queryParams: {participated: 'false'}})
    participated_help: ->
      alert('All Forums is a list of every forum that exists in Twit-arr. My Forums are forums where you have made a post.')

Twitarr.ForumsMetaPartialController = Twitarr.Controller.extend
  posts_sentence: (->
    post_word = 'post'
    post_word = 'posts' if @get('model.posts') > 1
    if @get('model.new_posts') != undefined
      "#{@get('model.posts')} #{post_word}, #{@get('model.new_posts')} <b class=\"highlight\">new</b>"
    else
      "#{@get('model.posts')} #{post_word}"
  ).property('model.posts', 'model.new_posts') 

Twitarr.ForumsPagingPartialController = Twitarr.Controller.extend
  maxPagesToDisplay: 9 # Should be odd

  currentPage: (->
    @get('model.current_page')
  ).property('model.current_page')

  pageCount: (->
    @get('model.page_count')
  ).property('model.page_count')

  pageItems: (->
    currentPage = @get('currentPage')
    pageCount = @get('pageCount')
    maxPages = @get('maxPagesToDisplay')

    pages = for pageNumber in [1..pageCount]
      excluded: false
      page: pageNumber
      current: currentPage == pageNumber-1
    
    if pages.length > maxPages
      currentPage = currentPage + 1
      currentPosition = ((maxPages - 1) / 2) + 1
      if currentPosition > currentPage
        currentPosition = currentPage
      if (pageCount - currentPage) < (maxPages - currentPosition)
        currentPosition = maxPages - (pageCount - currentPage)
      
      if (pageCount - currentPage) > (maxPages - currentPosition)
        maxDistance = maxPages - currentPosition
        overspill = pageCount - currentPage - maxDistance
        toRemove = overspill + 1
        idx = pageCount - 1 - toRemove
        pages.replace idx, toRemove, [
          excluded: true
        ]
      
      if currentPage > currentPosition
        maxDistance = currentPosition
        overspill = currentPage - currentPosition
        toRemove = overspill + 1
        idx = 1
        pages.replace idx, toRemove, [
          excluded: true
        ]

    pages
  ).property('currentPage', 'pageCount', 'maxPagesToDisplay')

Twitarr.ForumsEditController = Twitarr.Controller.extend Twitarr.MultiplePhotoUploadMixin,
  errors: Ember.A()
  photo_ids: Ember.A()

  photos: (->
    pics = @get('photo_ids')
    if pics
      Twitarr.Photo.create({id: id}) for id in pics
    else
      []
  ).property('photo_ids.[]')

  actions:
    handleKeyDown: (v,e) ->
      @send('save') if e.ctrlKey and e.keyCode == 13

    cancel: ->
      window.history.back()
    
    save: ->
      if @get('application.uploads_pending')
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
          @set('model.errors', Ember.A())
          @set 'posting', false
          window.history.back()
      )

    file_uploaded: (data) ->
      if data.photo?.id
        @get('photo_ids').pushObject(data.photo.id)

    remove_photo: (id) ->
      @get('photo_ids').removeObject(id)
