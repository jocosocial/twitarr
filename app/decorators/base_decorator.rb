class BaseDecorator < Draper::Decorator

  include Twitter::Autolink
  include CruiseMonkeyHelper

  @@emojiRE = Regexp.new('\:(buffet|die-ship|die|fez|hottub|joco|pirate|ship-front|ship|towel-monkey|tropical-drink|zombie)\:')
  @@emojiReplace = '<img src="/img/emoji/small/\1.png" class="emoji" />'
  @@emojiReplaceCM = '<cm-emoji type="\1" />'

  MAX_LIST_LIKES = 5

  def clean_text(text)
    CGI.escapeHTML(text)
  end

  def clean_text_with_cr(text, options)
    if options[:app] == 'plain'
      CGI.escapeHTML(text)
    else
      CGI.escapeHTML(text || '').gsub("\n", '<br />')
    end
  end
  
  def replace_emoji(text, options)
    if options[:app] == 'CM'
      text.gsub(@@emojiRE, @@emojiReplaceCM)
    elsif options[:app] == 'plain'
      text
    else
      text.gsub(@@emojiRE, @@emojiReplace)
    end
  end

  def twitarr_auto_linker(text, options = {})
    if options[:app] == 'CM'
      cm_auto_link text
    elsif options[:app] == 'plain'
      # plain wants us to not do any markup
      text
    else
      auto_link text, {username_url_base: "#/user/profile/"}
    end
  end

  def some_likes(username, likes)
    favs = []
    unless username.nil?
      favs << 'You' if likes.include? username
    end
    if likes.count < MAX_LIST_LIKES
      favs += likes.reject { |x| x == username }
    else
      if likes.include? username
        favs << "#{likes.count - 1} other seamonkeys"
      else
        favs << "#{likes.count} seamonkeys"
      end
    end
    return nil if favs.empty?
    favs
  end

  def all_likes(username, likes)
    favs = []
    unless username.nil?
      favs << 'You' if likes.include? username
    end
    favs += likes.reject { |x| x == username }
    return nil if favs.empty?
    favs
  end

  def reaction_summary(reactions)
    summary = {}
    reactions.each do |x|
      if summary.has_key?(x.reaction) then
        summary[x.reaction] += 1
      else
        summary[x.reaction] = 1
      end
    end
    summary
  end
end
