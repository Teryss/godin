package main

import "core:fmt"

init_all :: proc(masks: ^C_Attack_masks){
	init_masks(masks);
}

main :: proc() {
	masks := new(C_Attack_masks);
	init_all(masks);
	defer free(masks);

	board := new(C_Board);
	load_fen(board, TRICKY_POSITION);
	defer free(board);
	
	print_board(board);
	board.enPas = uint(SQUARES.C6);
	// board.whitesMove = false;
	generate_pseudo_moves(board, masks)
}