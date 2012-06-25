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
  # The argument pass_on_options allows you to give options to be
  # passed on to the PositionRanges created from the string
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
  def self.around(string)
    if string.size > 0
      return PositionRange::List.new([PositionRange.new(0,string.size)])
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
  # Attributes are ignored.
  #
  def below?(size)
    return self.within?(
        PositionRange::List.new([PositionRange.new(0,size)]))
  end

  # Returns true if all PositionRanges in this list fall within the
  # PositionRanges in the given other PositionRange::List
  #
  # Attributes are ignored.
  #
  def within?(other)
    if (self.substract(other, :ignore_attributes => true)).empty?
      return true
    else
      return false
    end
  end

  # Returns the index of the given PositionRange.
  #
  # Options
  # <tt>:dont_ignore_attributes</tt> => true, finds the one that has
  # also equal attributes, defaults to false
  #
  def index(position_range, options = {})
    if options[:dont_ignore_attributes]
      self.each_with_index do |s_p_r, i|
        if position_range == s_p_r and position_range.has_equal_pointer_attributes?(s_p_r)
          return i
        end
      end
      return nil
    else
      super(position_range)
    end
  end

  ### Low level operations

  # Applies an intersection in the sense of Set theory.
  #
  # All PositionRanges and parts of PositionRanges that fall outside
  # the PositionRanges given in the intersection_list are removed.
  #
  # Example:
  # 1,5:7,8:10,12' becomes '2,5:11,12' after limiting to '2,6:11,40'
  #
  def &(other)
    substraction_list = other.invert
    return self.substract(substraction_list, :ignore_attributes => true)
  end

  # Applies a substraction in the sense of Set theory.
  #
  # See substract
  #
  def -(other)
    self.substract(other)
  end

  # Applies a substraction in the sense of Set theory.
  #
  # It removes all PositionRanges and parts of PositionRanges that overlap with the
  # PositionRanges given as the other.
  #
  # So for example:
  # 1,5:7,9:11,12' becomes '1,4:7,8:11,12' after substracting '4,6:8,9'
  #
  # Only substracts PositionRanges if all their attributes (except for first and
  # last) are the same, unless ignore_attributes is specified.
  #
  # Options
  # <tt>:ignore_attributes</tt> => Ignores attributes
  #
  def substract!(other, options = {})
    ignore_attributes = options[:ignore_attributes]

    sorted_self = self.dup.sort!
    if sorted_self.size > 0 and other.size > 0
      other = other.dup.sort!.merge_adjacents!

      last_i = 0
      other.each do |p_r|
        i = last_i
        while sorted_self[i] and sorted_self[i].end < p_r.begin
          i += 1
        end
        last_i = i
        while sorted_self[i] and sorted_self[i].begin < p_r.end
          if ignore_attributes or sorted_self[i].has_equal_pointer_attributes?(p_r)
            self_i = self.index(sorted_self[i], :dont_ignore_attributes => !ignore_attributes)
            if sorted_self[i].begin < p_r.begin
              copy = sorted_self[i].dup
              sorted_self[i] = copy.new_dup(copy.begin, p_r.begin)
              self[self_i] = sorted_self[i]
              sorted_self.insert(i + 1, copy.new_dup(p_r.begin, copy.end))
              self.insert(self_i + 1, sorted_self[i + 1])
              i += 1
            elsif sorted_self[i].end <= p_r.end
              sorted_self.delete_at(i)
              self.delete_at(self_i)
            else
              sorted_self[i] = sorted_self[i].new_dup(
                  p_r.end, sorted_self[i].end)
              self[self_i] = sorted_self[i]
            end
          else
            i += 1
          end
        end
      end
    end
    return self
  end

  # Substraction returning a new list.
  #
  # See substract!
  #
  def substract(other, options = {})
    self.dup.substract!(other, options)
  end

  # Deletes the position_range that is specified.
  #
  def delete!(p_r)
    self.substract!(PositionRange::List.new([p_r]))
  end

  # Deletion returning a new list.
  #
  # See delete!
  #
  def delete(p_r)
    self.substract(PositionRange::List.new([p_r]))
  end

  # Results in all positions being included, being excluded now, and
  # all positions that were excluded, being included now, upto the
  # range below maximum_size.
  #
  # NOTE: new ranges are created as PositionRanges, so references to
  # objects or ordering_positions of subclasses are not maintained, as
  # they are meaningless for inverted lists of ranges.
  #
  # NOTE: Also that self is sorted.
  #
  def invert!(maximum_size = PositionRange::MaximumSize)
    if self.size > 0
      self.sort!.merge_adjacents!
      # sorts and prevents problems with adjacent ranges
      if self[-1].end > maximum_size
        raise PositionRange::Error.new(self[-1].begin, self[-1].end),
            'PositionRange larger than the maximum'
      end
      start_point = 0
      if self[0].begin > 0
        self.insert(0, PositionRange.new(0, self[0].begin))
        start_point += 1
      end
      if self.size > 1
        (start_point...(self.size - 1)).each {|i|
          self[i] = PositionRange.new(self[i].end, self[i + 1].begin)
        }
      end
      if self[-1].end < maximum_size - 1
        self[-1] = PositionRange.new(self[-1].end, maximum_size)
      else
        self.delete_at(-1)
      end
    elsif maximum_size > 0
      self.push(PositionRange.new(0, maximum_size))
    end
    return self
  end

  # Inversion returning a new list.
  #
  # See invert!
  #
  def invert(maximum_size = PositionRange::MaximumSize)
    self.dup.invert!(maximum_size)
  end

  # Makes sure that there are no overlapping borders between
  # PositionRanges.
  #
  # The guaranteed situation after calling this method:
  # * Multiple PositionRanges can refer to the same ranges, but if
  #   they do they will have the same begin and end position.
  # * All positions associated with an object (a Link or an Authorship
  #   for example) will still be associated with that same object, but
  #   possibly through a different or a new PositionRange.
  #
  # Example:
  # '3,7->a:5,9->b' lined up will be '3,5->a:5,7->a:5,7->b:7,9->b'
  #
  # Where the ->X indicates an association with object X
  #
  # This is used for simplifying PositionRanges for parsing Links into
  # Logis.
  #
  def line_up_overlaps!
    self.sort!.merge_adjacents!
    # note that the merging and the sorting done by merge_adjacents
    # assures that he PositionRanges are always sorted by
    # begin-position AND size (short to long).
    i = 0
    while i < (self.size - 1)
      if self[i].end > self[i + 1].begin
        # found an overlap
        if self[i].begin != self[i + 1].begin
          # the beginnings are not lined up, so align them
          self.insert(i + 1, self[i].new_dup(self[i + 1].begin, self[i].end))
          self[i] = self[i].new_dup(self[i].begin, self[i + 1].begin)
          i = -1; self.sort! # restart in case more than 1 overlap
        elsif self[i].end != self[i + 1].end
          # the beginnings are already lined up, now do the ends
          if self[i].end < self[i + 1].end
            # i is the shortest, so self[i].end is used
            self.insert(i + 2, self[i + 1].new_dup(self[i].end, self[i + 1].end))
            self[i + 1] = self[i + 1].new_dup(self[i + 1].begin, self[i].end)
          else
            # i + 1 is the shortest, so self[i + 1].end is used
            self.insert(i + 2, self[i].new_dup(self[i + 1].end, self[i].end))
            self[i] = self[i].new_dup(self[i].begin, self[i + 1].end)
          end
          i = -1; self.sort! # restart in case more than 1 overlap
        end
      end
      i += 1
    end
    return self
  end

  # Lining up overlaps returning a new list.
  #
  # See line_up_overlaps!
  #
  def line_up_overlaps
    self.dup.line_up_overlaps!
  end

  # Simplifies the PositionRange::List by merging adjacent PositionRanges.
  #
  # Example:
  # 1,4:4,7:10,11 => 1,7:10,11
  #
  # Only merges adjacent PositionRanges if all their attributes
  # (except for first and last) are the same
  #
  def merge_adjacents!(options = {})
    ignore_attributes = options[:ignore_attributes]
    if self.size > 1
      i = 0
      while i < self.size
        if self[i - 1].end == self[i].begin and
            (ignore_attributes or self[i - 1].has_equal_pointer_attributes?(self[i]))
          self[i - 1] = self[i - 1].new_dup(self[i - 1].begin, self[i].end)
          self.delete_at(i)
        else
          i += 1
        end
      end
    end
    return self
  end

  # Merging adjacents returning a new list.
  #
  # See merge_adjacents!
  # 
  def merge_adjacents(options = {})
    self.dup.merge_adjacents!(options)
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

  # Translation returning a new list.
  #
  # See translate!
  #
  def translate(integer)
    self.dup.translate!(integer)
  end

  # The ranges_to_insert are inserted at the ranges_at_which_to_insert
  # of this list, counted in range_size from it's beginning, and inter-
  # luded with ranges_to_skip.
  #
  # So PositionRange::List.from_s('39,49:16,20').insert_at_ranges!(
  #     PositionRange::List.from_s('100,102:6,7'),
  #     PositionRange::List.from_s('10,12:19,20'),
  #     PositionRange::List.from_s('12,19'))
  #
  # will result in:
  # PositionRange::List.from_s('39,49:100,102:6,7:16,20')
  #
  def insert_at_ranges!(ranges_to_insert, ranges_at_which_to_insert,
      ranges_to_skip = [])
    if ranges_to_insert.range_size != ranges_at_which_to_insert.range_size
      raise StandardError, 'Ranges to insert, and at which to insert are ' +
          'of different range_sizes: ' + ranges_to_insert.to_s + ', ' +
          ranges_at_which_to_insert.to_s
    end
    ranges_to_insert.align_chunks!(ranges_at_which_to_insert)
    ranges_at_which_to_insert.align_chunks!(ranges_to_insert)

    ranges_to_act = ranges_at_which_to_insert.each {|p_r| p_r.action = :ins}.concat(
        ranges_to_skip).sort!

    i = -1
    self_p = 0
    ins_p = 0
    ranges_to_act.each {|p_r|
      while self_p < p_r.begin - 1
        i += 1
        self_p += self[i].size
      end
      if self_p > p_r.begin
        copy = self[i]
        cut = copy.end + p_r.begin - self_p
        self[i] = copy.new_dup(copy.begin, cut)
        self.insert(i + 1, copy.new_dup(cut, copy.end))
        self_p = p_r.begin
      end
      if p_r.action == :ins
        inner_p = 0
        while inner_p < p_r.size
          self.insert(i + 1, ranges_to_insert[ins_p])
          inner_p += ranges_to_insert[ins_p].size
          i += 1
          ins_p += 1
        end
      end
      self_p += p_r.size
    }
    return self
  end

  # Ensures that the other list and this list don't have any
  # overlapping chunks, considering their size.
  #
  # So PositionRange::List.from_s('10,20:50,70').align_chunks!(
  #     PositionRange::List.from_s('20,30:200,210,550,560'))
  #
  # will result in:
  # PositionRange::List.from_s('10,20:50,60:60,70')
  #
  def align_chunks!(other_ranges)
    i = -1
    self_p = 0
    other_p = 0
    other_ranges.each {|p_r|
      i += 1
      if !self[i]
        return self
      end
      other_p += p_r.size
      self_p += self[i].size
      if self_p > other_p
        copy = self[i]
        cut = self[i].begin + p_r.size
        self[i] = copy.new_dup(copy.begin, cut)
        self.insert(i + 1, copy.new_dup(cut, copy.end))
        self_p = other_p
      end
    }
    return self
  end

  # Inserting at ranges returning a new list.
  #
  # See insert_at_ranges!
  #
  def insert_at_ranges(ranges_to_insert, ranges_at_which_to_insert,
      ranges_to_skip = [])
    return self.dup.insert_at_ranges!(ranges_to_insert, ranges_at_which_to_insert,
        ranges_to_skip)
  end

  ### Highlevel methods

  # Translates the PositionRange::List into the relative space defined
  # by the view_position_range_list
  #
  def translate_to_view(view_position_range_list)
    relative = PositionRange::List.new
    self.each do |p_r|
      view_p = 0
      p_r_list = PositionRange::List.new([p_r])
      view_position_range_list.each do |snippet_p_r|
        translate_list = p_r_list & PositionRange::List.new([snippet_p_r])
        vector = view_p - snippet_p_r.first
        relative.concat(translate_list.translate!(vector))
        view_p += snippet_p_r.size
      end
    end
    relative.merge_adjacents!
    return relative
  end

  # Translates the PositionRange::List into absolute space
  #
  def translate_from_view(view_position_range_list)
    absolute = PositionRange::List.new
    self.each do |p_r|
      view_p = 0
      p_r_list = PositionRange::List.new([p_r])
      view_position_range_list.each do |snippet_p_r|
        translate_list = p_r_list & PositionRange::List.new(
            [PositionRange.new(view_p,view_p + snippet_p_r.size)])
        vector = snippet_p_r.first - view_p
        absolute.concat(translate_list.translate!(vector))
        view_p += snippet_p_r.size
      end
    end
    absolute.merge_adjacents!
    return absolute
  end

  # Stacks the PositionRanges in the List adjacent in a new
  # PositionRange::List, while maintaining their size.
  #
  # So PositionRangeList.from_s('50,53:11,30').stack_adjacents
  # returns: PositionRangeList.from_s('0,3:4,23')
  #
  # Options
  # <tt>:space</tt> => The space to leave inbetween
  #
  def stack_adjacent(options = {})
    space = options[:space] || 0
    adjacent = PositionRange::List.new
    adjacent_p = 0
    self.collect do |p_r|
      step = p_r.size
      adjacent << PositionRange.new(adjacent_p, adjacent_p + step)
      adjacent_p += step + space
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
  #  PositionRange::List.from_s('10,14'),
  #  PositionRange::List.from_s('14,18:14,18')]
  #
  # Except that the pointer_attributes are of course kept in order
  #
  def cluster_overlaps
    if !self.empty?
      lined_up_self = self.line_up_overlaps
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
  # Options
  # <tt>:separator</tt> => The string to insert between the parts
  #
  def apply_to_string(string, options = {})
    separator = options[:separator] || ''
    new_string = ''
    self.each {|p_r|
      if p_r.end > string.size
        raise StandardError, 'End-range bigger than string'
      end
      new_string += string[p_r] + separator
    }
    return new_string[0..-1 - separator.size]
  end

  ### Parsing methods

  # Parses a PositionRange::List to a string
  #
  def to_s
    self.sort!
    p_r_l_string = ''
    self.each {|p_r|
      p_r_l_string += p_r.to_s + ':'
    }
    return p_r_l_string[0...-1]
  end
end
