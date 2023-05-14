package main

import "core:fmt"

S_Board :: struct {
	pieces : [12]u64,
	occupied : [3]u64,
	fiftyMoves: u8,
	ply: u8,
	castlePerm: u8,
	whitesMove: bool,
	enPas: u8,
	moveHistory: [12][64]i32,
	// moves_count : u16,
	killer_moves: [2][MAX_PLY]u64,
	pv : ^S_Pv,
};

update_occupied :: #force_inline proc(board: ^S_Board){
	board.occupied[COLOR.BOTH], board.occupied[COLOR.WHITE], board.occupied[COLOR.BLACK] = 0, 0, 0
    for i in PIECES.p..=PIECES.K{
	    board.occupied[COLOR.BOTH] |= board.pieces[i]
	    if i >= PIECES.P { board.occupied[COLOR.WHITE] |= board.pieces[i] }
	    else { board.occupied[COLOR.BLACK] |= board.pieces[i] }
    }
}

reset :: proc (board: ^S_Board){
	for i in 0..<12{
		board.pieces[i] = 0
	}
	for i in 0..<3{
		board.occupied[i] = 0
	}
	board.fiftyMoves = 0
	board.castlePerm = 0
	board.ply = 0
	board.enPas = u8(SQUARES.NO_SQR)
	for i in 0..<12{
		for j in 0..<64{
			board.moveHistory[i][j] = 0
		}
	}
	for i in 0..<2{
		for j in 0..<MAX_PLY{
			board.killer_moves[i][j] = 0
		}
	}
}

load_fen :: proc(board: ^S_Board, fen: string){
	fen_split : [6]string;
	temp : [dynamic]u8;
	defer delete(temp)
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
	sqr : u8 = u8(SQUARES.A8);
	for i in 0..<len(fen_split[0]){
		if fen_split[0][i] >= 'A' && fen_split[0][i] <= 'Z' || fen_split[0][i] >= 'a' && fen_split[0][i] <= 'z'{
			set_bit(&board.pieces[u8_to_piece[fen_split[0][i]]], sqr);
			sqr += 1;
		}else if fen_split[0][i] >= '0' && fen_split[0][i] < '9'{
			sqr += u8(fen_split[0][i]) - u8('0');
		}else if fen_split[0][i] == '/'{
			continue;
		}else{
			fmt.println("Couldn't parse a piece in FEN:", rune(fen_split[0][i]));
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

	board.enPas = u8(SQUARES.NO_SQR);
	if fen_split[3][0] != '-' { board.enPas = FR_2_SQR(fen_split[3][0] - u8('a'), u8('8') - u8(fen_split[3][1]))}

	board.ply = len(fen_split[5]) == 1 ? u8(fen_split[5][0])  - u8('0') : (u8(fen_split[5][0])  - u8('0')) * 10 + u8(fen_split[5][1]) - u8('0');
	board.fiftyMoves = len(fen_split[4]) == 1 ? u8(fen_split[4][0]) - u8('0') : (u8(fen_split[4][0]) - u8('0')) * 10 + u8(fen_split[4][1]) - u8('0');
	update_occupied(board);
}