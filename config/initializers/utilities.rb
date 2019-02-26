# Be sure to restart your server when you modify this file.
class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("Invalid value for Boolean: #{self}")
  end
end

class Integer
  def to_bool
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("Invalid value for Boolean: #{self}")
  end
end

class TrueClass
  def to_i; 1; end
  def to_bool; self; end
end

class FalseClass
  def to_i; 0; end
  def to_bool; self; end
end

class NilClass
  def to_bool; false; end
end

class Time
  def to_ms
    (self.to_f * 1000.0).to_i
  end

  def self.from_param(input)
    if input.is_a?(Integer) || input =~ /^\d+$/
      Time.at(input.to_i / 1000)
    elsif input
      Time.parse(input)
    end
  end
end

# Fixes errors in the ImageVoodoo library. Don't have time to wait for a new version.
# https://github.com/jruby/image_voodoo/issues/21
# https://github.com/jruby/image_voodoo/issues/23
class ImageVoodoo
  def calculate_thumbnail_dimentions
    calculate_thumbnail_dimensions
  end

  private
  def correct_orientation_impl
    case metadata.orientation
    when 2 then flip_horizontally
    when 3 then rotate(180)
    when 4 then flip_vertically
    when 5 then flip_horizontally && rotate(90)
    when 6 then rotate(90)
    when 7 then flip_horizontally && rotate(270)
    when 8 then rotate(270)
    else self
    end
  end
end
