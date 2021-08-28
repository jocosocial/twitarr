# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require File.expand_path('../config/environment', __dir__)

require 'rails/test_help'
require 'mocha/setup'

class BaseTestCase < ActiveSupport::TestCase
end
