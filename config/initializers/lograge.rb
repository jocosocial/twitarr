#config/initializers/lograge.rb

Rails.application.configure do
    # Lograge config
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
		config.colorize_logging = false
		
		config.lograge.keep_original_rails_log = true
		config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/lograge_#{Rails.env}.log"

    config.lograge.custom_options = lambda do |event| { 
			params: event.payload[:params],
			time: Time.now.utc.round(7).iso8601(3),
			user: event.payload[:username],
			exception: event.payload[:exception], # ["ExceptionClass", "the message"]
			exception_object: event.payload[:exception_object] # the exception instance
		}
  end
end