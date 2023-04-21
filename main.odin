package main

import "core:fmt"

init_all :: proc (game : ^S_Game, FEN : string){
	init_masks(game.masks)
	init_random_numbers()
	load_fen(game.board, FEN)
}

DEPTH :: 7
SORT_PRINT :: false

main :: proc() {
	game : S_Game = { new(S_Board), new(S_Attack_masks) }
	defer free(game.board)
	defer free(game.masks)
	init_all(&game, TRICKY_POSITION)

	test(&game)
}

test :: proc(game : ^S_Game) {
	// print_board(game.board)
	// moves : [256]u64
	// count := generate_pseudo_moves(game.board, game.masks, &moves)
	// sort_moves(&moves, count)
	
	for i in 0..<3{
		print_board(game.board)
		best_move, score := search(game.board, game.masks, DEPTH)
		fmt.println("Current score:", score)
		print_single_move(best_move)
		make_move(game.board, best_move)
	}
	print_board(game.board)
	// print_board(game.board)
	// best_move, score = search(game.board, game.masks, DEPTH)
	// print_single_move(best_move)
	// make_move(game.board, best_move)
	// fmt.println("Current score:", score)
	// print_board(game.board)
}
