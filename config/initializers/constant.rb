# add some useful functions to the array class
class Array
  def sum
    inject( 0.0 ) { |sum,x| sum ? sum+x : x }
  end

  def mean
    size == 0 ? nil : sum / size
  end

  def median
    if size == 0
      nil
    elsif size == 1
      self[0]
    elsif size % 2 == 1
      (self.sort)[size/2]
    else
      ((self.sort)[size/2] + (self.sort)[(size/2)-1]) / 2.0
    end
  end

  def std
    mu = mean
    (size < 2) ? 0.0 : Math.sqrt(inject(0.0){ |sum,x| sum + (x-mu)**2 } / size)
  end

  def rmse
    if size == 0
      0.0
    elsif size == 1
      self[0].abs
    else
      Math.sqrt(self.collect{ |v| v**2 }.mean)
    end
  end
end

