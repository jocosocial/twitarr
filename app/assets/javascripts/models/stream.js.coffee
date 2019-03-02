Twitarr.StreamPost = Ember.Object.extend
  author: null
  display_name: null
  text: null
  timestamp: null
  photo: null
  reactions: []
  parent_chain: []
  children: Ember.A(),
  as_mod: false

  objectize: (->
    photo = @get('photo')
    if photo
      @set 'photo', Twitarr.Photo.create(photo)

    children = @get('children')
    fixed_children = Ember.A()
    for child in children
      fixed_children.push Twitarr.StreamPost.create(child)
    @set 'children', fixed_children
  ).on('init')

  user_likes: (->
    @get('reactions') && @get('reactions')['like'] && @get('reactions')['like'].me
  ).property('reactions')

  parent_id: (->
    _.first(@get('parent_chain')) or @get('id')
  ).property('parent_chain', 'id')

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
    $.post("#{Twitarr.api_path}/tweet/#{@get('id')}/react/#{word}").fail((response) =>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert 'Unable to add reaction. Please try again later.'
    ).then((response) =>
      @set('reactions', response.reactions)
    )

  unreact: (word) ->
    $.ajax("#{Twitarr.api_path}/tweet/#{@get('id')}/react/#{word}", method: 'DELETE').fail((response) =>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert 'Unable to remove reaction. Please try again later.'
    ).then((response) =>
      @set('reactions', response.reactions)
    )

  delete: ->
    $.ajax("#{Twitarr.api_path}/tweet/#{@get('id')}", method: 'DELETE').fail((response) =>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert 'Unable to delete tweet. Please try again later.'
    )
  
  toggle_locked: ->
    $.post("#{Twitarr.api_path}/tweet/#{@get('id')}/locked/#{!@get('locked')}").fail((response) =>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert 'Could not toggle locked. Please try again later. Or try again someplace without so many seamonkeys.'
    )

Twitarr.StreamPost.reopenClass
  page: (page) ->
    $.getJSON("#{Twitarr.api_path}/stream/#{page}").then (data) =>
      { posts: Ember.A(@create(post) for post in data.stream_posts), has_next_page: data.has_next_page, next_page: data.next_page }

  star_page: (page) ->
    $.getJSON("#{Twitarr.api_path}/stream/#{page}?starred=true").then (data) =>
      { posts: Ember.A(@create(post) for post in data.stream_posts), has_next_page: data.has_next_page, next_page: data.next_page }

  mentions_page: (username, page) ->
    $.getJSON("#{Twitarr.api_path}/stream/#{page}?mentions=#{username}").then (data) =>
      { posts: Ember.A(@create(post) for post in data.stream_posts), has_next_page: data.has_next_page, next_page: data.next_page }
  
  author_page: (username, page) ->
    $.getJSON("#{Twitarr.api_path}/stream/#{page}?author=#{username}").then (data) =>
      { posts: Ember.A(@create(post) for post in data.stream_posts), has_next_page: data.has_next_page, next_page: data.next_page }

  view: (post_id) ->
    $.getJSON("#{Twitarr.api_path}/thread/#{post_id}").then (data) =>
      if(data.post?)
        @create(data.post)

  get: (post_id) ->
    $.getJSON("#{Twitarr.api_path}/tweet/#{post_id}?app=plain").then (data) =>
      data.post.photo = Twitarr.Photo.create(data.post.photo) if data.post and data.post.photo
      data

  edit: (post_id, text, photo) ->
    $.post("#{Twitarr.api_path}/tweet/#{post_id}", text: text, photo: photo).then (data) =>
      data.stream_post = Twitarr.StreamPost.create(data.stream_post) if data.stream_post?
      data

  new_post: (text, photo, as_mod) ->
    $.post("#{Twitarr.api_path}/stream", text: text, photo: photo, as_mod: as_mod).then (data) =>
      data.stream_post = Twitarr.StreamPost.create(data.stream_post) if data.stream_post?
      data

  reply: (id, text, photo, as_mod) ->
    $.post("#{Twitarr.api_path}/stream", text: text, photo: photo, parent: id, as_mod: as_mod).then (data) =>
      data.stream_post = Twitarr.StreamPost.create(data.stream_post) if data.stream_post?
      data
