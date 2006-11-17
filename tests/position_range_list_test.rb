#! /usr/bin/env ruby
#
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

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'position_range/list'
require 'test/unit'

class PositionRangeListTest < Test::Unit::TestCase
  # Parsing & Creating

  def test_parsing
    assert_equal PositionRange::List.new([PositionRange.new(2,8)]),
        PositionRange::List.from_s('2,8')
    assert_equal PositionRange::List.new([PositionRange.new(1,2),PositionRange.new(1,5),
        PositionRange.new(3,4)]),PositionRange::List.from_s('1,2:1,5:3,4')
    assert_equal PositionRange::List.new([PositionRange.new(1,1),PositionRange.new(1,3),
        PositionRange.new(3,3)]),PositionRange::List.from_s('1,1:1,3:3,3')
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('')

    assert_equal '1,3:4,6',
        PositionRange::List.new([PositionRange.new(1,3),PositionRange.new(4,6)]).to_s
    assert_equal '',
        PositionRange::List.new.to_s

    assert_raise(StandardError) {
      PositionRange::List.from_s('1,2-3,4')
    }
  end

  def test_new_for
    assert_equal PositionRange::List.from_s('0,4'),
        PositionRange::List.new_around('12345')
    assert_equal PositionRange::List.from_s('0,2'),
        PositionRange::List.new_around([1,2,3])
    assert_equal PositionRange::List.new,
        PositionRange::List.new_around('')
  end

  # Getters

  def test_range_size
    assert_equal 7, PositionRange::List.from_s('2,4:5,8').range_size
    assert_equal 11, PositionRange::List.from_s('1,4:22,24:5,8').range_size
    assert_equal 0, PositionRange::List.new.range_size
  end

  def test_within
    assert PositionRange::List.from_s('1,3:5,6').within?(
        PositionRange::List.from_s('0,8'))
    assert PositionRange::List.from_s('1,3:5,6').within?(
        PositionRange::List.from_s('1,6'))
    assert PositionRange::List.from_s('5,6:1,3').within?(
        PositionRange::List.from_s('1,6'))

    assert_equal false,
        PositionRange::List.from_s('5,7:1,3').within?(
            PositionRange::List.from_s('1,6'))
    assert_equal false,
        PositionRange::List.from_s('0,408:500,520').within?(
            PositionRange::List.from_s('0,519'))
  end

  def test_below
    assert PositionRange::List.from_s('1,3:5,6').below?(7)
    assert PositionRange::List.from_s('0,408:500,520').below?(521)
    assert_equal false,
        PositionRange::List.from_s('0,408:500,520').below?(520)
  end

  # Lowlevel methods

  def test_merge_adjacents
    # same pointer attributes
    assert_equal PositionRange::List.from_s('2,8'),
        PositionRange::List.from_s('2,4:5,8').merge_adjacents!

    assert_equal PositionRange::List.from_s('2,4:6,13'),
        PositionRange::List.from_s('2,4:6,9:10,13').merge_adjacents!

    assert_equal PositionRange::List.from_s('2,4:6,13'),
        PositionRange::List.from_s('6,9:2,4:10,13').merge_adjacents!

    assert_equal PositionRange::List.from_s('1,3'),
        PositionRange::List.from_s('1,1:2,2:3,3').merge_adjacents!

    # different pointer attributes
    p1 = PositionRange.new(2,4,:link => :a)
    p2 = PositionRange.new(5,8,:link => :b)
    assert_equal PositionRange::List.from_s('2,4:5,8'),
        PositionRange::List.new([p1,p2]).merge_adjacents!

    assert_equal PositionRange::List.from_s('2,8'),
        PositionRange::List.new([p1,p2]).merge_adjacents!(:ignore_attributes)

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.merge_adjacents!
  end

  def test_invert
    # default maximum size
    assert_equal PositionRange::List.from_s('0,4:16,' + (PositionRange::MaximumSize - 1).to_s),
        PositionRange::List.from_s('5,15').invert!
    assert_equal PositionRange::List.from_s('2,4:16,' + (PositionRange::MaximumSize - 1).to_s),
        PositionRange::List.from_s('0,1:5,15').invert!
    assert_equal PositionRange::List.from_s('16,' + (PositionRange::MaximumSize - 1).to_s),
        PositionRange::List.from_s('0,4:5,15').invert!

    # epecified maximum size
    assert_equal PositionRange::List.from_s('0,4:6,17:21,27'),
        PositionRange::List.from_s('5,5:18,20:28,50').invert!(50)
    assert_equal PositionRange::List.from_s('0,4:6,17:21,27:51,54'),
        PositionRange::List.from_s('5,5:18,20:28,50').invert!(55)

    # empty stuff
    assert_equal PositionRange::List.from_s('0,54'),
        PositionRange::List.new.invert!(55)
    assert_equal PositionRange::List.new,
        PositionRange::List.new.invert!(0)
  end

  def test_substract
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('2,7') - 
            PositionRange::List.from_s('1,8')
    assert_equal PositionRange::List.from_s('3,5:8,11'),
        PositionRange::List.from_s('1,15') - 
            PositionRange::List.from_s('1,2:6,7:12,20')

    assert_equal PositionRange::List.from_s('1,2:10,11'),
        PositionRange::List.from_s('1,5:7,11') -
            PositionRange::List.from_s('3,9')

    assert_equal PositionRange::List.from_s('1,2:8,8:13,15:20,20'),
        PositionRange::List.from_s('1,3:7,9:13,15:19,21') -
            PositionRange::List.from_s('3,7:9,10:18,19:21,50')

    assert_equal PositionRange::List.from_s('1,2:7,8'),
        PositionRange::List.from_s('1,5:4,8') -
            PositionRange::List.from_s('3,6')

    assert_equal PositionRange::List.from_s('10,13'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('0,9:14,200000')

    assert_equal PositionRange::List.from_s('3,5:10,16'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('21,2147483647')

    assert_equal PositionRange::List.from_s('3,5'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('6,2147483647')

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('2,5') -
            PositionRange::List.from_s('2,5')
    assert_equal PositionRange::List.new,
        PositionRange::List.new -
            PositionRange::List.from_s('2,3')
    assert_equal PositionRange::List.new,
        PositionRange::List.new -
            PositionRange::List.new

    # attributes
    p1 = PositionRange.new(1,5,:attr => 1)
    p2 = PositionRange.new(1,5,:attr => 2)
    assert_equal PositionRange::List.new([p1]),
        PositionRange::List.new([p1]) - PositionRange::List.new([p2])

    assert_equal PositionRange::List.new(),
        PositionRange::List.new([p1]).substract!(
            PositionRange::List.new([p2]),:ignore_attributes)
  end

  def test_delete
    assert_equal PositionRange::List.from_s('1,2:7,8'),
        PositionRange::List.from_s('1,5:4,8').delete(PositionRange.new(3,6))
  end

  def test_intersect
    assert_equal PositionRange::List.from_s('3,5:8,11'),
        PositionRange::List.from_s('1,5:8,17') &
            PositionRange::List.from_s('3,11')

    assert_equal PositionRange::List.from_s('10,13'),
        PositionRange::List.from_s('3,5:10,16') &
            PositionRange::List.from_s('10,13')

    assert_equal PositionRange::List.from_s('4,11:13,21:22,29:35,42:62,68:342,349:357,360'),
        PositionRange::List.from_s('4,11:13,21:22,29:35,42:62,68:342,349:357,360:410,420') &
            PositionRange::List.from_s('0,408')

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('3,7') &
            PositionRange::List.from_s('200,205')
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('4,77') &
            PositionRange::List.new
    assert_equal PositionRange::List.new,
        PositionRange::List.new & 
            PositionRange::List.new
  end

  def test_line_up_overlaps
    assert_equal PositionRange::List.from_s('0,1:2,6:2,6:7,8'),
        PositionRange::List.from_s('2,6:0,8').line_up_overlaps!
    assert_equal PositionRange::List.from_s('1,2:1,2:10,13:14,18:14,18:20,23'),
        PositionRange::List.from_s('1,2:1,2:10,18:14,18:20,23').line_up_overlaps!

    p = PositionRange::List.new([
            PositionRange.new(5,8, :link => :a),
            PositionRange.new(0,15, :authorship => 1),
            PositionRange.new(11,30, :authorship => :c)])

    output = PositionRange::List.new([
             PositionRange.new(0,4, :authorship => 1),
             PositionRange.new(5,8, :link => :a),
             PositionRange.new(5,8, :authorship => 1),
             PositionRange.new(9,10, :authorship => 1),
             PositionRange.new(11,15, :authorship => 1),
             PositionRange.new(11,15, :authorship => :c),
             PositionRange.new(16,30, :link => :c)])

    assert_equal output, p.line_up_overlaps!

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.line_up_overlaps!
  end

  def test_translate
    p = PositionRange::List.from_s('10,13:16,18')
    p2 = p.dup

    assert_equal PositionRange::List.from_s('13,16:19,21'),
        p.translate!(3)
    assert_equal PositionRange::List.from_s('8,11:14,16'),
        p2.translate!(-2)

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.translate!(5)
  end

  def test_insert_at_ranges
    # Without skipping
    assert_equal PositionRange::List.from_s('0,10:50,59:15,20'),
        PositionRange::List.from_s('0,10:15,20').insert_at_ranges!(
            PositionRange::List.from_s('50,59'),
            PositionRange::List.from_s('11,20'))

    # With skipping
    assert_equal PositionRange::List.from_s('39,48:100,102:6,7:16,20'),
        PositionRange::List.from_s('39,48:16,20').insert_at_ranges!(
            PositionRange::List.from_s('100,102:6,7'),
            PositionRange::List.from_s('10,12:19,20'),
            PositionRange::List.from_s('13,18'))

    # With multiple elements in one range to insert at
    assert_equal PositionRange::List.from_s('0,10:35,36:33,34:15,20'),
        PositionRange::List.from_s('0,10:15,20').insert_at_ranges!(
            PositionRange::List.from_s('35,36:33,34'),
            PositionRange::List.from_s('11,14'))

    # With cutting
    assert_equal PositionRange::List.from_s('0,7:50,63:8,10:15,20'),
        PositionRange::List.from_s('0,10:15,20').insert_at_ranges!(
            PositionRange::List.from_s('50,63'),
            PositionRange::List.from_s('8,21'))

    assert_equal PositionRange::List.from_s('0,100:430,480:101,408:500,519'),
        PositionRange::List.from_s('0,408:500,519').insert_at_ranges!(
            PositionRange::List.from_s('430,480'),
            PositionRange::List.from_s('159,209'),
            PositionRange::List.from_s('101,158'))
  end

  def test_stack_adjacent
    assert_equal PositionRange::List.from_s('0,3:4,23'),
        PositionRange::List.from_s('50,53:11,30').stack_adjacent
  end

  # Highlevel methods

  def test_translate_to_view
    p = PositionRange::List.from_s('3,5:10,16')
    # basic transition
    assert_equal PositionRange::List.from_s('2,4:9,15'),
        p.translate_to_view(PositionRange::List.from_s('1,20'))
    # chop off the end
    assert_equal PositionRange::List.from_s('2,4:9,10'),
        p.translate_to_view(PositionRange::List.from_s('1,11'))
    # chop off first snippet
    assert_equal PositionRange::List.from_s('3,4'),
        p.translate_to_view(PositionRange::List.from_s('7,11'))
    # two snippets into one
    assert_equal PositionRange::List.from_s('2,8'),
        p.translate_to_view(PositionRange::List.from_s('1,5:10,13'))
    # last before the first
    assert_equal PositionRange::List.from_s('3,9:17,19'),
        p.translate_to_view(PositionRange::List.from_s('7,20:0,6'))

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.translate_to_view(
            PositionRange::List.from_s('5,8'))
  end

  def test_translate_from_view
    p = PositionRange::List.from_s('3,5:10,16')
    # basic transition
    assert_equal PositionRange::List.from_s('13,15:20,26'),
      p.translate_from_view(PositionRange::List.from_s('10,30'))
    # different samples
    assert_equal PositionRange::List.from_s('8,10:35,41'),
      p.translate_from_view(PositionRange::List.from_s('5,12:33,50'))
    # splitting into different abs position-ranges
    assert_equal PositionRange::List.from_s('3,5:35,38:50,52'),
      p.translate_from_view(PositionRange::List.from_s('0,5:31,38:50,90'))
    # last before the first
    assert_equal PositionRange::List.from_s('2,8:203,205'),
      p.translate_from_view(PositionRange::List.from_s('200,207:0,30'))

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.translate_from_view(
            PositionRange::List.from_s('5,8'))
  end

  def test_cluster_overlaps
    p = PositionRange::List.from_s('1,2:1,2:10,18:14,18:20,23')
    output = [
        PositionRange::List.from_s('1,2:1,2'),
        PositionRange::List.from_s('10,13'),
        PositionRange::List.from_s('14,18:14,18'),
        PositionRange::List.from_s('20,23')
      ]
    assert_equal output, p.cluster_overlaps

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.cluster_overlaps
  end

  def test_apply_to_string
    p = PositionRange::List.from_s('4,6:8,8:0,2')
    assert_equal '5679123', p.apply_to_string('123456789')

    p = PositionRange::List.from_s('0,408:500,520')
    assert_equal 'a' * p.range_size, p.apply_to_string('a' * 521)

    # empty
    assert_equal '', PositionRange::List.new.apply_to_string('12345')
  end
end
