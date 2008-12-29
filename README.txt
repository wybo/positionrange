= Position Range -- Ranges with attributes that can be juggled

Allows you to assign random attributes to ranges and juggle them in
lists. Also adds parsing from string, but most intereting when used in
a PositionRange::List.

There standard set operations can be applied to it, like additions,
substractions and intersections. In addition you can also get the
combined size of all the ranges in the list. And cluster overlapping
ranges, maintaining the attributes (more below).

PositionRange is a library by the LogiLogi Foundation, extracted from
http://www.logilogi.org (http://foundation.logilogi.org).

== Usage

You can assign random attributes to PositionRanges.

  r = PositionRange.new(1,10, :cow => 'moo')

  r.cow => 'moo'

You can also create a PositionRange::List directly from a string.

  l = PositionRange::List.from_s('0,10:5,15')

Then you can get the combined size.

  l.range_size => 20

Or line up overlaps.

  l.line_up_overlaps!.to_s => '0,5:5,10:5,10:10,15'

Clustering overlaps maintains attributes.

  l = PositionRange::List.new([
        PositionRange.new(0,10, :cow => 'moo'),
        PositionRange.new(5,15, :goat => 7)
      ])

  l.cluster_overlaps => [
        PositionRange::List.new([
            PositionRange.new(0,5, :cow => 'moo')]),
        PositionRange::List.new([
            PositionRange.new(5,10, :cow => 'moo'),
            PositionRange.new(5,10, :goat => 7)]),
        PositionRange::List.new([
            PositionRange.new(10,15, :goat => 7)])
      ]

== Download

The latest version of Position Range can be found at:

* http://rubyforge.org/frs/?group_id=7564

Documentation can be found at:

* http://positionrange.rubyonrails.org

== Installation

You can install Position Range with the following command:

  % [sudo] gem install positionrange

Or from its distribution directory with:

  % [sudo] ruby install.rb

== License

Position Range is released under the GNU Affero GPL licence.

* http://www.fsf.org/licensing/licenses/agpl-3.0.html

== Support

The Position Range homepage is http://positionrange.rubyforge.org.

For the latest news on Position Range:

* http://foundation.logilogi.org/tags/PositionRange

Feel free to submit commits or feature requests. If you send a patch,
remember to update the corresponding unit tests.
