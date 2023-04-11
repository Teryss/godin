package main

import "core:fmt"

main :: proc() {
	board := new(C_Board)
	load_fen(board, STARTING_POS)
	defer free(board)

	masks := new(C_Attack_masks)
	init_masks(masks)
	defer free(masks)

	print_board(board)
	// fmt.println(int(SQUARES.NO_SQR), u8(SQUARES.NO_SQR), u8(SQUARES.A8))
	run_perft(board, masks, 6)
	// print_bitboard(board.pieces[PIECES.P])
}
