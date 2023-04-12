package main

import "core:fmt"
import "core:time"
import "core:math/rand"

MINUS_INFINITY :: -100000000
INFINITY :: 100000000

nodes_searched : u64 = 0
rand_numbers : [781]u64

init_random_numbers :: proc(){
    r : rand.Rand
    rand.init_as_system(&r)
    for i in 0..<781{
        // rand_numbers[i] = rand.uint64(&r)
        rand_numbers[i] = get_random_number()
    }
}

search :: proc (board : ^S_Board, masks: ^S_Attack_masks, depth : int) -> (u64, i32) {
    t1 := time.tick_now()
    moves : [256]u64
    score, max_score : i32 = MINUS_INFINITY, MINUS_INFINITY 
    best_move := moves[0]
    moves_count := generate_pseudo_moves(board, masks, &moves)

    for i in 0..<moves_count{
        // print_single_move(moves[i])
        make_move(board, moves[i])
        if !is_king_in_check(board, masks){
            nodes_searched += 1
            score = -alphabeta(board, masks, MINUS_INFINITY, INFINITY , depth - 1)
        }
        // fmt.println("Eval:",score)
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
    if (depth == 0) do return eval(board)
    _alpha, _beta := alpha, beta
    score : i32 = MINUS_INFINITY
    moves : [256]u64
    moves_count := generate_pseudo_moves(board, masks, &moves)
    
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
    
    // negaMax :: proc (board : ^S_Board, masks: ^S_Attack_masks, depth : int) -> i32{
    //     if (depth == 0) do return eval(board)
    //     max_score, score : i32 = MINUS_INFINITY, MINUS_INFINITY
    //     moves : [256]u64
    //     moves_count := generate_pseudo_moves(board, masks, &moves)
        
    //     for i in 0..<moves_count{
    //         make_move(board, moves[i])
    //         if !is_king_in_check(board, masks){
    //             nodes_searched += 1
    //             score = -negaMax(board, masks, depth - 1)
    //         }
    //         undo_move(board, moves[i])
    //         if score > max_score {
    //             max_score = score
    //         }
    //     }
    
    //     return max_score
    // }