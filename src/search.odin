package main

import "core:fmt"
import "core:time"

MINUS_INFINITY :: -100000000
INFINITY :: 100000000
ATTACKER_MULTIPLIER :: 12
CAPTURE_BONUS :: 10000
FIRST_KILLER_MOVE_BONUS :: 9000
SECOND_KILLER_MOVE_BONUS :: 8000

nodes_searched : u64 = 0
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

S_Score :: struct{
    score : i32,
    move_index : u8,
}

move_scores : [256]S_Score
temp_score : S_Score
temp_move : u64
scores_count : u8

sort_moves :: proc (board: ^S_Board, moves : ^[256]u64, moves_count : u8){
    temp_move = 0
    scores_count = 0

    for i in 0..<moves_count{
        if decode_is_capture(moves[i]) > 0{
            move_scores[scores_count] = {
                mvv_lva[decode_piece(moves[i]) * ATTACKER_MULTIPLIER + decode_target_piece(moves[i])] + CAPTURE_BONUS,
                u8(i),
            }
            scores_count += 1
        }else{
            if board.killer_moves[0][board.ply] == moves[i]{
                move_scores[scores_count] = {
                    FIRST_KILLER_MOVE_BONUS,
                    u8(i),
                }
                scores_count += 1
            }else if board.killer_moves[1][board.ply] == moves[i]{
                move_scores[scores_count] = {
                    SECOND_KILLER_MOVE_BONUS,
                    u8(i),
                }
                scores_count += 1
            }else if board.moveHistory[decode_piece(moves[i])][decode_to_sqr(moves[i])] != 0{
                move_scores[scores_count] = {
                    board.moveHistory[decode_piece(moves[i])][decode_to_sqr(moves[i])],
                    u8(i),
                }
                scores_count += 1
            }
        }
    }
    for i in 0..<scores_count{
        if move_scores[i].move_index < scores_count{
            temp_move = moves[scores_count + i]
            moves[scores_count + i] = moves[move_scores[i].move_index]
            moves[move_scores[i].move_index] = temp_move
            move_scores[i].move_index = scores_count + i
        }

        for j in 0..<scores_count{
            if move_scores[i].score > move_scores[j].score{
                temp_score = move_scores[i]
                move_scores[i] = move_scores[j]
                move_scores[j] = temp_score
            }
        }
    }
    for i in 0..<scores_count{
        temp_move = moves[i]
        moves[i] = moves[move_scores[i].move_index]
        moves[move_scores[i].move_index] = temp_move
    }
}

search :: proc (board : ^S_Board, masks: ^S_Attack_masks, depth : int) -> (u64, i32) {
    t1 := time.tick_now()
    score, max_score : i32 = MINUS_INFINITY, MINUS_INFINITY 
    moves : [256]u64
    best_move := moves[0]
    moves_count := generate_pseudo_moves(board, masks, &moves)
    sort_moves(board, &moves, moves_count)

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
    fmt.println("Search took:", time.duration_milliseconds(time.tick_diff(t1, t2)), "ms,", time.duration_seconds(time.tick_diff(t1, t2)), "s")
    return best_move, max_score
}

alphabeta :: proc (board: ^S_Board, masks: ^S_Attack_masks, alpha: i32, beta: i32, depth: int) -> i32{
    if (depth == 0) { return quiescence(board, masks, alpha, beta) }
    _alpha, _beta := alpha, beta
    score : i32 = MINUS_INFINITY
    moves : [256]u64
    moves_count := generate_pseudo_moves(board, masks, &moves)
    sort_moves(board, &moves, moves_count)

    for i in 0..<moves_count{
        make_move(board, moves[i])
        if !is_king_in_check(board, masks){
            nodes_searched += 1
            score = -alphabeta(board, masks, -_beta, -_alpha, depth - 1)
        }
        undo_move(board, moves[i])
        if score >= _beta{
            if decode_is_capture(moves[i]) == 0{
                board.killer_moves[1][board.ply] = board.killer_moves[0][board.ply]
                board.killer_moves[0][board.ply] = moves[i] 
            }
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
    // for now quiesence search takes too much time
    // it's depth is being limited to save search time
    if board.ply == DEPTH + 4 do return current_eval
    if current_eval >= _beta { return _beta }
    if current_eval > _alpha { _alpha = current_eval}
    
    score : i32 = MINUS_INFINITY
    moves : [256]u64
    moves_count := generate_pseudo_moves(board, masks, &moves)

    // with depth search limitation it's not effective to sort moves
    // sort_moves(board, &moves, moves_count)

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