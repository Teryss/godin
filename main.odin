package main

import "core:fmt"

init_all :: proc (game : ^S_Game, FEN : string){
	init_masks(game.masks)
	init_random_numbers()
	load_fen(game.board, FEN)
}

main :: proc() {
	game : S_Game = { new(S_Board), new(S_Attack_masks) }
	defer free(game.board)
	defer free(game.masks)
	init_all(&game, TRICKY_POSITION)

	// print_board(game.board)

	best_move : u64
	score : i32
	best_move, score = search(game.board, game.masks, 7)
	fmt.println("Results:")
	fmt.println("Nodes:", nodes_searched)
	print_single_move(best_move)
	fmt.println("Score:", score)
}
