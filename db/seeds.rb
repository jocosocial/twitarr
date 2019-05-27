require "open-uri"

Rails.logger.info "Using rails env #{Rails.env}"

load(Rails.root.join('db', 'seeds', "#{Rails.env.downcase}.rb"))
