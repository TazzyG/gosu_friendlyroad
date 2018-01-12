require 'gosu'
require 'defstruct'
require_relative 'vector'

GRAVITY = Vec[0, 600] #pixels/s^2
JUMP_VEL = Vec[0, -300] #pixels/s  - is up
OBSTACLE_SPEED = 200 #pixels/s, was pixels per frame

# replace with vectors
# Obstacle = DefStruct.new{{
# 	y: 0,
# 	x: 0
# 	}}

GameState = DefStruct.new{{
	scroll_x: 0,
	player_pos: Vec[0,0],
	player_vel: Vec[0,0],
	obstacles: [] # array of Vec
	}}

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@images = {
			background: Gosu::Image.new(self, 'images/Fall-Nature-Background-Pictures.jpg', false),
			foreground: Gosu::Image.new(self, 'images/foreground.png', true),
			player: Gosu::Image.new(self, 'images/Bird1.png', false),
			obstacle: Gosu::Image.new(self, 'images/obstacle.png', false)
		}
		@state = GameState.new
	end

	def button_down(button)
		case button
		when Gosu::KbEscape then close
		when Gosu::KbSpace then @state.player_vel.set!(JUMP_VEL)
		when Gosu::KbO then spawn_obstacle
		end
	end

	def spawn_obstacle
		@state.obstacles << Vec[width, 200]
	end

	def update
		dt = (update_interval / 1000.0)

		@state.scroll_x += dt*OBSTACLE_SPEED*0.5
		if @state.scroll_x > @images[:foreground].width
			@state.scroll_x = 0
		end
		# delta time
		
		@state.player_vel += dt * GRAVITY
		# puts @state.player_y_vel
		@state.player_pos +=  dt * @state.player_vel
		@state.obstacles.each do |obst|
			obst.x -= dt*OBSTACLE_SPEED
		end
	end

	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(-@state.scroll_x, 350, 0)
		@images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 350, 0)
		@images[:player].draw(20, @state.player_pos.y, 0)
		@state.obstacles.each do |obst|
			@images[:obstacle].draw(obst.x, -400, 0)
			scale(1, -1) do
				@images[:obstacle].draw(obst.x, -height - 520, 0)
			end
		end
	end
end
window = GameWindow.new(800, 600, false)
window.show

