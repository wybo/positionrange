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

require 'position_range/list'
require 'test/unit'

class PositionRangeListTest < Test::Unit::TestCase
  ### Parsing & Creating

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

  def test_new_around
    assert_equal PositionRange::List.from_s('0,5'),
        PositionRange::List.new_around('12345')
    assert_equal PositionRange::List.from_s('0,3'),
        PositionRange::List.new_around([1,2,3])
    assert_equal PositionRange::List.new,
        PositionRange::List.new_around('')
  end

  ### Getters

  def test_range_size
    assert_equal 5, PositionRange::List.from_s('2,4:5,8').range_size
    assert_equal 8, PositionRange::List.from_s('1,4:22,24:5,8').range_size
    assert_equal 0, PositionRange::List.new.range_size
  end

  def test_below
    assert PositionRange::List.from_s('1,3:5,6').below?(7)
    assert PositionRange::List.from_s('0,408:500,520').below?(520)
    assert_equal false,
        PositionRange::List.from_s('0,408:500,520').below?(519)
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

  def test_index
    p = PositionRange::List.from_s('1,5:7,9')
    assert_equal 0, p.index(PositionRange.new(1,5))
    assert_equal 1, p.index(PositionRange.new(7,9))

    assert_equal nil, p.index(PositionRange.new(7,9,:attrobo => 1),
        :dont_ignore_attributes => true)

    p = PositionRange::List.new([PositionRange.new(1,5,:attrobo => 1),
        PositionRange.new(1,5,:attrobo => 2)])
    assert_equal 0, p.index(PositionRange.new(1,5,:attrobo => 2))
    assert_equal 1, p.index(PositionRange.new(1,5,:attrobo => 2),
        :dont_ignore_attributes => true)
  end

  ### Lowlevel methods

  def test_intersection
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

  def test_substract
    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('2,7') -
            PositionRange::List.from_s('1,8')

    assert_equal PositionRange::List.from_s('2,6:7,12'),
        PositionRange::List.from_s('1,15') -
            PositionRange::List.from_s('1,2:6,7:12,20')

    assert_equal PositionRange::List.from_s('1,2:5,8'),
        PositionRange::List.from_s('1,8') -
            PositionRange::List.from_s('2,5')

    assert_equal PositionRange::List.from_s('1,3:9,11'),
        PositionRange::List.from_s('1,5:7,11') -
            PositionRange::List.from_s('3,9')

    assert_equal PositionRange::List.from_s('1,2:8,9:13,15:20,21'),
        PositionRange::List.from_s('1,3:7,9:13,15:19,21') -
            PositionRange::List.from_s('2,8:10,11:18,20:21,50')

    assert_equal PositionRange::List.from_s('1,3:6,8'),
        PositionRange::List.from_s('1,5:4,8') -
            PositionRange::List.from_s('3,6')

    assert_equal PositionRange::List.from_s('10,14'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('0,10:14,200000')

    assert_equal PositionRange::List.from_s('3,5:10,16'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('21,2147483647')

    assert_equal PositionRange::List.from_s('3,5'),
        PositionRange::List.from_s('3,5:10,16') -
            PositionRange::List.from_s('6,2147483647')

    assert_equal PositionRange::List.new,
        PositionRange::List.from_s('5,15:16,25') -
            PositionRange::List.from_s('5,15:16,25:10,20')

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
            PositionRange::List.new([p2]),:ignore_attributes => true)

    old = PositionRange::List.from_s('5,15:16,25')
    new = old.dup << PositionRange.new(10,20, :attr => 5)
    assert_equal PositionRange::List.new, old - new
  end

  def test_delete
    assert_equal PositionRange::List.from_s('1,3:6,8'),
        PositionRange::List.from_s('1,5:4,8').delete(PositionRange.new(3,6))
  end

  def test_invert
    # default maximum size
    assert_equal PositionRange::List.from_s('0,5:15,' + PositionRange::MaximumSize.to_s),
        PositionRange::List.from_s('5,15').invert!
    assert_equal PositionRange::List.from_s('1,5:15,' + PositionRange::MaximumSize.to_s),
        PositionRange::List.from_s('0,1:5,15').invert!
    assert_equal PositionRange::List.from_s('15,' + PositionRange::MaximumSize.to_s),
        PositionRange::List.from_s('0,5:5,15').invert!

    # specified maximum size
    assert_equal PositionRange::List.from_s('0,5:6,17:21,27'),
        PositionRange::List.from_s('5,6:17,21:27,50').invert!(50)
    assert_equal PositionRange::List.from_s('0,5:6,17:21,27:50,55'),
        PositionRange::List.from_s('5,6:17,21:27,50').invert!(55)

    # empty stuff
    assert_equal PositionRange::List.from_s('0,55'),
        PositionRange::List.new.invert!(55)
    assert_equal PositionRange::List.new,
        PositionRange::List.new.invert!(0)
  end

  def test_line_up_overlaps
    assert_equal PositionRange::List.from_s('0,2:2,6:2,6:6,8'),
        PositionRange::List.from_s('2,6:0,8').line_up_overlaps!
    assert_equal PositionRange::List.from_s('1,2:1,2:10,14:14,18:14,18:20,23'),
        PositionRange::List.from_s('1,2:1,2:10,18:14,18:20,23').line_up_overlaps!

    p = PositionRange::List.new([
            PositionRange.new(5,8, :link => :a),
            PositionRange.new(0,15, :authorship => 1),
            PositionRange.new(10,30, :authorship => :c)])

    output = PositionRange::List.new([
             PositionRange.new(0,5, :authorship => 1),
             PositionRange.new(5,8, :link => :a),
             PositionRange.new(5,8, :authorship => 1),
             PositionRange.new(8,10, :authorship => 1),
             PositionRange.new(10,15, :authorship => 1),
             PositionRange.new(10,15, :authorship => :c),
             PositionRange.new(15,30, :link => :c)])

    assert_equal output, p.line_up_overlaps!

    # ender
    p = PositionRange::List.new([
            PositionRange.new(28,38, :lo => 1),
            PositionRange.new(31,38, :la => 2),
            PositionRange.new(33,38, :lu => 3)])

    output = PositionRange::List.new([
        PositionRange.new(28,31, :lo => 1),
        PositionRange.new(31,33, :la => 2),
        PositionRange.new(31,33, :lo => 1),
        PositionRange.new(33,38, :lu => 3),
        PositionRange.new(33,38, :la => 2),
        PositionRange.new(33,38, :lo => 1)])

    assert_equal output, p.line_up_overlaps!

    # middler
    p = PositionRange::List.new([
            PositionRange.new(43,61, :lo => 1),
            PositionRange.new(45,58, :la => 2),
            PositionRange.new(48,58, :lu => 3)])
 
    p = PositionRange::List.from_s('43,61:45,58:48,58')
    output = PositionRange::List.new([
        PositionRange.new(43,45, :lo => 1),
        PositionRange.new(45,48, :la => 2),
        PositionRange.new(45,48, :lo => 1),
        PositionRange.new(48,58, :lu => 3),
        PositionRange.new(48,58, :la => 2),
        PositionRange.new(48,58, :lo => 1),
        PositionRange.new(58,61, :lo => 1)])

    assert_equal output, p.line_up_overlaps!

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.line_up_overlaps!
  end

  def test_merge_adjacents
    # same pointer attributes
    assert_equal PositionRange::List.from_s('2,8'),
        PositionRange::List.from_s('2,4:4,8').merge_adjacents!

    assert_equal PositionRange::List.from_s('2,4:6,13'),
        PositionRange::List.from_s('2,4:6,10:10,13').merge_adjacents!

    assert_equal PositionRange::List.from_s('6,9:2,4:10,13'),
        PositionRange::List.from_s('6,9:2,4:10,13').merge_adjacents!

    assert_equal PositionRange::List.from_s('1,4'),
        PositionRange::List.from_s('1,2:2,3:3,4').merge_adjacents!

    # different pointer attributes
    p1 = PositionRange.new(2,5,:link => :a)
    p2 = PositionRange.new(5,8,:link => :b)
    assert_equal PositionRange::List.from_s('2,5:5,8'),
        PositionRange::List.new([p1,p2]).merge_adjacents!

    assert_equal PositionRange::List.from_s('2,8'),
        PositionRange::List.new([p1,p2]).merge_adjacents!(:ignore_attributes => true)

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.merge_adjacents!
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
    assert_equal PositionRange::List.from_s('39,49:100,102:6,7:16,20'),
        PositionRange::List.from_s('39,49:16,20').insert_at_ranges!(
            PositionRange::List.from_s('100,102:6,7'),
            PositionRange::List.from_s('10,12:19,20'),
            PositionRange::List.from_s('12,19'))

    # with multiple elements in one range to insert at
    assert_equal PositionRange::List.from_s('0,10:35,36:33,34:15,20'),
        PositionRange::List.from_s('0,10:15,20').insert_at_ranges!(
            PositionRange::List.from_s('35,36:33,34'),
            PositionRange::List.from_s('10,12'))

    # with cutting
    assert_equal PositionRange::List.from_s('0,8:50,63:8,10:15,20'),
        PositionRange::List.from_s('0,10:15,20').insert_at_ranges!(
            PositionRange::List.from_s('50,63'),
            PositionRange::List.from_s('8,21'))

    assert_equal PositionRange::List.from_s('0,100:430,480:100,408:500,519'),
        PositionRange::List.from_s('0,408:500,519').insert_at_ranges!(
            PositionRange::List.from_s('430,480'),
            PositionRange::List.from_s('159,209'),
            PositionRange::List.from_s('100,159'))

    # the cut-bug
    assert_equal PositionRange::List.from_s('0,750:100,150:20,30:150,190:40,50:190,250'),
        PositionRange::List.from_s('0,750:100,250').insert_at_ranges!(
            PositionRange::List.from_s('20,30:40,50'),
            PositionRange::List.from_s('800,810:850,860'))
  end

  ### Highlevel methods

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
    assert_equal PositionRange::List.from_s('2,7'),
        p.translate_to_view(PositionRange::List.from_s('1,5:10,13'))
    # last before the first
    assert_equal PositionRange::List.from_s('3,9:16,18'),
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
    assert_equal PositionRange::List.from_s('8,10:36,42'),
      p.translate_from_view(PositionRange::List.from_s('5,12:33,50'))
    # splitting into different abs position-ranges
    assert_equal PositionRange::List.from_s('3,5:35,38:50,53'),
      p.translate_from_view(PositionRange::List.from_s('0,5:30,38:50,90'))
    # last before the first
    assert_equal PositionRange::List.from_s('203,205:3,9'),
      p.translate_from_view(PositionRange::List.from_s('200,207:0,30'))

    # swapped
    p = PositionRange::List.from_s('5,6:1,2')
    assert_equal PositionRange::List.from_s('6,7:2,3'),
      p.translate_from_view(PositionRange::List.from_s('1,8'))

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.translate_from_view(
            PositionRange::List.from_s('5,8'))
  end

  def test_stack_adjacent
    assert_equal PositionRange::List.from_s('0,3:3,23'),
        PositionRange::List.from_s('50,53:10,30').stack_adjacent

    # with space inbetween
    assert_equal PositionRange::List.from_s('0,3:4,24'),
        PositionRange::List.from_s('50,53:10,30').stack_adjacent(:space => 1)
  end

  def test_cluster_overlaps
    p = PositionRange::List.from_s('1,2:1,2:10,18:14,18:20,23')
    output = [
        PositionRange::List.from_s('1,2:1,2'),
        PositionRange::List.from_s('10,14'),
        PositionRange::List.from_s('14,18:14,18'),
        PositionRange::List.from_s('20,23')
      ]
    assert_equal output, p.cluster_overlaps

    # empty
    assert_equal PositionRange::List.new,
        PositionRange::List.new.cluster_overlaps
  end

  def test_apply_to_string
    p = PositionRange::List.from_s('4,6:8,9:0,2')
    assert_equal '56912', p.apply_to_string('123456789')

    p = PositionRange::List.from_s('0,408:500,520')
    assert_equal 'a' * p.range_size, p.apply_to_string('a' * 520)

    # with separator
    p = PositionRange::List.from_s('0,5:5,10')
    assert_equal 'aaaaa&bbbbb', p.apply_to_string('aaaaabbbbb', :separator => '&')
    assert_equal 'aaaaa%&bbbbb', p.apply_to_string('aaaaabbbbb', :separator => '%&')

    # empty
    assert_equal '', PositionRange::List.new.apply_to_string('12345')
  end
end
