Twitarr.SeamailDetailView = Ember.View.extend
  keyDown: (e) ->
    @get('controller').send('post') if e.ctrlKey and e.keyCode == 13
