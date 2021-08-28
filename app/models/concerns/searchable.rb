# frozen_string_literal: true

module Searchable
  def self.included(base)
    base.send :include, PgSearch::Model
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
  end

  module ClassMethods
    DEFAULT_SEARCH_LIMIT = 5
    def limit_criteria(criteria, params)
      limit = (params[:limit] || DEFAULT_SEARCH_LIMIT).to_i
      start = (params[:page] || 0).to_i * limit
      # Rails.logger.info "Start = #{start}"
      criteria = criteria.limit(limit)
      criteria = criteria.offset(start) if start > 0
      criteria
    end
  end
end
