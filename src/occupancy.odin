package main

RELEVANT_OCCUPANCY_BITS_ROOK : [64] uint = {
    12, 11, 11, 11, 11, 11, 11, 12, 
    11, 10, 10, 10, 10, 10, 10, 11,
    11, 10, 10, 10, 10, 10, 10, 11,
    11, 10, 10, 10, 10, 10, 10, 11,
    11, 10, 10, 10, 10, 10, 10, 11,
    11, 10, 10, 10, 10, 10, 10, 11,
    11, 10, 10, 10, 10, 10, 10, 11,
    12, 11, 11, 11, 11, 11, 11, 12,
}

RELEVANT_OCCUPANCY_BITS_BISHOP : [64] uint = {
    6, 5, 5, 5, 5, 5, 5, 6, 
    5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 7, 7, 7, 7, 5, 5,
    5, 5, 7, 9, 9, 7, 5, 5,
    5, 5, 7, 9, 9, 7, 5, 5,
    5, 5, 7, 7, 7, 7, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5,
    6, 5, 5, 5, 5, 5, 5, 6,
}

set_occupancy :: proc(index, bits_in_mask: uint, attack_mask: u64) -> u64{
    occ : u64 = 0;
    mask := attack_mask;

    for i in 0..<bits_in_mask{
        sqr := u8(ffs(mask));
        clear_bit(&mask, sqr);

        if (index & (1 << uint(i))) != 0{
            occ |= (1 << sqr);
        }
    }
    
    return occ;
}