package main

set_bit :: proc(bitboard: ^u64, n: uint){
	bitboard^ |= 1 << n;
}

get_bit :: proc(bitboard: ^u64, n: uint) -> u64{
	return bitboard^ & (1 << n);
}

clear_bit :: proc(bitboard: ^u64, n: uint){
	bitboard^ &= ~(1 << n);
}

count_bits :: proc(bitboard: u64) -> int{
	count : int;
    bb : u64 = bitboard;
    for count = 0; bb > 0; count += 1{
        bb &= bb - 1;
    }
    return count;
}

ffs :: proc(bitboard: u64) -> int{
    bb : u64 = bitboard;
	if bb != 0{
        bb = (bb & -bb) - 1
        return count_bits(bb);
    }
    return -1
}

