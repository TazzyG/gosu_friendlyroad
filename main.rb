require 'gosu'

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@scroll_x = 0
		@background = Gosu::Image.new(self, 'Fall-Nature-Background-Pictures.jpg', false)
		@foreground = Gosu::Image.new(self, 'foreground.png', true)
		

	end
	def button_down(button)
		close if button == Gosu::KbEscape
	end

	def update
		@scroll_x += 3
		if @scroll_x > @foreground.width
			@scroll_x = 0
		end
	end

	def draw
		@background.draw(0, 0, 0)
		@foreground.draw(-@scroll_x, 350, 0)
		@foreground.draw(-@scroll_x + @foreground.width, 350, 0)
	end
end
window = GameWindow.new(800, 600, false)
window.show

