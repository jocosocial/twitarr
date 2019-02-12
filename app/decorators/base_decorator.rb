class BaseDecorator < Draper::Decorator

  include Twitter::Autolink
  include CruiseMonkeyHelper

  @@emojiRE = Regexp.new('\:(buffet|die-ship|die|fez|hottub|joco|pirate|ship-front|ship|towel-monkey|tropical-drink|zombie)\:')
  @@emojiReplace = '<img src="/img/emoji/small/\1.png" class="emoji" />'
  @@emojiReplaceCM = '<cm-emoji type="\1" />'

  def format_text(text, options = {})
    twitarr_auto_linker(replace_emoji(clean_text_with_cr(text, options), options), options)
  end

  def clean_text_with_cr(text, options = {})
    if options[:app] == 'plain'
      text
    else
      CGI.escapeHTML(text || '').gsub("\n", '<br />')
    end
  end
  
  def replace_emoji(text, options = {})
    if options[:app] == 'CM'
      text.gsub(@@emojiRE, @@emojiReplaceCM)
    elsif options[:app] == 'plain'
      text
    else
      text.gsub(@@emojiRE, @@emojiReplace)
    end
  end

  def self.reaction_summary(reactions, username)
    summary = Hash.new
    reactions.each do |x|
      if summary.has_key?(x.reaction) then
        summary[x.reaction] = {count: summary[x.reaction].fetch(:count) + 1, me: ((summary[x.reaction].fetch(:me) == true) || x.username == username)}
      else
        summary[x.reaction] = {count: 1, me: x.username == username}
      end
    end
    summary
  end

  def twitarr_auto_linker(text, options = {})
    if options[:app] == 'CM'
      cm_auto_link text
    elsif options[:app] == 'plain'
      # plain wants us to not do any markup
      text
    else
      auto_link text
    end
  end

end
