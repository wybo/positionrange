#--#
# Copyright: (c) 2006-2009 The LogiLogi Foundation <foundation@logilogi.org>
#
# License:
#   This file is part of the PositionRange Library. PositionRange is Free 
#   Software. You can run/distribute/modify PositionRange under the terms 
#   of the GNU Lesser General Public License version 3. This license
#   states that you can use PositionRange in applications that are not Free 
#   Software but PositionRange itself remains Free Software. (LICENSE contains 
#   the full text of the legally binding license).
#++#
#
# This Error is raised if positions are out of range.

class PositionRange::Error < StandardError
  attr_accessor :from_range, :to_range

  def initialize(from_range, to_range)
    @from_range = from_range
    @to_range = to_range
  end

  def message
    super.to_s + ': ' + @from_range.to_s + ',' + @to_range.to_s
  end
end
