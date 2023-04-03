package main

import "core:fmt"

ON_A_FILE : u64 = 72340172838076673;
ON_H_FILE : u64 = 9259542123273814144;
ON_GH_FILE : u64 = 13889313184910721216;
ON_AB_FILE : u64 = 217020518514230019;
ON_8_RANK : u64 = 18374686479671623680;
ON_1_RANK : u64 = 255;
ON_12_RANK : u64 = 65535;
ON_78_RANK : u64 = 18446462598732840960;

init_masks :: proc (masks: ^C_Attack_masks){
    for sqr in 0..<64{
        masks.pawn[int(COLOR.WHITE)][sqr] = mask_pawn_attacks(COLOR.WHITE, uint(sqr));
        masks.pawn[int(COLOR.BLACK)][sqr] = mask_pawn_attacks(COLOR.BLACK, uint(sqr));
        masks.bishop[sqr] = mask_bishop_attacks(uint(sqr));
        masks.rook[sqr] = mask_rook_attacks(uint(sqr));
        masks.king[sqr] = mask_king_attacks(uint(sqr));
        masks.knight[sqr] = mask_knight_attacks(uint(sqr));
    }
    init_slider_attacks(masks, true);
    init_slider_attacks(masks, false);
}

init_slider_attacks :: proc (masks: ^C_Attack_masks, bishop: bool){
    att_mask, occ, magic_index : u64;
    relevant_bits, occupancy_indicies : int;

    for sqr in 0..<64{
        att_mask = bishop ? masks.bishop[sqr] : masks.rook[sqr];
        relevant_bits = count_bits(att_mask);
        occupancy_indicies = (1 << uint(relevant_bits));

        for i in 0..<occupancy_indicies{
            if bishop{
                occ = set_occupancy(i, relevant_bits, att_mask);
                magic_index = (occ * BISHOP_MAGICS[sqr]) >> uint(64 - RELEVANT_OCCUPANCY_BITS_BISHOP[sqr]);
                masks.bishop_attacks[sqr][magic_index] = mask_bishop_attacks_on_fly(uint(sqr), &occ);
            }else{
                occ = set_occupancy(i, relevant_bits, att_mask);
                magic_index = (occ * ROOK_MAGICS[sqr]) >> uint(64 - RELEVANT_OCCUPANCY_BITS_ROOK[sqr]);
                masks.rook_attacks[sqr][magic_index] = mask_rook_attacks_on_fly(uint(sqr), &occ);
            }
        }
    }
}

get_rook_attacks :: proc (masks: ^C_Attack_masks, sqr: uint, occupancy: u64) -> u64 {
    occ : u64 = occupancy;
    occ &= masks.rook[sqr];
    occ *= ROOK_MAGICS[sqr]
    occ >>= uint(64 - RELEVANT_OCCUPANCY_BITS_ROOK[sqr]);
    return masks.rook_attacks[sqr][occ];
}

get_bishop_attacks :: proc (masks: ^C_Attack_masks, sqr: uint, occupancy: u64) -> u64 {
    occ : u64 = occupancy;
    occ &= masks.bishop[sqr];
    occ *= BISHOP_MAGICS[sqr]
    occ >>= uint(64 - RELEVANT_OCCUPANCY_BITS_BISHOP[sqr]);
    return masks.bishop_attacks[sqr][occ];
}

get_queen_attacks :: proc (masks: ^C_Attack_masks, sqr: uint, occupancy: u64) -> u64 {
    return get_bishop_attacks(masks, sqr, occupancy) | get_rook_attacks(masks, sqr, occupancy)
}

mask_pawn_attacks :: proc (color: COLOR, sqr : uint) -> u64{
    bb : u64 = 0;

    if color == COLOR.WHITE{
        if get_bit(&ON_1_RANK, sqr) == 0{
            if get_bit(&ON_A_FILE, sqr) == 0 { set_bit(&bb, sqr - 9); }
            if get_bit(&ON_H_FILE, sqr) == 0 { set_bit(&bb, sqr - 7); }
        }
    }else{
        if get_bit(&ON_8_RANK, sqr) == 0{
            if get_bit(&ON_A_FILE, sqr) == 0 { set_bit(&bb, sqr + 7); }
            if get_bit(&ON_H_FILE, sqr) == 0 { set_bit(&bb, sqr + 9); }
        }
    }

    return bb;
}

mask_knight_attacks :: proc (sqr: uint) -> u64{
    bb : u64 = 0;
    
    if get_bit(&ON_8_RANK, sqr) == 0{
        if get_bit(&ON_AB_FILE, sqr) == 0 { set_bit(&bb, sqr + 6); }
        if get_bit(&ON_GH_FILE, sqr) == 0 { set_bit(&bb, sqr + 10); }
    }
    if get_bit(&ON_78_RANK, sqr) == 0{
        if get_bit(&ON_H_FILE, sqr) == 0 { set_bit(&bb, sqr + 17); }
        if get_bit(&ON_A_FILE, sqr) == 0 { set_bit(&bb, sqr + 15); }
    } 
    if get_bit(&ON_1_RANK, sqr) == 0{
        if get_bit(&ON_GH_FILE, sqr) == 0 { set_bit(&bb, sqr - 6); }
        if get_bit(&ON_AB_FILE, sqr) == 0 { set_bit(&bb, sqr - 10); }
    }
    if get_bit(&ON_12_RANK, sqr) == 0{
        if get_bit(&ON_A_FILE, sqr) == 0 { set_bit(&bb, sqr - 17); }
        if get_bit(&ON_H_FILE, sqr) == 0 { set_bit(&bb, sqr - 15); }
    }

    return bb;
}

mask_rook_attacks :: proc (sqr: uint) -> u64{
    bb : u64 = 0;
    r_ : int = int(sqr / 8);
    f_ : int = int(sqr % 8);

    for r := r_ + 1; r < 7; r += 1 { set_bit(&bb, FR_2_SQR(f_, r)); }
    for r := r_ - 1; r > 0; r -= 1 { set_bit(&bb, FR_2_SQR(f_, r)); }
    for f := f_ + 1; f < 7; f += 1 { set_bit(&bb, FR_2_SQR(f, r_)); }
    for f := f_ - 1; f > 0; f -= 1 { set_bit(&bb, FR_2_SQR(f, r_)); }

    return bb;
}

mask_bishop_attacks :: proc (sqr: uint) -> u64{
    bb : u64 = 0;
    r_ : int = int(sqr / 8);
    f_ : int = int(sqr % 8);

    f := f_ + 1;
    for r := r_ + 1; r < 7 && f < 7; r += 1 { set_bit(&bb, FR_2_SQR(f, r)); f += 1; }
    f = f_ - 1;
    for r := r_ + 1; r < 7 && f > 0; r += 1 { set_bit(&bb, FR_2_SQR(f, r)); f -= 1; }
    f = f_ + 1
    for r := r_ - 1; r > 0 && f < 7; r -= 1 { set_bit(&bb, FR_2_SQR(f, r)); f += 1; }
    f = f_ - 1
    for r := r_ - 1; r > 0 && f > 0; r -= 1 { set_bit(&bb, FR_2_SQR(f, r)); f -= 1; }

    return bb;
}

mask_king_attacks :: proc (sqr : uint) -> u64{
    bb : u64 = 0;

    if get_bit(&ON_A_FILE, sqr) == 0{
        set_bit(&bb, sqr - 1)
        if get_bit(&ON_8_RANK, sqr) == 0 { set_bit(&bb, sqr + 7); set_bit(&bb, sqr + 8); }
        if get_bit(&ON_1_RANK, sqr) == 0 { set_bit(&bb, sqr - 8); set_bit(&bb, sqr - 9); }
    }
    if get_bit(&ON_H_FILE, sqr) == 0{
        set_bit(&bb, sqr + 1)
        if get_bit(&ON_8_RANK, sqr) == 0 { set_bit(&bb, sqr + 8); set_bit(&bb, sqr + 9); }
        if get_bit(&ON_1_RANK, sqr) == 0 { set_bit(&bb, sqr - 7); set_bit(&bb, sqr - 8); }
    }

    return bb;
}

mask_rook_attacks_on_fly :: proc (sqr: uint, occ: ^u64) -> u64{
    bb : u64 = 0;
    r_ : int = int(sqr / 8);
    f_ : int = int(sqr % 8);

    for r := r_ + 1; r < 8; r += 1  { set_bit(&bb, FR_2_SQR(f_, r)); if get_bit(occ, FR_2_SQR(f_, r)) != 0 do break;}
    for r := r_ - 1; r > -1; r -= 1 { set_bit(&bb, FR_2_SQR(f_, r)); if get_bit(occ, FR_2_SQR(f_, r)) != 0 do break;}
    for f := f_ + 1; f < 8; f += 1  { set_bit(&bb, FR_2_SQR(f, r_)); if get_bit(occ, FR_2_SQR(f, r_)) != 0 do break;}
    for f := f_ - 1; f > -1; f -= 1 { set_bit(&bb, FR_2_SQR(f, r_)); if get_bit(occ, FR_2_SQR(f, r_)) != 0 do break;}

    return bb;
}

mask_bishop_attacks_on_fly :: proc (sqr: uint, occ: ^u64) -> u64{
    bb : u64 = 0;
    r_ : int = int(sqr / 8);
    f_ : int = int(sqr % 8);

    f := f_ + 1;
    for r := r_ + 1; r < 8 && f < 8; r += 1 { set_bit(&bb, FR_2_SQR(f, r)); if get_bit(occ, FR_2_SQR(f, r)) != 0 do break; f += 1; }
    f = f_ - 1;
    for r := r_ + 1; r < 8 && f > -1; r += 1 { set_bit(&bb, FR_2_SQR(f, r)); if get_bit(occ, FR_2_SQR(f, r)) != 0 do break; f -= 1; }
    f = f_ + 1
    for r := r_ - 1; r > -1 && f < 8; r -= 1 { set_bit(&bb, FR_2_SQR(f, r)); if get_bit(occ, FR_2_SQR(f, r)) != 0 do break; f += 1; }
    f = f_ - 1
    for r := r_ - 1; r > -1 && f > -1; r -= 1 { set_bit(&bb, FR_2_SQR(f, r)); if get_bit(occ, FR_2_SQR(f, r)) != 0 do break; f -= 1; }

    return bb;
}