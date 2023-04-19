package main

UP :: 8;

is_square_attacked :: #force_inline proc (board: ^S_Board, masks: ^S_Attack_masks, sqr: u8, by_side: COLOR) -> bool{
	using COLOR;
	using PIECES;	
	if by_side == WHITE && (masks.pawn[BLACK][sqr] & board.pieces[P]) > 0 { return true; }
	if by_side == BLACK && (masks.pawn[WHITE][sqr] & board.pieces[p]) > 0 { return true; }
	if masks.king[sqr] & board.pieces[u8(K) if by_side == WHITE else u8(k)] > 0 { return true; }
	if masks.knight[sqr] & board.pieces[u8(N) if by_side == WHITE else u8(n)] > 0 { return true; }
	if get_rook_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? u8(R) : u8(r)] > 0 { return true; }
	if get_bishop_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? u8(B) : u8(b)] > 0 { return true; }
	if get_queen_attacks(masks, sqr, board.occupied[BOTH]) & board.pieces[by_side == WHITE ? u8(Q) : u8(q)] > 0 { return true; }
	return false;
}

is_king_in_check :: #force_inline proc(board: ^S_Board, masks: ^S_Attack_masks) -> bool{
	board.whitesMove = !board.whitesMove
	is_in_check := is_square_attacked(board, masks, ffs(board.pieces[PIECES.K if board.whitesMove else PIECES.k]), (COLOR.BLACK if board.whitesMove else COLOR.WHITE))
	board.whitesMove = !board.whitesMove
	return is_in_check
}

get_target_piece :: #force_inline proc (borad: ^S_Board, to_sqr : u8) -> u8{
	for i : u8 = 0; i < 12; i+=1{
		if get_bit(&borad.pieces[i], to_sqr) > 0{
			return i;
		}
	}
	return 15;
}

add_move :: #force_inline proc(board: ^S_Board, moves_count: ^u8, move: u64, move_list: ^[256]u64){
	move_list[moves_count^] = add_info_to_encoded_move(board, move);
	moves_count^ += 1;
}

enocode_move :: #force_inline proc (from_sqr, to_sqr, piece, promoted_piece, is_capture, is_double_push, is_en_passant, is_castling: u8) -> u64{
	return (u64(from_sqr) | u64(to_sqr) << 6 | u64(piece) << 12 | u64(promoted_piece) << 16 | u64(is_capture) << 20 | u64(is_double_push) << 21 | u64(is_en_passant) << 22 | u64(is_castling)  << 23); 
}

add_info_to_encoded_move :: #force_inline proc (board: ^S_Board, move: u64) -> u64 { 
	return (move | u64(board.enPas) << 24 | u64(board.castlePerm) << 32 | u64(board.fiftyMoves) << 38 | u64((decode_is_capture(move) > 0 ? get_target_piece(board, decode_to_sqr(move)) : 0)) << 44)
}

decode_move :: #force_inline proc (move: u64) -> (u8, u8, u8, u8, u8, u8, u8, u8){
	return u8(move & 0x3f), u8(move & 0xfc0 >> 6), u8(move & 0xf000 >> 12), u8(move & 0xf0000 >> 16), u8(move & 0x100000 >> 20), u8(move & 0x200000 >> 21), u8(move & 0x400000 >> 22), u8(move & 0x800000 >> 23)
}

decode_from_sqr :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x3f); }
decode_to_sqr :: #force_inline proc (move: u64) -> u8 { return u8(move & 0xfc0 >> 6); }
decode_piece :: #force_inline proc (move: u64) -> u8 { return u8(move & 0xf000 >> 12); }
decode_promoted_piece :: #force_inline proc (move: u64) -> u8 { return u8(move & 0xf0000 >> 16); }
decode_is_capture :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x100000 >> 20); }
decode_is_double_push :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x200000 >> 21); }
decode_is_en_passant :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x400000 >> 22); }
decode_is_castling :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x800000 >> 23); }
decode_en_pas :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x7F000000 >> 24); }
decode_castle_perm :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x3F00000000 >> 32) }
decode_fifty_moves :: #force_inline proc (move: u64) -> u8 { return u8(move & 0xFC000000000 >> 38) }
decode_target_piece :: #force_inline proc (move: u64) -> u8 { return u8(move & 0x3F00000000000 >> 44); }

generate_pseudo_moves :: proc(board: ^S_Board, masks: ^S_Attack_masks, move_list: ^[256]u64) -> u8 #no_bounds_check{
	using PIECES;
	using SQUARES;
	
	moves_count : u8 = 0
	from_sqr, to_sqr : u8;
	bb, attacks, enpas_attack : u64;
	
	if board.whitesMove{
		bb = board.pieces[u8(P)];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr - UP;
			if get_bit(&board.occupied[int(COLOR.BOTH)], to_sqr) == 0{
				if to_sqr < u8(A7){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(Q), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(R), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(B), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(N), 0, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), 0, 0, 0, 0, 0), move_list);
					if from_sqr > u8(H3) && get_bit(&board.occupied[COLOR.BOTH], to_sqr - UP) == 0{
						add_move(board, &moves_count, enocode_move(from_sqr, to_sqr - UP, u8(P), 0, 0, 1, 0, 0), move_list);
					}
				}
			}

			attacks = masks.pawn[COLOR.WHITE][from_sqr] & board.occupied[COLOR.BLACK]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr < u8(A7){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(Q), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(R), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(B), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), u8(N), 1, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), 0, 1, 0, 0, 0), move_list);
				}
				clear_bit(&attacks, to_sqr);
			}
			if board.enPas != u8(NO_SQR){
				enpas_attack = masks.pawn[COLOR.WHITE][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(P), 0, 0, 0, 1, 0), move_list);
				}
			}
			clear_bit(&bb, from_sqr);
		}
		if board.castlePerm & u8(CASTLING.K) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], u8(G1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(F1)) == 0{
				if !is_square_attacked(board, masks, u8(E1), COLOR.BLACK) && !is_square_attacked(board, masks, u8(F1), COLOR.BLACK){
					add_move(board, &moves_count, enocode_move(u8(E1), u8(G1), u8(K), 0, 0, 0, 0, 1), move_list);
				}
			}
		}
		if board.castlePerm & u8(CASTLING.Q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], u8(D1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(C1)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(B1)) == 0{
				if !is_square_attacked(board, masks, u8(E1), COLOR.BLACK) && !is_square_attacked(board, masks, u8(D1), COLOR.BLACK){
					add_move(board, &moves_count, enocode_move(u8(E1), u8(C1), u8(K), 0, 0, 0, 0, 1), move_list);
				}
			}
		}
	}else{
		bb = board.pieces[u8(p)];
		for (bb > 0){
			from_sqr = ffs(bb);
			to_sqr = from_sqr + UP;

			if to_sqr < 64 && get_bit(&board.occupied[COLOR.BOTH], to_sqr) == 0{
				if to_sqr > u8(H2){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(q), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(r), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(b), 0, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(n), 0, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), 0, 0, 0, 0, 0), move_list);
					if from_sqr < u8(A6) && get_bit(&board.occupied[COLOR.BOTH], to_sqr + UP) == 0{
						add_move(board, &moves_count, enocode_move(from_sqr, to_sqr + UP, u8(p), 0, 0, 1, 0, 0), move_list);
					}
				}
			}
			attacks = masks.pawn[int(COLOR.BLACK)][from_sqr] & board.occupied[COLOR.WHITE]
			for (attacks > 0){
				to_sqr = ffs(attacks)
				if to_sqr > u8(H2){
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(q), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(r), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(b), 1, 0, 0, 0), move_list);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), u8(n), 1, 0, 0, 0), move_list);
				}else{
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), 0, 1, 0, 0, 0), move_list);
				}
				clear_bit(&attacks, to_sqr);
			}
			if board.enPas != u8(NO_SQR){
				enpas_attack = masks.pawn[COLOR.BLACK][from_sqr] & (1 << board.enPas);
				if enpas_attack > 0{
					to_sqr = ffs(enpas_attack);
					add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(p), 0, 0, 0, 1, 0), move_list);
				}
			}
			clear_bit(&bb, from_sqr);
		}
		if board.castlePerm & u8(CASTLING.k) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], u8(G8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(F8)) == 0{
				if !is_square_attacked(board, masks, u8(E8), COLOR.WHITE) && !is_square_attacked(board, masks, u8(F8), COLOR.WHITE){
					add_move(board, &moves_count, enocode_move(u8(E8), u8(G8), u8(k), 0, 0, 0, 0, 1), move_list);
				}
			}
		}
		if board.castlePerm & u8(CASTLING.q) > 0{
			if get_bit(&board.occupied[COLOR.BOTH], u8(D8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(C8)) == 0 && get_bit(&board.occupied[COLOR.BOTH], u8(B8)) == 0{
				if !is_square_attacked(board, masks, u8(E8), COLOR.WHITE) && !is_square_attacked(board, masks, u8(D8), COLOR.WHITE){
					add_move(board, &moves_count, enocode_move(u8(E8), u8(C8), u8(k), 0, 0, 0, 0, 1), move_list);
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
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], to_sqr) > 0{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(N if board.whitesMove else n), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(N if board.whitesMove else n), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, to_sqr);
		}
		clear_bit(&bb, from_sqr);
	}
	bb = board.pieces[K if board.whitesMove else k];
	for (bb > 0){
		from_sqr = ffs(bb);
		attacks = masks.king[from_sqr] & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], to_sqr) > 0{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(K if board.whitesMove else k), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(K if board.whitesMove else k), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, to_sqr);
		}
		clear_bit(&bb, from_sqr);
	}
	bb = board.pieces[R if board.whitesMove else r];
	for (bb > 0){
		from_sqr = ffs(bb);
		attacks = get_rook_attacks(masks, from_sqr, board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], to_sqr) > 0{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(R if board.whitesMove else r), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(R if board.whitesMove else r), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, to_sqr);
		}
		clear_bit(&bb, from_sqr);
	}
	bb = board.pieces[B if board.whitesMove else b];
	for (bb > 0){
		from_sqr = ffs(bb);
		attacks = get_bishop_attacks(masks, from_sqr, board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], to_sqr) > 0{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(B if board.whitesMove else b), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(B if board.whitesMove else b), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, to_sqr);
		}
		clear_bit(&bb, from_sqr);
	}
	bb = board.pieces[Q if board.whitesMove else q];
	for (bb > 0){
		from_sqr = ffs(bb);
		attacks = get_queen_attacks(masks, from_sqr, board.occupied[COLOR.BOTH]) & (board.whitesMove ? ~board.occupied[COLOR.WHITE] : ~board.occupied[COLOR.BLACK]);
		for (attacks > 0){
			to_sqr = ffs(attacks);
			if get_bit(board.whitesMove ? &board.occupied[COLOR.BLACK] : &board.occupied[COLOR.WHITE], to_sqr) > 0{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(Q if board.whitesMove else q), 0, 1, 0, 0, 0), move_list);
			}else{
				add_move(board, &moves_count, enocode_move(from_sqr, to_sqr, u8(Q if board.whitesMove else q), 0, 0, 0, 0, 0), move_list);
			}
			clear_bit(&attacks, to_sqr);
		}
		clear_bit(&bb, from_sqr);
	}
	return moves_count
}

make_move :: proc(board: ^S_Board, move: u64){
	// board.moveHistory[board.ply] = move
	piece := decode_piece(move);
	piece_color := board.whitesMove ? int(COLOR.WHITE) : int(COLOR.BLACK)
	from_sqr := u8(decode_from_sqr(move));
	to_sqr := u8(decode_to_sqr(move));
	promoted_piece := decode_promoted_piece(move);

	clear_bit(&board.pieces[piece], from_sqr);
	board.enPas = u8(SQUARES.NO_SQR)

	if promoted_piece > 0 { set_bit(&board.pieces[promoted_piece], to_sqr) }
	else { set_bit(&board.pieces[piece], to_sqr) }

	if decode_is_capture(move) > 0 {
		board.fiftyMoves = 0
		clear_bit(&board.pieces[decode_target_piece(move)], to_sqr)
	}else{
		if (piece != u8(PIECES.P) && piece != u8(PIECES.p)) { board.fiftyMoves += 1 }
	}
	if decode_is_double_push(move) > 0 {
		board.enPas = u8(to_sqr + 8 * (-1 if piece_color == 1 else 1))
	}
	if decode_is_castling(move) > 0 {
		sq1, sq2 : u8
		if board.whitesMove{
			if to_sqr == u8(SQUARES.C1) { sq1, sq2 = u8(SQUARES.A1), u8(SQUARES.D1) }
			else { sq1, sq2 = u8(SQUARES.H1), u8(SQUARES.F1) }
			clear_bit(&board.pieces[PIECES.R], sq1)
			set_bit(&board.pieces[PIECES.R], sq2)
		}else{
			if to_sqr == u8(SQUARES.C8) { sq1, sq2 = u8(SQUARES.A8), u8(SQUARES.D8) }
			else { sq1, sq2 = u8(SQUARES.H8), u8(SQUARES.F8) }
			clear_bit(&board.pieces[PIECES.r], sq1)
			set_bit(&board.pieces[PIECES.r], sq2)
		}
	}
	if decode_is_en_passant(move) > 0{
		clear_bit(&board.pieces[PIECES.p if board.whitesMove else PIECES.P], to_sqr + 8 * (1 if piece_color == 0 else -1))
	}

	board.castlePerm &= CASTLING_PERM_ON_MOVE[from_sqr]
	board.castlePerm &= CASTLING_PERM_ON_MOVE[to_sqr]
	board.ply += 1
	board.whitesMove = !board.whitesMove
	update_occupied(board)
}

undo_move :: proc(board: ^S_Board, move: u64) {
	piece_color := board.whitesMove ? int(COLOR.BLACK) : int(COLOR.WHITE)
	piece := decode_piece(move)
	from_sqr := decode_from_sqr(move)
	to_sqr := decode_to_sqr(move)

	set_bit(&board.pieces[piece], from_sqr)

	if decode_promoted_piece(move) > 0 { 
		clear_bit(&board.pieces[decode_promoted_piece(move)], to_sqr) 
	}else { 
		clear_bit(&board.pieces[piece], to_sqr) 
	}
	if decode_is_capture(move) > 0 {
		set_bit(&board.pieces[decode_target_piece(move)], to_sqr)
	}
	if decode_is_en_passant(move) > 0{
		set_bit(&board.pieces[PIECES.p if piece_color == 0 else PIECES.P], to_sqr + 8 * (1 if piece_color == 0 else -1))
	}

	board.whitesMove = !board.whitesMove
	if decode_is_castling(move) > 0 {
		sq1, sq2 : u8
		if board.whitesMove{
			if to_sqr == u8(SQUARES.C1) { sq1, sq2 = u8(SQUARES.A1), u8(SQUARES.D1) }
			else { sq1, sq2 = u8(SQUARES.H1), u8(SQUARES.F1) }
			set_bit(&board.pieces[int(PIECES.R)], sq1)
			clear_bit(&board.pieces[int(PIECES.R)], sq2)
		}else{
			if to_sqr == u8(SQUARES.C8) { sq1, sq2 = u8(SQUARES.A8), u8(SQUARES.D8) }
			else { sq1, sq2 = u8(SQUARES.H8), u8(SQUARES.F8) }
			set_bit(&board.pieces[int(PIECES.r)], sq1)
			clear_bit(&board.pieces[int(PIECES.r)], sq2)
		}
	}

	board.fiftyMoves = decode_fifty_moves(move)
	board.castlePerm = decode_castle_perm(move)
	board.enPas = decode_en_pas(move)
	board.ply -= 1
	update_occupied(board)
}