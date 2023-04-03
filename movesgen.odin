package main

import "core:fmt"

// LAYOUT
// SQUARES :: enum {
// 	A8, B8, C8, D8, E8, F8, G8, H8,
// 	A7, B7, C7, D7, E7, F7, G7, H7,
// 	A6, B6, C6, D6, E6, F6, G6, H6,
// 	A5, B5, C5, D5, E5, F5, G5, H5,
// 	A4, B4, C4, D4, E4, F4, G4, H4,
// 	A3, B3, C3, D3, E3, F3, G3, H3,
// 	A2, B2, C2, D2, E2, F2, G2, H2,
// 	A1, B1, C1, D1, E1, F1, G1, H1, NO_SQR,
// };

// is square attacked by a given side
is_square_attacked :: proc(board: ^C_Board, masks: ^C_Attack_masks, sqr: uint, by_side: COLOR) -> bool{
	using COLOR;
	using PIECES;	
	if by_side == WHITE && (masks.pawn[int(BLACK)][sqr] & board.pieces[int(P)]) > 0 { return true; }
	if by_side == BLACK && (masks.pawn[int(WHITE)][sqr] & board.pieces[int(p)]) > 0 { return true; }
	if (masks.king[sqr] & board.pieces[int(K) if by_side == WHITE else int(k)]) > 0 { return true; }
	if (masks.knight[sqr] & board.pieces[int(N) if by_side == WHITE else int(n)]) > 0 { return true; }
	if (get_rook_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(R) : int(r)] > 0) { return true; }
	if (get_bishop_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(B) : int(b)] > 0) { return true; }
	if (get_queen_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(Q) : int(q)] > 0) { return true; }
	return false;
}

print_attacked :: proc(board: ^C_Board, masks: ^C_Attack_masks, side: COLOR) {
	fmt.println()
	sqr : uint = 0; 
    for rank := 7; rank > -1; rank -= 1{
        for file in 0..<8{
            if file == 0 { fmt.printf("    %d ", rank + 1); }
            sqr = FR_2_SQR(file, rank);
            fmt.printf(" %d ", is_square_attacked(board, masks, sqr, side) ? 1 : 0);
        }
        fmt.println()
    }
    fmt.println("\n       A  B  C  D  E  F  G  H\n");
}

generate_pseudo_moves :: proc(board: ^C_Board, masks: ^C_Attack_masks){
	using PIECES;
	using SQUARES;
	
	from_sqr, to_sqr : int;
	bb, attacks, enpas_attack : u64;
	UP : int = 8;

	// pawns and castling
	if board.whitesMove{
		bb = board.pieces[P];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr - UP;

			if to_sqr > -1 && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr)) == 0{
				if to_sqr < int(A7){
					fmt.printf("White pawn promotion %s%sQ\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion %s%sB\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion %s%sN\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion %s%sR\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}else{
					fmt.printf("White pawn push %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					
					if from_sqr > int(H3) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr - UP)) == 0{
						fmt.printf("White pawn double push %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr - UP]);
					}
				}
			}

			attacks = masks.pawn[int(COLOR.WHITE)][from_sqr] & board.occupied[int(COLOR.BLACK)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr < int(A7){
					fmt.printf("White pawn promotion with capture %s%sB\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion with capture %s%sN\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion with capture %s%sQ\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("White pawn promotion with capture %s%sR\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}else{
					fmt.printf("White pawn capture %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.WHITE)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					fmt.printf("Black pawn enpassant %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.K) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(F1), COLOR.BLACK){
					fmt.printf("White castling king-side e1g1\n");
				}
			}
		}
		if board.castlePerm & u8(CASTLING.Q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(D1), COLOR.BLACK){
					fmt.printf("White castling queen-side e1b1\n");
				}
			}
		}
	}else{
		bb = board.pieces[p];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr + UP;

			if to_sqr < 64 && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr)) == 0{
				if to_sqr > int(H2){
					fmt.printf("Black pawn promotion %s%sQ\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion %s%sB\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion %s%sN\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion %s%sR\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}else{
					fmt.printf("Black pawn push %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					
					if from_sqr < int(A6) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr + UP)) == 0{
						fmt.printf("Black pawn double push %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr + UP]);
					}
				}
			}

			attacks = masks.pawn[int(COLOR.BLACK)][from_sqr] & board.occupied[int(COLOR.WHITE)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr > int(H2){
					fmt.printf("Black pawn promotion with capture %s%sB\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion with capture %s%sN\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion with capture %s%sQ\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
					fmt.printf("Black pawn promotion with capture %s%sR\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}else{
					fmt.printf("Black pawn capture %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.BLACK)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					fmt.printf("Black pawn enpassant %s%s\n", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.k) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(F8), COLOR.WHITE){
					fmt.printf("Black castling king-side e8g8\n");
				}
			}
		}
		if board.castlePerm & u8(CASTLING.q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(D8), COLOR.WHITE){
					fmt.printf("Black castling queen-side e8b8\n");
				}
			}
		}
	}

	// start : int = int(B) if board.whitesMove else int(b);
	// end : int = int(K) + 1 if board.whitesMove else int(k) + 1;

	bb = board.pieces[N if board.whitesMove else n];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = masks.knight[from_sqr] & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				fmt.printf("%s knight capture %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
			}else{
				fmt.printf("%s knight move %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr])
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
	bb = board.pieces[K if board.whitesMove else k];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = masks.king[from_sqr] & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				fmt.printf("%s king capture %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
			}else{
				fmt.printf("%s king move %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr])
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
	bb = board.pieces[R if board.whitesMove else r];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = get_rook_attacks(masks, uint(from_sqr), board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				fmt.printf("%s rook capture %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
			}else{
				fmt.printf("%s rook move %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr])
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
	bb = board.pieces[B if board.whitesMove else b];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = get_bishop_attacks(masks, uint(from_sqr), board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				fmt.printf("%s rook capture %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
			}else{
				fmt.printf("%s rook move %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr])
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
	bb = board.pieces[Q if board.whitesMove else q];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = get_queen_attacks(masks, uint(from_sqr), board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				fmt.printf("%s rook capture %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr]);
			}else{
				fmt.printf("%s rook move %s%s\n", board.whitesMove ? "White" : "Black", SQUARE_TO_CHR[from_sqr], SQUARE_TO_CHR[to_sqr])
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
}
