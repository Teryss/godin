package main

import "core:fmt"
import "core:time"
import "core:os"
import "core:io"
import "core:simd/x86"

init_all :: proc(masks: ^C_Attack_masks){
	init_masks(masks);
}

perft_debug :: proc (board: ^C_Board, masks: ^C_Attack_masks, depth : int, type_counter : ^type_of_moves_counter) -> u64{
	fmt.printf("Perf test at depth %d \n----------------------\n", depth)
	nodes : u64 = 0
	moves : [256]u64
	moves_count : int = generate_pseudo_moves(board, masks, &moves)
	nodes_now : u64 = 0
	do_print := false
	for i in 0..<moves_count{
		// if decode_is_double_push(moves[i]) > 0 { print_board(board) }
		// if decode_from_sqr(moves[i]) == int(SQUARES.E8) && decode_to_sqr(moves[i]) == int(SQUARES.D8) { print_board(board) }
		make_move(board, moves[i])
		// if decode_from_sqr(moves[i]) == int(SQUARES.E8) && decode_to_sqr(moves[i]) == int(SQUARES.D8) { print_board(board) }
		if !is_king_in_check(board, masks){
			if decode_is_en_passant(moves[i]) > 0 { type_counter.enpas += 1 }
			if decode_is_capture(moves[i]) > 0 { type_counter.captures += 1 }
			// fmt.println("Recursive call")
			nodes_now = perft(board, masks, depth - 1, type_counter, do_print)
			nodes += nodes_now
		}
		undo_move(board, moves[i])
		// if decode_is_double_push(moves[i]) > 0 { print_board(board) }
		fmt.printf("	%s%s: %d\n", SQUARE_TO_CHR[decode_from_sqr(moves[i])], SQUARE_TO_CHR[decode_to_sqr(moves[i])], nodes_now)
		nodes_now = 0
	}
	fmt.println("----------------------")
	return nodes
}

perft :: proc (board: ^C_Board, masks: ^C_Attack_masks, depth : int, type_counter : ^type_of_moves_counter, do_print : bool) -> u64{
	if depth == 0 { return 1 }
	nodes : u64 = 0
	moves : [256]u64
	moves_count : int = generate_pseudo_moves(board, masks, &moves)
	_do_print := do_print
	for i in 0..<moves_count{
		castle_perm := board.castlePerm
		en_pas := board.enPas
		fifty := board.fiftyMoves
		// assert(count_bits(board.pieces[PIECES.k]) == 1)
		// assert(count_bits(board.pieces[PIECES.K]) == 1)
		make_move(board, moves[i])
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		if is_king_in_check(board, masks) == false{
			if decode_is_en_passant(moves[i]) > 0 { type_counter.enpas += 1 }
			else if decode_is_capture(moves[i]) > 0 && decode_target_piece(moves[i]) > 0 { type_counter.captures += 1 }
			// print_board(board)
			nodes += perft(board, masks, depth - 1, type_counter, do_print)
		}
		// assert(count_bits(board.pieces[PIECES.k]) == 1)
		// assert(count_bits(board.pieces[PIECES.K]) == 1)
		undo_move(board, moves[i])
		// print_board(board)
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		assert(castle_perm == board.castlePerm)
		assert(en_pas == board.enPas)
		assert(fifty == board.fiftyMoves)
	}
	return nodes
}

type_of_moves_counter :: struct{
	captures, enpas : int,
}

main :: proc() {
	masks := new(C_Attack_masks);
	init_all(masks);
	defer free(masks);

	type_counter : type_of_moves_counter

	FEN :: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 0"
	DEPTH :: 7

	board := new(C_Board);
	load_fen(board, FEN);
	defer free(board);

	// fmt.println(is_square_attacked(board, masks, uint(SQUARES.D8), COLOR.WHITE))

	// moves : [256]u64
	// move_count := generate_pseudo_moves(board, masks, &moves)

	// for i in 0..<move_count{
	// 	print_board(board)
	// 	make_move(board, moves[i])
	// 	if decode_is_double_push(moves[i]) > 0 {
	// 		print_bitboard(board.occupied[COLOR.BOTH])
	// 		print_bitboard(board.occupied[COLOR.WHITE])
	// 	}
	// 	print_board(board)
	// 	undo_move(board, moves[i])
	// }

	// t1 := time.tick_now()
	nodes : u64 = perft_debug(board, masks, DEPTH, &type_counter)
	fmt.println("Nodes:", nodes)
	// // t2 := time.tick_now()
	// // fmt.println("Captures:", type_counter.captures)
	// // fmt.println("En passant:", type_counter.enpas)	
	// // fmt.println("It took:", time.duration_seconds(time.tick_diff(t1, t2)), "seconds")
	// print_board(board)
}