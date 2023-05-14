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

	// run_test_suite(&game)
	reset(game.board)
	load_fen(game.board, TRICKY_POSITION)
	run(&game)
	// run(&game)
	// fmt.println(CONST_INT)
}

run_test_suite :: proc (game : ^S_Game){
	nodes : u64
	expected_nodes : u64 = 193690690
	reset(game.board)
	load_fen(game.board, TRICKY_POSITION)
	nodes = run_perft(game.board, game.masks, 5, false)
	if nodes != expected_nodes { fmt.printf("Tricky position depth 5 failed, expected: %lld, got: %lld\n", expected_nodes, nodes); return}
	fmt.println("Tricky positon passed")

	reset(game.board)
	load_fen(game.board, STARTING_POS)
	expected_nodes = 119060324
	nodes = run_perft(game.board, game.masks, 6, false)
	if nodes != expected_nodes { fmt.printf("Starting position depth 6 failed, expected: %lld, got: %lld\n", expected_nodes, nodes); return}
	fmt.println("Starting positon passed")

	reset(game.board)
	load_fen(game.board, "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1")
	expected_nodes = 15833292
	nodes = run_perft(game.board, game.masks, 5, false)
	if nodes != expected_nodes { fmt.printf("Position 3 depth 5 failed, expected: %lld, got: %lld\n", expected_nodes, nodes); return}
	fmt.println("Possiton 3 passed")

	fmt.println("\nTest suite passed")
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
