require 'securerandom'

unless User.exist? 'TwitarrTeam'
  puts 'Creating user TwitarrTeam'
  user = User.new(username: 'TwitarrTeam', display_name: 'TwitarrTeam', password: Rails.application.secrets.initial_admin_password,
                  role: User::Role::ADMIN, status: User::ACTIVE_STATUS, email: 'admin@james.com', registration_code: 'code1')
  user.change_password user.password
  user.save
end

unless User.exist? 'moderator'
  puts 'Creating user moderator'
  user = User.new username: 'moderator', display_name: 'moderator', password: SecureRandom.hex,
                  role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code2'
  user.change_password user.password
  user.save
end

unless User.exist? 'moderator'
  raise Exception.new('No user named \'moderator\'!  Create one first!')
end

puts 'Creating events...'
cal_filename = 'db/seeds/all.ics'
# fix bad encoding from sched.org
cal_text = File.read(cal_filename)
cal_text = cal_text.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')

File.delete(cal_filename + '.tmp') if File.exists? cal_filename + '.tmp'
File.open(cal_filename + '.tmp', 'w') { |file| file << cal_text }

cal_file = File.open(cal_filename + '.tmp')
Icalendar::Calendar.parse(cal_file).first.events.map { |x| Event.create_from_ics x }

def create_reaction(tag)
  reaction = Reaction.add_reaction tag
  reaction.save!
  reaction
end

puts 'Creating reactions...'
Reaction.delete_all
if Reaction.count.zero?
  create_reaction 'like'
end

puts 'Creating sections...'
Section.delete_all
if Section.count == 0
  Section.add(:forums, :global)
  Section.add(:stream, :global)
  Section.add(:seamail, :global)
  Section.add(:calendar, :global)
  Section.add(:deck_plans, :global)
  Section.add(:games, :global)
  Section.add(:karaoke, :global)
  Section.add(:search, :global)
  Section.add(:registration, :global)
  Section.add(:user_profile, :global)
  Section.add(:Kraken_forums, :kraken)
  Section.add(:Kraken_stream, :kraken)
  Section.add(:Kraken_seamail, :kraken)
  Section.add(:Kraken_calendar, :kraken)
  Section.add(:Kraken_deck_plans, :kraken)
  Section.add(:Kraken_games, :kraken)
  Section.add(:Kraken_karaoke, :kraken)
  Section.add(:Kraken_search, :kraken)
  Section.add(:Kraken_registration, :kraken)
  Section.add(:Kraken_user_profile, :kraken)
end
