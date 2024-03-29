# frozen_string_literal: true

class ForumDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(current_user = nil, page_size = Forum::PAGE_SIZE)
    ret = {
      id: id.to_s,
      subject:,
      sticky:,
      locked:,
      last_post_author: last_post_user.decorate.gui_hash,
      posts: forum_posts_count,
      timestamp: last_post_time.to_ms,
      last_post_page: 0
    }
    unless current_user.nil?
      count = post_count_since_last_visit(current_user)
      ret[:new_posts] = count if count.positive?
      ret[:last_post_page] = (forum_posts_count - count) / page_size
    end
    ret
  end

  def to_hash(current_user = nil, options = {})
    last_view = current_user ? Forum.forum_last_view(id, current_user.id) : nil

    ret = {
      id: id.to_s,
      subject:,
      sticky:,
      locked:,
      post_count: forum_posts_count,
      posts: posts_with_data.map { |x| x.decorate.to_hash(current_user, last_view, options) }
    }
    ret[:latest_read] = last_view&.to_ms unless current_user.nil?
    ret
  end

  def to_paginated_hash(page, page_size = Forum::PAGE_SIZE, current_user = nil, options = {})
    offset = page * page_size
    next_page = nil
    prev_page = nil

    next_page = page + 1 if forum_posts_count > offset + page_size
    prev_page = page - 1 unless (offset - 1).negative?
    page_count = (forum_posts_count.to_f / page_size).ceil

    last_view = current_user ? Forum.forum_last_view(id, current_user.id) : nil

    ret = {
      id: id.to_s,
      subject:,
      sticky:,
      locked:,
      next_page:,
      prev_page:,
      page:,
      page_count:,
      post_count: forum_posts_count,
      posts: posts_with_data.limit(page_size).offset(offset).map { |x| x.decorate.to_hash(current_user, last_view, options) }
    }
    ret[:latest_read] = last_view&.to_ms unless current_user.nil?
    ret
  end
end
