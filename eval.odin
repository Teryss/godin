package main

KING_WT :: 10000
QUEEN_WT :: 1000
ROOK_WT :: 525
BISHOP_WT :: 350
KNIGHT_WT :: 350
PAWN_WT :: 100

import "core:fmt"

PIECES_WEIGHT : [6]i32 = {PAWN_WT, KNIGHT_WT, BISHOP_WT, ROOK_WT, QUEEN_WT, KING_WT}
SIDE_MULTIPLIER : [2]i32 = {-1, 1}

eval :: #force_inline proc (board: ^S_Board) -> i32{
    evaluation : i32 = 0

    for index in 6..<12{
        // white pieces
        evaluation += i32(count_bits(board.pieces[index - 6 * int(!board.whitesMove)])) * PIECES_WEIGHT[index - 6]
        // black pieces
        evaluation -= i32(count_bits(board.pieces[index - 6 * int(board.whitesMove)])) * PIECES_WEIGHT[index - 6]
    }

    return (evaluation * SIDE_MULTIPLIER[int(board.whitesMove)])
}