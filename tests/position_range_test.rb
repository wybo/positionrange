#! /usr/bin/env ruby
#--#
# Copyright: (c) 2006-2008 The LogiLogi Foundation <foundation@logilogi.org>
#
# License:
#   This file is part of the PositionRange Library. PositionRange is free
#   software. You can run/distribute/modify PositionRange under the terms of
#   the GNU Affero General Public License version 3. The Affero GPL states
#   that running a modified version or a derivative work also requires you to
#   make the sourcecode of that work available to everyone that can interact
#   with it. We chose the Affero GPL to ensure that PositionRange remains open
#   and libre (doc/LICENSE.txt contains the full text of the legally binding
#   license).
#++#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'position_range'
require 'test/unit'

class PositionRangeTest < Test::Unit::TestCase
  ### Initialization

  def test_initialization
    p = PositionRange.new(2,6, :mooo => 88)
    assert_equal 2, p.first
    assert_equal 6, p.last
    assert_equal 88, p.mooo
  end

  def test_initialization_exceptions
    assert_raise(PositionRange::Error) {
      PositionRange.new(4,2)
    }
    assert_raise(PositionRange::Error) {
      PositionRange.new(-1,3)
    }
  end

  ### Parsing

  def test_parsing
    assert_equal PositionRange.new(1,4), PositionRange.from_s('1,4')
    assert_equal '1,3', PositionRange.new(1,3).to_s
  end

  def test_parsing_exceptions
    assert_raise(StandardError) {
      PositionRange.from_s('4,,2')
    }
  end

  ### Methods

  def test_define_attribute
    p = PositionRange.new(1,2, :kk => 0)
    assert p.respond_to?('kk')
    assert_equal ['kk'], p.attributes
    p.kk = 3
    assert_equal 3, p.kk
    p.lll = 5
    assert_equal ['kk','lll'], p.attributes
    p2 = PositionRange.new(1,2)
    assert_equal ['kk','lll'], p2.attributes
  end

  def test_dynamic_attributes
    p = PositionRange.new(1,3,:blah => 2)
    assert_equal 2, p.blah
    k = PositionRange.new(2,44,:blah => 7)
    assert_equal 7, k.blah
    assert_equal 2, p.blah
  end

  def test_size
    assert_equal 3, PositionRange.new(1,4).size
  end

  def test_new_dup
    p = PositionRange.new(1,3)
    p.authorship = 'a'
    p.link = 34

    pd = p.new_dup(4,6)

    assert_equal p.authorship, pd.authorship
    assert_equal p.link, pd.link
  end

  def test_substraction
    p1 = PositionRange.new(11,20)
    p2 = PositionRange.new(16,25)
    assert_equal PositionRange.new(11,16), p1 - p2

    p3 = PositionRange.new(10,11)
    assert_equal PositionRange.new(11,20), p1 - p3

    p4 = PositionRange.new(19,21)
    assert_equal PositionRange.new(11,19), p1 - p4

    p5 = p1.dup
    assert_equal nil, p1 - p5

    p6 = PositionRange.new(30,80)
    assert_equal p1, p1 - p6

    p7 = PositionRange.new(2,4)
    p8 = PositionRange.new(3,4)
    assert_equal PositionRange.new(2,3), p7 - p8
  end

  def test_eq_eq_eq
    p1 = PositionRange.new(1,5)
    p2 = PositionRange.new(4,10)
    assert p1 === p2

    p3 = PositionRange.new(2,3)
    assert p1 === p3

    p4 = PositionRange.new(15,90)
    assert !(p1 === p4)
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
end
