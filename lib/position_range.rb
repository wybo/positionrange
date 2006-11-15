#--#
# Author: Wybo Wiersma <wybo@logilogi.org>
#
# Copyright: (c) 2006 Wybo Wiersma
#
# License:
#   This file is part of the PositionRange library. PositionRange is free software. 
#   You can run/distribute/modify/link PositionRange under the terms of the GNU 
#   General Public License version 3, or any later version, with the extra copyleft 
#   provision (covered by subsection 7b of the GP v3) that running a modified version 
#   or a derivative work also requires you to make the sourcecode of that work
#   available to everyone that can interact with it, this to ensure that PositionRange
#   remains open and libre (doc/LICENSE.txt contains the full text of the legally
#   binding license, including that of the extra restrictions).
#++#
#
# PositionRanges allow one to model ranges of text.
#
# PositionRanges can be compared, sorted and parsed from and to strings.
#
# You can do most interesting things with PositionRanges in a
# PositionRangeList.
#
# They are wrappers around the Range class, and tus can be directly fed into the 
# index-operator of strings.
#
# PositionRanges are including the last position, so: 
# 
# first..last, not first...last

class PositionRange < Range
  include Comparable
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
  attr_accessor :authorship, :link

  ### Constructors

  # Initializes a new PositionRange. 
  #
  # Note that PositionRanges cannot be descending, nor exclude the 
  # end-position from the range.
  #
  # Options:
  # * <tt>:authorship</tt> - Authorship to associate with this position range
  # * <tt>:link</tt> - Link to associate with this range
  #
  # NOTE: The associations set in this way are not 2-way like in Rails
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

    @authorship = options[:authorship]
    @link = options[:link]

    super(first, last)
  end

  ### Class methods
  
  # Creates a PositionRange from a string.
  #
  # The syntax is:
  # <begin position>,<end position>
  #
  # Where the end position is included in the range.
  #
  # The options var allows one to pass options to the new PositionRange
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

  # Returns the size of the range, that is last - first + 1
  #
  # NOTE that PositionRanges cannot become negative, thus np. with
  # negative sizes.
  #
  def size
    return self.last - self.first + 1
  end

  # Duplicates the current object, except for the two arguments requested, which set
  # the begin and end positions of the new PositionRange.
  #
  def new_dup(first, last)
    PositionRange.new(first, last, :authorship => @authorship, :link => @link)
  end

  # Comparison

  # Comparisons happen in two stages.
  #
  # First the begin-positions are compared.
  #
  #     1..3 > 4..5 => true
  #     1..3 > 2..3 => true
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
    if self.link == other_position_range.link and
        self.authorship == other_position_range.authorship
      return true
    else
      return false
    end
  end

  # Turns a PositionRange into a string
  #
  def to_s
    return self.begin.to_s + ',' + self.end.to_s
  end
end
