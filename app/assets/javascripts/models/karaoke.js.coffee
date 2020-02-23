Twitarr.Karaoke = Ember.Object.extend
  letter: null
  search_artist: null
  search_song: null
  song_list: Ember.A()
  loaded: false
  metadata_types: {
    'M': 'MIDI',
    'VR': 'Reduced Vocals',
    'Bowieoke': 'All-Bowie Karaoke',
    '(No Lyrics)': 'Missing Lyrics Display',
  }
  filtered: Ember.computed('selected_letter', 'search_artist', 'search_song', ->
    letter = @get('letter')
    search_artist = @get('search_artist')
    search_song = @get('search_song')

    letter || (search_artist && search_artist.length > 2) || (search_song && search_song.length > 2)
  )
  filtered_songs: Ember.computed('song_list', 'selected_letter', 'search_artist', 'search_song', ->
    list = @get('song_list')
    letter = @get('letter')
    search_artist = @get('search_artist')
    search_song = @get('search_song')

    if letter
      if letter == '#'
        list = list.filter((artist) -> artist.artist.match(/^\d/))
      else
        list = list.filter((artist) -> artist.artist.toLowerCase().startsWith(letter.toLowerCase()))
    if search_artist && search_artist.length > 2
      list = list.filter((artist) -> artist.artist.toLowerCase().includes(search_artist.toLowerCase()))
    if search_song && search_song.length > 2
      # This is incredibly dumb but I can't figure out another way to do this in ember
      results = []
      list.forEach((artist) ->
        songs = artist.songs.filter((song) -> song.song.toLowerCase().includes(search_song.toLowerCase()))
        if songs.length > 0
          artistObj = { 'artist': artist.artist, 'songs': [] }
          songs.forEach((song) ->
            artistObj.songs.push({'song': song.song, 'metadata': song.metadata})
          )
          results.push(artistObj)
      )
      list = results
    return list
  )

  init: ->
    metadata_types = @get('metadata_types')
    song_list = Ember.A()

    $.get("/JoCoKaraokeSongCatalog.txt").then((response) =>
      response.split(/\r?\n/).forEach((line) =>
        [artist, title, metadata] = line.split('\t')
        if artist && title
          songObj = { 'song': title, metadata: metadata_types[metadata] }

          artistObj = song_list.find((x) -> x['artist'] == artist)

          if artistObj
            artistObj['songs'].push(songObj)
          else
            artistObj = { 'artist': artist, 'songs': [songObj] }
            song_list.push(artistObj)
      )
      @set('song_list', song_list)
      @set('loaded', true)
    )
