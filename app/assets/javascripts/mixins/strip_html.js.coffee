Twitarr.StripHtmlMixin = Ember.Mixin.create
  stripHtml: (str) ->
    if(!str || !str.length)
      return ''
    str = str.replace(/<br \/>/igm, '\n')
    str = str.replace(/<img src="\/img\/emoji\/small\/(.*)\.png" class="emoji">/igm, ':$1:')
    tmp = document.createElement("DIV");
    tmp.innerHTML = str;
    return tmp.textContent || "";