package main

import "core:fmt"

STARTING_POS :: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
EMPTY_BOARD :: "8/8/8/8/8/8/8/8 b - - "
TRICKY_POSITION :: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
KILLER_POSITION :: "rnbqkb1r/pp1p1pPp/8/2p1pP2/1P1P4/3P3P/P1P1P3/RNBQKBNR w KQkq e6 0 1"
CMK_POSITION :: "r2q1rk1/ppp2ppp/2n1bn2/2b1p3/3pP3/3P1NPP/PPP1NPB1/R1BQ1RK1 b - - 0 9"
REPETITIONS :: "2r3k1/R7/8/1R6/8/8/P4KPP/8 w - - 0 40"
POS_3 :: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
MAX_PLY :: 2048

SQUARES :: enum{
	A8 = 0, B8, C8, D8, E8, F8, G8, H8,
	A7	  , B7, C7, D7, E7, F7, G7, H7,
	A6	  , B6, C6, D6, E6, F6, G6, H6,
	A5	  , B5, C5, D5, E5, F5, G5, H5,
	A4	  , B4, C4, D4, E4, F4, G4, H4,
	A3	  , B3, C3, D3, E3, F3, G3, H3,
	A2	  , B2, C2, D2, E2, F2, G2, H2,
	A1	  , B1, C1, D1, E1, F1, G1, H1, NO_SQR = 64,
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
PIECES :: enum u8 { p = 0, n, b, r, q, k, P, N, B, R, Q, K };
PIECES_CHR : string = "pnbrqkPNBRQK";

u8_to_piece := map[u8]int {
	'P' = int(PIECES.P),
	'N' = int(PIECES.N),
	'B' = int(PIECES.B),
	'R' = int(PIECES.R),
	'Q' = int(PIECES.Q),
	'K' = int(PIECES.K),
	'p' = int(PIECES.p),
	'n' = int(PIECES.n),
	'b' = int(PIECES.b),
	'r' = int(PIECES.r),
	'q' = int(PIECES.q),
	'k' = int(PIECES.k),
}

CASTLING_PERM_ON_MOVE : [64]u8 = {
	 7, 15, 15, 15,  3, 15, 15, 11,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 15, 15, 15, 15, 15, 15, 15,
	13, 15, 15, 15, 12, 15, 15, 14,
}

@(export)
FR_2_SQR :: #force_inline proc(f, r: u8) -> u8{
	return r * 8 + f;
}