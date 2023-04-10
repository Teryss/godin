package main

import "core:fmt"

UP :: 8;

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

add_move :: #force_inline proc(board : ^C_Board, moves_count: ^int, move: u64, move_list: ^[256]u64){
	move_list[moves_count^] = add_info_to_encoded_move(board, move);

	move_after := move_list[moves_count^]
	assert(decode_castle_perm(move_after) == int(board.castlePerm), "Castle perm is wrong")
	if decode_en_pas(move_after) != int(board.enPas){
		fmt.println(board.enPas, decode_en_pas(move_after))
		assert(decode_en_pas(move_after) == int(board.enPas), "En pas sqr wrong")
	}
	assert(decode_fifty_moves(move_after) == board.fiftyMoves, "Wrong fifty move")
	assert((decode_is_capture(move_after) > 0 ? int(get_target_piece(board, decode_to_sqr(move_after))) : 0) == decode_target_piece(move_after), "Wrong target square")
	moves_count^ += 1;
}
// #no_bounds_check
generate_pseudo_moves :: proc(board: ^C_Board, masks: ^C_Attack_masks, move_list: ^[256]u64) -> int #no_bounds_check{
	using PIECES;
	using SQUARES;
	
	moves_count : int = 0
	from_sqr, to_sqr : int;
	bb, attacks, enpas_attack : u64;
	
	if board.whitesMove{
		bb = board.pieces[P];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr - UP;
			if to_sqr > -1 && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr)) == 0{
				if to_sqr < int(A7){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(Q), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(R), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(B), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(N), 0, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 0, 0, 0), move_list);
					if from_sqr > int(H3) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr - UP)) == 0{
						add_move(board, &moves_count, enocode_move(from_sqr, to_sqr - UP, int(P), 0, 0, 1, 0, 0), move_list);
					}
				}
			}

			attacks = masks.pawn[int(COLOR.WHITE)][from_sqr] & board.occupied[int(COLOR.BLACK)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr < int(A7){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(Q), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(R), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(B), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), int(N), 1, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), 0, 1, 0, 0, 0), move_list);
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.WHITE)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(P), 0, 0, 0, 1, 0), move_list);
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.K) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(F1), COLOR.BLACK){
					add_move(board, &moves_count, enocode_move(int(E1), int(G1), int(K), 0, 0, 0, 0, 1), move_list);
				}
			}
		}
		if board.castlePerm & u8(CASTLING.Q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B1)) == 0{
				if !is_square_attacked(board, masks, uint(E1), COLOR.BLACK) && !is_square_attacked(board, masks, uint(D1), COLOR.BLACK){
					add_move(board, &moves_count, enocode_move(int(E1), int(C1), int(K), 0, 0, 0, 0, 1), move_list);
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
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(q), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(r), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(b), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(n), 0, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), 0, 0, 0, 0, 0), move_list);
					if from_sqr < int(A6) && get_bit(&board.occupied[int(COLOR.BOTH)], uint(to_sqr + UP)) == 0{
						add_move(board, &moves_count, enocode_move(from_sqr, to_sqr + UP, int(p), 0, 0, 1, 0, 0), move_list);
					}
				}
			}
			attacks = masks.pawn[int(COLOR.BLACK)][from_sqr] & board.occupied[int(COLOR.WHITE)]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr > int(H2){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(q), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(r), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(b), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), int(n), 1, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), 0, 1, 0, 0, 0), move_list);
				}
				clear_bit(&attacks, uint(to_sqr));
			}
			if board.enPas != uint(NO_SQR){
				enpas_attack = masks.pawn[int(COLOR.BLACK)][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(p), 0, 0, 0, 1, 0), move_list);
				}
			}
			clear_bit(&bb, uint(from_sqr));
		}
		if board.castlePerm & u8(CASTLING.k) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(G8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(F8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(F8), COLOR.WHITE){
					add_move(board, &moves_count, enocode_move(int(E8), int(G8), int(k), 0, 0, 0, 0, 1), move_list);
				}
			}
		}
		if board.castlePerm & u8(CASTLING.q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], uint(D8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(C8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], uint(B8)) == 0{
				if !is_square_attacked(board, masks, uint(E8), COLOR.WHITE) && !is_square_attacked(board, masks, uint(D8), COLOR.WHITE){
					add_move(board, &moves_count, enocode_move(int(E8), int(C8), int(k), 0, 0, 0, 0, 1), move_list);
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
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(N if board.whitesMove else n), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(N if board.whitesMove else n), 0, 0, 0, 0, 0), move_list);
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
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(K if board.whitesMove else k), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(K if board.whitesMove else k), 0, 0, 0, 0, 0), move_list);
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
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(R if board.whitesMove else r), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(R if board.whitesMove else r), 0, 0, 0, 0, 0), move_list);
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
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(B if board.whitesMove else b), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(B if board.whitesMove else b), 0, 0, 0, 0, 0), move_list);
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
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(Q if board.whitesMove else q), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, int(Q if board.whitesMove else q), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, uint(to_sqr));
		}
		clear_bit(&bb, uint(from_sqr));
	}
	return moves_count
}

get_target_piece :: #force_inline proc (borad: ^C_Board, to_sqr : int) -> uint{
	using PIECES
	for i in 0..<12{
		if get_bit(&borad.pieces[i], uint(to_sqr)) > 0{
			return uint(i);
		}
	}
	// fmt.println(SQUARE_TO_CHR[to_sqr])
	assert(0 == 1, "Couldn't find which piece is going to be captured");
	return 15;
}

enocode_move :: #force_inline proc "contextless" (from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling: int) -> u64{
	return u64(from_sqr | to_sqr << 6 | piece << 12 | promoted_piece << 16 | is_capture << 20 | is_double_push << 21 | is_en_passant << 22 | is_castling << 23); 
}

add_info_to_encoded_move :: #force_inline proc (board: ^C_Board, move: u64) -> u64 { 
	return move | u64(board.enPas << 24 | uint(board.castlePerm) << 32 | uint(board.fiftyMoves) << 38 | (decode_is_capture(move) > 0 ? get_target_piece(board, decode_to_sqr(move)) : 0) << 44)
}

decode_move :: #force_inline proc "contextless" (move: u64) -> (int, int, int, int, int, int, int, int){
	return int(move & 0x3f), int(move & 0xfc0) >> 6, int(move & 0xf000) >> 12, int(move & 0xf0000) >> 16, int(move & 0x100000) >> 20, int(move & 0x200000) >> 21, int(move & 0x400000) >> 22, int(move & 0x800000) >> 23
}

decode_from_sqr :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x3f); }
decode_to_sqr :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0xfc0) >> 6; }
decode_piece :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0xf000) >> 12; }
decode_promoted_piece :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0xf0000) >> 16; }
decode_is_capture :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x100000) >> 20; }
decode_is_double_push :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x200000) >> 21; }
decode_is_en_passant :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x400000) >> 22; }
decode_is_castling :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x800000) >> 23; }
// 3F000000
decode_en_pas :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x7F000000) >> 24; }
decode_castle_perm :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x3F00000000) >> 32 }
decode_fifty_moves :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0xFC000000000) >> 38 }
decode_target_piece :: #force_inline proc "contextless" (move: u64) -> int { return int(move & 0x3F00000000000) >> 44; }

make_move :: proc(board: ^C_Board, move: u64){
	board.moveHistory[board.ply] = move
	piece := decode_piece(move);
	piece_color := board.whitesMove ? int(COLOR.WHITE) : int(COLOR.BLACK)
	from_sqr := uint(decode_from_sqr(move));
	to_sqr := uint(decode_to_sqr(move));
	promoted_piece := decode_promoted_piece(move);

	clear_bit(&board.pieces[piece], from_sqr);
	board.enPas = uint(SQUARES.NO_SQR)

	if promoted_piece > 0 { set_bit(&board.pieces[promoted_piece], to_sqr) }
	else { set_bit(&board.pieces[piece], to_sqr) }

	if decode_is_capture(move) > 0 {
		board.fiftyMoves = 0
		clear_bit(&board.pieces[decode_target_piece(move)], uint(to_sqr))
	}else{
		if (piece != int(PIECES.P) && piece != int(PIECES.p)) { board.fiftyMoves += 1 }
	}
	if decode_is_double_push(move) > 0 {
		board.enPas = uint(to_sqr + 8 * (-1 if piece_color == 1 else 1))
	}
	if decode_is_castling(move) > 0 {
		sq1, sq2 : uint
		if board.whitesMove{
			if to_sqr == uint(SQUARES.C1) { sq1, sq2 = uint(SQUARES.A1), uint(SQUARES.D1) }
			else { sq1, sq2 = uint(SQUARES.H1), uint(SQUARES.F1) }
			clear_bit(&board.pieces[int(PIECES.R)], sq1)
			set_bit(&board.pieces[int(PIECES.R)], sq2)
		}else{
			if to_sqr == uint(SQUARES.C8) { sq1, sq2 = uint(SQUARES.A8), uint(SQUARES.D8) }
			else { sq1, sq2 = uint(SQUARES.H8), uint(SQUARES.F8) }
			clear_bit(&board.pieces[int(PIECES.r)], sq1)
			set_bit(&board.pieces[int(PIECES.r)], sq2)
		}
	}
	if decode_is_en_passant(move) > 0{
		clear_bit(&board.pieces[PIECES.p if board.whitesMove else PIECES.P], uint(to_sqr + 8 * (1 if piece_color == 0 else -1)))
	}

	board.castlePerm &= CASTLING_PERM_ON_MOVE[from_sqr]
	board.castlePerm &= CASTLING_PERM_ON_MOVE[to_sqr]
	board.ply += 1
	board.whitesMove = !board.whitesMove
	update_occupied(board)
}

undo_move :: proc(board: ^C_Board, move: u64) {
	piece_color := board.whitesMove ? int(COLOR.BLACK) : int(COLOR.WHITE)
	piece := decode_piece(move)
	from_sqr := decode_from_sqr(move)
	to_sqr := decode_to_sqr(move)

	set_bit(&board.pieces[piece], uint(from_sqr))

	if decode_promoted_piece(move) > 0 { 
		clear_bit(&board.pieces[decode_promoted_piece(move)], uint(to_sqr)) 
	}else { 
		clear_bit(&board.pieces[piece], uint(to_sqr)) 
	}
	if decode_is_capture(move) > 0 {
		set_bit(&board.pieces[decode_target_piece(move)], uint(to_sqr))
	}
	if decode_is_en_passant(move) > 0{
		set_bit(&board.pieces[PIECES.p if piece_color == 0 else PIECES.P], uint(to_sqr + 8 * (1 if piece_color == 0 else -1)))
	}

	board.whitesMove = !board.whitesMove
	if decode_is_castling(move) > 0 {
		// print_single_move(move)
		sq1, sq2 : uint
		if board.whitesMove{
			if to_sqr == int(SQUARES.C1) { sq1, sq2 = uint(SQUARES.A1), uint(SQUARES.D1) }
			else { sq1, sq2 = uint(SQUARES.H1), uint(SQUARES.F1) }
			set_bit(&board.pieces[int(PIECES.R)], sq1)
			clear_bit(&board.pieces[int(PIECES.R)], sq2)
		}else{
			if to_sqr == int(SQUARES.C8) { sq1, sq2 = uint(SQUARES.A8), uint(SQUARES.D8) }
			else { sq1, sq2 = uint(SQUARES.H8), uint(SQUARES.F8) }
			set_bit(&board.pieces[int(PIECES.r)], sq1)
			clear_bit(&board.pieces[int(PIECES.r)], sq2)
		}
	}

	board.fiftyMoves = decode_fifty_moves(move)
	board.castlePerm = u8(decode_castle_perm(move))
	board.enPas = uint(decode_en_pas(move))
	board.ply -= 1
	update_occupied(board)
}

is_king_in_check :: #force_inline proc(board: ^C_Board, masks: ^C_Attack_masks) -> bool{
	board.whitesMove = !board.whitesMove
	is_in_check := is_square_attacked(board, masks, uint(ffs(board.pieces[PIECES.K if board.whitesMove else PIECES.k])), (COLOR.BLACK if board.whitesMove else COLOR.WHITE))
	// fmt.println(SQUARE_TO_CHR[ffs(board.pieces[PIECES.K if board.whitesMove else PIECES.k])], is_in_check)
	board.whitesMove = !board.whitesMove
	return is_in_check
}