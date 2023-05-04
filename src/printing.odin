package main

import "core:fmt"

print_bitboard :: proc(bb: u64){
	bb_p : u64 = bb;
	r, f : u8 = 0, 0
	for r : u8 = 0; r < 8; r+=1{
		for f : u8 = 0; f < 8; f+=1{
			if f == 0{
				fmt.printf("    %d ", 8 - r);
			}
			sqr := FR_2_SQR(f, r);
			fmt.printf("%s", get_bit(&bb_p, sqr) > 0 ? " X " : " . ");
		}
		fmt.println()
	}
	fmt.printf("\n       A  B  C  D  E  F  G  H\n")
    fmt.printf("\n\n       Bitboard: %d\n", bb);
}

print_attacked :: proc(board: ^S_Board, masks: ^S_Attack_masks, side: COLOR) {
	fmt.println()
	sqr : u8 = 0; 
    for rank := 7; rank > -1; rank -= 1{
        for file in 0..<8{
            if file == 0 { fmt.printf("    %d ", rank + 1); }
            sqr = FR_2_SQR(u8(file), u8(rank));
            fmt.printf(" %d ", is_square_attacked(board, masks, sqr, side) ? 1 : 0);
        }
        fmt.println()
    }
    fmt.println("\n       A  B  C  D  E  F  G  H\n");
}

print_single_move :: proc(move : u64){
	fmt.println("Move   Piece  Capture   Double push   En passant   Castling");
	from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling : u8 = decode_move(move);
	fmt.printf("%s%s%c    %c       %d           %d             %d          %d\n", 
			SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr], promoted_piece > 0 ? rune(PIECES_CHR[promoted_piece]) : ' ', rune(PIECES_CHR[piece]), is_capture, is_double_push, is_en_passant, is_castling)
}

print_moves :: proc(move_list : ^[256]u64, move_count : u8){
	fmt.println("Move   Piece  Capture   Double push   En passant   Castling	En passant sqr		Castle perm		Fifty moves 	Target piece");
	for i in 0..<move_count{
		from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling : u8 = decode_move(move_list[i]);
		fmt.printf("%s%s%c    %c       %d           %d             %d          %d			%s			%d				%d		%c\n", 
				SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr], promoted_piece > 0 ? rune(PIECES_CHR[promoted_piece]) : ' ', rune(PIECES_CHR[piece]), is_capture, is_double_push, is_en_passant, is_castling,
				SQUARE_TO_CHR[decode_en_pas(move_list[i])], decode_castle_perm(move_list[i]), decode_fifty_moves(move_list[i]), PIECES_CHR[decode_target_piece(move_list[i])],
			)
	}
	fmt.println("Total number of moves in position:", move_count);
}

print_board :: proc(board: ^S_Board){
	fmt.println()
	for r : u8 = 0; r < 8; r+=1{
		for f : u8 = 0; f < 8; f+=1{
			if f == 0{
				fmt.printf("    %d ", 8 - r);
			}
			sqr := FR_2_SQR(f, r);
			piece := -10
			for i in 0..<12{
				if get_bit(&board.pieces[i], sqr) > 0 { piece = i; break; };
			}
			fmt.printf(" %c ", piece != -10 ? PIECES_CHR[piece] : '.');
		}
		fmt.println()
	}
	fmt.printf("\n       A  B  C  D  E  F  G  H\n")
	fmt.println("\nWhite to move?", board.whitesMove ? "Yes" : "No");
	fmt.println("Castle permission:", 
			board.castlePerm & u8(CASTLING.K) > 0 ? "wK" : "-", 
			board.castlePerm & u8(CASTLING.Q) > 0 ? "wQ" : "-",
			board.castlePerm & u8(CASTLING.k) > 0 ? "bK" : "-", 
			board.castlePerm & u8(CASTLING.q) > 0 ? "bQ" : "-", 
	);
	fmt.println("En passant", SQUARE_TO_CHR[board.enPas]);
	fmt.println("Fifty moves:", board.fiftyMoves);
	fmt.println("Ply:", board.ply);
	fmt.println()
}
