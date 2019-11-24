class ForumDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(_user = nil, _page_size = Forum::PAGE_SIZE)
    ret = {
        id: id.to_s,
        subject: subject,
        sticky: sticky,
        locked: locked,
        last_post_author: {
          username: posts.last.user.username,
          display_name: posts.last.user.display_name,
          last_photo_updated: posts.last.user.last_photo_updated.to_ms
        },
        posts: post_count,
        timestamp: last_post_time.to_ms,
        last_post_page: 0
    }
    # unless user.nil?
    #   count = post_count_since(user.last_forum_view(id.to_s))
    #   ret[:new_posts] = count if count > 0
    #   ret[:last_post_page] = (post_count - count) / page_size
    # end
    ret
  end

  def to_hash(user = nil, options = {})
    last_view = user&.last_forum_view(id.to_s)
    post_count = posts.count
    ret = {
      id: id.to_s,
      subject: subject,
      sticky: sticky,
      locked: locked,
      post_count: post_count,
      posts: posts.map { |x| x.decorate.to_hash(locked, user, last_view, options) }
    }
    ret[:latest_read] = last_view.to_ms unless user.nil?
    ret
  end

  def to_paginated_hash(page, limit = Forum::PAGE_SIZE, user = nil, options = {})
    last_view = user&.last_forum_view(id.to_s)

    per_page = limit
    offset = page * per_page
    next_page = nil
    prev_page = nil

    next_page = page + 1 if posts.offset((page + 1) * per_page).limit(per_page).to_a.count != 0
    prev_page = page - 1 unless (offset - 1) < 0
    page_count = (posts.count.to_f / per_page).ceil

    ret = {
      id: id.to_s,
      subject: subject,
      sticky: sticky,
      locked: locked,
      next_page: next_page,
      prev_page: prev_page,
      page: page,
      page_count: page_count,
      post_count: post_count,
      posts: posts.limit(per_page).offset(offset).map { |x| x.decorate.to_hash(locked, user, last_view, options) }
    }
    ret[:latest_read] = last_view.to_ms unless user.nil?
    ret
  end

end
