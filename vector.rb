## RUBY 
# def Vector.[](*array)
#   new convert_to_array(array, false)
# end

# Lesson
Vec = Struct.new(:x, :y) do
	def set!(other)
		self.x = other.x
		self.y = other.y
		self
	end

	def +(other)
		Vec[x + other.x, y + other.y]
	end

	def -(other)
		Vec[x - other.x, y - other.y]
	end

	def *(scalar)
		Vec[x*scalar, y*scalar]
	end

	def -@
		Vec[-x, -y]
	end

	# Ruby does not know how to muliply vectors, need to reverse the multiplication eg vector x 5, instead of 5 * vector 
	def coerce(left)
		[self, left]
	end

end

