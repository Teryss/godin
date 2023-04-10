package main

import "core:fmt"

init_all :: proc(masks: ^C_Attack_masks){
	init_masks(masks);
}

main :: proc() {
	masks := new(C_Attack_masks);
	init_all(masks);
	defer free(masks);

	FEN :: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 0"
	DEPTH :: 7

	board := new(C_Board);
	load_fen(board, FEN);
	defer free(board);

	run_perft(board, masks, DEPTH)
}