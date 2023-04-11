package main

import "core:intrinsics"
// import "core:simd/x86"

set_bit :: #force_inline proc(bitboard: ^u64, n: i8) {
	bitboard^ |= 1 << u8(n);
}

get_bit :: #force_inline proc(bitboard: ^u64, n: i8) -> u64{
	return bitboard^ & (1 << u8(n));
}

clear_bit :: #force_inline proc(bitboard: ^u64, n: i8){
	bitboard^ &= ~(1 << u8(n));
}

count_bits :: #force_inline proc(bitboard: u64) -> int{
    return int(intrinsics.count_ones(bitboard))
    // return int(x86._popcnt64(bitboard))
}

ffs :: #force_inline proc(bitboard: u64) -> int{
    return int(intrinsics.count_trailing_zeros(bitboard))
}