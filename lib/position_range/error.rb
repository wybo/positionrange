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
