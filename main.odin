package main

import "core:fmt"
import "core:time"
import "core:os"
import "core:io"
import "core:simd/x86"

init_all :: proc(masks: ^C_Attack_masks){
	init_masks(masks);
}

perft_debug :: proc (board: ^C_Board, masks: ^C_Attack_masks, depth : int) -> u64{
	fmt.printf("Perf test at depth %d \n----------------------\n", depth)
	nodes : u64 = 0
	moves : [256]u64
	moves_count : int = generate_pseudo_moves(board, masks, &moves)
	nodes_now : u64 = 0
	for i in 0..<moves_count{
		// fmt.println("Castle perm before", decode_castle_perm(moves[i]))
		make_move(board, moves[i])
		// fmt.println("Castle perm after", decode_castle_perm(moves[i]))
		if is_king_in_check(board, masks) == false{
			nodes_now = perft(board, masks, depth - 1)
			nodes += nodes_now
		}
		undo_move(board, moves[i])
		fmt.printf("	%s%s: %d\n", SQUARE_TO_CHR[decode_from_sqr(moves[i])], SQUARE_TO_CHR[decode_to_sqr(moves[i])], nodes_now)
	}
	fmt.println("----------------------")
	return nodes
}

perft :: proc (board: ^C_Board, masks: ^C_Attack_masks, depth : int) -> u64{
	if depth == 0 { return 1 }
	nodes : u64 = 0
	moves : [256]u64
	moves_count : int = generate_pseudo_moves(board, masks, &moves)
	for i in 0..<moves_count{
		// if board.whitesMove && decode_is_castling(moves[i]) > 0{
		// 	fmt.println("Before castling:", depth)
		// 	fmt.println("Castle perm", decode_castle_perm(moves[i]))
		// 	print_single_move(moves[i])
		// 	print_board(board)
		// }
		castle_perm := board.castlePerm
		en_pas := board.enPas
		fifty := board.fiftyMoves
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		make_move(board, moves[i])
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		// if count_bits(board.pieces[PIECES.K]) > 1{
		// 	fmt.println("2 kings at depth:", depth)
		// 	print_single_move(moves[i])
		// 	print_board(board)
		// 	print_bitboard(board.pieces[PIECES.K])
		// 	print_bitboard(board.occupied[COLOR.WHITE])
		// 	print_bitboard(board.occupied[COLOR.BOTH])
		// }
		if is_king_in_check(board, masks) == false{
			// if depth == 1 {
			// 	if decode_is_castling(moves[i]) > 0{
			// 		fmt.println("Number of white kings on the board:",count_bits(board.pieces[PIECES.K]))
			// 		print_single_move(moves[i])
			// 		// fmt.println(board.castlePerm)
			// 		print_board(board)
			// 		print_bitboard(board.pieces[PIECES.K])
			// 		print_bitboard(board.occupied[COLOR.WHITE])
			// 		print_bitboard(board.occupied[COLOR.BOTH])
			// 	}
			// 	// print_single_move(moves[i])
			// }
			nodes += perft(board, masks, depth - 1)
		}
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		undo_move(board, moves[i])
		assert(count_bits(board.pieces[PIECES.k]) == 1)
		assert(count_bits(board.pieces[PIECES.K]) == 1)
		assert(castle_perm == board.castlePerm)
		assert(en_pas == board.enPas)
		assert(fifty == board.fiftyMoves)
		// if count_bits(board.pieces[PIECES.K]) > 1{
		// 	fmt.println("2 kings at depth after REMOVING a move:", depth)
		// 	print_single_move(moves[i])
		// 	print_board(board)
		// 	print_bitboard(board.pieces[PIECES.K])
		// 	print_bitboard(board.occupied[COLOR.WHITE])
		// 	print_bitboard(board.occupied[COLOR.BOTH])
		// 	assert(0 == 1)
		// }
	}
	return nodes
}

main :: proc() {
	masks := new(C_Attack_masks);
	init_all(masks);
	defer free(masks);

	FEN :: STARTING_POS
	DEPTH :: 6

	board := new(C_Board);
	load_fen(board, FEN);
	defer free(board);

	// move := enocode_move(0,0,0,0,0,0,0,1)
	// board.castlePerm = 13
	// board.enPas = 0
	// print_board(board)
	// move = add_info_to_encoded_move(board,move)
	// fmt.println("castle perm: ", board.castlePerm)
	// print_bitboard(move)
	// fmt.println("Castle perm after decoding:", decode_castle_perm(move))
	// fmt.println(SQUARE_TO_CHR[decode_en_pas(move)])

	// set_bit(&board.pieces[PIECES.p], uint(SQUARES.C5))
	// clear_bit(&board.pieces[PIECES.p], uint(SQUARES.C7))
	// // clear_bit(&board.pieces[PIECES.p], uint(SQUARES.D7))
	// update_occupied(board)
	// board.whitesMove = !board.whitesMove

	// moves : [256]u64
	// moves_cnt := generate_pseudo_moves(board, masks, &moves)
	// print_moves(&moves, moves_cnt)

	t1 := time.tick_now()
	nodes : u64
	nodes = perft(board, masks, DEPTH)
	t2 := time.tick_now()
	fmt.println("Nodes:", nodes)
	fmt.println("It took:", time.duration_seconds(time.tick_diff(t1, t2)), "seconds")
	print_board(board)
}