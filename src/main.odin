package main

import "core:fmt"

S_Game :: struct {
	board : ^S_Board,
	masks : ^S_Attack_masks,
}

init_all :: proc (game : ^S_Game, FEN : string){
	init_masks(game.masks)
	init_random_numbers()
	load_fen(game.board, FEN)
	game.board.pv = new(S_Pv)
}

DEPTH :: 7
TRANSPOSITION_TABLE_SIZE :: 0

main :: proc() {
	game : S_Game = { new(S_Board), new(S_Attack_masks) }
	defer free(game.board.pv)
	defer free(game.board)
	defer free(game.masks)
	init_all(&game, TRICKY_POSITION)
	run(&game)
	// fmt.println(CONST_INT)
}

run :: proc(game : ^S_Game) {
	for i in 0..<3{
		print_board(game.board)
		best_move, score := search(game.board, game.masks, DEPTH)
		fmt.println("Current score:", score)
		fmt.println("Searched nodes", nodes_searched)
		print_single_move(best_move)
		make_move(game.board, best_move)
		nodes_searched = 0
	}
	print_board(game.board)
}
