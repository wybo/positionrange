#--#
# Copyright: (c) 2006-2008 The LogiLogi Foundation <foundation@logilogi.org>
#
# License:
#   This file is part of the PositionRange Library. PositionRange is Free
#   Software. You can run/distribute/modify PositionRange under the terms of
#   the GNU Affero General Public License version 3. The Affero GPL states
#   that running a modified version or a derivative work also requires you to
#   make the sourcecode of that work available to everyone that can interact
#   with it. We chose the Affero GPL to ensure that PositionRange remains open
#   and libre (LICENSE.txt contains the full text of the legally binding
#   license).
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
