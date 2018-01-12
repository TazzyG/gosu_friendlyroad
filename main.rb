require 'gosu'
require 'defstruct'
require_relative 'vector'

GRAVITY = Vec[0, 600] #pixels/s^2
JUMP_VEL = Vec[0, -300] #pixels/s  - is up
OBSTACLE_SPEED = 200 #pixels/s, was pixels per frame
OBSTACLE_SPAWN_INTERVAL = 1.3 #seconds
OBSTACLE_GAP = 100 #pixels

Rect = DefStruct.new{{
	pos: Vec[0, 0], # x, y
	size: Vec[0 , 0] # width, height
	# rotation:, maybe later

	}}

# replace with vectors
# Obstacle = DefStruct.new{{
# 	y: 0,
# 	x: 0
# 	}}

GameState = DefStruct.new{{
	scroll_x: 0,
	player_pos: Vec[0,0],
	player_vel: Vec[0,0],
	obstacles: [], # array of Vec
	obstacle_countdown: OBSTACLE_SPAWN_INTERVAL,
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
		# when Gosu::KbO then spawn_obstacle
		end
	end

	def spawn_obstacle
		@state.obstacles << Vec[width, rand(50..350)]
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

		@state.obstacle_countdown -= dt
		if @state.obstacle_countdown <= 0 
			spawn_obstacle
			@state.obstacle_countdown += OBSTACLE_SPAWN_INTERVAL
		end
		@state.obstacles.each do |obst|
			obst.x -= dt*OBSTACLE_SPEED
		end
	end

	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(-@state.scroll_x, 350, 0)
		@images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 350, 0)
		
		@state.obstacles.each do |obst|
			img_y = @images[:obstacle].height
			#top obstacles
			@images[:obstacle].draw(obst.x, obst.y - img_y, 0)
			#bottom obstacles
			scale(1, -1) do
				@images[:obstacle].draw(obst.x, - height - img_y + (height - obst.y - OBSTACLE_GAP), 0)
			end
		end
		@images[:player].draw(20, @state.player_pos.y, 0)

		#draws the collison boxes
		debug_draw
	end

	def debug_draw
		draw_debug_rect(Rect.new( pos: Vec[100, 100], size: Vec[200, 300]))
	end

	def draw_debug_rect(rect)
		color = Gosu::Color::GREEN;
		x = rect.pos.x
		y = rect.pos.y
		w = rect.size.x
		h = rect.size.y
		points = [
			Vec[x, y],
			Vec[x + width, y],
			Vec[x + width, y + height],
			Vec[x, y + height]
		]

		points.each_with_index do |p1, idx|
			p2 = points[(idx + 1) % points.size]
			draw_line(p1.x, p1.y, color, p2.x, p2.y, color)
		end

	end
end

window = GameWindow.new(800, 600, false)
window.show

