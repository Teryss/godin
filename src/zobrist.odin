package main

RANDOM_NUMBERS_TABLE_SIZE :: 793
INDEX_SIDE_TO_MOVE :: 768
INDEX_CASTLING :: 769 
INDEX_ENPAS :: 785
rand_numbers : [RANDOM_NUMBERS_TABLE_SIZE]u64

HASH_TABLE_SIZE :: 10000000

hash_flag :: enum { exact, alpha, beta }
S_Move :: struct{
    move : u64,
    score : u64,
}

S_TT_entry :: struct{
    key: u64,
    depth : int,
    falg : hash_flag,
    best_move : S_Move,
}

get_file :: #force_inline proc (square : u8) -> u16{
    return u16(square % 8)
}

init_random_numbers :: proc(){
    for i in 0..<RANDOM_NUMBERS_TABLE_SIZE{
        rand_numbers[i] = get_random_number()
    }
}

hash_position :: proc (board : ^S_Board) -> u64{
    hash : u64
    bb : u64
    sqr : u8
    for piece in PIECES.p..=PIECES.K{
        bb = board.pieces[piece]
        for (bb > 0){
            sqr = ffs(bb)
            hash ~= rand_numbers[sqr * 12 + u8(piece)]
            clear_bit(&bb, sqr)
        }
    }
    hash ~= rand_numbers[INDEX_CASTLING + u16(board.castlePerm)]
    if board.whitesMove { hash ~= rand_numbers[INDEX_SIDE_TO_MOVE]}
    if board.enPas != u8(SQUARES.NO_SQR) { hash ~= rand_numbers[INDEX_ENPAS + get_file(board.enPas)] }
    return hash
}

