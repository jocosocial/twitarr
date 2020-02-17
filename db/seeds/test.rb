require 'securerandom'

puts 'Creating default users...'
User.create_default_users

unless User.exist? 'TwitarrTeam'
  raise Exception.new("No user named 'TwitarrTeam'!  Create one first!")
end

unless User.exist? 'official'
  raise Exception.new("No user named 'official'!  Create one first!")
end

unless User.exist? 'moderator'
  raise Exception.new("No user named 'moderator'!  Create one first!")
end

puts 'Creating moderator seamail thread...'
Seamail.create_moderator_seamail

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
Section.repopulate_sections
