package main

import "core:fmt"
import "core:time"
import "core:os"
// import "core:bufio"
import "core:io"

init_all :: proc(masks: ^C_Attack_masks){
	init_masks(masks);
}

print_single_move :: proc(move : u64){
	from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling : int = decode_move(move);
	fmt.printf("%s%s%c    %c       %d           %d             %d          %d\n", 
			SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr], promoted_piece > 0 ? rune(PIECES_CHR[promoted_piece]) : ' ', rune(PIECES_CHR[piece]), is_capture, is_double_push, is_en_passant, is_castling)
}

main :: proc() {
	masks := new(C_Attack_masks);
	init_all(masks);
	defer free(masks);

	board := new(C_Board);
	load_fen(board, TRICKY_POSITION);
	defer free(board);

	generate_pseudo_moves(board, masks)
	// print_moves(board)
	// fmt.print("")
	x : [256]u8;
	// fmt.println(1)
	previous_move := new(C_Move);
	defer free(previous_move)
	// fmt.println(2)
	print_board(board);
	for i in 0..<board.moves_count{
		// print_single_move(board.moves[i])
		make_move(board, board.moves[i])
		print_board(board);
		os.read(os.stdin,x[:])

		decode_u64_move_to_s_move(board.moveHistory[board.ply - 1], previous_move)
		undo_move(board, previous_move)
		print_board(board);
		os.read(os.stdin,x[:])
	}
}