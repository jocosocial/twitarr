class BaseDecorator < Draper::Decorator

  include Twitter::TwitterText::Autolink
  include CruiseMonkeyHelper

  EMOJI_REGEX = Regexp.new('\:(buffet|die-ship|die|fez|hottub|joco|pirate|ship-front|ship|towel-monkey|tropical-drink|zombie)\:')
  EMOJI_REPLACE = '<img src="/img/emoji/small/\1.png" class="emoji" />'.freeze
  EMOJI_REPLACE_CM = '<cm-emoji type="\1" />'.freeze

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
      text.gsub(EMOJI_REGEX, EMOJI_REPLACE_CM)
    elsif options[:app] == 'plain'
      text
    else
      text.gsub(EMOJI_REGEX, EMOJI_REPLACE)
    end
  end

  def self.reaction_summary(post_reactions, user_id)
    summary = Hash.new
    post_reactions.each do |x|
      reaction = x.reaction.name
      summary[reaction] = if summary.key?(reaction)
                            { count: summary[reaction].fetch(:count) + 1, me: ((summary[reaction].fetch(:me) == true) || x.user_id == user_id) }
                          else
                            { count: 1, me: x.user_id == user_id }
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
