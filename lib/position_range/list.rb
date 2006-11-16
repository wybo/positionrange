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
# Keeps a list of PositionRanges

require 'position_range'

class PositionRange::List < Array

  ###### Regular expressions  

  # Check-regexps
  CHECK_POSITION_RANGE_LIST_RE = 
      /^(#{PositionRange::BLOCK_POSITION_RANGE}(\:#{PositionRange::BLOCK_POSITION_RANGE})*)?$/ 

  ###### Class methods

  # Parses a list of PositionRanges from a string.
  #
  # Syntax:
  # <position range string>[:<position range string>]*
  #
  # Options:
  # The argument pass_on_options allows you to give options to be passed on to the 
  # PositionRanges created from the string
  #
  def self.from_s(position_range_list_string, pass_on_options = {})
    if position_range_list_string
      if position_range_list_string !~ CHECK_POSITION_RANGE_LIST_RE
        raise StandardError.new(), 'Invalid position_range_list string given: ' + 
            position_range_list_string
      end

      p_r_l = PositionRange::List.new
      p_r_s_arr = position_range_list_string.split(':')
      p_r_s_arr.each {|p_r_s|
        p_r_l.push(PositionRange.from_s(p_r_s, pass_on_options))
      }
      return p_r_l
    else
      return PositionRange::List.new
    end
  end

  # Returns a new PositionRangeList for the provided string, covering
  # it from start to end (the 'string' can also be an array).
  #
  def self.new_around(string)
    if string.size > 0
      return PositionRange::List.new([PositionRange.new(0,string.size - 1)])
    else
      return PositionRange::List.new
    end
  end

  ###### Methods

  ### Low level methods

  # Checking, ranges, etc

  # Returns the combined size of the ranges in this list.
  #
  def range_size
    range_size = 0
    self.each {|range|
      range_size += range.size
    }
    return range_size
  end

  # Returns true if all PositionRanges in this list don't refer to
  # positions bigger than size. Otherwise false.
  #
  def below?(size)
    return self.within?(
        PositionRange::List.new([PositionRange.new(0,size - 1)]))
  end

  # Returns true if all PositionRanges in this list fall within the
  # PositionRanges in the given other PositionRange::List
  #
  def within?(other)
    if (self - other).empty?
      return true
    else
      return false
    end
  end

  # Operations

  # Applies an intersection in the sense of Set theory.
  #
  # All PositionRanges and parts of PositionRanges that fall outside the 
  # PositionRanges given in the intersection_list are removed.
  #
  # Example:
  # 1,5:7,8:10,11' becomes '2,5:11,11' after limiting to '2,6:11,40'
  # 
  def &(other)
    substraction_list = other.dup.invert!
    return self - substraction_list
  end

  # Applies a substraction in the sense of Set theory.
  #
  # See substract!
  #
  def -(other)
    self.dup.substract!(other)
  end

  # Applies a substraction in the sense of Set theory.
  #
  # It removes all PositionRanges and parts of PositionRanges that overlap with the
  # PositionRanges given as the other.
  #
  # So for example:
  # 1,5:7,8:10,11' becomes '1,3:7,7:10,11' after substracting '4,6:8,9'
  #
  def substract!(other)
    self.sort!
    if other.size > 0
      other.dup.merge_adjacents!
      start_self_p = 0
      # walk the other
      other.each {|substract_p_r|
        self_p = start_self_p
        # walk self untill overlap
        while self[self_p] and 
            self[self_p].last < substract_p_r.first
          self_p += 1
        end
        if !self[self_p]
          # done for substract_p_r if at last item
          break
        end
        # for the next substract_p_r we start here again
        start_self_p = self_p
        # now while there is overlap
        while self[self_p] and 
            self[self_p].last >= substract_p_r.first and 
            self[self_p].first <= substract_p_r.last
          self_p_jump = 0
          # take a copy for the case of overlap on both sides
          examined_p_r = self[self_p]
          if examined_p_r.first < substract_p_r.first
            # overlap at the end
            self[self_p] = examined_p_r.new_dup(
                examined_p_r.first,substract_p_r.first - 1)
            self_p_jump = 1
          end
          if examined_p_r.last > substract_p_r.last
            # overlap at the beginning
            new_p_r = examined_p_r.new_dup(substract_p_r.last + 1,examined_p_r.last)
            if self_p_jump == 1
              self.insert(self_p + 1,new_p_r)
            else
              self[self_p] = new_p_r
            end
            self_p_jump += 1
          end
          if self_p_jump == 0
            # total overlap
            self.delete_at(self_p)
          else
            self_p += self_p_jump
          end
        end
      }
    end
    return self
  end

  # Deletes the position_range that is specified.
  #
  def delete!(p_r)
    self.substract!(PositionRange::List.new([p_r]))
  end

  # Results in all positions being included, being excluded now, and
  # all positions that were excluded, being included now, upto the
  # range below maximum_size.
  #
  # NOTE: new ranges are created as PositionRanges, so references to
  # objects or ordering_positions of subclasses are not maintained, as 
  # they are meaningless for inverted lists of ranges.
  #
  def invert!(maximum_size = PositionRange::MaximumSize)
    if self.size > 0
      self.merge_adjacents!
      # sorts and prevents problems with adjacent ranges
      if self[-1].end > maximum_size
        raise PositionRange::Error.new(self[-1].begin, self[-1].end),
            'PositionRange larger than the maximum'
      end
      start_point = 0
      if self[0].begin > 0
        self.insert(0, PositionRange.new(0, self[0].begin - 1))
        start_point += 1
      end
      if self.size > 1
        (start_point...(self.size - 1)).each {|i|
          self[i] = PositionRange.new(self[i].end + 1, self[i + 1].begin - 1)
        }
      end
      if self[-1].end < maximum_size - 1
        self[-1] = PositionRange.new(self[-1].end + 1, maximum_size - 1)
      else
        self.delete_at(-1)
      end
    elsif maximum_size > 0
      self.push(PositionRange.new(0, maximum_size - 1))
    end
    return self
  end

  # Makes sure that there are no non-overlapping borders between PositionRanges.
  # 
  # The guaranteed situation after calling this method:
  # * Multiple PositionRanges can refer to the same ranges, but if they do they will
  #   have the same begin and end position.
  # * All positions associated with an object (a Link or an Authorship for example) 
  #   will still be associated with that same object, but possibly through a 
  #   different or a new PositionRange.
  # 
  # Example:
  # '3,7->a:5,9->b' lined up will be '3,4->a:5,7->a:5,7->b:8,9->b'
  #
  # Where the ->X indicates an association with object X
  #
  # This is used for simplifying PositionRanges for parsing Links into Logis.
  #
  def line_up_overlaps!
    self.merge_adjacents!
    # note that the merging and the sorting done by merge_adjacents assures that 
    # he PositionRanges are always sorted by begin-position AND size (short to 
    # long).
    i = 0
    while i < (self.size - 1)
      if self[i].end > self[i + 1].begin
        # found an overlap
        if self[i].begin != self[i + 1].begin
          # the beginnings are not lined up, so align them
          self.insert(i + 1, self[i].new_dup(self[i + 1].begin, self[i].end))
          self[i] = self[i].new_dup(self[i].begin, self[i + 1].begin - 1)
        elsif self[i].end != self[i + 1].end
          # the beginnings are already lined up, now do the ends
          if self[i].end < self[i + 1].end
            # i is the shortest, so self[i].end is used
            self.insert(i + 2, self[i + 1].new_dup(self[i].end + 1, self[i + 1].end))
            self[i + 1] = self[i + 1].new_dup(self[i + 1].begin, self[i].end)
          else
            # i + 1 is the shortest, so self[i + 1].end is used
            self.insert(i + 2, self[i].new_dup(self[i + 1].end + 1, self[i].end))
            self[i] = self[i].new_dup(self[i].begin, self[i + 1].end)
          end
        end
      end
      i += 1
    end
    return self
  end

  # Simplifies the PositionRange::List by merging adjacent PositionRanges.
  #
  # Example:
  # 1,3:4,7:10,11 => 1,7:10,11
  #
  # Only merges adjacent PositionRanges if all their attributes
  # (except for first and last) are the same
  #
  def merge_adjacents!
    self.sort!
    if self.size > 1
      i = 0
      while i < self.size
        if self[i - 1].end + 1 == self[i].begin and 
            self[i - 1].has_equal_pointer_attributes?(self[i])
          self[i - 1] = self[i - 1].new_dup(self[i - 1].begin, self[i].end)
          self.delete_at(i)
        else
          i += 1
        end
      end
    end
    return self
  end

  # Translates the PositionRange::List in space, along the given vector.
  #
  def translate!(integer)
    if !integer.kind_of?(Integer)
      raise StandardError.new, 'Tried to translate a PositionRange::List with a non-integer'
    end
    (0...self.size).each {|i|
      self[i] = self[i].new_dup(self[i].first + integer,self[i].last + integer)
    }
    return self
  end

  # The ranges_to_insert are inserted at the ranges_at_which_to_insert 
  # of this list, counted in range_size from it's beginning, and inter-
  # luded with ranges_to_skip.
  #
  # So PositionRange::List.from_s('39,48:16,20').insert_at_ranges!(
  #     PositionRange::List.from_s('100,102:6,7'),
  #     PositionRange::List.from_s('10,12:19,20'),
  #     PositionRange::List.from_s('13,18'))
  #
  # will result in:
  # PositionRange::List.from_s('39,48:100,102:6,7:16,20')
  #
  def insert_at_ranges!(ranges_to_insert, ranges_at_which_to_insert, 
      ranges_to_skip = [])
    if ranges_to_insert.range_size != ranges_at_which_to_insert.range_size
      raise StandardError, 'Ranges to insert, and at which to insert are ' +
          'of different range_sizes: ' + ranges_to_insert.to_s + ', ' +
          ranges_at_which_to_insert.to_s
    end
    ranges_to_act = ranges_at_which_to_insert.each {|p_r| p_r.link = :ins}.concat(
        ranges_to_skip).sort!

    self_i = -1
    self_p = 0
    ins_p = 0
    ranges_to_act.each {|p_r|
      while self_p < p_r.begin - 1
        self_i += 1
        self_p += self[self_i].size
      end
      if self_p > p_r.begin
        copy = self[self_i]
        cut = copy.end + p_r.begin - self_p
        self[self_i] = copy.new_dup(copy.begin, cut)
        self.insert(self_i + 1, copy.new_dup(cut + 1, copy.end))
        self_p = cut
      end
      if p_r.link == :ins
        inner_p = 0
        while inner_p < p_r.size
          self.insert(self_i + 1, ranges_to_insert[ins_p])
          inner_p += ranges_to_insert[ins_p].size
          self_i += 1
          ins_p += 1
        end
      end
      self_p += p_r.size
    }
    return self
  end

  ### Highlevel methods
  
  # Translates the PositionRange::List into the relative space defined
  # by the view_position_range_list
  #
  def translate_to_view(view_position_range_list)
    relative = PositionRange::List.new
    view_p = 0
    view_position_range_list.each {|snippet_p_r|
      translate_list = self & PositionRange::List.new([snippet_p_r])
      vector = view_p - snippet_p_r.first
      relative.concat(translate_list.translate!(vector))
      view_p += snippet_p_r.size
    }
    relative.merge_adjacents!
    return relative
  end

  # Translates the PositionRange::List into absolute space
  #
  def translate_from_view(view_position_range_list)
    absolute = PositionRange::List.new
    view_p = 0
    view_position_range_list.each {|snippet_p_r|
      translate_list = self & PositionRange::List.new(
          [PositionRange.new(view_p,view_p + snippet_p_r.size - 1)])
      vector = snippet_p_r.first - view_p
      absolute.concat(translate_list.translate!(vector))
      view_p += snippet_p_r.size
    }
    absolute.merge_adjacents!
    return absolute
  end

  # Stacks the PositionRanges in the List adjacent in a new
  # PositionRange::List, while maintaining their size.
  #
  # So PositionRangeList.from_s('50,53:11,30').stack_adjacents
  # returns: PositionRangeList.from_s('0,3:4,23')
  #
  def stack_adjacent
    adjacent = PositionRange::List.new
    adjacent_p = 0
    self.collect do |p_r|
      step = p_r.size
      adjacent << PositionRange.new(adjacent_p, adjacent_p + step - 1)
      adjacent_p += step
    end
    return adjacent
  end

  # Adds all items to a cluster-array, where overlapping PositionRanges are
  # added to the same cluster_array position.
  #
  # So PositionRange::List.from_s('1,2:1,2:10,18:14,18').cluster_overlaps will 
  # get you a cluster arr equal to the following:
  #
  # [PositionRange::List.from_s('1,2:1,2'),
  #  PositionRange::List.from_s('10,13'),
  #  PositionRange::List.from_s('14,18:14,18')]
  #
  # Except that the pointer_attributes are of course kept in order
  #
  def cluster_overlaps
    if !self.empty?
      lined_up_self = self.dup.line_up_overlaps!
      clusters = [PositionRange::List.new().push(lined_up_self.shift)]
      lined_up_self.each {|p_r|
        if p_r == clusters.last[0]
          clusters.last.push(p_r)
        else
          clusters.push(PositionRange::List.new([p_r]))
        end
      }
      return clusters
    else
      return self.dup
    end
  end

  # Returns a new string containing only the parts of the old string
  # designated by position_ranges.
  #
  # Appends the string[position_range] in the order in which they are 
  # found in this list.
  #
  def apply_to_string(string)
    new_string = ''
    self.each {|p_r|
      if p_r.end > string.size
        raise StandardError, 'End-range bigger than string'
      end
      new_string += string[p_r]
    }
    return new_string
  end

  ### Parsing methods

  # Parses a PositionRange::List to a string
  #
  def to_s
    self.sort
    p_r_l_string = ''
    self.each {|p_r|
      p_r_l_string += p_r.to_s + ':'
    }
    return p_r_l_string[0...-1]
  end
end
