module main

import os
import gg
import gx
import sokol.sapp
import generator
import time

// sizes
const (
	cell_size         = 50
	cell_text_size    = 30
	game_size         = cell_size * 9
	status_size       = 50
	timer_text_size   = 25
)

// paths
const (
	font_path = os.resource_abs_path('./assets/fonts/ProximaNova-Regular.otf')
)

// colors
const (
	cell_border_color             = gx.rgb(200, 200, 200)
	cell_highlight_color          = gx.rgb(217, 217, 217)
	cell_line_row_highlight_color = gx.rgb(240, 240, 240)
	cell_user_input_color         = gx.rgb(27 , 84 , 196)
	cell_invalid_active_bg_color  = gx.rgb(255, 191, 191)
	cell_invalid_bg_color         = gx.rgb(255, 219, 219)
	cell_invalid_fg_color         = gx.rgb(255, 33, 33)
	timer_text_color              = gx.rgb(158, 158, 158)
)

// text configs
const (
	cell_text_cfg = gx.TextCfg {
		align: .center
		vertical_align: .middle
		size: cell_text_size
		mono: false
	}

	cell_user_input_text_cfg = gx.TextCfg {
		align: .center
		vertical_align: .middle
		size: cell_text_size
		color: cell_user_input_color
		mono: false
	}

	cell_invalid_text_cfg = gx.TextCfg {
		align: .center
		vertical_align: .middle
		size: cell_text_size
		color: cell_invalid_fg_color
		mono: false
	}

	timer_text_cfg = gx.TextCfg {
		align: .center
		vertical_align: .middle
		size: timer_text_size
		color: timer_text_color
		mono: true
	}

	right_align_text_cfg = gx.TextCfg {
		align: .right
		vertical_align: .middle
		size: timer_text_size - 2
		color: timer_text_color
		mono: false
	}

	left_align_text_cfg = gx.TextCfg {
		align: .left
		vertical_align: .middle
		size: timer_text_size - 2
		color: timer_text_color
		mono: false
	}
)

struct Cell {
mut:
  value     i8
	generated bool
}

struct Location {
pub:
  row i8
	col i8
}

enum GameState {
	running
	pause
	won
}

struct Game {
mut:
	grid          [][]Cell
	gg            &gg.Context = voidptr(0)
	active_cell   Location
	invalid_cells []Location
	game_timer    time.StopWatch = time.new_stopwatch({})
	state         GameState = .running
	level         generator.Difficulty = .easy
}

fn frame(mut game Game) {
	game.gg.begin()
	game.draw_scene()
	game.gg.end()
}

fn main() {
	mut game := &Game {
		gg: 0
		active_cell: Location {
			row: 5
			col: 2
		}
		invalid_cells: []Location{}
	}

	game.gg = gg.new_context({
		bg_color: gx.white
		width: game_size
		height: game_size + status_size
		use_ortho: true
		create_window: true
		window_title: 'Vudoku'
		user_data: game
		frame_fn: frame
		event_fn: on_event
		font_path: font_path
	})

	game.init_game()
	game.gg.run()
}

fn (mut g Game) init_game() {
	board := generator.generate_board(g.level)

	g.game_timer.start()

	mut grid := [][]Cell{ cap: 9, init: []Cell{ cap: 9 } }
	for y in 0 .. 9 {
		mut row_arr := []Cell{ cap: 9 }
		for x in 0 .. 9 {
			cell := Cell {
				value: board[y][x]
				// if there's a value, then that cell is generated
				generated: board[y][x] != 0
			}
			row_arr << cell
		}
		grid << row_arr
	}
	g.grid = grid
}

fn (mut g Game) draw_grid() {
	for y, row in g.grid {
		for x, cell in row {
			g.gg.draw_empty_rect(
				x * cell_size,
				y * cell_size,
				cell_size,
				cell_size,
				cell_border_color
			)

			text_cfg := if cell.generated {
				cell_text_cfg
			} else {
				cell_user_input_text_cfg
			}

			if cell.value > 0 && g.state != .pause {
				g.gg.draw_text(
					x * cell_size + cell_size / 2,
					y * cell_size + cell_size / 2,
					cell.value.str(),
					text_cfg
				)
			}
		}
	}
}

fn (mut g Game) draw_time() {
	current_time := g.game_timer.elapsed()
	seconds_num := int(current_time.seconds())
	hours := seconds_num / 3600
	minutes := (seconds_num - (hours * 3600)) / 60
	seconds := seconds_num - (hours * 3600) - (minutes * 60)

	hours_str := if hours < 10 { '0' + hours.str() } else { hours.str() }
	minutes_str := if minutes < 10 { '0' + minutes.str() } else { minutes.str() }
	seconds_str := if seconds < 10 { '0' + seconds.str() } else { seconds.str() }

	mut current_time_str := ''

	if hours > 0 {
		current_time_str += hours_str + ':'
	}

	current_time_str += minutes_str + ':' + seconds_str

	g.gg.draw_text(
		game_size / 2,
		game_size + status_size / 2,
		current_time_str,
		timer_text_cfg
	)
}

fn (mut g Game) draw_level() {
	difficulty_str := match g.level {
		.easy { 'Easy' }
		.medium { 'Medium' }
		.hard { 'Hard' }
		.expert { 'Expert' }
	}

	g.gg.draw_text(
		game_size - 10,
		game_size + status_size / 2,
		difficulty_str,
		right_align_text_cfg
	)
}

fn (mut g Game) draw_state() {
	status_str := match g.state {
		.running { 'In progress' }
		.won { 'You won!' }
		else { 'Paused' }
	}

	g.gg.draw_text(
		10,
		game_size + status_size / 2,
		status_str,
		left_align_text_cfg
	)
}

fn (mut g Game) draw_regions() {
	for y in 0 .. 3 {
		for x in 0 .. 3 {
			g.gg.draw_empty_rect(
				x * cell_size * 3,
				y * cell_size * 3,
				cell_size * 3,
				cell_size * 3,
				gx.black
			)
		}
	}
}

fn (mut g Game) draw_invalid_cell() {
	for cell in g.invalid_cells {
		cell_value := g.grid[cell.row][cell.col].value

		if cell_value == 0 {
			continue
		}

		g.gg.draw_empty_rect(
			cell.col * cell_size,
			cell.row * cell_size,
			cell_size,
			cell_size,
			cell_border_color
		)
		g.gg.draw_text(
			cell.col * cell_size + cell_size / 2,
			cell.row * cell_size + cell_size / 2,
			cell_value.str(),
			cell_invalid_text_cfg
		)
	}

	for invalid_cell in g.invalid_cells {
		if g.active_cell.row == invalid_cell.row && g.active_cell.col == invalid_cell.col {
			for cell in g.get_invalids_for_cell(g.active_cell) {
				cell_value := g.grid[cell.row][cell.col].value

				g.gg.draw_rect(
					cell.col * cell_size,
					cell.row * cell_size,
					cell_size,
					cell_size,
					cell_invalid_bg_color
				)
				g.gg.draw_empty_rect(
					cell.col * cell_size,
					cell.row * cell_size,
					cell_size,
					cell_size,
					cell_border_color
				)
				g.gg.draw_text(
					cell.col * cell_size + cell_size / 2,
					cell.row * cell_size + cell_size / 2,
					cell_value.str(),
					cell_invalid_text_cfg
				)
			}
			break
		}
	}
}

fn (mut g Game) draw_active_cell() {
	for count in 0 .. 9 {
		// highlight the whole col
		g.gg.draw_rect(
			g.active_cell.col * cell_size,
			count * cell_size,
			cell_size,
			cell_size,
			cell_line_row_highlight_color
		)
		// highlight the whole row
		g.gg.draw_rect(
			count * cell_size,
			g.active_cell.row * cell_size,
			cell_size,
			cell_size,
			cell_line_row_highlight_color
		)
	}

	// highlight region
	region_x := g.active_cell.col / 3
	region_y := g.active_cell.row / 3

	for y in region_y * 3 .. region_y * 3 + 3 {
		for x in region_x * 3 .. region_x * 3 + 3 {
			g.gg.draw_rect(
				x * cell_size,
				y * cell_size,
				cell_size,
				cell_size,
				cell_line_row_highlight_color
			)
		}
	}

	// highlight the main cell
	g.gg.draw_rect(
		g.active_cell.col * cell_size,
		g.active_cell.row * cell_size,
		cell_size,
		cell_size,
		cell_highlight_color
	)
}

fn (mut g Game) draw_scene() {
	if g.state != .pause {
		g.draw_active_cell()
		g.draw_grid()
		g.draw_invalid_cell()
	} else {
		g.draw_grid()
	}

	g.draw_regions()
	g.draw_time()
	g.draw_level()
	g.draw_state()
}

fn (mut g Game) set_active_cell(col i8, row i8) {
	used_col := if col < 0 {
		0
	} else if col > 8 {
		8
	} else {
		col
	}

	used_row := if row < 0 {
		0
	} else if row > 8 {
		8
	} else {
		row
	}

	g.active_cell = Location {
		col: used_col,
		row: used_row
	}
}

fn (mut g Game) set_cell_value(cell Location, value i8) {
	// prevent modifying a generated cell
	if g.grid[cell.row][cell.col].generated {
		return
	}
	g.grid[cell.row][cell.col].value = value

	// validate the board
	g.validate()
}

fn (mut g Game) clear_cell(cell Location) {
	g.set_cell_value(cell, 0)
}

fn (mut g Game) toggle_state() {
	if g.state == .running {
		g.state = .pause
		g.game_timer.pause()
	} else {
		g.state = .running
		g.game_timer.start()
	}
}

fn (mut g Game) mouse_left_down(x f32, y f32) {
	col := i8(x / cell_size)
	row := i8(y / cell_size)
	g.set_active_cell(col, row)
}

fn (mut g Game) key_down(key sapp.KeyCode) {
	match key {
		._1 {
			g.set_cell_value(g.active_cell, 1)
		}
		._2 {
			g.set_cell_value(g.active_cell, 2)
		}
		._3 {
			g.set_cell_value(g.active_cell, 3)
		}
		._4 {
			g.set_cell_value(g.active_cell, 4)
		}
		._5 {
			g.set_cell_value(g.active_cell, 5)
		}
		._6 {
			g.set_cell_value(g.active_cell, 6)
		}
		._7 {
			g.set_cell_value(g.active_cell, 7)
		}
		._8 {
			g.set_cell_value(g.active_cell, 8)
		}
		._9 {
			g.set_cell_value(g.active_cell, 9)
		}
		.q {
			println("Bye bye!")
			exit(0)
		}
		.left, .h {
			g.set_active_cell(g.active_cell.col - 1, g.active_cell.row)
		}
		.right, .l {
			g.set_active_cell(g.active_cell.col + 1, g.active_cell.row)
		}
		.up, .k {
			g.set_active_cell(g.active_cell.col, g.active_cell.row - 1)
		}
		.down, .j {
			g.set_active_cell(g.active_cell.col, g.active_cell.row + 1)
		}
		.c {
			g.clear_cell(g.active_cell)
		}
		.p {
			g.toggle_state()
		}
		else {
		}
	}
}

fn on_event(e &sapp.Event, mut game Game) {
	if e.typ == .mouse_down && e.mouse_button == .left {
		game.mouse_left_down(e.mouse_x, e.mouse_y)
	}

	if e.typ == .key_down {
		game.key_down(e.key_code)
	}
}

fn (g Game) get_invalids_for_cell(cell Location) []Location {
	mut invalids := []Location{}

	cell_value := g.grid[cell.row][cell.col].value

	if cell_value == 0 {
		return []
	}

	// check column
	for row, row_content in g.grid {
		if row_content[cell.col].value == cell_value && row != cell.row {
			invalids << Location {
				row: i8(row),
				col: i8(cell.col)
			}
		}
	}

	// check row
	for col, current_cell in g.grid[cell.row] {
		if current_cell.value == cell_value && col != cell.col {
			invalids << Location {
				row: i8(cell.row),
				col: i8(col)
			}
		}
	}

	// check region
	region_x := cell.col / 3
	region_y := cell.row / 3

	for y in region_y * 3 .. region_y * 3 + 3 {
		for x in region_x * 3 .. region_x * 3 + 3 {
			if g.grid[y][x].value == cell_value {
				invalids << Location {
					row: i8(y),
					col: i8(x)
				}
			}
		}
	}

	return invalids
}

fn (g Game) is_valid(value i8, cell Location) bool {
	// check column
	for i, row_content in g.grid {
		if row_content[cell.col].value == value && i != cell.row {
			return false
		}
	}

	// check row
	for i, current_cell in g.grid[cell.row] {
		if current_cell.value == value && i != cell.col {
			return false
		}
	}

	// check region
	region_x := cell.col / 3
	region_y := cell.row / 3

	for y in region_y * 3 .. region_y * 3 + 3 {
		for x in region_x * 3 .. region_x * 3 + 3 {
			if g.grid[y][x].value == value && y != cell.row && x != cell.col {
				return false
			}
		}
	}

	return true
}

fn (mut g Game) validate() {
	g.invalid_cells = []

	for row_index, row in g.grid {
		for col_index, cell in row {
			if cell.value == 0 || cell.generated {
				continue
			}

			cell_location := Location {
				row: i8(row_index),
				col: i8(col_index)
			}

			cell_valid := g.is_valid(cell.value, cell_location)

			if !cell_valid {
				g.invalid_cells << cell_location
			}
		}
	}
}
