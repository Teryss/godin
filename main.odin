package main

import "core:fmt"

main :: proc() {
	board := new(C_Board)
	load_fen(board, STARTING_POS)
	defer free(board)

	masks := new(C_Attack_masks)
	init_masks(masks)
	defer free(masks)

	run_perft(board, masks, 6, false)
	// print_bitboard(board.pieces[PIECES.P])
}
