class ForumDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(user = nil)
    ret = {
        id: id.to_s,
        subject: subject,
        last_post_author: {
          username: posts.last.author,
          display_name: User.display_name_from_username(posts.last.author),
          last_photo_updated: User.last_photo_updated_from_username(posts.last.author).to_ms
        },
        posts: post_count,
        timestamp: last_post_time.to_ms,
        sticky: sticky,
        last_post_page: 0
    }
    unless user.nil?
      count = post_count_since(user.last_forum_view(id.to_s))
      ret[:new_posts] = count if count > 0
      ret[:last_post_page] = (post_count - count) / 20
    end
    ret
  end

  def to_hash(user = nil, options = {})
    if user.nil?
      {
          id: id.to_s,
          subject: subject,
          posts: posts.map { |x| x.decorate.to_hash(user, nil, options) }
      }
    else
      last_view = user.last_forum_view(id.to_s)
      {
          id: id.to_s,
          subject: subject,
          posts: posts.map { |x| x.decorate.to_hash(user.username, last_view, options) },
          latest_read: last_view.to_ms
      }
    end
  end

  def to_paginated_hash(page, limit = 10, user = nil, options = {})
    per_page = limit
    offset = page * per_page
    next_page = nil
    prev_page = nil

    next_page = page + 1 if posts.offset((page + 1) * per_page).limit(per_page).to_a.count != 0
    prev_page = page - 1 unless (offset - 1) < 0
    if user.nil?
      {
          id: id.to_s,
          subject: subject,
          posts: posts.limit(per_page).offset(offset).map { |x| x.decorate.to_hash(nil, nil, options) },
          next_page: next_page,
          prev_page: prev_page
      }
    else
      last_view = user.last_forum_view(id.to_s)
      {
          id: id.to_s,
          subject: subject,
          posts: posts.limit(per_page).offset(offset).map { |x| x.decorate.to_hash(user.username, last_view, options) },
          latest_read: last_view.to_ms,
          next_page: next_page,
          prev_page: prev_page
      }
    end
  end

end
