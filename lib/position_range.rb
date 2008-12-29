#--#
# Copyright: (c) 2006-2008 The LogiLogi Foundation <foundation@logilogi.org>
#
# License:
#   This file is part of the PositionRange Library. PositionRange is Free
#   Software. You can run/distribute/modify PositionRange under the terms of
#   the GNU Affero General Public License version 3. The Affero GPL states
#   that running a modified version or a derivative work also requires you to
#   make the sourcecode of that work available to everyone that can interact
#   with it. We chose the Affero GPL to ensure that PositionRange remains open
#   and libre (LICENSE.txt contains the full text of the legally binding
#   license).
#++#
#
# PositionRanges allow one to model ranges of text.
#
# PositionRanges can be compared, sorted and parsed from and to
# strings.
#
# You can do most interesting things with PositionRanges in a
# PositionRangeList.
#
# They are wrappers around the Range class, and thus can be directly
# fed into the index-operator of strings.
#
# PositionRanges are excluding the last position, so:
#
# first...last, not first..last

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

class PositionRange < Range
  include Comparable

  @@attributes = []

  def attributes
    return @@attributes
  end

  ### Constants

  # Mainly used by PositionRange::List
  MaximumSize = 2 ** 31

  ### Regular expressions

  # Regexp building blocks
  BLOCK_POSITION_RANGE = '(?:\d+,\d+)'

  # Check-regexps
  CHECK_POSITION_RANGE_RE = /^#{BLOCK_POSITION_RANGE}$/
end

require 'position_range/error'
require 'position_range/list'

class PositionRange
  ### Constructors

  # Initializes a new PositionRange.
  #
  # Note that PositionRanges cannot be descending.
  #
  # Options:
  # * <tt>:<any attribute you need></tt> - Usefull for associating Links or
  #     Remarks with this range.
  #
  def initialize(first, last, options = {})
    if first < 0
      raise PositionRange::Error.new(first, last), 'Tried to create a negative PositionRange'
    end
    if first > last
      raise PositionRange::Error.new(first, last), 'Tried to create a descending PositionRange'
    end
    if last > MaximumSize
      raise PositionRange::Error.new(first, last), 'Tried to create a PositionRange that is' +
          ' larger than the MaximumSize'
    end

    options.each_key do |attribute|
      if !self.respond_to?(attribute)
        self.define_attribute(attribute.to_s)
      end
      self.send(attribute.to_s + '=', options[attribute])
    end

    super(first, last, true)
  end

  ### Class methods

  # Creates a PositionRange from a string.
  #
  # The syntax is:
  # <begin position>,<end position>
  #
  # Where the end position is included in the range.
  #
  # The optional options var allows one to pass attributes to the new
  # PositionRange
  #
  def self.from_s(position_range_string, options = {})
    if position_range_string !~ CHECK_POSITION_RANGE_RE
      raise StandardError.new, 'Invalid position_range string given: ' +
          position_range_string
    end
    p_r_arr = position_range_string.split(',')
    return PositionRange.new(p_r_arr[0].to_i, p_r_arr[1].to_i, options)
  end

  ### Methods

  # Returns the size of the range, that is last - first
  #
  # NOTE that PositionRanges cannot become negative.
  #
  def size
    return self.last - self.first
  end

  # Duplicates the current object, except for the two required
  # arguments, which set the begin and end positions of the new
  # PositionRange.
  #
  def new_dup(first, last)
    attributes_hash = Hash.new
    self.attributes.each {|attribute|
      attributes_hash[attribute.to_sym] = self.send(attribute)
    }
    PositionRange.new(first, last, attributes_hash)
  end

  # Returns this PositionRange substracted by the previous
  #
  # NOTE: The substracted PositionRange must overlap with at least
  # one side of this one. If it's begin-position is bigger than this
  # one's and it's end position smaller than this one's, no
  # meaningfull output is guaranteed.
  #
  def -(other)
    if other.begin >= self.end or other.end <= self.begin
      return self
    elsif other.begin < self.begin and other.end > self.end
      return nil
    elsif other.end < self.end
      return self.new_dup(other.end, self.end)
    elsif other.begin > self.begin
      return self.new_dup(self.begin, other.begin)
    end
  end

  # Returns true if there is overlap between the PositionRange
  # given as other, and this range.
  #
  # Other values are treated as Range normally does.
  #
  def ===(other)
    if other.kind_of?(PositionRange)
      if self.size > other.size
        return ((self) === other.begin or (self) === other.end)
      else
        return ((other) === self.begin or (other) === self.end)
      end
    else
      super(other)
    end
  end

  # Comparison

  # Comparisons happen in two stages.
  #
  # First the begin-positions are compared.
  #
  #     4..5 > 1..3 => true
  #     2..3 > 1..3 => true
  #
  # If those are equal the end-positions are compared.
  #
  #     1..3 > 1..2
  #
  # If also the end-positions are equal, 0 is returned
  #
  #     1..2 == 1..2
  #
  def <=>(other)
    if self.begin < other.begin
      return -1
    elsif self.begin > other.begin
      return 1
    else
      if self.end < other.end
        return -1
      elsif self.end > other.end
        return 1
      else
        return 0
      end
    end
  end

  # Returns true if the pointer_attributes (link and authorship) are equal
  #
  def has_equal_pointer_attributes?(other_position_range)
    self.attributes.each {|attribute|
      if self.send(attribute) != other_position_range.send(attribute)
        return false
      end
    }
    return true
  end

  # Turns a PositionRange into a string
  #
  def to_s
    return self.begin.to_s + ',' + self.end.to_s
  end

  ### Sub-functions

  protected

  # Allows the dynamic adding of attributes
  #
  def method_missing(method_id, *arguments)
    if method_id.to_s[-1..-1] == '='
      attribute = method_id.to_s.slice!(0...-1)
      self.define_attribute(attribute)
      self.send(method_id.to_s, *arguments)
    elsif arguments.empty?
      return nil
    else
      super(method_id, *arguments)
    end
  end

  # Defines the given string as an attribute.
  #
  # (attr_accessor)
  #
  def define_attribute(attribute)
    PositionRange.class_eval {
      attr_accessor attribute
    }
    @@attributes.push(attribute)
  end
end
