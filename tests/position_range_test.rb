#! /usr/bin/env ruby
#
#--#
# Author: Wybo Wiersma <wybo@logilogi.org>
#
# Copyright: (c) 2006 Wybo Wiersma
#
# License:
#   This file is part of the LogiLogi program. LogiLogi is free software. You
#   can run/distribute/modify LogiLogi under the terms of the GNU General Public
#   License version 3, or any later version, with the extra copyleft provision
#   (covered by subsection 7b of the GP v3) that running a modified version or a
#   derivative work also requires you to make the sourcecode of that work
#   available to everyone that can interact with it, this to ensure that LogiLogi
#   remains open and libre (doc/LICENSE.txt contains the full text of the legally
#   binding license, including that of the extra restrictions).
#++#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'position_range'
require 'test/unit'

class PositionRangeTest < Test::Unit::TestCase
  def test_parsing
    assert_equal PositionRange.new(1,4), PositionRange.from_s('1,4')
    assert_equal '1,3', PositionRange.new(1,3).to_s
  end

  def test_exceptions
    assert_raise(StandardError) {
      PositionRange.from_s('4,,2')
    }

    assert_raise(PositionRange::Error) {
      PositionRange.new(4,2)
    }

    assert_raise(PositionRange::Error) {
      PositionRange.new(-1,3)
    }
  end

  def test_size
    assert_equal 4, PositionRange.new(1,4).size
  end

  def test_comparison
    p1 = PositionRange.new(1,3)
    p2 = PositionRange.new(2,3)
    assert p1 < p2

    p1 = PositionRange.new(1,3)
    p2 = PositionRange.new(1,2)
    assert p1 > p2

    p1 = PositionRange.new(1,3)
    p2 = PositionRange.new(1,3)
    assert p1 == p2
  end

  def test_has_equal_pointer_attributes
    p1 = PositionRange.new(1,3)
    p1.link = 'aa'
    p2 = PositionRange.new(7,13)
    p2.link = 'aa'
    p2.authorship = 3
    assert !p1.has_equal_pointer_attributes?(p2)
    p2.authorship = nil
    assert p1.has_equal_pointer_attributes?(p2)
    p2.link = 'ac'
    assert !p1.has_equal_pointer_attributes?(p2)
  end

  def test_new_dup
    p = PositionRange.new(1,3)
    p.authorship = 'a'
    p.link = 34

    pd = p.new_dup(4,6)

    assert_equal p.authorship, pd.authorship
    assert_equal p.link, pd.link
  end
end