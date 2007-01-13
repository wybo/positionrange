#--#
# Author: Wybo Wiersma <wybo@logilogi.org>
#
# Copyright: (c) 2006 Wybo Wiersma
#
# License:
#   This file is part of the PositionRange library. PositionRange is free software. 
#   You can run/distribute/modify/link PositionRange under the terms of the GNU 
#   General Public License version 3, or any later version, with the extra copyleft 
#   provision (covered by subsection 7b of the GPL v3) that running a modified version 
#   or a derivative work also requires you to make the sourcecode of that work
#   available to everyone that can interact with it, this to ensure that PositionRange
#   remains open and libre (doc/LICENSE.txt contains the full text of the legally
#   binding license, including that of the extra restrictions).
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
