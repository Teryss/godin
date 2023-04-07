package main

import "core:fmt"

is_square_attacked :: #force_inline proc (board: ^C_Board, masks: ^C_Attack_masks, sqr: uint, by_side: COLOR) -> bool{
	using COLOR;
	using PIECES;	
	if by_side == WHITE && (masks.pawn[int(BLACK)][sqr] & board.pieces[int(P)]) > 0 { return true; }
	if by_side == BLACK && (masks.pawn[int(WHITE)][sqr] & board.pieces[int(p)]) > 0 { return true; }
	if masks.king[sqr] & board.pieces[int(K) if by_side == WHITE else int(k)] > 0 { return true; }
	if masks.knight[sqr] & board.pieces[int(N) if by_side == WHITE else int(n)] > 0 { return true; }
	if get_rook_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(R) : int(r)] > 0 { return true; }
	if get_bishop_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(B) : int(b)] > 0 { return true; }
	if get_queen_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? int(Q) : int(q)] > 0 { return true; }
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

add_move :: #force_inline proc(board: ^C_Board, move: u64){
	board.moves[board.moves_count] = move;
	board.moves_count += 1;
}

generate_pseudo_moves :: proc(board: ^C_Board, masks: ^C_Attack_masks) #no_bounds_check{
	using PIECES;
	using SQUARES;
	
	board.moves_count = 0;
	from_sqr, to_sqr : int;
	bb, attacks, enpas_attack : u64;
	UP : int = 8;

	if board.whitesMove{
		bb = board.pieces[P];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr - UP;
			if to_sqr > -1 && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr)) == 0{
				if to_sqr < int(A7){
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(Q), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(R), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(B), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(N), 0, 0, 0, 0));
				}else{
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 0, 0, 0));
					if from_sqr > int(H3) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr - UP)) == 0{
						add_move(board, enocode_move(from_sqr, to_sqr - UP, int(P), 0, 0, 1, 0, 0));
					}
				}
			}

			attacks = masks.pawn[int(COLOR.WHITE)][from_sqr] & board.occupied[int(COLOR.BLACK)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr < int(A7){
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(Q), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(R), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(B), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), int(N), 1, 0, 0, 0));
				}else{
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), 0, 1, 0, 0, 0));
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.WHITE)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 0, 1, 0));
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.K) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(F1), COLOR.BLACK){
					add_move(board, enocode_move(int(E1), int(G1), int(K), 0, 0, 0, 0, 1));
				}
			}
		}
		if board.castlePerm & u8(CASTLING.Q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(D1), COLOR.BLACK){
					add_move(board, enocode_move(int(E1), int(B1), int(K), 0, 0, 0, 0, 1));
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
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(q), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(r), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(b), 0, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(n), 0, 0, 0, 0));
				}else{
					add_move(board, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 0, 0, 0));
					if from_sqr < int(A6) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr + UP)) == 0{
						add_move(board, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 1, 0, 0));
					}
				}
			}
			attacks = masks.pawn[int(COLOR.BLACK)][from_sqr] & board.occupied[int(COLOR.WHITE)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr > int(H2){
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(q), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(r), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(b), 1, 0, 0, 0));
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), int(n), 1, 0, 0, 0));
				}else{
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), 0, 1, 0, 0, 0));
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.BLACK)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, enocode_move(from_sqr, to_sqr, int(p), 0, 0, 0, 1, 0));
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.k) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(F8), COLOR.WHITE){
					add_move(board, enocode_move(int(E8), int(G8), int(K), 0, 0, 0, 0, 1));
				}
			}
		}
		if board.castlePerm & u8(CASTLING.q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(D8), COLOR.WHITE){
					add_move(board, enocode_move(int(E8), int(B8), int(K), 0, 0, 0, 0, 1));
				}
			}
		}
	}

	bb = board.pieces[N if board.whitesMove else n];
	for (bb > 0){
		from_sqr = ffs(bb);

		attacks = masks.knight[from_sqr] & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], uint(to_sqr)) > 0{
				add_move(board, enocode_move(from_sqr, to_sqr, int(N if board.whitesMove else n), 0, 1, 0, 0, 0));
			}else{
				add_move(board, enocode_move(from_sqr, to_sqr, int(N if board.whitesMove else n), 0, 0, 0, 0, 0));
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
				add_move(board, enocode_move(from_sqr, to_sqr, int(K if board.whitesMove else k), 0, 1, 0, 0, 0));
			}else{
				add_move(board, enocode_move(from_sqr, to_sqr, int(K if board.whitesMove else k), 0, 0, 0, 0, 0));
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
				add_move(board, enocode_move(from_sqr, to_sqr, int(R if board.whitesMove else R), 0, 1, 0, 0, 0));
			}else{
				add_move(board, enocode_move(from_sqr, to_sqr, int(R if board.whitesMove else R), 0, 0, 0, 0, 0));
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
				add_move(board, enocode_move(from_sqr, to_sqr, int(B if board.whitesMove else b), 0, 1, 0, 0, 0));
			}else{
				add_move(board, enocode_move(from_sqr, to_sqr, int(B if board.whitesMove else b), 0, 0, 0, 0, 0));
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
				add_move(board, enocode_move(from_sqr, to_sqr, int(Q if board.whitesMove else q), 0, 1, 0, 0, 0));
			}else{
				add_move(board, enocode_move(from_sqr, to_sqr, int(Q if board.whitesMove else q), 0, 0, 0, 0, 0));
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
}

get_target_piece :: #force_inline proc(borad: ^C_Board, to_sqr : int) -> uint{
	using PIECES
	for i in 0..=12{
		if get_bit(&borad.pieces[i], uint(to_sqr)) > 0{
			return uint(i);
		}
	}
	assert(0 == 1);
	return 0;
}

enocode_move :: #force_inline proc(from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling: int) -> u64{
	return u64(from_sqr | to_sqr << 6 | piece << 12 | promoted_piece << 16 | is_capture << 20 | is_double_push << 21 | is_en_passant << 22 | is_castling << 23); 
	// 8 bits left, 4 for current castle perm, 4 for a taken piece ?
}

add_info_to_encoded_move :: #force_inline proc (board: ^C_Board, move: u64) -> u64 { 
	return move | u64(board.enPas << 24 | uint(int(board.castlePerm) << 30) | uint(board.fiftyMoves) << 36 | (decode_is_capture(move) > 0 ? get_target_piece(board, decode_to_sqr(move)) : 0) << 42)
}

decode_move :: #force_inline proc(move: u64) -> (int, int, int, int, int, int, int, int){
	return int(move & 0x3f), int(move & 0xfc0) >> 6, int(move & 0xf000) >> 12, int(move & 0xf0000) >> 16, int(move & 0x100000) >> 20, int(move & 0x200000) >> 21, int(move & 0x400000) >> 22, int(move & 0x800000) >> 23
}

decode_u64_move_to_s_move :: #force_inline proc(move: u64, s_move: ^C_Move){
	s_move.from_sqr = decode_from_sqr(move)
	s_move.to_sqr = decode_to_sqr(move)
	s_move.piece = int(move & 0xf000) >> 12
	s_move.promoted_piece = int(move & 0xf0000) >> 16
	s_move.is_capture = int(move & 0x100000) >> 20
	s_move.is_double_push = int(move & 0x200000) >> 21
	s_move.is_en_passant = int(move & 0x400000) >> 22
	s_move.is_castling = int(move & 0x800000) >> 23
	s_move.enPas = int(move & 0x3F000000) >> 24
	s_move.castlePerm = int(move & 0xFC0000000) >> 30
	s_move.fiftyMoves = int(move & 0x3F000000000) >> 36
	s_move.target_piece = int(move & 0xFC0000000000) >> 42
}

decode_from_sqr :: #force_inline proc(move: u64) -> int { return int(move & 0x3f); }
decode_to_sqr :: #force_inline proc(move: u64) -> int { return int(move & 0xfc0) >> 6; }
decode_piece :: #force_inline proc(move: u64) -> int { return int(move & 0xf000) >> 12; }
decode_promoted_piece :: #force_inline proc(move: u64) -> int { return int(move & 0xf0000) >> 16; }
decode_is_capture :: #force_inline proc(move: u64) -> int { return int(move & 0x100000) >> 20; }
decode_is_double_push :: #force_inline proc(move: u64) -> int { return int(move & 0x200000) >> 21; }
decode_is_en_passant :: #force_inline proc(move: u64) -> int { return int(move & 0x400000) >> 22; }
decode_is_castling :: #force_inline proc(move: u64) -> int { return int(move & 0x800000) >> 23; }

make_move :: proc(board: ^C_Board, move: u64){
	board.moveHistory[board.ply] = add_info_to_encoded_move(board, move);

	piece := decode_piece(move);
	piece_color := board.whitesMove ? int(COLOR.WHITE) : int(COLOR.BLACK)
	from_sqr := uint(decode_from_sqr(move));
	to_sqr := uint(decode_to_sqr(move));
	promoted_piece := decode_promoted_piece(move);

	if promoted_piece > 0 { set_bit(&board.pieces[promoted_piece], to_sqr) }
	else { set_bit(&board.pieces[piece], to_sqr) }
	if decode_is_capture(move) > 0 {
		clear_bit(&board.pieces[get_target_piece(board, int(to_sqr))], to_sqr)
		clear_bit(&board.occupied[1 if piece_color == 0 else 1], to_sqr)
	}
	if decode_is_double_push(move) > 0 {
		board.enPas = uint(to_sqr + 8 * (-1 if piece_color == 1 else 1))
	}
	// castling works
	if decode_is_castling(move) > 0 {
		sq1, sq2 : uint
		if board.whitesMove{
			// board.castlePerm &= CASTLING_PERM_ON_MOVE[from_sqr]
			if to_sqr == uint(SQUARES.B1) { sq1, sq2 = uint(SQUARES.A1), uint(SQUARES.C1) }
			else { sq1, sq2 = uint(SQUARES.H1), uint(SQUARES.F1) }
			clear_bit(&board.pieces[int(PIECES.R)], sq1)
			clear_bit(&board.occupied[COLOR.WHITE], sq1)
			clear_bit(&board.occupied[COLOR.BOTH], sq1)
			set_bit(&board.pieces[int(PIECES.R)], sq2)
			set_bit(&board.occupied[COLOR.WHITE], sq2)
			set_bit(&board.occupied[COLOR.BOTH], sq2)
		}else{
			// board.castlePerm &= CASTLING_PERM_ON_MOVE[from_sqr]
			if to_sqr == uint(SQUARES.B1) { sq1, sq2 = uint(SQUARES.A8), uint(SQUARES.C8) }
			else { sq1, sq2 = uint(SQUARES.H8), uint(SQUARES.F8) }
			clear_bit(&board.pieces[int(PIECES.R)], sq1)
			clear_bit(&board.occupied[COLOR.WHITE], sq1)
			clear_bit(&board.occupied[COLOR.BOTH], sq1)
			set_bit(&board.pieces[int(PIECES.R)], sq2)
			set_bit(&board.occupied[COLOR.WHITE], sq2)
			set_bit(&board.occupied[COLOR.BOTH], sq2)
		}
	}

	// this should work too
	board.castlePerm &= CASTLING_PERM_ON_MOVE[from_sqr]
	board.ply += 1
	board.whitesMove = false if board.whitesMove else true

	clear_bit(&board.pieces[piece], from_sqr);
	clear_bit(&board.occupied[piece_color], from_sqr)
	clear_bit(&board.occupied[int(COLOR.BOTH)], from_sqr)
	set_bit(&board.occupied[piece_color], to_sqr)
	set_bit(&board.occupied[int(COLOR.BOTH)], to_sqr)
}

undo_move :: proc(board: ^C_Board, move: ^C_Move) {
	piece_color := board.whitesMove ? int(COLOR.BLACK) : int(COLOR.WHITE)

	// set_bit(&board.occupied[0 if piece_color == int(COLOR.BLACK) else 1], move.to_sqr)
	if move.is_capture > 0 {
		if move.promoted_piece > 0{
			
		}else{
			set_bit(&board.pieces[move.target_piece], uint(move.to_sqr))
			clear_bit(&board.pieces[move.piece], uint(move.to_sqr))
			
			set_bit(&board.occupied[1 - piece_color], uint(move.to_sqr))
			clear_bit(&board.occupied[piece_color], uint(move.to_sqr))
			
			set_bit(&board.occupied[piece_color], uint(move.from_sqr))
			set_bit(&board.pieces[move.piece], uint(move.from_sqr))
			set_bit(&board.occupied[COLOR.BOTH], uint(move.from_sqr))
		}
	}else{
		clear_bit(&board.pieces[move.piece], uint(move.to_sqr))
		set_bit(&board.pieces[move.piece], uint(move.from_sqr))
	}

	board.whitesMove = false if board.whitesMove else true
	if move.is_castling > 0 {
		sq1, sq2 : uint
		if board.whitesMove{
			if move.to_sqr == int(SQUARES.B1) { sq1, sq2 = uint(SQUARES.A1), uint(SQUARES.C1) }
			else { sq1, sq2 = uint(SQUARES.H1), uint(SQUARES.F1) }
			set_bit(&board.pieces[int(PIECES.R)], sq1)
			set_bit(&board.occupied[COLOR.WHITE], sq1)
			set_bit(&board.occupied[COLOR.BOTH], sq1)
			clear_bit(&board.pieces[int(PIECES.R)], sq2)
			clear_bit(&board.occupied[COLOR.WHITE], sq2)
			clear_bit(&board.occupied[COLOR.BOTH], sq2)
		}else{
			if move.to_sqr == int(SQUARES.B1) { sq1, sq2 = uint(SQUARES.A8), uint(SQUARES.C8) }
			else { sq1, sq2 = uint(SQUARES.H8), uint(SQUARES.F8) }
			set_bit(&board.pieces[int(PIECES.R)], sq1)
			set_bit(&board.occupied[COLOR.WHITE], sq1)
			set_bit(&board.occupied[COLOR.BOTH], sq1)
			clear_bit(&board.pieces[int(PIECES.R)], sq2)
			clear_bit(&board.occupied[COLOR.WHITE], sq2)
			clear_bit(&board.occupied[COLOR.BOTH], sq2)
		}
	}

	board.castlePerm = u8(move.castlePerm)
	if move.is_double_push > 0 {
		if move.enPas > int(SQUARES.A8) { board.enPas = uint(move.enPas) }
		else { board.enPas = uint(SQUARES.NO_SQR)}  
	}
	board.ply -= 1
} 