Twitarr.SeamailNewView = Ember.View.extend

  keyUp: (e) ->
    switch e.keyCode
      when 40
        return @moveDown()
      when 38
        return @moveUp()
      when 27
        @get('controller').send('cancel_autocomplete')
        $('#seamail-user-autocomplete').focus()
        return false

  keyDown: (e) ->
    @get('controller').send('new') if e.ctrlKey and e.keyCode == 13

  moveUp: ->
    if $('#seamail-user-autocomplete').is(':focus')
      $('.seamail-user-autocomplete-item:last').children('a').focus()
    else if $('.seamail-user-autocomplete-anchor:first').is(':focus')
      $('#seamail-user-autocomplete').focus()
    else
      $('.seamail-user-autocomplete-anchor:focus').parent().prev().children('a').focus()
    false

  moveDown: ->
    if $('#seamail-user-autocomplete').is(':focus')
      $('.seamail-user-autocomplete-item:first').children('a').focus()
    else if $('.seamail-user-autocomplete-anchor:last').is(':focus')
      $('#seamail-user-autocomplete').focus()
    else
      $('.seamail-user-autocomplete-anchor:focus').parent().next().children('a').focus()