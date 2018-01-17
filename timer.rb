class Timer
	def initialize(interval)
		@interval = Float(interval) #constant
		@interval_remaining = @interval  #changes every frame
	end

	def update(seconds_elapsed)
		@interval_remaining -= seconds_elapsed
		while @interval_remaining <= 0
			yield
			@interval_remaining += @interval
		end
	end
end

# t = Timer.new(1.0/PLAYER_ANIMATION_FPS)

# t.update(dt) do

# end