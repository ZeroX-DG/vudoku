module main

import os
import gg
import gx
import sokol.sapp

// sizes
const (
	cell_size         = 50
	cell_text_size    = 25
	game_size         = cell_size * 9
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
)

// text configs
const (
	valid_cell_text_cfg = gx.TextCfg {
		align: .center
		vertical_align: .middle
		size: cell_text_size
		mono: false
	}
)

struct Cell {
mut:
  value   i8
	invalid bool
}

struct Location {
pub:
  row i8
	col i8
}

struct Game {
mut:
	grid        [][]Cell
	gg          &gg.Context = voidptr(0)
	active_cell Location
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
	}

	game.gg = gg.new_context({
		bg_color: gx.white
		width: game_size
		height: game_size
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
	mut grid := [][]Cell{ cap: 9, init: []Cell{ cap: 9 } }
	for _ in 0 .. 9 {
		mut row_arr := []Cell{ cap: 9 }
		for _ in 0 .. 9 {
			cell := Cell {
				value: 0
				invalid: false
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

			if cell.value > 0 {
				g.gg.draw_text(
					x * cell_size + cell_size / 2,
					y * cell_size + cell_size / 2,
					cell.value.str(),
					valid_cell_text_cfg
				)
			}
		}
	}

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
	g.gg.draw_rect(
		g.active_cell.col * cell_size,
		g.active_cell.row * cell_size,
		cell_size,
		cell_size,
		cell_highlight_color
	)
}

fn (mut g Game) draw_scene() {
	g.draw_active_cell()
	g.draw_grid()
}

fn (mut g Game) set_active_cell(col i8, row i8) {
	g.active_cell = Location {
		col: col,
		row: row
	}
}

fn (mut g Game) set_cell_value(cell Location, value i8) {
	g.grid[cell.row][cell.col].value = value
}

fn (mut g Game) clear_cell(cell Location) {
	g.set_cell_value(cell, 0)
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
		.c {
			g.clear_cell(g.active_cell)
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
