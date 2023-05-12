package main

import "core:fmt"

KING_WT :: 10000
QUEEN_WT :: 1000
ROOK_WT :: 525
BISHOP_WT :: 350
KNIGHT_WT :: 350
PAWN_WT :: 100

pawn_score : [64]i8 = 
{
    90,  90,  90,  90,  90,  90,  90,  90,
    30,  30,  30,  40,  40,  30,  30,  30,
    20,  20,  20,  30,  30,  30,  20,  20,
    10,  10,  10,  20,  20,  10,  10,  10,
     5,   5,  10,  20,  20,   5,   5,   5,
     0,   0,   0,   5,   5,   0,   0,   0,
     0,   0,   0, -10, -10,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
};

knight_score : [64]i8 = 
{
    -5,   0,   0,   0,   0,   0,   0,  -5,
    -5,   0,   0,  10,  10,   0,   0,  -5,
    -5,   5,  20,  20,  20,  20,   5,  -5,
    -5,  10,  20,  30,  30,  20,  10,  -5,
    -5,  10,  20,  30,  30,  20,  10,  -5,
    -5,   5,  20,  10,  10,  20,   5,  -5,
    -5,   0,   0,   0,   0,   0,   0,  -5,
    -5, -10,   0,   0,   0,   0, -10,  -5,
};

bishop_score : [64]i8 = 
{
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,  20,   0,  10,  10,   0,  20,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,  10,   0,   0,   0,   0,  10,   0,
     0,  30,   0,   0,   0,   0,  30,   0,
     0,   0, -10,   0,   0, -10,   0,   0,
};

rook_score : [64]i8 =
{
    50,  50,  50,  50,  50,  50,  50,  50,
    50,  50,  50,  50,  50,  50,  50,  50,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,  10,  20,  20,  10,   0,   0,
     0,   0,   0,  20,  20,   0,   0,   0,
};

queen_score : [64]i8 =
{
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
};

king_score : [64]i8 = 
{
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   5,   5,   5,   5,   0,   0,
     0,   5,   5,  10,  10,   5,   5,   0,
     0,   5,  10,  20,  20,  10,   5,   0,
     0,   5,  10,  20,  20,  10,   5,   0,
     0,   0,   5,  10,  10,   5,   0,   0,
     0,   5,   5,  -5,  -5,   0,   5,   0,
     0,   0,   5,   0, -15,   0,  10,   0,
};

mirror_score : [64]i8 =
{
	i8(SQUARES.A1), i8(SQUARES.B1), i8(SQUARES.C1), i8(SQUARES.D1), i8(SQUARES.E1), i8(SQUARES.F1), i8(SQUARES.G1), i8(SQUARES.H1),
	i8(SQUARES.A2), i8(SQUARES.B2), i8(SQUARES.C2), i8(SQUARES.D2), i8(SQUARES.E2), i8(SQUARES.F2), i8(SQUARES.G2), i8(SQUARES.H2),
	i8(SQUARES.A3), i8(SQUARES.B3), i8(SQUARES.C3), i8(SQUARES.D3), i8(SQUARES.E3), i8(SQUARES.F3), i8(SQUARES.G3), i8(SQUARES.H3),
	i8(SQUARES.A4), i8(SQUARES.B4), i8(SQUARES.C4), i8(SQUARES.D4), i8(SQUARES.E4), i8(SQUARES.F4), i8(SQUARES.G4), i8(SQUARES.H4),
	i8(SQUARES.A5), i8(SQUARES.B5), i8(SQUARES.C5), i8(SQUARES.D5), i8(SQUARES.E5), i8(SQUARES.F5), i8(SQUARES.G5), i8(SQUARES.H5),
	i8(SQUARES.A6), i8(SQUARES.B6), i8(SQUARES.C6), i8(SQUARES.D6), i8(SQUARES.E6), i8(SQUARES.F6), i8(SQUARES.G6), i8(SQUARES.H6),
	i8(SQUARES.A7), i8(SQUARES.B7), i8(SQUARES.C7), i8(SQUARES.D7), i8(SQUARES.E7), i8(SQUARES.F7), i8(SQUARES.G7), i8(SQUARES.H7),
	i8(SQUARES.A8), i8(SQUARES.B8), i8(SQUARES.C8), i8(SQUARES.D8), i8(SQUARES.E8), i8(SQUARES.F8), i8(SQUARES.G8), i8(SQUARES.H8),
};

PIECES_SQR_WEIGHT : [6]^[64]i8 = { 
    &pawn_score, &knight_score, &bishop_score, &rook_score, &queen_score, &king_score,
}
PIECES_WEIGHT : [6]i32 = { 
    PAWN_WT, KNIGHT_WT, BISHOP_WT, ROOK_WT, QUEEN_WT, KING_WT,
}
SIDE_MULTIPLIER : [2]i32 = {-1, 1}

eval :: proc (board: ^S_Board) -> i32{
    evaluation : i32 = 0
    bb : u64;
    sqr : u8;

    for piece in 0..<12{
        bb = board.pieces[piece]
        for (bb > 0){
            sqr = ffs(bb)
            if piece < int(PIECES.P){
                evaluation -= PIECES_WEIGHT[piece]
                evaluation -= i32(PIECES_SQR_WEIGHT[piece][mirror_score[sqr]])
            }else{
                evaluation += PIECES_WEIGHT[piece - 6]
                evaluation += i32(PIECES_SQR_WEIGHT[piece - 6][sqr])
            }
            clear_bit(&bb, sqr)
        }
    }

    return (evaluation * SIDE_MULTIPLIER[int(board.whitesMove)])
}