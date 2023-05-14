package main

import "core:fmt"
import "core:time"

@(private)
perft_debug :: proc (board: ^S_Board, masks: ^S_Attack_masks, depth : int) -> u64{
	fmt.printf("Perf test at depth %d \n----------------------\n", depth)
	nodes : u64 = 0
	moves : [256]u64
	moves_count : u8 = generate_pseudo_moves(board, masks, &moves)
	nodes_now : u64 = 0
	for i in 0..<moves_count{
		make_move(board, moves[i])
		if !is_king_in_check(board, masks){
			nodes_now = perft(board, masks, depth - 1)
			nodes += nodes_now
		}
		undo_move(board, moves[i])
		fmt.printf("	%s%s: %d\n", SQUARE_TO_CHR[decode_from_sqr(moves[i])], SQUARE_TO_CHR[decode_to_sqr(moves[i])], nodes_now)
		nodes_now = 0
	}
	fmt.println("----------------------")
	return nodes
}

@(private)
perft :: proc (board: ^S_Board, masks: ^S_Attack_masks, depth : int) -> u64 {
	if depth == 0 { return 1 }
	nodes : u64 = 0
	moves : [256]u64
	moves_count : u8 = generate_pseudo_moves(board, masks, &moves)
	for i in 0..<moves_count{
		make_move(board, moves[i])
		if is_king_in_check(board, masks) == false{
			nodes += perft(board, masks, depth - 1)
		}
		undo_move(board, moves[i])
	}
	return nodes
}

run_perft :: proc (board: ^S_Board, masks: ^S_Attack_masks, depth : int, debug : bool) -> u64{
	nodes : u64
	t1 := time.tick_now()
	if debug {
		nodes = perft_debug(board, masks, depth)
	}else{
		nodes = perft(board, masks, depth)
	}
	t2 := time.tick_now()
	// fmt.println("Nodes:", nodes)
	// fmt.println("It took:", time.duration_seconds(time.tick_diff(t1, t2)), "seconds")
	return nodes
}