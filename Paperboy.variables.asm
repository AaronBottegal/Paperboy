; Work in progress disassembly of Paperboy for the Nintendo Entertainment System.
; Created by Aaron Bottegal.


; NES PPU Registers

PPU_CTRL:                                     .equ $2000
PPU_MASK:                                     .equ $2001
PPU_STATUS:                                   .equ $2002
PPU_OAM_ADDR:                                 .equ $2003
PPU_OAM_DATA:                                 .equ $2004
PPU_SCROLL:                                   .equ $2005
PPU_ADDR:                                     .equ $2006
PPU_DATA:                                     .equ $2007


; NES APU Registers

APU_SQ1_CTRL:                                 .equ $4000
APU_SQ1_SWEEP:                                .equ $4001
APU_SQ1_LTIMER:                               .equ $4002
APU_SQ1_LENGTH:                               .equ $4003
APU_SQ2_CTRL:                                 .equ $4004
APU_SQ2_SWEEP:                                .equ $4005
APU_SQ2_LTIMER:                               .equ $4006
APU_SQ2_LENGTH:                               .equ $4007
APU_TRI_CTRL:                                 .equ $4008
APU_TRI_UNUSED:                               .equ $4009
APU_TRI_LTIMER:                               .equ $400A
APU_TRI_LENGTH:                               .equ $400B
APU_NSE_CTRL:                                 .equ $400C
APU_NSE_UNUSED:                               .equ $400D
APU_NSE_LOOP:                                 .equ $400E
APU_NSE_LENGTH:                               .equ $400F
APU_DMC_CTRL:                                 .equ $4010
APU_DMC_LOAD:                                 .equ $4011
APU_DMC_ADDR:                                 .equ $4012
APU_DMC_LENGTH:                               .equ $4013
OAM_DMA:                                      .equ $4014
APU_STATUS:                                   .equ $4015
NES_CTRL1:                                    .equ $4016
APU_FSEQUENCE:                                .equ $4017
NES_CTRL2:                                    .equ $4017


; NES RAM Variables.


          .rsset 0x0000
TMP_00:                                       .rs 1 ; 0x0000
TMP_01:                                       .rs 1 ; 0x0001
TMP_02:                                       .rs 1 ; 0x0002
TMP_03:                                       .rs 1 ; 0x0003
PPU_MASK_COPY:                                .rs 1 ; 0x0004
CONTROLLER_BUTTONS_NEWLY_PRESSED:             .rs 2 ; 0x0005 to 0x0006


          .rsset 0x0006
PPU_SCROLL_X_COPY:                            .rs 1 ; 0x0006
PPU_SCROLL_Y_COPY:                            .rs 1 ; 0x0007
PPU_CTRL_COPY:                                .rs 1 ; 0x0008
CONTROLLER_BUTTONS_CURRENT:                   .rs 2 ; 0x0009 to 0x000A
NMI_PROTECTION_VAR:                           .rs 1 ; 0x000B
PPU_UPDATE_BUF_INDEX:                         .rs 1 ; 0x000C
OBJ_SCREEN_POS_X:                             .rs 2 ; 0x000D to 0x000E


          .rsset 0x0026
OBJ_PTR_UNK_A_H:                              .rs 2 ; 0x0026 to 0x0027


          .rsset 0x003F
OBJ_PTR_UNK_B_L:                              .rs 2 ; 0x003F to 0x0040


          .rsset 0x0058
OBJ_PTR_UNK_B_H:                              .rs 2 ; 0x0058 to 0x0059


          .rsset 0x0071
OBJ_ATTR_UNK_071:                             .rs 19 ; 0x0071 to 0x0083


          .rsset 0x008A
COUNTER_A?:                                   .rs 1 ; 0x008A
COUNTER_B?:                                   .rs 1 ; 0x008B
MAP_GEN_VAL?:                                 .rs 1 ; 0x008C
ROTATE_PAIR_B:                                .rs 2 ; 0x008D to 0x008E
ROTATE_PAIR_A:                                .rs 2 ; 0x008F to 0x0090
STREAM_INPUT:                                 .rs 2 ; 0x0091 to 0x0092
STREAM_DATA_TYPE/COUNT:                       .rs 1 ; 0x0093
STREAM_COUNT_TODO:                            .rs 2 ; 0x0094 to 0x0095
STREAM_BUFFER_ADDR:                           .rs 2 ; 0x0096 to 0x0097
CURRENT_OBJ_PROCESSING:                       .rs 1 ; 0x0098
OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT?:    .rs 1 ; 0x0099
COUNT_LARGER:                                 .rs 1 ; 0x009A


          .rsset 0x009D
TEXT_STREAM_FILE:                             .rs 2 ; 0x009D to 0x009E
COUNT_SMALLER:                                .rs 1 ; 0x009F
SPRITE_X_VAL_LSB:                             .rs 1 ; 0x00A0
SPRITE_X_VAL_MSB:                             .rs 1 ; 0x00A1
SPRITE_Y_VAL_LSB:                             .rs 1 ; 0x00A2
SPRITE_Y_VAL_MSB:                             .rs 1 ; 0x00A3


          .rsset 0x00A5
SPRITE_PAGE_INDEX:                            .rs 1 ; 0x00A5
FILE_STREAM_UNK:                              .rs 2 ; 0x00A6 to 0x00A7
STREAM_HELPER:                                .rs 1 ; 0x00A8


          .rsset 0x00AD
HOUSE_OBJ_INDEX_CURRENT:                      .rs 1 ; 0x00AD
CUSTOMER_TYPE_DOING:                          .rs 1 ; 0x00AE
CURRENT_PLAYER_DAY_OF_THE_WEEK:               .rs 1 ; 0x00AF


          .rsset 0x00B1
VAL_CMP_UNK:                                  .rs 1 ; 0x00B1
CURRENT_PLAYER_LIVES:                         .rs 1 ; 0x00B2
PLAYER_OBJECT_ID:                             .rs 1 ; 0x00B3
OBJECTS_AVAILABLE?:                           .rs 1 ; 0x00B4
FLAG_PLAYER_ANIMATION?:                       .rs 1 ; 0x00B5
ENGINE_UNK_PTR?:                              .rs 2 ; 0x00B6 to 0x00B7
GAME_CURRENT_PLAYER:                          .rs 1 ; 0x00B8
FLAG_MULTIPLAYER_GAME:                        .rs 1 ; 0x00B9


          .rsset 0x00BC
GAME_VAR_FORWARD_CONTROL_HMM:                 .rs 1 ; 0x00BC
SCRIPT_X_SCROLL:                              .rs 1 ; 0x00BD
SCRIPT_Y_SCROLL:                              .rs 1 ; 0x00BE
SCRIPT_PPU_CTRL:                              .rs 1 ; 0x00BF
GAME_INDEX_HOUSE_ID_UPLOADING:                .rs 1 ; 0x00C0
GAME_INDEX_HOUSE_ID_UPLOADING_ALTERNATE_PLAYER: .rs 1 ; 0x00C1
HOUSE_FILE_STREAM_POS:                        .rs 1 ; 0x00C2
HOUSE_FILE_STREAM_DATA_LOADED:                .rs 1 ; 0x00C3
FILE_STREAM_UNK:                              .rs 2 ; 0x00C4 to 0x00C5


          .rsset 0x00C7
PPU_UPDATE_ADDR_A:                            .rs 2 ; 0x00C7 to 0x00C8
GAME_NAMETABLE_BASE_ADDR?:                    .rs 2 ; 0x00C9 to 0x00CA
UPDATE_BUF_A_ADDL:                            .rs 2 ; 0x00CB to 0x00CC
UPDATE_BUF_A_ADDL_DATA:                       .rs 1 ; 0x00CD
INDIRECT_THINGY_UNK:                          .rs 1 ; 0x00CE


          .rsset 0x00D0
GAME_DAY_OF_THE_WEEK_OTHER_PLAYER:            .rs 1 ; 0x00D0
PLAYER_LIVES_OTHER_PLAYER:                    .rs 1 ; 0x00D1
OBJ_UNK_WORD:                                 .rs 2 ; 0x00D2 to 0x00D3
PLAYER_SCORE_CURRENT:                         .rs 5 ; 0x00D4 to 0x00D8
SND_D9_TODO:                                  .rs 1 ; 0x00D9
SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL:         .rs 1 ; 0x00DA
SOUND_TRIPLET_IDK:                            .rs 3 ; 0x00DB to 0x00DD


          .rsset 0x00DF
SND_DF_TODO:                                  .rs 1 ; 0x00DF
SOUND_STREAM_TODO:                            .rs 2 ; 0x00E0 to 0x00E1
SOUND_FILE_STREAM_BASED:                      .rs 2 ; 0x00E2 to 0x00E3
SOUND_FIRE_B:                                 .rs 2 ; 0x00E4 to 0x00E5
EXTRA_FILE_POINTER_RAM:                       .rs 2 ; 0x00E6 to 0x00E7
SOUND_ARG_EXTRA_FILE:                         .rs 1 ; 0x00E8
SND_PROCESS_A_OBJ_ID:                         .rs 1 ; 0x00E9
SND_PROCESS_B_OBJ_ID:                         .rs 1 ; 0x00EA
SND_PROCESS_C_OBJ_ID:                         .rs 1 ; 0x00EB


          .rsset 0x0200
SPRITE_PAGE:                                  .rs 256 ; 0x0200 to 0x02FF
PPU_UPDATE_BUFFER_ARR:                        .rs 8 ; 0x0300 to 0x0307


          .rsset 0x03D0
GAME_MAP/LEVEL_GEN_ARR_HOUSES?:               .rs 20 ; 0x03D0 to 0x03E3


          .rsset 0x0407
OBJ_PROCESS_DATA_PTR_L:                       .rs 19 ; 0x0407 to 0x0419


          .rsset 0x0420
OBJ_PROCESS_DATA_PTR_H:                       .rs 19 ; 0x0420 to 0x0432


          .rsset 0x0439
OBJ_DATA_BYTE_FROM_PTR:                       .rs 1 ; 0x0439


          .rsset 0x0452
OBJ_ATTR_SCREEN_TILE_UNDER:                   .rs 19 ; 0x0452 to 0x0464


          .rsset 0x046B
OBJ_ATTR_SCRADDR_L:                           .rs 19 ; 0x046B to 0x047D


          .rsset 0x0484
OBJ_ATTR_SCRADDR_H:                           .rs 19 ; 0x0484 to 0x0496


          .rsset 0x04B6
OBJ_PROCESS_HANDLER_L:                        .rs 19 ; 0x04B6 to 0x04C8


          .rsset 0x04CF
OBJ_PROCESS_HANDLER_H:                        .rs 19 ; 0x04CF to 0x04E1


          .rsset 0x04E8
OBJ_FLAG_ACTIVE/USED/STATUS:                  .rs 19 ; 0x04E8 to 0x04FA


          .rsset 0x0501
OBJ_ATTR_TIMER:                               .rs 19 ; 0x0501 to 0x0513


          .rsset 0x051A
OBJ_SCRIPT_RETURN_ARG?:                       .rs 1 ; 0x051A


          .rsset 0x0533
NMI_RTN_PTR:                                  .rs 2 ; 0x0533 to 0x0534
UPDATE_BUF_A:                                 .rs 62 ; 0x0535 to 0x0572


          .rsset 0x0575
OBJ_HOUSE_ATTR_BLINKY?_OTHER_PLAYER:          .rs 1 ; 0x0575


          .rsset 0x05B7
OBJ_HOUSE_ATTR_BLINKY?:                       .rs 19 ; 0x05B7 to 0x05C9


          .rsset 0x05CD
OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT:             .rs 19 ; 0x05CD to 0x05DF


          .rsset 0x05E3
OBJ_ATTR_DEEP_UNK:                            .rs 19 ; 0x05E3 to 0x05F5


          .rsset 0x0605
HOUSE_ID_ATTRS_A:                             .rs 1 ; 0x0605


          .rsset 0x0627
HOUSE_ID_ATTRS_B:                             .rs 1 ; 0x0627


          .rsset 0x0649
OBJ_ATTR_UNK_649:                             .rs 19 ; 0x0649 to 0x065B


          .rsset 0x06F1
ARRAY_UNK:                                    .rs 32 ; 0x06F1 to 0x0710


          .rsset 0x0731
OBJ_ATTR_731_UNK:                             .rs 1 ; 0x0731


          .rsset 0x0758
OBJ_ATTR_UNK_758:                             .rs 19 ; 0x0758 to 0x076A


          .rsset 0x076C
INDEX_UNK_A:                                  .rs 1 ; 0x076C
INDEX_UNK_B:                                  .rs 1 ; 0x076D
PLAYER_ARR_UNK_OTHER_PLAYER:                  .rs 5 ; 0x076E to 0x0772
SCORES_INITIALS_ARRAY:                        .rs 1 ; 0x0773


          .rsset 0x077B
SCORE_INITIALS:                               .rs 1 ; 0x077B


          .rsset 0x07C3
TOP_SCORE_DISLAY_PACKET_CREATION_AREA:        .rs 5 ; 0x07C3 to 0x07C7


          .rsset 0x07D4
OBJ_PTR_RAM_DATA_UNK:                         .rs 1 ; 0x07D4


          .rsset 0x07D7
LARGER_ARR:                                   .rs 29 ; 0x07D7 to 0x07F3
