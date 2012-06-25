# Position Range
  "Ranges with attributes that can be juggled"

Allows one to assign random attributes to ranges and juggle them in
lists. Also adds parsing from string, but most interesting when used in
a PositionRange::List.

In lists standard set operations can be applied to them, like
addition, substraction and intersection. In addition one can also get the
combined size of all the ranges in the list. And cluster overlapping
ranges, maintaining the attributes (more below).

PositionRange is a library by the LogiLogi Foundation, extracted from
http://www.logilogi.org (http://foundation.logilogi.org).

## Usage

First require it.

  $ irb

  > require 'rubygems'
  > require 'positionrange'

You can assign random attributes to PositionRanges.

  > r = PositionRange.new(1,10, :cow => 'moo')
  => 1...10
  > r.cow
  => "moo"

You can also create a PositionRange::List directly from a string.

  > l = PositionRange::List.from_s('0,10:5,15')
  => [0...10, 5...15]

Then you can get the combined size.

  > l.range_size 
  => 20

Or line up overlaps.

  > l.line_up_overlaps!.to_s 
  => "0,5:5,10:5,10:10,15"

Clustering overlaps maintains attributes.

  > l = PositionRange::List.new([
              PositionRange.new(0,10, :cow => 'moo'),
              PositionRange.new(5,15, :goat => 7)
            ])
  => [0...10, 5...15]

  > output = [
        PositionRange::List.new([
            PositionRange.new(0,5, :cow => 'moo')]),
        PositionRange::List.new([
            PositionRange.new(5,10, :cow => 'moo'),
            PositionRange.new(5,10, :goat => 7)]),
        PositionRange::List.new([
            PositionRange.new(10,15, :goat => 7)])
      ]
  => [[0...5], [5...10, 5...10], [10...15]]
 
  > l.cluster_overlaps == output
  => true

## Installation

Add this line to your application's Gemfile:

    gem 'positionrange'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install positionrange

Feel free to report issues and to ask questions. For the latest news on
PositionRange:

* http://foundation.logilogi.org/tags/PositionRange

## Contributing

If you wish to contribute, please create a pull-request and remember to update
the corresponding unit test(s).

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
