class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Searchable

  DST_START = Time.new(2019, 3, 11, 2, 0, 0, "-05:00")

  field :tl, as: :title, type: String
  field :sm, as: :description, type: String
  field :lc, as: :location, type: String
  field :st, as: :start_time, type: Time
  field :et, as: :end_time, type: Time
  field :fa, as: :favorites, type: Array, default: []
  # TODO add type
  field :of, as: :official, type: Boolean

  validates :title, :start_time, presence: true

  # 1 = ASC, -1 DESC
  index start_time: 1
  index title: 1
  index({:title => 'text', :description => 'text', :location => 'text'})

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    criteria = Event.or({title: /^#{search_text}.*/}, {'$text' => {'$search' => "\"#{search_text}\""}})
    limit_criteria(criteria, params).order_by(id: :desc)
  end

  def self.create_new_event(author, title, start_time, options={})
    event = Event.new(title: title, start_time: start_time)
    event.description = options[:description] unless options[:description].nil?
    event.location = options[:location] unless options[:location].nil?
    event.official = options[:official] unless options[:official].nil?
    # Time.parse should occur on the controller side, but I haven't got time to straighten this out right now
    event.end_time = Time.parse(options[:end_time]) unless options[:end_time].nil?
    event
  end

  def self.create_from_ics(ics_event)
    event = Event.where(id: ics_event.uid).first
    if event.nil?
      event = Event.new(
          _id: ics_event.uid
      )
    end
    event.title = ics_event.summary.force_encoding('utf-8')
    event.description = ics_event.description.force_encoding('utf-8')
    if ics_event.dtstart <= DST_START
      event.start_time = ics_event.dtstart + 1.hour
      event.end_time = ics_event.dtend + 1.hour
    else
      event.start_time = ics_event.dtstart
      event.end_time = ics_event.dtend unless ics_event.dtend.nil?
    end
    event.official = !ics_event.categories.include?('SHADOW CRUISE')
    # locations tend to have trailing commas for some reason
    event.location = ics_event.location.force_encoding('utf-8').strip.gsub(/,$/, '')
    event.save
  end

  def self.favorite_from_ics(ics_event, username)
    uid = ics_event.uid.split('@')[0]
    begin
      event = Event.find(uid)
    rescue Mongoid::Errors::DocumentNotFound
      return
    end
    event.favorites << username unless event.favorites.include? username
    event.save
  end

  def follow(username)
    self.favorites << username unless self.favorites.include? username
  end

  def unfollow(username)
    self.favorites.delete username
  end

end
