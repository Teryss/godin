package main

import "core:fmt"

init_all :: proc (game : ^S_Game, FEN : string){
	init_masks(game.masks)
	init_random_numbers()
	load_fen(game.board, FEN)
}

DEPTH :: 7

main :: proc() {
	game : S_Game = { new(S_Board), new(S_Attack_masks) }
	defer free(game.board)
	defer free(game.masks)
	init_all(&game, TRICKY_POSITION)

	// print_board(game.board)

	moves : [256]u64
	count := generate_pseudo_moves(game.board, game.masks, &moves)
	fmt.println("move count:", count)
	sort_moves(&moves, count)

	// best_move : u64
	// score : i32
	// best_move, score = search(game.board, game.masks, DEPTH)
	// fmt.println("Results in depth:", DEPTH)
	// fmt.println("Nodes:", nodes_searched)
	// print_single_move(best_move)
	// fmt.println("Score:", score)
}
