class Version
  def initialize(version_string)
    @version_array = version_string.split('.').map(&:to_i)
  end

  def major
    @version_array[0]
  end

  def minor
    @version_array[1]
  end

  def patch
    @version_array[2]
  end

  # returns the larger semantic version
  def compare_to(other)
    if major > other.major
      self
    elsif other.major > major
      other
    elsif minor > other.minor
      self
    elsif other.minor > minor
      other
    elsif patch > other.patch
      self
    elsif other.patch > patch
      other
    end
  end
end
