package main

import "core:intrinsics"
// import "core:simd/x86"

set_bit :: #force_inline proc(bitboard: ^u64, n: u8) {
	bitboard^ |= 1 << n;
}

get_bit :: #force_inline proc(bitboard: ^u64, n: u8) -> u64{
	return bitboard^ & (1 << n);
}

clear_bit :: #force_inline proc(bitboard: ^u64, n: u8){
	bitboard^ &= ~(1 << n);
}

count_bits :: #force_inline proc(bitboard: u64) -> u8{
    return u8(intrinsics.count_ones(bitboard))
}

ffs :: #force_inline proc(bitboard: u64) -> u8{
    return u8(intrinsics.count_trailing_zeros(bitboard))
}