require 'securerandom'

unless User.exist? 'TwitarrTeam'
  puts 'Creating user TwitarrTeam'
  user = User.new username: 'TwitarrTeam', display_name: 'TwitarrTeam', password: Rails.application.secrets.initial_admin_password,
    role: User::Role::ADMIN, status: User::ACTIVE_STATUS, email: 'admin@james.com', registration_code: 'code1'
  user.set_password user.password
  user.save
end

unless User.exist? 'moderator'
  puts 'Creating user moderator'
  user = User.new username: 'moderator', display_name: 'moderator', password: SecureRandom.hex,
  role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code2'
  user.set_password user.password
  user.save
end

puts 'Creating events...'
cal_filename = "db/seeds/all.ics"
# fix bad encoding from sched.org
cal_text = File.read(cal_filename)
cal_text = cal_text.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
if File.exists? cal_filename + ".tmp"
  File.delete(cal_filename + ".tmp")
end
File.open(cal_filename + ".tmp", "w") { |file| file << cal_text }

cal_file = File.open(cal_filename + ".tmp")
Icalendar::Calendar.parse(cal_file).first.events.map { |x| Event.create_from_ics x }

def create_reaction(tag)
  reaction = Reaction.add_reaction tag
  reaction.save!
  reaction
end

puts 'Creating reactions...'
Reaction.delete_all
if Reaction.count == 0
  create_reaction 'like'
  create_reaction 'love'
  create_reaction 'laugh'
end
