package main

import "core:fmt"

init_all :: proc (board: ^S_Board, masks: ^S_Attack_masks, FEN : string){
	init_masks(masks)
	init_random_numbers()
	load_fen(board, FEN)
}

main :: proc() {
	board := new(S_Board)
	masks := new(S_Attack_masks)
	defer free(board)
	defer free(masks)


	init_all(board, masks, TRICKY_POSITION)
	print_board(board)

	best_move : u64
	score : i32
	best_move, score = search(board, masks, 6)
	fmt.println("Results:\n")
	fmt.println("Nodes:", nodes_searched)
	print_single_move(best_move)
	fmt.println("Score:", score)

	// print_board(board)
	// fmt.println(int(SQUARES.NO_SQR), u8(SQUARES.NO_SQR), u8(SQUARES.A8))
	// run_perft(board, masks, 5, false)
	// print_bitboard(board.pieces[PIECES.P])
}
