# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'peach'

SERVER_URL = 'http://localhost:3000'
# SERVER_URL = 'https://twitarr.rylath.net'

requests = [
  proc do |http|
    response = http.request Net::HTTP::Get.new("#{SERVER_URL}/posts/all")
    Rails.logger.info "ALL: #{response.msg}"
    data = JSON.parse(response.body)
    photos = data['list'].map { |x| x['data']['photos'] }.flatten.compact!
    photos.each do |photo|
      photo_response = http.request(Net::HTTP::Get.new("#{SERVER_URL}/img/photos/sm_#{photo}"))
      Rails.logger.info "PHOTO #{photo}: #{photo_response.msg}"
    end
    1 + photos.size
  end,
  proc do |http|
    response = http.request Net::HTTP::Get.new("#{SERVER_URL}/posts/popular")
    Rails.logger.info "POPULAR: #{response.msg}"
    data = JSON.parse(response.body)
    photos = data['list'].map { |x| x['data']['photos'] }.flatten.compact!
    photos.each do |photo|
      photo_response = http.request(Net::HTTP::Get.new("https://twitarr.rylath.net/img/photos/sm_#{photo}"))
      Rails.logger.info "PHOTO #{photo}: #{photo_response.msg}"
    end
    1 + photos.size
  end,
  proc do |http|
    response = http.request Net::HTTP::Get.new("#{SERVER_URL}/user/ac?string=g")
    Rails.logger.info "AUTOCOMPLETE: #{response.msg}"
    1
  end,
  proc do |http|
    response = http.request Net::HTTP::Get.new("#{SERVER_URL}/api/v1/user/auth?username=kvort&password=foobar")
    Rails.logger.info "AUTH: #{response.msg}"
    1
  end
]

class Array
  def average
    reduce(:+) / size.to_f
  end
end

if $PROGRAM_NAME == __FILE__

  signal = false
  lock = Mutex.new
  total_count = 0
  start_time = Time.zone.now

  Rails.logger.info 'Starting requests'

  threads = 10.times.map do
    Thread.new do
      count = 0
      until signal
        Net::HTTP.start('twitarr.rylath.net', 443, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
          count += requests[Random.rand requests.size].call http
        end
      end
      lock.synchronize { total_count += count }
    end
  end

  trap('INT') do
    Rails.logger.info 'Shutting down'
    signal = true
    threads.each do |thread|
      thread.join
      Rails.logger.info 'Ended correctly'
    rescue StandardError => e
      Rails.logger.error e.inspect
    end
    end_time = Time.zone.now
    Rails.logger.info "TOTAL COUNT: #{total_count} in time: #{end_time - start_time} seconds"
    exit
  end

  sleep
end
