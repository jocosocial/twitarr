# Be sure to restart your server when you modify this file.
module Twitter
  module TwitterText
    module Autolink
      # this generates a warning, but I much prefer that to setting these EVERYWHERE
      DEFAULT_OPTIONS = {
        list_class: DEFAULT_LIST_CLASS,
        username_class: DEFAULT_USERNAME_CLASS,
        hashtag_class: DEFAULT_HASHTAG_CLASS,
        cashtag_class: DEFAULT_CASHTAG_CLASS,

        username_url_base: '#/user/profile/',
        hashtag_url_base: '#/tag/',
        cashtag_url_base: '#/tag/',
        suppress_lists: true,
        suppress_no_follow: true,
        username_include_symbol: true,
        url_target: '_blank',

        invisible_tag_attrs: DEFAULT_INVISIBLE_TAG_ATTRS
      }.freeze

      # Monkey patching auto_link_entities so that it doesn't strip out emoji
      def auto_link_entities(text, entities, options = {}, &block)
        return text if entities.empty?

        # NOTE deprecate these attributes not options keys in options hash, then use html_attrs
        options = DEFAULT_OPTIONS.merge(options)
        options[:html_attrs] = extract_html_attrs_from_options!(options)
        options[:html_attrs][:rel] ||= 'nofollow' unless options[:suppress_no_follow]
        options[:html_attrs][:target] = '_blank' if options[:target_blank] == true

        Twitter::TwitterText::Rewriter.rewrite_entities(text.dup, entities) do |entity, chars|
          if entity[:url]
            link_to_url(entity, chars, options, &block)
          elsif entity[:hashtag]
            link_to_hashtag(entity, chars, options, &block)
          elsif entity[:screen_name]
            link_to_screen_name(entity, chars, options, &block)
          elsif entity[:cashtag]
            link_to_cashtag(entity, chars, options, &block)
          elsif entity[:emoji]
            entity[:emoji]
          end
        end
      end
    end
  end
end
