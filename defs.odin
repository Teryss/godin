package main

import "core:fmt"

STARTING_POS :: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
EMPTY_BOARD :: "8/8/8/8/8/8/8/8 b - - "
TRICKY_POSITION :: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
KILLER_POSITION :: "rnbqkb1r/pp1p1pPp/8/2p1pP2/1P1P4/3P3P/P1P1P3/RNBQKBNR w KQkq e6 0 1"
CMK_POSITION :: "r2q1rk1/ppp2ppp/2n1bn2/2b1p3/3pP3/3P1NPP/PPP1NPB1/R1BQ1RK1 b - - 0 9"
REPETITIONS :: "2r3k1/R7/8/1R6/8/8/P4KPP/8 w - - 0 40"	

SQUARES :: enum {
	A8, B8, C8, D8, E8, F8, G8, H8,
	A7, B7, C7, D7, E7, F7, G7, H7,
	A6, B6, C6, D6, E6, F6, G6, H6,
	A5, B5, C5, D5, E5, F5, G5, H5,
	A4, B4, C4, D4, E4, F4, G4, H4,
	A3, B3, C3, D3, E3, F3, G3, H3,
	A2, B2, C2, D2, E2, F2, G2, H2,
	A1, B1, C1, D1, E1, F1, G1, H1, NO_SQR,
};
SQUARE_TO_CHR : [65]string = {
	"a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8",
	"a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7",
	"a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6",
	"a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5",
	"a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4",
	"a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3",
	"a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2",
	"a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1", "NO_SQR",
};
COLOR :: enum { WHITE, BLACK, BOTH };
CASTLING :: enum { K = 1, Q = 2, k = 4, q = 8 };
PIECES :: enum { p = 0, n, b, r, q, k, P, N, B, R, Q, K };
// white is upper case
PIECES_CHR : string = "pnbrqkPNBRQK";


C_Board :: struct {
	pieces : [12]u64,
	occupied : [3]u64,
	fiftyMoves: int,
	ply: int,
	moveHistory: [2048]u64,
	castlePerm: u8,
	whitesMove: bool,
	enPas: uint,
};

C_Attack_masks :: struct{
    pawn : [2][64]u64,
	knight : [64]u64,
	bishop : [64]u64,
	king : [64]u64,
	rook : [64]u64,
	rook_attacks : [64][4096]u64,
	bishop_attacks : [64][512]u64,
};

FR_2_SQR :: proc(f, r: int) -> uint{
	return uint(r * 8 + f);
}

print_bitboard :: proc(bb: u64){
	bb_p : u64 = bb;
	for r in 0..<8{
		for f in 0..<8{
			if f == 0{
				fmt.printf("    %d ", 8 - r);
			}
			sqr := (FR_2_SQR(f, r));
			fmt.printf("%s", get_bit(&bb_p, sqr) > 0 ? " X " : " . ");
		}
		fmt.println()
	}
	fmt.printf("\n       A  B  C  D  E  F  G  H\n")
    fmt.printf("\n\n       Bitboard: %d\n", bb);
}

print_board :: proc(board: ^C_Board){
	// bb : u64 = 0;
	fmt.println()
	for r in 0..<8{
		for f in 0..<8{
			if f == 0{
				fmt.printf("    %d ", 8 - r);
			}
			sqr := (FR_2_SQR(f, r));
			piece := -10
			for i in 0..<12{
				// bb |= board.pieces[i];
				if get_bit(&board.pieces[i], sqr) > 0 { piece = i; break; };
			}
			fmt.printf(" %c ", piece != -10 ? PIECES_CHR[piece] : '.');
		}
		fmt.println()
	}
	fmt.printf("\n       A  B  C  D  E  F  G  H\n")
	fmt.println("\nWhite to move?", board.whitesMove ? "Yes" : "No");
	fmt.println("Castle permission:", 
			board.castlePerm & u8(CASTLING.K) > 0 ? "wK" : "", 
			board.castlePerm & u8(CASTLING.Q) > 0 ? "wQ" : "",
			board.castlePerm & u8(CASTLING.k) > 0 ? "bK" : "", 
			board.castlePerm & u8(CASTLING.q) > 0 ? "bQ" : "", 
	);
	fmt.println("En passant", SQUARE_TO_CHR[board.enPas]);
	fmt.println("Fifty moves:", board.fiftyMoves);
	fmt.println("Ply:", board.ply);
	fmt.println()
}

update_occupied :: proc(board: ^C_Board){
    for i in 0..<12{
	    board.occupied[int(COLOR.BOTH)] |= board.pieces[i]
	    if i >= int(PIECES.P) { board.occupied[int(COLOR.WHITE)] |= board.pieces[i] }
	    else { board.occupied[int(COLOR.BLACK)] |= board.pieces[i] }
    }
}

u8_piece_to_int :: proc (piece: u8) -> int{
	using PIECES
	switch piece{
		case u8(80): return int(P);
		case u8(78): return int(N);
		case u8(66): return int(B);
		case u8(82): return int(R);
		case u8(81): return int(Q);
		case u8(75): return int(K);
		case u8(112): return int(p);
		case u8(110): return int(n);
		case u8(98): return int(b);
		case u8(114): return int(r);
		case u8(113): return int(q);
		case u8(107): return int(k);
	}
	return -10;
}

load_fen :: proc(board: ^C_Board, fen: string){
	fen_split : [6]string;
	temp : [dynamic]u8;
	space_ascii : u8 = 32;
	counter : int = 0;

	for i in 0..<len(fen){
		if counter == 6 { fmt.println("Wrong FEN lenght!"); break; }
		if fen[i] == space_ascii || i == len(fen) - 1{
			if len(temp) == 0{
				append(&temp, fen[i]);		
			}
			fen_split[counter] = transmute(string)temp[:];
			temp = {};
			counter += 1;
			continue
		}
		append(&temp, fen[i]);
		if (len(temp) == 0) { fmt.println("Wrong FEN!"); break; }
	}

	sqr : uint = uint(SQUARES.A8);
	for i in 0..<len(fen_split[0]){
		if fen_split[0][i] >= 'A' && fen_split[0][i] <= 'Z' || fen_split[0][i] >= 'a' && fen_split[0][i] <= 'z'{
			set_bit(&board.pieces[u8_piece_to_int(fen_split[0][i])], sqr);
			sqr += 1;
		}else if fen_split[0][i] >= '0' && fen_split[0][i] < '9'{
			sqr += uint(fen_split[0][i]) - uint('0');
		}else if fen_split[0][i] == '/'{
			continue;
		}else{
			fmt.println("Couldn't parse a piece FEN:", rune(fen_split[0][i]));
		}
	}

	if fen_split[1][0] != 'w' && fen_split[1][0] != 'b'{
		fmt.println("Couldn't parse side to move from FEN [w or b or -], got:", rune(fen_split[1][0]));
	}
	board.whitesMove = (fen_split[1] == string("w") ? true : false);

	if fen_split[2][0] != '-'{
		board.castlePerm = 0
		for i in 0..<len(fen_split[2]){
			switch fen_split[2][i]{
				case 'K': board.castlePerm |= u8(CASTLING.K);
				case 'Q': board.castlePerm |= u8(CASTLING.Q);
				case 'k': board.castlePerm |= u8(CASTLING.k);
				case 'q': board.castlePerm |= u8(CASTLING.q);
			}
		}
		if board.castlePerm == 0 { fmt.println("Wrong castle permission, expected - or combination of KQkq, got:", fen_split[2])};
	}

	board.enPas = uint(SQUARES.NO_SQR);
	if fen_split[3][0] != '-' { board.enPas = FR_2_SQR(int(fen_split[3][0] - u8('a')), int(fen_split[3][1] - u8('1')))}

	board.ply = len(fen_split[5]) == 1 ? int(fen_split[5][0])  - int('0') : (int(fen_split[5][0])  - int('0')) * 10 + int(fen_split[5][1]) - int('0');
	board.fiftyMoves = len(fen_split[4]) == 1 ? int(fen_split[4][0]) - int('0') : (int(fen_split[4][0]) - int('0')) * 10 + int(fen_split[4][1]) - int('0');

	update_occupied(board);
}