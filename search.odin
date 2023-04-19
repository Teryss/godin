package main

import "core:fmt"
import "core:time"
import "core:math/rand"

MINUS_INFINITY :: -100000000
INFINITY :: 100000000
MAX_PLY :: 255
nodes_searched : u64 = 0
rand_numbers : [781]u64
ATTACKER_MULTIPLIER :: 12
mvv_lva : [144]i32 = {
    105, 205, 305, 405, 505, 605,  105, 205, 305, 405, 505, 605,
    104, 204, 304, 404, 504, 604,  104, 204, 304, 404, 504, 604,
    103, 203, 303, 403, 503, 603,  103, 203, 303, 403, 503, 603,
    102, 202, 302, 402, 502, 602,  102, 202, 302, 402, 502, 602,
    101, 201, 301, 401, 501, 601,  101, 201, 301, 401, 501, 601,
    100, 200, 300, 400, 500, 600,  100, 200, 300, 400, 500, 600,

    105, 205, 305, 405, 505, 605,  105, 205, 305, 405, 505, 605,
    104, 204, 304, 404, 504, 604,  104, 204, 304, 404, 504, 604,
    103, 203, 303, 403, 503, 603,  103, 203, 303, 403, 503, 603,
    102, 202, 302, 402, 502, 602,  102, 202, 302, 402, 502, 602,
    101, 201, 301, 401, 501, 601,  101, 201, 301, 401, 501, 601,
    100, 200, 300, 400, 500, 600,  100, 200, 300, 400, 500, 600,
}

init_random_numbers :: proc(){
    for i in 0..<781{
        rand_numbers[i] = get_random_number()
    }
}

score_moves :: proc (scores: ^[256]i32, moves : ^[256]u64, moves_count : u8){
    for i in 0..<moves_count{
        if decode_is_capture(moves[i]) > 0{
            scores[i] = mvv_lva[decode_piece(moves[i]) * ATTACKER_MULTIPLIER + decode_target_piece(moves[i])]
        }else{
            scores[i] = 0
        }
    }
}

sort_moves :: proc (moves : ^[256]u64, moves_count : u8){
    temp_move : u64
    temp_score : i32
    move_scores : [256]i32
    score_moves(&move_scores, moves, moves_count)

    for i in 1..<moves_count{
        for j in 1..<moves_count{
            if move_scores[i] > move_scores[j]{
                temp_move = moves[i]
                moves[i] = moves[j]
                moves[j] = temp_move

                temp_score = move_scores[i]
                move_scores[i] = move_scores[j]
                move_scores[j] = temp_score
            }
        }
    }
}

search :: proc (board : ^S_Board, masks: ^S_Attack_masks, depth : int) -> (u64, i32) {
    t1 := time.tick_now()
    score, max_score : i32 = MINUS_INFINITY, MINUS_INFINITY 
    moves : [256]u64
    best_move := moves[0]
    moves_count := generate_pseudo_moves(board, masks, &moves)
    sort_moves(&moves, moves_count)

    for i in 0..<moves_count{
        make_move(board, moves[i])
        if !is_king_in_check(board, masks){
            nodes_searched += 1
            score = -alphabeta(board, masks, MINUS_INFINITY, INFINITY , depth - 1)
        }
        undo_move(board, moves[i])
        if score > max_score {
            max_score = score
            best_move = moves[i]
        }        
    }

    t2 := time.tick_now()
    fmt.println("Search took:", time.duration_milliseconds(time.tick_diff(t1, t2)), "ms")
    return best_move, max_score
}

alphabeta :: proc (board: ^S_Board, masks: ^S_Attack_masks, alpha: i32, beta: i32, depth: int) -> i32{
    // if (depth == 0) do return eval(board)
    if (depth == 0) { return quiescence(board, masks, alpha, beta) }
    _alpha, _beta := alpha, beta
    score : i32 = MINUS_INFINITY
    moves : [256]u64
    moves_count := generate_pseudo_moves(board, masks, &moves)
    sort_moves(&moves, moves_count)

    for i in 0..<moves_count{
        make_move(board, moves[i])
        if !is_king_in_check(board, masks){
            nodes_searched += 1
            score = -alphabeta(board, masks, -_beta, -_alpha, depth - 1)
        }
        undo_move(board, moves[i])
        if score >= _beta{
            return _beta
        }
        if score > _alpha{
            _alpha = score
        }
    }
    
    return _alpha
}

quiescence :: proc (board: ^S_Board, masks: ^S_Attack_masks, alpha: i32, beta: i32) -> i32 {
    current_eval : i32 = eval(board)
    _alpha, _beta := alpha, beta
    if board.ply == 10 do return current_eval
    if current_eval >= _beta { return _beta }
    if current_eval > _alpha { _alpha = current_eval}
    
    score : i32 = MINUS_INFINITY
    moves : [256]u64
    moves_count := generate_pseudo_moves(board, masks, &moves)
    // sort_moves(&moves, moves_count)

    for i in 0..<moves_count{
        if decode_is_capture(moves[i]) > 0{
            make_move(board, moves[i])
            if !is_king_in_check(board, masks){
                nodes_searched += 1
                score = -quiescence(board, masks, -_beta, -_alpha)
            }
            undo_move(board, moves[i])
            if score >= _beta{
                return _beta
            }
            if score > _alpha{
                _alpha = score
            }
        }
    }
    return _alpha
}