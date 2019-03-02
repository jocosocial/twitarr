require 'securerandom'

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

def create_registration_code(code)
  regcode = RegistrationCode.add_code code
  regcode.save!
  regcode
end

puts "Creating registration codes..."
RegistrationCode.delete_all
if RegistrationCode.count == 0
  # stub codes for built-in accounts
  for i in 1..3 do
    create_registration_code "code#{i}"
  end

  # if the twkeys.txt file exists, also import those codes
  keys_filename = "db/seeds/twkeys.txt"
  if File.exists?(keys_filename)
    File.foreach(keys_filename) do |line|
      create_registration_code line
   end
  end
end

unless User.exist? 'TwitarrTeam'
  puts 'Creating user TwitarrTeam'
  user = User.new username: 'TwitarrTeam', display_name: 'TwitarrTeam', password: Rails.application.secrets.initial_admin_password,
    role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code1'
  user.set_password user.password
  user.save
end

unless User.exist? 'official'
  puts 'Creating user official'
  user = User.new username: 'official', display_name: 'official', password: SecureRandom.hex,
    role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code2'
  user.set_password user.password
  user.save
end

unless User.exist? 'moderator'
  puts 'Creating user moderator'
  user = User.new username: 'moderator', display_name: 'moderator', password: Rails.application.secrets.initial_admin_password,
  role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code3'
  user.set_password user.password
  user.save
end

unless User.exist? 'official'
  raise Exception.new("No user named 'official'!  Create one first!")
end

unless User.exist? 'moderator'
  raise Exception.new("No user named 'moderator'!  Create one first!")
end

def create_event(id, title, author, start_time, end_time, description, official)
  event = Event.create(_id: id, title: title, description: description, start_time: start_time, end_time: end_time, official: official)
  unless event.valid?
    puts "Errors for event #{title}: #{event.errors.full_messages}"
    return event
  end
  event.save!
  event
end

puts 'Creating events...'
cal_filename = "db/seeds/all.ics"
if File.exists?(cal_filename)
  # fix bad encoding from sched.org
  cal_text = File.read(cal_filename)
  cal_text = cal_text.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
  if File.exists?(cal_filename + ".tmp")
    File.delete(cal_filename + ".tmp")
  end
  File.open(cal_filename + ".tmp", "w") { |file| file << cal_text }

  cal_file = File.open(cal_filename + ".tmp")
  Icalendar::Calendar.parse(cal_file).first.events.map { |x| Event.create_from_ics x }
end

def create_reaction(tag)
  reaction = Reaction.add_reaction tag
  reaction.save!
  reaction
end

puts 'Creating reactions...'
Reaction.delete_all
if Reaction.count == 0
  create_reaction 'like'
end

def create_section(name)
  section = Section.add(name)
  section.save!
  section
end

puts 'Creating sections...'
Section.delete_all
if Section.count == 0
  create_section :forums
  create_section :stream
  create_section :seamail
end
