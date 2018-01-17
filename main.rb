require 'gosu'
require_relative 'defstruct'
require_relative 'vector'
require_relative 'timer'
require_relative 'animation'

# Contstants
PLAYER_ANIMATION_FPS = 5.0 #frames/second
GRAVITY = Vec[0, 600] #pixels/s^2
JUMP_VEL = Vec[0, -300] #pixels/s  - is up
OBSTACLE_SPAWN_INTERVAL = 1.3 #seconds
DEATH_VELOCITY = Vec[50, -500] #pixels/s
DEATH_ROTATIONAL_VEL =  360 # degrees/s
RESTART_INTERVAL = 3 # seconds
PLAYER_FRAMES = [:player1, :player2, :player3]
DIFFICULTIES = {
  easy: {
    speed: 150, # pixels/s
    obstacle_gap: 220, # pixels
    obstacle_spawn_interval: 2.0, # secs
  },
  medium: {
    speed: 200, # pixels/s
    obstacle_gap: 180, #pixels
    obstacle_spawn_interval: 1.3, #seconds
  },
  hard: {
    speed: 400, # pixels/s
    obstacle_gap: 160, # pixels
    obstacle_spawn_interval: 1, #seconds
  },
}


Rect = DefStruct.new{{
	pos: Vec[0, 0], # x, y
	size: Vec[0 , 0] # width, height
	# rotation:, maybe later
	}}.reopen do 
		def min_x; pos.x; end #tip to shorten lines using ;
		def min_y; pos.y; end
		def max_x; pos.x + size.x; end
		def max_y; pos.y + size.y; end
	end

Obstacle = DefStruct.new{{
	pos: Vec[0, 0],
	player_has_crossed: false,
	gap: DIFFICULTIES[:medium][:obstacle_gap],
	}}
GameState = DefStruct.new{{
	difficulty: :medium,
	score: 0,
	started: false,
	alive: true, 
	scroll_x: 0,
	player_pos: Vec[20, 350],
	player_vel: Vec[0,0],
	player_rotation: 0, 
	player_animation: Animation.new(PLAYER_ANIMATION_FPS, PLAYER_FRAMES),
	player_animation_timer: Timer::Looping.new(1.0/PLAYER_ANIMATION_FPS),
	obstacles: [], # array of Obstacles
	obstacle_timer: Timer::Looping.new(DIFFICULTIES[:medium][:obstacle_spawn_interval]),
	restart_timer: Timer::OneShot.new(RESTART_INTERVAL),
	}}

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@font = Gosu::Font.new(self, Gosu.default_font_name, 25)
		@images = {
			background: Gosu::Image.new(self, 'images/Fall-Nature-Background-Pictures.jpg', false),
			foreground: Gosu::Image.new(self, 'images/foreground.png', true),
			player: Gosu::Image.new(self, 'images/dog.png', false),
			player1: Gosu::Image.new(self, 'images/bird1.png', false),
			player2: Gosu::Image.new(self, 'images/bird2.png', false), 
			player3: Gosu::Image.new(self, 'images/birdFly_000.png', false),  
			obstacle: Gosu::Image.new(self, 'images/obstacle.png', false),
		}
		@state = GameState.new
	end

	def button_down(button)
		case button
		when Gosu::KbEscape then close
		when Gosu::Kb1 then set_difficulty(:easy)
    when Gosu::Kb2 then set_difficulty(:medium)
    when Gosu::Kb3 then set_difficulty(:hard)
		when Gosu::KbSpace 
			@state.player_vel.set!(JUMP_VEL) if @state.alive
			@state.started = true
		end
	end

	def set_difficulty(name)
    @state.difficulty = name
    @state.obstacle_timer.interval = DIFFICULTIES[name][:obstacle_spawn_interval]
  end

	def update
		dt = (update_interval / 1000.0)

		@state.scroll_x += dt*difficulty[:speed]*0.5
		if @state.scroll_x > @images[:foreground].width
			@state.scroll_x = 0
		end
		@state.player_animation.update(dt)

		return unless @state.started
		
		@state.player_vel += dt * GRAVITY
		@state.player_pos +=  dt * @state.player_vel

		if @state.alive
			@state.obstacle_timer.update(dt) do
				@state.obstacles << Obstacle.new(
					pos: Vec[width, rand(50..350)],
					gap: difficulty[:obstacle_gap],
					)

				# puts @state.obstacles.size
			end
		end 
		@state.obstacles.each do |obst|
			obst.pos.x -= dt*difficulty[:speed]
			if obst.pos.x < @state.player_pos.x && !obst.player_has_crossed && @state.alive
				@state.score += 1
				obst.player_has_crossed = true
			end
		end

		@state.obstacles.reject! { |obst| obst.pos.x < -@images[:obstacle].width }

		if @state.alive && player_is_colliding? 
			@state.alive = false
			@state.player_vel.set!(DEATH_VELOCITY)
		end

		unless @state.alive
			@state.player_rotation += dt*DEATH_ROTATIONAL_VEL
			@state.restart_timer.update(dt) { restart_game }
		end 
	end

	def restart_game
		@state = GameState.new(scroll_x: @state.scroll_x)
	end

	def player_is_colliding?
		player_r = player_rect
		return true if obstacle_rects.find { |obst_r| rects_intersect?(player_r, obst_r) }
		not rects_intersect?(player_r, Rect.new(pos: Vec[0, 0], size: Vec[width, height]))
	end

	def rects_intersect?(r1, r2)
    return false if r1.max_x < r2.min_x
    return false if r1.min_x > r2.max_x

    return false if r1.min_y > r2.max_y
    return false if r1.max_y < r2.min_y

    true
  end


	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(-@state.scroll_x, 350, 0)
		@images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 350, 0)
		
		@state.obstacles.each do |obst|
			img_y = @images[:obstacle].height
			#top obstacles
			@images[:obstacle].draw(obst.pos.x, obst.pos.y - img_y, 0)
			#bottom obstacles
			scale(1, -1) do
				@images[:obstacle].draw(obst.pos.x, - height - img_y + (height - obst.pos.y - obst.gap), 0)
			end
		end

		player_frame.draw_rot(
			@state.player_pos.x, @state.player_pos.y, 
			0, @state.player_rotation,
			0, 0)
		@font.draw_rel(@state.score.to_s, width/2.0, 60, 0, 0.5, 0.5)

		#draws the collison boxes
		# debug_draw
	end

	def difficulty
    DIFFICULTIES[@state.difficulty]
  end

	def player_frame
		@images[@state.player_animation.frame]
	end

	def player_rect
		Rect.new(
			pos: @state.player_pos,
			size: Vec[player_frame.width, player_frame.height]
			)
	end

	def obstacle_rects
		img_y = @images[:obstacle].height
		obst_size = Vec[@images[:obstacle].width, @images[:obstacle].height]

		@state.obstacles.flat_map do |obst|
			top = Rect.new(pos: Vec[obst.pos.x, obst.pos.y - img_y], size: obst_size)
			bottom = Rect.new( pos: Vec[obst.pos.x, obst.pos.y + obst.gap], size: obst_size)
			[top, bottom]
		end
	end

	def debug_draw
		color = player_is_colliding? ? Gosu::Color::RED : Gosu::Color::GREEN
		draw_debug_rect(player_rect, color)

		obstacle_rects.each do |obst_rect|
			draw_debug_rect(obst_rect)
		end
	end

	def draw_debug_rect(rect, color = Gosu::Color::GREEN)
		x = rect.pos.x
		y = rect.pos.y
		w = rect.size.x
		h = rect.size.y
		points = [
			Vec[x, y],
			Vec[x + w, y],
			Vec[x + w, y + h],
			Vec[x, y + h]
		]

		points.each_with_index do |p1, idx|
			p2 = points[(idx + 1) % points.size]
			draw_line(p1.x, p1.y, color, p2.x, p2.y, color)
		end

	end
end

window = GameWindow.new(800, 600, false)
window.show

