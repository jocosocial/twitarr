Twitarr.ForumMeta = Ember.Object.extend
  id: null
  subject: null
  posts: null
  timestamp: null

Twitarr.ForumMeta.reopenClass
  list: ->
    $.getJSON("#{Twitarr.api_path}/forums").then (data) =>
      Ember.A(@create(meta)) for meta in data.forum_meta

  page: (page) ->
    $.getJSON("#{Twitarr.api_path}/forums?page=#{page}").then (data) =>
      { forums: Ember.A(@create(meta)) for meta in data.forum_meta, next_page: data.next_page, prev_page: data.prev_page }

Twitarr.Forum = Ember.Object.extend
  id: null
  subject: null
  posts: []
  timestamp: null

  objectize: (->
    @set('posts', Ember.A(Twitarr.ForumPost.create(post)) for post in @get('posts'))
  ).on('init')

Twitarr.Forum.reopenClass
  get: (id, page = 0) ->
    $.getJSON("#{Twitarr.api_path}/forums/thread/#{id}?page=#{page}").then (data) =>
      { forum: @create(data.forum), next_page: data.forum.next_page, prev_page: data.forum.prev_page }

  new_post: (forum_id, text, photos) ->
    $.post("#{Twitarr.api_path}/forums/thread/#{forum_id}", { text: text, photos: photos }).then (data) =>
      data.forum_post = Twitarr.ForumPost.create(data.forum_post) if data.forum_post?
      data

  new_forum: (subject, text, photos) ->
    $.post("#{Twitarr.api_path}/forums", { subject: subject, text: text, photos: photos }).then (data) =>
      data.forum_meta = Twitarr.ForumMeta.create(data.forum_meta) if data.forum_meta?
      data

Twitarr.ForumPost = Ember.Object.extend
  photos: []
  reactions: []

  objectize: (->
    @set('photos', Ember.A(Twitarr.Photo.create(photo) for photo in @get('photos')))
  ).on('init')

  user_likes: (->
    @get('reactions') && @get('reactions')['like'] && @get('reactions')['like'].me
  ).property('reactions')

  likes_string: (->
    reactions = @get('reactions')
    return '' unless reactions

    likes = reactions['like']
    return '' unless likes
    
    if likes.me
      output = 'You'
      likes.count -= 1
      
      if likes.count > 0
        output += " and #{likes.count} other"
      else
        output += " like this."
        return output
    else
      output = "#{likes.count}"
    
    if likes.count > 1
      output += " seamonkeys like this."
    else
      output += " seamonkey likes this."

    return output
  ).property('reactions')

  react: (word) ->
    $.post("#{Twitarr.api_path}/forums/thread/#{@get('forum_id')}/react/#{@get('id')}/#{word}").then (data) =>
      if(data.status == 'ok')
        @set('reactions', data.reactions)
      else
        alert data.status

  unreact: (word) ->
    $.ajax("#{Twitarr.api_path}/forums/thread/#{@get('forum_id')}/react/#{@get('id')}/#{word}", method: 'DELETE').then (data) =>
      if(data.status == 'ok')
        @set('reactions', data.reactions)
      else
        alert data.status