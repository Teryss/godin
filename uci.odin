package main

import "core:fmt"
// import "core:bufio"
import "core:os"
// import "core:io"

buf: [256]u8

read_input :: proc () -> string {
    bytes_read, ok := os.read(os.stdin, buf[:])
    // fmt.println(bytes_read)
    return string(buf[:bytes_read])
}

parse_move :: proc (game : ^S_Game input: string) -> u64{
    move_string : [dynamic]u8
    defer delete(move_string)
    append(&move_string, input[:])
    moves : [256]u64
    move_count := generate_pseudo_moves(game.board, game.masks, &moves)

    from_sqr : u8 = FR_2_SQR(move_string[0] - u8('a'), u8('8') - move_string[1])
    to_sqr : u8 = FR_2_SQR(move_string[2] - u8('a'), u8('8') - move_string[3])
    promoted_piece : u8 = 0

    // fmt.println("Original string:", input[:5])
    // fmt.println(from_sqr, "->", SQUARE_TO_CHR[from_sqr], to_sqr, "->", SQUARE_TO_CHR[to_sqr])

    for i in 0..<move_count{
        if decode_from_sqr(moves[i]) == from_sqr{
            if decode_to_sqr(moves[i]) == to_sqr{
                promoted_piece = decode_promoted_piece(moves[i])
                if promoted_piece > 0{
                    if (promoted_piece == u8(PIECES.Q) || promoted_piece == u8(PIECES.q)) && move_string[4] == 'q' do return moves[i]
                    else if (promoted_piece == u8(PIECES.R) || promoted_piece == u8(PIECES.r)) && move_string[4] == 'r' do return moves[i]
                    else if (promoted_piece == u8(PIECES.B) || promoted_piece == u8(PIECES.b)) && move_string[4] == 'b' do return moves[i]
                    else if (promoted_piece == u8(PIECES.N) || promoted_piece == u8(PIECES.n)) && move_string[4] == 'n' do return moves[i]
                    else do continue
                }
                return moves[i]
            }
        }
    }
    return 0
}