module generator

import rand

pub fn generate_board() [][]i8 {
	mut grid := [][]i8{len: 9, init: []i8{ len: 9, init: 0 }}
	mut density := 9

	randomize(mut grid, density)

	for !solve(mut grid) {
		grid = [][]i8{len: 9, init: []i8{ len: 9, init: 0 }}
		randomize(mut grid, density)
	}

	return grid
}

fn randomize(mut grid [][]i8, density int) {
	mut count := 0

	for count < density {
		row, col := find_empty_random(grid)

		mut value := i8(rand.int_in_range(1, 10))

		for !is_valid(grid, value, row, col) {
			value = i8(rand.int_in_range(1, 10))
		}

		grid[row][col] = value
		count++
	}
}

fn solve(mut grid [][]i8) bool {
	row, col := find_empty(grid) or {
		return true
	}

	for value in 1 .. 10 {
		if is_valid(grid, i8(value), row, col) {
			grid[row][col] = i8(value)

			if solve(mut grid) {
				return true
			}

			grid[row][col] = 0
		}
	}

	return false
}

fn is_valid(grid [][]i8, value i8, row int, col int) bool {
	// check column
	for row_index, row_content in grid {
		// if there's a row has a value that we need to check
		// at the specified column and the row is not the one
		// we about to insert then there's a dupplicate.
		if row_content[col] == value && row_index != row {
			return false
		}
	}

	// check row
	for col_index, cell_value in grid[row] {
		if cell_value == value && col_index != col {
			return false
		}
	}

	// check region
	region_x := col / 3
	region_y := row / 3

	for y in region_y * 3 .. region_y * 3 + 3 {
		for x in region_x * 3 .. region_x * 3 + 3 {
			if grid[y][x] == value {
				return false
			}
		}
	}
	return true
}

fn find_empty(grid [][]i8) ?(int, int) {
	for row_index, row in grid {
		for col_index, cell in row {
			if cell == 0 {
				return row_index, col_index
			}
		}
	}
	return none
}

fn find_empty_random(grid [][]i8) (int, int) {
	mut possible_positions := [][]int{}
	for row_index, row in grid {
		for col_index, cell in row {
			if cell == 0 {
				possible_positions << [row_index, col_index]
			}
		}
	}

	random_index := rand.int_in_range(0, possible_positions.len)
	pos := possible_positions[random_index]

	return pos[0], pos[1]
}
