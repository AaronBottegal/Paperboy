LOOP_START_OF_ROM: ; C:0000, 0x000000
    JSR ENGINE_FORWARD_OBJECTS/DISPLAY ; Do rtn.
    JMP LOOP_START_OF_ROM ; Goto start.
VECTOR_NMI: ; C:0006, 0x000006
    INC NMI_PROTECTION_VAR ; ++
    BNE EXIT_NMI_PROTECTED ; != 0, goto. Initial 0xFF = Can run. 0x00 = Protected.
    PHA ; Save A,X,Y.
    TXA
    PHA
    TYA
    PHA
    LDA PPU_STATUS ; Reset latch.
    LDA #$02
    STA OAM_DMA ; Upload sprites from 0x200
    LDA NMI_RTN_PTR+1 ; Load high byte.
    BEQ SKIP_NMI_HANDLER ; == 0, goto.
    JSR EXECUTE_NMI_RTN_PTR ; Run handler scripty.
SKIP_NMI_HANDLER: ; C:001F, 0x00001F
    JSR PPU_UPDATE_PACKET_UPLOADER ; Do background updates.
    LDA PPU_SCROLL_X_COPY ; Set scroll.
    STA PPU_SCROLL
    LDA PPU_SCROLL_Y_COPY
    STA PPU_SCROLL
    LDA PPU_CTRL_COPY ; Load.
    ASL A ; << 1, *2. Why shift data? Odd.
    ORA #$90 ; Set NMI, BG from 0x1000.
    STA PPU_CTRL ; Store to CTRL.
    LDA PPU_MASK_COPY ; Load.
    STA PPU_MASK ; Store to mask.
    JSR ENGINE_FORWARD_OBJECTS/DISPLAY ; Sprity thing.
    PLA ; Restore registers.
    TAY
    PLA
    TAX
    PLA
EXIT_NMI_PROTECTED: ; C:0041, 0x000041
    DEC NMI_PROTECTION_VAR ; --
    RTI ; Leave.
EXECUTE_NMI_RTN_PTR: ; C:0044, 0x000044
    JMP [NMI_RTN_PTR[2]] ; Run code at addr.
VECTOR_IRQ: ; C:0047, 0x000047
    .db 40 ; Leave me alone.
VECTOR_RESET: ; C:0048, 0x000048
    LDA #$00
    STA PPU_CTRL ; Clear CTRL.
    STA PPU_MASK ; And mask.
    STA NMI_PROTECTION_VAR ; Clear for protection.
    SEI ; Interrupt disable.
    CLD ; No decimal mode.
    LDX #$FF ; Set up stack.
    TXS
    JSR GEN_BUF_RANDOMNESS? ; Do.
WAIT_PPU_BLANKS: ; C:005A, 0x00005A
    JSR COUNTER_DOWN_RET_VAL_UNK ; Do.
    LDA PPU_STATUS ; Load.
    BPL WAIT_PPU_BLANKS ; Positive, wait.
WAIT_PART_2: ; C:0062, 0x000062
    LDA PPU_STATUS ; Load.
    BPL WAIT_PART_2 ; Wait for 2nd frame.
    LDA #$00
    STA PPU_CTRL ; Clear again.
    STA PPU_MASK
    STA PPU_MASK_COPY ; Clear.
    STA PPU_OAM_ADDR ; Reset OAM addr.
    LDA #$0F
    STA APU_STATUS ; Set audio state.
    LDA #$40
    STA APU_FSEQUENCE ; Set steps.
    LDA #$00
    STA APU_DMC_CTRL ; Set APU CTRL.
    LDA #$00
    STA PPU_UPDATE_BUF_INDEX ; Clear ??
    STA PPU_UPDATE_BUFFER_ARR[8]
    JSR CLEAR_ALL_OBJECTS_USED ; Do.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn.
    LOW(ENTER_GAME_MENUS/INTRO_LOOP_WITH_INITIALS_INIT) ; Goto rtn. <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    HIGH(ENTER_GAME_MENUS/INTRO_LOOP_WITH_INITIALS_INIT)
    JSR INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING ; Do.
    JSR PTR_AFTER_JSR_TO_NMI_PTR ; NULL NMI PTR.
    BRK ; 0x0000. NULL. No pointer for handler. Caught case in NMI.
    BRK
    LDA #$90
    STA PPU_CTRL ; Set PPU_CTRL, NMI enabled, BG from 0x1000.
    DEC NMI_PROTECTION_VAR ; --
JMP_FOREVER: ; C:00A1, 0x0000A1
    JMP JMP_FOREVER ; Loop forever.
SWITCH_GRAPHICS_TO_BANK_INDEXED: ; C:00A4, 0x0000A4
    TAY ; Val to Y.
    LDA GRAPHICS_DATA_ARR,Y ; Get GFX Bnak from index.
    STA MAPPER_BANK_SELECT,Y ; Store to mapper, avoiding conflicts with same location.
    STA MAPPER_BANK_SELECT,Y ; TODO: Why twice. Not needed?
    RTS ; Leave.
GRAPHICS_DATA_ARR: ; C:00AF, 0x0000AF
    .db 30
    .db 31
    .db 32
    .db 33
ENGINE_TABLE_SWITCH_ON_ARGUMENT: ; C:00B3, 0x0000B3
    STA TMP_02 ; Arg to.
    PLA
    STA TMP_00 ; Addr from to TMP.
    PLA
    STA TMP_01
    LDY #$01 ; Index for data past JSR.
SEARCH_FOR_MATCH: ; C:00BD, 0x0000BD
    LDA [TMP_00],Y ; Load data.
    BEQ TABLE_EOF ; == 0, goto. Default/EOF.
    CMP TMP_02 ; If _ arg
    BEQ MATCHED_ARG ; ==, goto.
    INY ; Slot++
    INY
    INY
    BNE SEARCH_FOR_MATCH ; !=, goto.
TABLE_EOF: ; C:00CA, 0x0000CA
    TYA ; Index to A.
    CLC ; Prep add.
    ADC TMP_00 ; Add to PTR L.
    TAY ; To index.
    LDA TMP_01 ; Load PTR H.
    ADC #$00 ; Carry add.
    PHA ; Save addr.
    TYA
    PHA
    LDA TMP_02 ; Return arg.
    RTS ; Return past table.
MATCHED_ARG: ; C:00D9, 0x0000D9
    INY ; Stream++
    LDA [TMP_00],Y ; Load.
    PHA ; Save to stack.
    INY ; Stream++
    LDA [TMP_00],Y ; Load.
    STA TMP_01 ; Store.
    PLA ; Pull from stack.
    STA TMP_00 ; Store PTR L.
    LDA TMP_02 ; Load arg.
    JMP [TMP_00] ; Goto RTN.
CTRL_READ_PORT_Y: ; C:00EA, 0x0000EA
    LDA #$01
    STA NES_CTRL1 ; Reset latch.
    LDA #$00
    STA NES_CTRL1
    TXA ; Index to A.
    PHA ; Save it.
    LDX #$07 ; Loop count - 1
LOOP_READ_CTRL: ; C:00F8, 0x0000F8
    LDA NES_CTRL1,Y ; Load CTRL for player.
    CMP #$41 ; If _ #$41
    BEQ VAL_EQ_0x41 ; ==, goto. Buttons set.
    CLC ; No press.
VAL_EQ_0x41: ; C:0100, 0x000100
    ROL TMP_00 ; Bit to TMP.
    DEX ; Loops--
    BPL LOOP_READ_CTRL ; Positive, do more.
    PLA ; Get index working with.
    TAX ; To X.
    LDA CONTROLLER_BUTTONS_CURRENT[2],Y ; Load indexed.
    AND #$F0 ; Keep A/B/SEL/START
    AND TMP_00 ; Test against, keeping pressed.
    EOR TMP_00 ; Invert with the pressed now. This sets NEWLY pressed to 1.
    STA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Store newly pressed.
    LDA TMP_00
    STA CONTROLLER_BUTTONS_CURRENT[2],Y ; Set with pressed.
    LDA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Load newly pressed.
    RTS
SETUP_FILE_PROCESS_ENTIRE_SCREEN: ; C:011A, 0x00011A
    STA STREAM_INPUT[2] ; A to.
    STY STREAM_INPUT+1 ; Y to.
    LDA #$07
    STA STREAM_BUFFER_ADDR[2] ; Val to, 0x2007.
    LDA #$20
    STA STREAM_BUFFER_ADDR+1
    LDA #$00
    STA STREAM_COUNT_TODO[2] ; Val, 0x400.
    LDA #$04
    STA STREAM_COUNT_TODO+1
    JSR INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING ; Do.
    JSR STREAM_PROCESS_FILES ; Do.
    LDX CURRENT_OBJ_PROCESSING ; Index from.
    RTS ; Leave.
GEN_BUF_RANDOMNESS?: ; C:013E, 0x00013E
    LDA #$17
    STA COUNTER_A? ; Set ??.
    LDA #$36
    STA COUNTER_B? ; Set ??
    LDX #$36 ; Index.
MAKE_BUFFER_WTF: ; C:0148, 0x000148
    ADC #$15 ; Add A val.
    STA GAME_MAP/LEVEL_GEN_ARR_HOUSES?[20],X ; Store to. 0x36 to 0x00
    DEX ; X--
    BPL MAKE_BUFFER_WTF ; Positive, loop.
    RTS ; Leave.
COUNTER_DOWN_RET_VAL_UNK: ; C:0151, 0x000151
    TXA ; Save X,Y
    PHA
    TYA
    PHA
    LDY COUNTER_A? ; Index from.
    DEY ; Index--
    BPL VAL_NO_RELOAD
    LDY #$36 ; If negative, reload.
VAL_NO_RELOAD: ; C:015C, 0x00015C
    STY COUNTER_A? ; Store to.
    LDX COUNTER_B? ; X from
    DEX ; X--
    BPL VAL_NO_RELOAD
    LDX #$36 ; X val.
VAL_NO_RELOAD: ; C:0165, 0x000165
    STX COUNTER_B? ; Store to.
    LDA GAME_MAP/LEVEL_GEN_ARR_HOUSES?[20],X ; Load from arr.
    CLC ; Prep add.
    ADC GAME_MAP/LEVEL_GEN_ARR_HOUSES?[20],Y ; Add with X.
    STA GAME_MAP/LEVEL_GEN_ARR_HOUSES?[20],X ; Store to Y.
    STA MAP_GEN_VAL? ; Store to.
    PLA ; Restore X and Y.
    TAY
    PLA
    TAX
    LDA MAP_GEN_VAL? ; Load.
    RTS ; Leave.
SAVE_ROTATE_B_HELPER_UNK: ; C:017A, 0x00017A
    STA ROTATE_PAIR_B+1 ; A to.
    JSR COUNTER_DOWN_RET_VAL_UNK
    STA ROTATE_PAIR_B[2] ; Store to.
    TYA ; Save Y to stack.
    PHA
    JSR SHIFTING_UNK ; Do ??
    PLA
    TAY ; Restore Y.
    LDA ROTATE_PAIR_A+1
    RTS
SHIFTING_UNK: ; C:018B, 0x00018B
    LDA #$00
    STA ROTATE_PAIR_A[2] ; Clear ??
    STA ROTATE_PAIR_A+1
    LDY #$08 ; Count todo.
COUNT_NONZERO: ; C:0193, 0x000193
    ASL ROTATE_PAIR_A[2] ; Shift zero into.
    ROL ROTATE_PAIR_A+1 ; Rotate up.
    ASL ROTATE_PAIR_B[2] ; Shift.
    BCC SHIFTED_CC ; CC, goto.
    LDA ROTATE_PAIR_B+1 ; Load.
    CLC ; Prep add.
    ADC ROTATE_PAIR_A[2] ; Add with.
    STA ROTATE_PAIR_A[2] ; Store back.
    BCC SHIFTED_CC ; No overflow, goto.
    INC ROTATE_PAIR_A+1 ; Inc ??
SHIFTED_CC: ; C:01A6, 0x0001A6
    DEY ; Count--
    BNE COUNT_NONZERO ; != 0, goto.
    RTS ; Leave.
STREAM_PROCESS_FILES: ; C:01AA, 0x0001AA
    LDY #$00 ; Stream index.
    LDA [STREAM_INPUT[2]],Y ; Load from.
    STA STREAM_DATA_TYPE/COUNT ; Store to. Type.
    INC STREAM_INPUT[2] ; Inc ptr word.
    BNE MOVE_TYPE_TEST ; No rollover, goto.
    INC STREAM_INPUT+1 ; Inc high.
MOVE_TYPE_TEST: ; C:01B6, 0x0001B6
    LDA STREAM_DATA_TYPE/COUNT ; Load data.
    BMI STREAM_DATA_UNIQUE_ENTRY ; If negative, goto. Unique.
    BEQ STREAM_PROCESS_FILES ; Zero, goto. Nonzero falls through, count.
STREAM_MOVER_COUNT: ; C:01BC, 0x0001BC
    LDY #$00 ; Stream index.
    LDA [STREAM_INPUT[2]],Y ; Load from file.
    JSR DATA_TO_OUTPUT_BUFFER ; Do with data.
    BNE STREAM_MOVER_COUNT ; != 0, continue.
    LDA STREAM_DATA_TYPE/COUNT ; Load.
    BNE RTS ; != 0, leave.
    INC STREAM_INPUT[2] ; ++
    BNE CONTINUE_IF_COUNT ; != 0, goto.
    INC STREAM_INPUT+1 ; Inc high byte.
CONTINUE_IF_COUNT: ; C:01CF, 0x0001CF
    LDA STREAM_COUNT_TODO[2] ; Load.
    ORA STREAM_COUNT_TODO+1 ; Or with.
    BNE STREAM_PROCESS_FILES ; Any count, goto.
    RTS ; Leave.
STREAM_DATA_UNIQUE_ENTRY: ; C:01D6, 0x0001D6
    CMP #$80 ; If _ #$80
    BEQ STREAM_PROCESS_FILES ; ==, goto.
STREAM_MOVER_UNIQUE_LOOP: ; C:01DA, 0x0001DA
    LDY #$00 ; Index.
    LDA [STREAM_INPUT[2]],Y ; Load from.
    INC STREAM_INPUT[2] ; Inc low.
    BNE NO_INC_ROLLOVER ; != 0, no rollover.
    INC STREAM_INPUT+1 ; Inc high.
NO_INC_ROLLOVER: ; C:01E4, 0x0001E4
    JSR DATA_TO_OUTPUT_BUFFER ; Do rtn with.
    BNE STREAM_MOVER_UNIQUE_LOOP ; Ret != 0, goto.
    LDA STREAM_COUNT_TODO[2] ; Load.
    ORA STREAM_COUNT_TODO+1 ; Combine bits with.
    BNE STREAM_PROCESS_FILES ; Any set, re-enter.
RTS: ; C:01EF, 0x0001EF
    RTS ; Leave.
DATA_TO_OUTPUT_BUFFER: ; C:01F0, 0x0001F0
    LDY STREAM_BUFFER_ADDR+1 ; Index to.
    CPY #$20 ; If _ #$20
    BEQ STREAM_DATA_TO_PPU ; ==, goto. Ptr 0x20XX, goto "to PPU" routine.
    LDY #$00 ; Index.
    STA [STREAM_BUFFER_ADDR[2]],Y ; Store data to wherever in RAM.
    INC STREAM_BUFFER_ADDR[2] ; Inc ptr low.
    BNE STREAM_DATA_TO_BUFFER ; != 0, goto.
    INC STREAM_BUFFER_ADDR+1 ; Inc high.
    BNE STREAM_DATA_TO_BUFFER ; Goto. Always taken.
STREAM_DATA_TO_PPU: ; C:0202, 0x000202
    STA PPU_DATA ; Store data to PPU.
STREAM_DATA_TO_BUFFER: ; C:0205, 0x000205
    DEC STREAM_DATA_TYPE/COUNT ; Count--
    LDA STREAM_COUNT_TODO[2] ; Load.
    SEC ; Prep sub.
    SBC #$01 ; Sub with.
    STA STREAM_COUNT_TODO[2] ; Store to.
    LDA STREAM_COUNT_TODO+1 ; Carry sub.
    SBC #$00
    STA STREAM_COUNT_TODO+1 ; Store result of carry.
    ORA STREAM_COUNT_TODO[2] ; Set with lower bits.
    BEQ RTS ; == 0, done, leave.
    LDA STREAM_DATA_TYPE/COUNT ; Load.
    AND #$7F ; Isolate bits.
RTS: ; C:021C, 0x00021C
    RTS ; Leave.
CLEAR_SCREEN_0x2000: ; C:021D, 0x00021D
    JSR INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING ; Init hardware.
CLEAR_ENTIRE_SCREEN: ; C:0220, 0x000220
    LDA #$00 ; Data.
    LDX #$04 ; Pages + 1
    LDY #$40 ; ~Tiles
CLEAR_TILES_LOOP: ; C:0226, 0x000226
    STA PPU_DATA ; Clear.
    INY ; Count++
    BNE CLEAR_TILES_LOOP ; != 0, goto.
    DEX ; Pages--
    BNE CLEAR_TILES_LOOP ; != 0, do more pages of 256.
    LDX #$40 ; Number of attributes.
CLEAR_ATTRIBUTES_LOOP: ; C:0231, 0x000231
    STA PPU_DATA ; Clear.
    DEX ; Extra--
    BNE CLEAR_ATTRIBUTES_LOOP ; != 0, do more.
    LDX CURRENT_OBJ_PROCESSING ; Load index.
    RTS ; Leave.
    TYA
    STA PPU_ADDR
    TXA
    STA PPU_ADDR
    RTS
INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING: ; C:0244, 0x000244
    LDA #$00
    STA PPU_MASK_COPY ; Clear copy.
    STA PPU_MASK ; Clear mask, no rendering.
    STA PPU_SCROLL_X_COPY ; Clear scroll copy.
    STA PPU_SCROLL_Y_COPY
    STA PPU_CTRL_COPY
    LDA #$20
    STA PPU_ADDR ; Set addr, $2000 nametable.
    LDA #$00
    STA PPU_ADDR
    RTS ; Leave.
PPU_HELPER_ENABLE_RENDERING: ; C:025C, 0x00025C
    LDA #$1E ; Sprite+BG and in left 8 enable.
    STA PPU_MASK_COPY ; Enable rendering for entire screen.
    RTS ; Leave.
MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR: ; C:0261, 0x000261
    PLA
    STA TMP_02 ; Move JSR to TMP_02
    PLA
    STA TMP_03
    LDY #$01 ; Index.
    LDA [TMP_02],Y ; Load from file pointed to. Index of start.
    CLC ; Prep add.
    ADC #$00 ; Add 0x00 because fuck you.
    STA TMP_00 ; Store to.
    LDA #$3F ; Load upper for palette addr.
    STA TMP_01
    JSR PPU_PALETTE_UPDATE_CREATOR ; Make update.
    LDY #$02 ; Index into stream.
LOOP_DATA_INDEX_NONZERO: ; C:0279, 0x000279
    LDA [TMP_02],Y ; Load from file.
    BMI PALETTE_DATA_EOF ; If negative, leave.
    JSR PPU_UPDATE_ARRAY_RTN_UNK ; Palette rtn.
    INY ; Index++
    BNE LOOP_DATA_INDEX_NONZERO ; != 0, loop.
PALETTE_DATA_EOF: ; C:0283, 0x000283
    TYA ; Index to A.
    CLC ; Prep add.
    ADC TMP_02 ; Add with prt.
    TAY ; Low val to Y.
    LDA TMP_03 ; Load high.
    ADC #$00 ; Carry add.
    PHA ; Save to stack high value.
    TYA
    PHA ; Save to stack low value.
    RTS ; Leave.
ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED: ; C:0290, 0x000290
    TAX ; A to X. TODO: How works.
    TYA ; Y to A.
    CMP #$1E ; If A _ #$1E
    BCC SKIP_MODS ; <, goto.
    CLC ; Prep add.
    ADC #$22 ; Add with.
    CMP #$5E ; If _ #$5E
    BCC SKIP_MODS ; <, goto.
    SEC ; Mod to 0x00 base.
    SBC #$5E
SKIP_MODS: ; C:02A0, 0x0002A0
    TAY ; To Y index.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    CLC ; Prep add.
    ADC #$20 ; Add with.
    STA TMP_01 ; Store to addr.
    TYA ; Y to A.
    ASL A ; << 5, *16.
    ASL A
    ASL A
    ASL A
    ASL A
    STA TMP_00 ; Store to.
    TXA ; X to A.
    AND #$1F ; Isolate bits.
    ORA TMP_00 ; Combine with.
    STA TMP_00 ; Store to.
PPU_PALETTE_UPDATE_CREATOR: ; C:02B8, 0x0002B8
    LDX PPU_UPDATE_BUF_INDEX ; Index from.
    LDA PPU_UPDATE_BUFFER_ARR[8],X ; Load from arr.
    BEQ BUF_INDEX_ENDED ; == 0, goto. EOF.
    CLC ; Prep add. Not ended adds index here to start. Seems iffy if used wrong.
    ADC PPU_UPDATE_BUF_INDEX ; Add with index original.
    ADC #$03 ; Add pad.
    STA PPU_UPDATE_BUF_INDEX ; Store back, new buffer index for next.
    TAX ; Index created to X.
BUF_INDEX_ENDED: ; C:02C7, 0x0002C7
    LDA TMP_01 ; Load, update PPU addr H.
    STA PPU_UPDATE_BUFFER_ARR+2,X ; Store to buffer header.
    LDA TMP_00 ; Addr L.
    STA PPU_UPDATE_BUFFER_ARR+1,X
    LDA #$00
    STA PPU_UPDATE_BUFFER_ARR[8],X ; Store NULL to buffer at end.
    LDX CURRENT_OBJ_PROCESSING ; Restore obj.
    RTS ; Leave.
ENGINE_HIT_DETECT_XOBJ_WITH_YOBJ: ; C:02D9, 0x0002D9
    LDA OBJ_SCREEN_POS_X[2],X ; Load Xobj.
    SEC ; Prep sub.
    SBC OBJ_SCREEN_POS_X[2],Y ; Sub with Yobj.
    STA TMP_00 ; Store to diff.
    LDA OBJ_PTR_UNK_A_H[2],X ; Load X.
    SBC OBJ_PTR_UNK_A_H[2],Y ; Carry sub Y.
    STA TMP_01 ; Store diff two.
    BPL VAL_POSITIVE ; Positive, goto.
    JSR SUB_COMPLIMENT_16B_TEMP ; Compliment.
VAL_POSITIVE: ; C:02ED, 0x0002ED
    LDA TMP_01 ; Load.
    BNE RET_CC_NOHIT ; Nonzero, goto.
    LDA TMP_00 ; Load.
    CMP #$08 ; If _ #$08
    BCS RET_CC_NOHIT ; >=, leave.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load Xobj.
    SEC ; Prep sub.
    SBC OBJ_PTR_UNK_B_L[2],Y ; Sub with Yobj.
    STA TMP_00 ; Store result.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load top.
    SBC OBJ_PTR_UNK_B_H[2],Y ; Sub with carry top.
    STA TMP_01 ; Store to.
    BPL RESULT_POSITIVE ; Positive, goto.
    JSR SUB_COMPLIMENT_16B_TEMP ; Do compliment.
RESULT_POSITIVE: ; C:030B, 0x00030B
    LDA TMP_01 ; Load.
    BNE RET_CC_NOHIT ; Nonzero, leave.
    LDA TMP_00 ; Load top.
    CMP #$08 ; If _ #$08
    BCS RET_CC_NOHIT ; >=, leave.
    SEC ; Ret CS, hit.
    RTS
RET_CC_NOHIT: ; C:0317, 0x000317
    CLC ; No hit.
    RTS
SUB_COMPLIMENT_16B_TEMP: ; C:0319, 0x000319
    LDA TMP_00 ; Load.
    EOR #$FF ; Invert.
    CLC ; Carry prep.
    ADC #$01 ; Compliment.
    STA TMP_00 ; Store to.
    LDA TMP_01 ; Load.
    EOR #$FF ; Invert.
    ADC #$00 ; Carry add compliment.
    STA TMP_01 ; Store to.
    RTS ; Leave.
ENGINE_GET_SCREEN_GFX_UNDER_TILES: ; C:032B, 0x00032B
    LDX #$18 ; Obj start.
OBJ_INDEX_POSITIVE: ; C:032D, 0x00032D
    LDA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Load.
    BPL TO_NEXT_OBJ ; Positive, skip.
    LDA OBJ_ATTR_SCRADDR_H[19],X ; Load.
    BEQ TO_NEXT_OBJ ; == 0, skip.
    STA PPU_ADDR ; Set as addr.
    LDA OBJ_ATTR_SCRADDR_L[19],X ; Load.
    STA PPU_ADDR ; Set addr.
    LDA PPU_DATA ; Rest screen data at.
    LDA PPU_DATA
    STA OBJ_ATTR_SCREEN_TILE_UNDER[19],X
TO_NEXT_OBJ: ; C:0349, 0x000349
    DEX ; Obj--
    BPL OBJ_INDEX_POSITIVE ; Positive, goto.
    RTS ; Leave.
SCREEN_ADDR_THINGY_TODO: ; C:034D, 0x00034D
    PHA ; Save A.
    STY TMP_03 ; Store Y to. ??
    LDA PPU_CTRL_COPY ; Load CTRL copy.
    ASL A ; << 1, *2.
    ORA #$08 ; Set ??
    STA TMP_01 ; Store to, addr ??
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    SEC ; Prep sub.
    SBC TMP_03 ; Sub with.
    CLC ; Prep add.
    ADC PPU_SCROLL_Y_COPY ; Add with Y scroll.
    ROR A ; Rotate into.
    LSR A ; >> 2, /4.
    LSR A
    STA TMP_00 ; Store to, addr ??
    CMP #$1E ; If _ #$1E
    BCC VAL_LT_0x1E ; <, goto.
    SEC ; Prep sub.
    SBC #$1E ; Sub with.
    STA TMP_00 ; Store to.
    LDA #$02 ; Bit to invert.
    EOR TMP_01 ; Invert it.
    STA TMP_01 ; Store back.
VAL_LT_0x1E: ; C:0373, 0x000373
    LDA TMP_00 ; Load addr.
    ASL A ; << 4, *16.
    ASL A
    ASL A
    ASL A
    ROL TMP_01 ; Rotate into addr.
    ASL A ; << 1, *2.
    ROL TMP_01 ; Rotate into addr.
    STA TMP_00 ; Store result of shifts.
    LDA PPU_SCROLL_X_COPY ; Load X scroll.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    STA TMP_02 ; Store result. Tile base on.
    PLA ; Pull stack.
    CLC ; Prep add.
    ADC OBJ_SCREEN_POS_X[2],X ; Add with.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    CLC ; Prep add.
    ADC TMP_02 ; Add with.
    AND #$1F ; Keep 0001.1111
    ORA TMP_00 ; Combine with.
    STA OBJ_ATTR_SCRADDR_L[19],X ; Store result.
    LDA TMP_01 ; Move addr H.
    STA OBJ_ATTR_SCRADDR_H[19],X ; Store addr.
    RTS ; Leave.
DISPLAY_OBJECTS_SPRITES: ; C:039E, 0x00039E
    LDA #$00
    STA SPRITE_PAGE_INDEX ; Clear ??
    LDY #$00 ; Clear. Bad, TAY works.
    LDX #$18 ; Object index.
LOOP_ALL_X_INDEXES: ; C:03A6, 0x0003A6
    LDA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Load.
    BPL NEXT_INDEX
    LDA OBJ_PROCESS_DATA_PTR_L[19],X ; Load.
    ORA OBJ_PROCESS_DATA_PTR_H[19],X ; Combine with.
    BEQ NEXT_INDEX ; == 0, next.
    TXA ; Index to A.
    STA **:$049D,Y ; Index save.
    INY ; Next Y index.
NEXT_INDEX: ; C:03B8, 0x0003B8
    DEX ; X--
    BPL LOOP_ALL_X_INDEXES ; Positive, goto.
    CPY #$00 ; If Y _ #$00
    BNE Y_NONZERO ; != 0, goto.
    JMP SPRITE_OFFSCREEN ; Goto.
Y_NONZERO: ; C:03C2, 0x0003C2
    DEY ; Y--
    STY **:$009C ; Store to.
    BEQ Y_EQ_ZERO ; == 0, goto.
Y_POSITIVE_DEC: ; C:03C7, 0x0003C7
    LDX **:$049D,Y ; X from.
    LDA OBJ_ATTR_UNK_071[19],X ; Load from X.
    BEQ VAL_ZERO/FF ; == 0, goto.
    CMP #$FF
    BEQ VAL_ZERO/FF ; == 0xFF, goto.
    LDA OBJ_SCREEN_POS_X[2],X ; Load.
    LSR A ; >> 1, /2.
    STA TMP_00 ; Store to.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load.
    LSR A ; >> 1, /2.
    CLC ; Prep add.
    ADC TMP_00 ; Add with.
    EOR #$FF ; Invert bits.
    STA OBJ_ATTR_UNK_071[19],X ; Store to.
VAL_ZERO/FF: ; C:03E1, 0x0003E1
    DEY ; Y--
    BPL Y_POSITIVE_DEC ; Positive, goto.
    LDX #$00 ; Index.
X_LT_VAR_LOOP: ; C:03E6, 0x0003E6
    STX TMP_00 ; Clear.
    LDY **:$049E,X ; Y from, no index.
    STY TMP_01 ; Store to.
    LDA OBJ_ATTR_UNK_071[19],Y ; Load from.
    STA TMP_02 ; Store to.
X_STILL_POSITIVE: ; C:03F2, 0x0003F2
    LDA **:$049D,X ; Load from, no index.
    TAY ; Val to Y.
    LDA OBJ_ATTR_UNK_071[19],Y ; Load from arr.
    CMP TMP_02 ; If _ TMP
    BCC VAL_LT_TMP ; <, goto.
    TYA ; Y to A.
    STA **:$049E,X ; Store to.
    DEX ; X--
    BPL X_STILL_POSITIVE ; Positive, goto.
VAL_LT_TMP: ; C:0404, 0x000404
    LDA TMP_01 ; Load TMP.
    INX ; X++
    STA **:$049D,X ; Val to.
    LDX TMP_00 ; X from.
    INX ; ++
    CPX **:$009C ; If _ var
    BCC X_LT_VAR_LOOP ; <, goto.
Y_EQ_ZERO: ; C:0411, 0x000411
    LDY #$00 ; Index.
ANOTHER_LONGER_REENTER: ; C:0413, 0x000413
    LDX **:$049D,Y ; X from, no index.
    TYA ; Clear A.
    PHA ; Save 0x00.
    STX **:$009B ; X to.
    LDA OBJ_PROCESS_DATA_PTR_L[19],X ; Load.
    STA TEXT_STREAM_FILE[2] ; Store to.
    LDA OBJ_PROCESS_DATA_PTR_H[19],X ; Load.
    STA TEXT_STREAM_FILE+1 ; Store to.
    LDY #$01 ; Stream index.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from file.
    STA COUNT_LARGER ; Store to.
    ASL A ; << 3, *8.
    ASL A
    ASL A
    STA TMP_00 ; Store to.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load.
    SEC ; Prep sub.
    SBC TMP_00 ; Sub val.
    STA SPRITE_Y_VAL_LSB ; Store to.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load.
    SBC #$00 ; Carry sub.
    STA SPRITE_Y_VAL_MSB ; Store to.
    LDY #$03 ; Val?
RTN_LONG_REENTER: ; C:043E, 0x00043E
    LDA OBJ_SCREEN_POS_X[2],X ; Load from X.
    STA SPRITE_X_VAL_LSB ; Store to.
    LDA OBJ_PTR_UNK_A_H[2],X ; Load from X.
    STA SPRITE_X_VAL_MSB ; Store to.
    TYA ; A = 0x03.
    PHA ; Save 0x03.
    LDY #$00 ; Stream index.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from file.
    STA COUNT_SMALLER ; Stoe to.
    PLA ; Pull 0x03.
    TAY ; To Y.
    LDA #$40 ; Load val.
    AND OBJ_DATA_BYTE_FROM_PTR,X ; And with arr.
    BEQ BIT_NOT_SET ; == 0, not set, goto.
    LDA COUNT_SMALLER ; Load.
    SEC ; Prep sub.
    SBC #$01 ; -= 0x1
    ASL A ; << 3, *8.
    ASL A
    ASL A
    CLC ; Prep add.
    ADC SPRITE_X_VAL_LSB ; Add with.
    STA SPRITE_X_VAL_LSB ; Store back.
    LDA SPRITE_X_VAL_MSB ; Carry add to here.
    ADC #$00
    STA SPRITE_X_VAL_MSB
BIT_NOT_SET: ; C:046A, 0x00046A
    LDA SPRITE_X_VAL_MSB ; Load
    ORA SPRITE_Y_VAL_MSB ; Combine with.
    BNE VAL_COMBINE_NONZERO ; != 0, goto.
    LDA OBJ_DATA_BYTE_FROM_PTR,X ; Load from arr.
    LDX SPRITE_PAGE_INDEX ; Load index.
    STA SPRITE_PAGE+2,X ; Store val to attr.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from file.
    BEQ VAL_EQ_ZERO_SPRITE ; == 0, goto.
    STA SPRITE_PAGE+1,X ; Store val to tile.
    LDA SPRITE_X_VAL_LSB
    STA SPRITE_PAGE+3,X ; Store to.
    LDA SPRITE_Y_VAL_LSB
    STA SPRITE_PAGE[256],X ; Store to.
    TXA ; Index to A.
    CLC ; Prep add.
    ADC #$04 ; Add with.
    BCS VAL_EQ_ZERO_SPRITE ; Overflow, tapped out of sprites, goto.
    STA SPRITE_PAGE_INDEX ; Store otherwise.
VAL_EQ_ZERO_SPRITE: ; C:0491, 0x000491
    LDX **:$009B ; Index load.
VAL_COMBINE_NONZERO: ; C:0493, 0x000493
    INY ; Index++
    LDA #$40 ; Load.
    AND OBJ_DATA_BYTE_FROM_PTR,X ; Test bit.
    BEQ BIT_UNSET ; == 0, not set, goto.
    LDA SPRITE_X_VAL_LSB ; Load.
    SEC ; Prep sub.
    SBC #$08 ; Sub with.
    STA SPRITE_X_VAL_LSB ; Store val back.
    LDA SPRITE_X_VAL_MSB ; Load
    SBC #$00 ; Carry sub.
    STA SPRITE_X_VAL_MSB ; Store back.
    JMP X_SUB_REENTER ; Goto.
BIT_UNSET: ; C:04AB, 0x0004AB
    LDA SPRITE_X_VAL_LSB ; Load.
    CLC ; Prep add.
    LDA SPRITE_X_VAL_LSB ; Load again to make sure, lol.
    ADC #$08 ; Add to val.
    STA SPRITE_X_VAL_LSB ; Store back.
    LDA SPRITE_X_VAL_MSB ; Carry add.
    ADC #$00
    STA SPRITE_X_VAL_MSB
X_SUB_REENTER: ; C:04BA, 0x0004BA
    DEC COUNT_SMALLER ; --
    BNE BIT_NOT_SET ; Nonzero, goto.
    CLC ; Prep add.
    LDA SPRITE_Y_VAL_LSB ; Load val. Again, bad.
    ADC #$08 ; Add to.
    STA SPRITE_Y_VAL_LSB ; Store.
    LDA SPRITE_Y_VAL_MSB ; Carry add.
    ADC #$00
    STA SPRITE_Y_VAL_MSB
    DEC COUNT_LARGER ; --
    BEQ VOUNTER_EQ_ZERO ; == 0, goto.
    JMP RTN_LONG_REENTER ; Loop.
VOUNTER_EQ_ZERO: ; C:04D2, 0x0004D2
    PLA ; Restore Y.
    TAY
    CPY **:$009C ; If _ var
    BEQ SPRITE_OFFSCREEN ; ==, goto.
    INY ; ++
    JMP ANOTHER_LONGER_REENTER ; Goto.
SPRITE_OFFSCREEN: ; C:04DC, 0x0004DC
    LDX SPRITE_PAGE_INDEX ; X from.
    LDA #$F0 ; Load.
SPRITES_OKAY: ; C:04E0, 0x0004E0
    STA SPRITE_PAGE[256],X ; Store to. Sprite page.
    INX ; Sprite slot++
    INX
    INX
    INX
    BNE SPRITES_OKAY ; Nonzero, we're gucci.
    RTS ; Leave.
INIT_OBJECT_ANIMATION_FILE_PTR_PAST: ; C:04EA, 0x0004EA
    JSR ORIGINAL_JSR_CALLER_DATA_PTR_TO_STACK ; Get data past.
    PLA
    STA TMP_00 ; Store to TMP.
    PLA
    STA TMP_01
OBJECT_MOVE_PTR_AND_SEED_FROM_STREAM_DISPLAY?: ; C:04F3, 0x0004F3
    LDA TMP_00 ; Load.
    STA OBJ_PROCESS_DATA_PTR_L[19],X ; Store animation ptr to obj?
    LDA TMP_01
    STA OBJ_PROCESS_DATA_PTR_H[19],X
    LDY #$02 ; File index for anims.
    LDA [TMP_00],Y ; Move.
    STA OBJ_DATA_BYTE_FROM_PTR,X ; Store to obj.
    RTS ; Leave.
SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN: ; C:0505, 0x000505
    PLA ; Pull address JSR'd from. L byte.
    STA TEXT_STREAM_FILE[2] ; Store to.
    PLA ; H byte.
    STA TEXT_STREAM_FILE+1 ; Store to.
    LDY #$01 ; Index RTS offset.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from after.
    TAX ; Val to X.
    INY ; Next index.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load val.
    TAY ; To Y. Data in X and Y.
    TXA ; Now in A and Y.
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Do.
    LDY #$03 ; Index.
    JSR FILE_NE_ZERO ; Do.
    TYA ; Val to A.
    CLC ; Prep add.
    ADC TEXT_STREAM_FILE[2] ; Add to.
    TAY ; Val to Y.
    LDA TEXT_STREAM_FILE+1 ; Add to, too.Load other val.
    ADC #$00 ; Add with.
    PHA ; Restore Y/A.
    TYA
    PHA
    RTS ; Leave.
TEXT_FROM_PTR_TABLE: ; C:052A, 0x00052A
    STA TEXT_STREAM_FILE[2]
    STY TEXT_STREAM_FILE+1
    LDY #$00 ; Reset index.
FILE_NE_ZERO: ; C:0530, 0x000530
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from file.
    BEQ RTS ; == 0, leave, EOF.
    SEC ; Prep sub.
    SBC #$20 ; Sub with.
    JSR PPU_UPDATE_ARRAY_RTN_UNK ; Do.
    INY ; File++
    BNE FILE_NE_ZERO ; != 0, loop on.
RTS: ; C:053D, 0x00053D
    RTS ; Leave.
PPU_UPDATE_PACKET_UPLOADER: ; C:053E, 0x00053E
    LDX #$00 ; Index to BG update range.
PACKET_CHECK_LOOP: ; C:0540, 0x000540
    LDY PPU_UPDATE_BUFFER_ARR[8],X ; Load update tile count.
    BEQ DATA_EOF ; == 0, goto. EOF. Nothing here.
    LDA PPU_UPDATE_BUFFER_ARR+2,X ; Load addr of update packet.
    STA PPU_ADDR
    LDA PPU_UPDATE_BUFFER_ARR+1,X
    STA PPU_ADDR
    INX ; Skip past addr and count.
    INX
    INX
LOOP_COUNT_TILES: ; C:0554, 0x000554
    LDA PPU_UPDATE_BUFFER_ARR[8],X ; Load from buf.
    STA PPU_DATA ; Store to PPU.
    INX ; Index++
    DEY ; Count--
    BNE LOOP_COUNT_TILES ; != 0, loop more tiles.
    BEQ PACKET_CHECK_LOOP ; == 0, goto.
DATA_EOF: ; C:0560, 0x000560
    LDA #$00
    STA PPU_UPDATE_BUFFER_ARR[8] ; Store EOF to.
    STA PPU_UPDATE_BUF_INDEX ; No more index.
    RTS ; Leave.
SUB_UNK_A: ; C:0568, 0x000568
    STA SPRITE_X_VAL_MSB ; Store pos.
    STY SPRITE_Y_VAL_LSB
    LDA TMP_00 ; Move to FPTR.
    STA TEXT_STREAM_FILE[2]
    LDA TMP_01
    STA TEXT_STREAM_FILE+1
    JMP ENTRY_SETUP ; Enter.
    STA SPRITE_X_VAL_MSB ; Store pos.
    STY SPRITE_Y_VAL_LSB
    JSR ORIGINAL_JSR_CALLER_DATA_PTR_TO_STACK ; Get PTR from caller JSR up.
    PLA ; Pull off stack, put to file.
    STA TEXT_STREAM_FILE[2]
    PLA
    STA TEXT_STREAM_FILE+1
ENTRY_SETUP: ; C:0584, 0x000584
    LDY #$01 ; Stream index.
    LDA [TEXT_STREAM_FILE[2]],Y ; Move ??
    STA COUNT_LARGER
    LDA SPRITE_Y_VAL_LSB ; Load ??
    SEC ; Prep sub.
    SBC COUNT_LARGER ; Sub with.
    BCS SUB_NO_UNDERFLOW ; No underflow, goto.
    CLC ; Prep add.
    ADC #$3C ; Add with.
SUB_NO_UNDERFLOW: ; C:0594, 0x000594
    STA SPRITE_Y_VAL_LSB ; Store val.
    INC SPRITE_Y_VAL_LSB ; And one more.
    LDY #$03 ; Index for later.
COUNT_NONZERO_LARGER: ; C:059A, 0x00059A
    LDA SPRITE_X_VAL_MSB ; Move ??
    STA SPRITE_X_VAL_LSB
    TYA ; Save index to stack.
    PHA
    LDA SPRITE_X_VAL_LSB ; Move ??
    LDY SPRITE_Y_VAL_LSB
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Do update packet.
    LDX CURRENT_OBJ_PROCESSING ; Load obj.
    LDY #$00 ; Stream reset.
    LDA [TEXT_STREAM_FILE[2]],Y ; Load ??
    STA COUNT_SMALLER ; Store to.
    PLA ; Pull stack.
    TAY ; To Y index.
COUNT_NONZERO_INNER: ; C:05B1, 0x0005B1
    LDA [TEXT_STREAM_FILE[2]],Y ; Load from stream.
    JSR PPU_UPDATE_ARRAY_RTN_UNK ; Update create.
    INY ; Stream++
    INC SPRITE_X_VAL_LSB ; ++
    DEC COUNT_SMALLER ; --
    BNE COUNT_NONZERO_INNER ; != 0, goto.
    INC SPRITE_Y_VAL_LSB ; ++
    DEC COUNT_LARGER ; --
    BNE COUNT_NONZERO_LARGER ; != 0, goto.
    RTS ; Leave.
PPU_UPDATE_ARRAY_RTN_UNK: ; C:05C4, 0x0005C4
    STA TMP_00 ; Val to.
    TXA ; Save X and Y.
    PHA
    TYA
    PHA
    LDX PPU_UPDATE_BUF_INDEX ; X from.
    TXA ; To A.
    CLC ; Prep add.
    ADC PPU_UPDATE_BUFFER_ARR[8],X ; Add with from arr index.
    ADC #$03 ; Add too. Size of packet?
    TAY ; A to Y index.
    LDA PPU_UPDATE_BUFFER_ARR+1,X ; Load from.
    AND #$1F ; Keep bits.
    CLC ; Prep add.
    ADC PPU_UPDATE_BUFFER_ARR[8],X ; Add with.
    CMP #$20 ; If _ #$20
    BCC LT_0x20 ; <, goto.
    STY PPU_UPDATE_BUF_INDEX ; Y to.
    LDA #$00
    STA PPU_UPDATE_BUFFER_ARR[8],Y ; Clear at Y.
    LDA PPU_UPDATE_BUFFER_ARR+1,X ; Load from arr.
    AND #$E0 ; Keep upper bits.
    STA PPU_UPDATE_BUFFER_ARR+1,Y ; Store back.
    LDA PPU_UPDATE_BUFFER_ARR+2,X ; Load. from X.
    STA PPU_UPDATE_BUFFER_ARR+2,Y ; Store to Y.
    TYA ; Y to X.
    TAX
    INY ; Y += 3
    INY
    INY
LT_0x20: ; C:05FB, 0x0005FB
    LDA TMP_00 ; Load.
    STA PPU_UPDATE_BUFFER_ARR[8],Y ; Store to arr at Y.
    LDA #$00
    STA PPU_UPDATE_BUFFER_ARR+1,Y ; Clear arr.
    INC PPU_UPDATE_BUFFER_ARR[8],X ; Inc X index.
    PLA
    TAY ; Restore X and Y.
    PLA
    TAX
    LDA TMP_00 ; Load original A val.
    RTS ; Leave.
SET_OBJ_ATTR_0x40_UNK: ; C:060F, 0x00060F
    LDA OBJ_DATA_BYTE_FROM_PTR,X ; Set attr bit unk.
    ORA #$40
    STA OBJ_DATA_BYTE_FROM_PTR,X
    RTS ; Leave.
OBJECT_MOVE_ATTR_A_BY_0x1: ; C:0618, 0x000618
    LDA #$01
RETRACT_PTR_A_BY_A: ; C:061A, 0x00061A
    STA TMP_00 ; Set ??
    LDA OBJ_SCREEN_POS_X[2],X ; Load from arr.
    SEC ; Prep sub.
    SBC TMP_00 ; Stream - val
    TAY ; To Y.
    LDA OBJ_PTR_UNK_A_H[2],X ; Load pair.
    SBC #$00 ; Carry sub.
    JMP OUTPUT_PTR_A_RESULT ; Goto.
ADVANCE_PTR_A_BY_0x1: ; C:0629, 0x000629
    LDA #$01 ; Seed forward 0x1
ADVANCE_PTR_A_BY_A: ; C:062B, 0x00062B
    STA TMP_00 ; Store to.
    LDA OBJ_SCREEN_POS_X[2],X ; Load.
    CLC ; Prep add.
    ADC TMP_00 ; Add with.
    TAY ; To Y index.
    LDA OBJ_PTR_UNK_A_H[2],X ; Load.
    ADC #$00 ; Carry add.
    JMP OUTPUT_PTR_A_RESULT ; Goto, abuse RTS.
CLEAR/SET_ARRAYS_A: ; C:063A, 0x00063A
    TAY ; Save in Y.
    LDA #$00
OUTPUT_PTR_A_RESULT: ; C:063D, 0x00063D
    STA OBJ_PTR_UNK_A_H[2],X ; Set PTR H passed.
    TYA ; Back to A.
    STA OBJ_SCREEN_POS_X[2],X ; Set PTR L.
    RTS ; Leave.
SET_A/B_ARRAYS_UNK: ; C:0643, 0x000643
    STY TMP_00 ; Y to.
    JSR CLEAR/SET_ARRAYS_A ; Do ??
    LDA TMP_00 ; Load.
    JMP SET_OBJECT_PTR_L_A_H_0x00 ; Goto, abuse RTS.
RETRACT_PTR_B_BY_0x1: ; C:064D, 0x00064D
    LDA #$01
RETRACT_PTR_B_BY_A: ; C:064F, 0x00064F
    STA TMP_00 ; Store to.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load.
    SEC ; Prep sub.
    SBC TMP_00 ; Sub with passed.
    TAY ; To Y.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load H.
    SBC #$00 ; Carry sub.
    JMP OUTPUT_PTR_B_RESULT
ADVANCE_PTR_B_BY_0x1: ; C:065E, 0x00065E
    LDA #$01 ; Move ??
ADVANCE_PTR_B_BY_A: ; C:0660, 0x000660
    STA TMP_00
    LDA OBJ_PTR_UNK_B_L[2],X ; Load from OBJ.
    CLC ; Prep add.
    ADC TMP_00 ; Add with.
    TAY ; To Y index.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load other.
    ADC #$00 ; Carry add.
    JMP OUTPUT_PTR_B_RESULT ; Exit.
SET_OBJECT_PTR_L_A_H_0x00: ; C:066F, 0x00066F
    TAY ; Val to Y.
    LDA #$00
OUTPUT_PTR_B_RESULT: ; C:0672, 0x000672
    STA OBJ_PTR_UNK_B_H[2],X ; Clear PTR H.
    TYA ; Back to A.
    STA OBJ_PTR_UNK_B_L[2],X ; Set PTR L.
    RTS ; Leave.
OBJECT_X_ID_DESTROY: ; C:0678, 0x000678
    LDA #$00
    STA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Clear flag of obj.
    RTS ; Leave.
ENGINE_FORWARD_OBJECTS/DISPLAY: ; C:067E, 0x00067E
    LDX #$18 ; Index.
OBJECT_SCRIPT_FORWARD: ; C:0680, 0x000680
    LDA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Load data.
    BPL NEXT_OBJECT ; Positive, next index.
    TAY ; Save attr.
    LDA OBJ_ATTR_TIMER[19],X ; Load from arr.
    BEQ VAL_LOADED_ZERO ; == 0, goto.
    SEC ; Prep sub.
    SBC #$01 ; Sub val.
    STA OBJ_ATTR_TIMER[19],X ; Store back.
    BEQ VAL_RESULT_ZERO ; == 0, goto.
    TYA ; Attr back.
    AND #$40 ; Test bit.
    BNE NEXT_OBJECT ; If set, next.
VAL_RESULT_ZERO: ; C:0698, 0x000698
    LDA #$80
    STA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Set attr.
VAL_LOADED_ZERO: ; C:069D, 0x00069D
    STX CURRENT_OBJ_PROCESSING ; Store current running.
    LDA OBJ_PROCESS_HANDLER_L[19],X ; Move code ptr.
    STA TMP_00
    LDA OBJ_PROCESS_HANDLER_H[19],X
    STA TMP_01
    LDY OBJ_SCRIPT_RETURN_ARG?,X ; Y index from.
    JSR OBJECT_RELAUNCH_HANDLER ; Do script rtn for obj.
    LDX CURRENT_OBJ_PROCESSING ; Restore obj index.
    TYA ; Returned Y to A.
    STA OBJ_SCRIPT_RETURN_ARG?,X ; Store val to obj.
NEXT_OBJECT: ; C:06B5, 0x0006B5
    DEX ; Obj--
    BPL OBJECT_SCRIPT_FORWARD ; Positive, goto.
    JSR DISPLAY_OBJECTS_SPRITES ; Do.
    INC OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; ++
    RTS ; Leave.
OBJECT_RELAUNCH_HANDLER: ; C:06BE, 0x0006BE
    JMP [TMP_00] ; Launch the routine.
CLEAR_ALL_OBJECTS_USED: ; C:06C1, 0x0006C1
    LDX #$18 ; X = 
    LDA #$00 ; A =
CLEAR_ALL: ; C:06C5, 0x0006C5
    STA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Clear.
    DEX ; Index--
    BPL CLEAR_ALL ; Positive, do more.
    RTS ; Leave.
CREATE_PROCESS_WITH_PTR_PAST: ; C:06CC, 0x0006CC
    JSR ORIGINAL_JSR_CALLER_DATA_PTR_TO_STACK ; Get PTR past original caller.
    PLA
    STA TMP_00 ; Pull addr of prev caller, store to.
    PLA
    STA TMP_01
SUB_HELPER_TODO: ; C:06D5, 0x0006D5
    LDX #$18 ; Index start.
LOOP_ALL_OBJS: ; C:06D7, 0x0006D7
    LDA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Load from.
    BPL OBJECT_SLOT_FOUND ; Not used, goto.
    DEX ; Index--
    BPL LOOP_ALL_OBJS ; Positive, loop.
    TXA ; Negative to A.
    RTS ; Leave.
OBJECT_SLOT_FOUND: ; C:06E1, 0x0006E1
    LDA #$80 ; Load.
    STA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Store to.
    LDA TMP_00 ; Move from TMP to OBJ.
    STA OBJ_PROCESS_HANDLER_L[19],X ; Is script handler.
    LDA TMP_01
    STA OBJ_PROCESS_HANDLER_H[19],X
    LDA #$00
    STA OBJ_PROCESS_DATA_PTR_L[19],X ; Clear these.
    STA OBJ_PROCESS_DATA_PTR_H[19],X
    STA OBJ_ATTR_SCRADDR_H[19],X
    STA OBJ_ATTR_SCREEN_TILE_UNDER[19],X
    LDA #$80 ; Val to.
    STA OBJ_ATTR_UNK_071[19],X
    TXA ; Obj index to A.
    LDX CURRENT_OBJ_PROCESSING ; Load current.
    RTS ; Leave.
ENGINE_OBJECT_SUSPEND_IN_PLACE: ; C:0706, 0x000706
    LDX CURRENT_OBJ_PROCESSING ; Reload object indexer.
    PLA ; Pull  addr at.
    CLC ; Prep add.
    ADC #$01 ; Add with to put past RTS addr into next inst.
    STA OBJ_PROCESS_HANDLER_L[19],X ; Store to arr.
    PLA ; Pull addr.
    ADC #$00 ; Carry add.
    STA OBJ_PROCESS_HANDLER_H[19],X ; Store to other arr.
    RTS ; Leave.
PTR_AFTER_JSR_TO_NMI_PTR: ; C:0716, 0x000716
    JSR ORIGINAL_JSR_CALLER_DATA_PTR_TO_STACK ; Set up.
    PLA
    STA NMI_RTN_PTR[2] ; Pull previous rtn addr and store to.
    PLA
    STA NMI_RTN_PTR+1
    RTS ; Leave.
SUSPEND_OBJ_TIMER/FLAG_HELPER: ; C:0722, 0x000722
    LDX CURRENT_OBJ_PROCESSING ; Load obj processing.
    STA OBJ_ATTR_TIMER[19],X ; Val to timer of the object.
    LDA #$C0
    STA OBJ_FLAG_ACTIVE/USED/STATUS[19],X ; Set flags.
    JMP ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend, abuse RTS.
ORIGINAL_JSR_CALLER_DATA_PTR_TO_STACK: ; C:072F, 0x00072F
    PLA ; Pull where the latest JSR is.
    STA TMP_00 ; To.
    PLA
    STA TMP_01
    PLA ; Pull the original caller addr.
    STA TMP_02 ; To. Original caller re-entry.
    CLC
    ADC #$02 ; Add offset to get addr to run.
    TAY ; Offset to Y.
    PLA ; Pull H byte.
    STA TMP_03 ; Store to.
    ADC #$00 ; Carry add.
    PHA ; Save back addr past data for RTS.
    TYA
    PHA ; Save PTR L.
    LDY #$02 ; Stream index for data first byte.
    LDA [TMP_02],Y ; Load addr in data.
    PHA ; Save address to stack thats past the JSR.
    DEY ; Data index-- for 2nd byte of addr.
    LDA [TMP_02],Y ; Load from stream.
    PHA ; Save to stack.
    LDA TMP_01 ; Move original RTS back into position.
    PHA
    LDA TMP_00
    PHA
    RTS ; Leave correctly, no extras or anything.
ENTER_GAME_MENUS/INTRO_LOOP_WITH_INITIALS_INIT: ; C:0754, 0x000754
    LDX #$4F ; Index.
INDEX_POSITIVE: ; C:0756, 0x000756
    LDA ROM_DATA_INIT_SCORES,X ; Load from ROM.
    STA SCORES_INITIALS_ARRAY,X ; Store to arr.
    DEX ; Index--
    BPL INDEX_POSITIVE ; Positive, goto. Do all.
REENTER_GAME_MENUS_WITHOUT_INTIAL_INIT: ; C:075F, 0x00075F
    JSR NEWSPAPER_SCREEN_HELPER ; Do.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Switch.
    .db 03
    .db 08
    .db 41
    .db 4D
    .db 41
    .db 5A
    .db 49
    .db 4E
    .db 47
    .db 20
    .db 50
    .db 41
    .db 50
    .db 45
    .db 52
    .db 42
    .db 4F
    .db 59
    .db 20
    .db 44
    .db 45
    .db 4C
    .db 49
    .db 56
    .db 45
    .db 52
    .db 53
    .db 21
    .db 00
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend the script here. SSSSSSSSSSSSSSSSSSSSSSSSSSSSS
    JSR PPU_HELPER_ENABLE_RENDERING ; Enable rendering.
    LDA #$FF ; Val ??
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend. SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
    JSR CTRL_TEST_SELECT/START_BOTH_CONTROLLERS ; Do ??
    BNE SETUP_SELECT_PLAYERS_SCREEN ; != 0, goto.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BEQ SETUP_SELECT_PLAYERS_SCREEN ; If zero, goto.
    RTS ; Leave.
SETUP_SELECT_PLAYERS_SCREEN: ; C:079B, 0x00079B
    JSR SELECT_SCREEN_FILE ; Setup select screen.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Put this on screen, too.
    .db 04
    .db 08
    .db 53
    .db 45
    .db 4C
    .db 45
    .db 43
    .db 54
    .db 20
    .db 4E
    .db 55
    .db 4D
    .db 42
    .db 45
    .db 52
    .db 20
    .db 4F
    .db 46
    .db 20
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 53
    .db 00
    .db 20
    .db 05
    .db 85
    .db 0D
    .db 0B
    .db 31
    .db 20
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 00
    .db 20
    .db 05
    .db 85
    .db 0D
    .db 0E
    .db 32
    .db 20
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 53
    .db 00
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show other stuff.
    .db 07
    .db 12
    .db 4D
    .db 49
    .db 4E
    .db 44
    .db 53
    .db 43
    .db 41
    .db 50
    .db 45
    .db 20
    .db 50
    .db 52
    .db 45
    .db 53
    .db 45
    .db 4E
    .db 54
    .db 53
    .db 00
    .db 20
    .db 05
    .db 85
    .db 02
    .db 14
    .db 50
    .db 41
    .db 50
    .db 45
    .db 52
    .db 42
    .db 4F
    .db 59
    .db 23
    .db 24
    .db 40
    .db 20
    .db 31
    .db 39
    .db 38
    .db 38
    .db 2C
    .db 31
    .db 39
    .db 38
    .db 34
    .db 20
    .db 54
    .db 45
    .db 4E
    .db 47
    .db 45
    .db 4E
    .db 00
    .db 20
    .db 05
    .db 85
    .db 07
    .db 16
    .db 20
    .db 41
    .db 4C
    .db 4C
    .db 20
    .db 52
    .db 49
    .db 47
    .db 48
    .db 54
    .db 53
    .db 20
    .db 52
    .db 45
    .db 53
    .db 45
    .db 52
    .db 56
    .db 45
    .db 44
    .db 00
    .db 20
    .db 05
    .db 85
    .db 0B
    .db 19
    .db 4C
    .db 49
    .db 43
    .db 45
    .db 4E
    .db 53
    .db 45
    .db 44
    .db 20
    .db 42
    .db 59
    .db 00
    .db 20
    .db 05
    .db 85
    .db 05
    .db 1B
    .db 4E
    .db 49
    .db 4E
    .db 54
    .db 45
    .db 4E
    .db 44
    .db 4F
    .db 20
    .db 4F
    .db 46
    .db 20
    .db 41
    .db 4D
    .db 45
    .db 52
    .db 49
    .db 43
    .db 41
    .db 20
    .db 49
    .db 4E
    .db 43
    .db 2E
    .db 00
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do ??
    LOW(DATA_UNK) ; 0x2E09
    HIGH(DATA_UNK)
    LDA #$00
    STA GAME_CURRENT_PLAYER ; Clear.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend. SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
    JSR PPU_HELPER_ENABLE_RENDERING ; Show screen.
SELECT_PRESSED: ; C:086B, 0x00086B
    LDA #$58 ; To A.
    LDY #$60 ; To B.
    JSR SET_A/B_ARRAYS_UNK ; Do ??
    LDA #$00
    STA FLAG_MULTIPLAYER_GAME ; Clear ??
    JSR CREATE_PROCESS_WITH_PTR_PAST
    LOW(RTN_SOUND_GOOD_BEEP) ; Routine ptr.
    HIGH(RTN_SOUND_GOOD_BEEP)
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Set ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend here.
    LDY #$00
    JSR CTRL_READ_PORT_Y ; Read P1 controller.
    LDA #$20 ; Test select.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
    BEQ TEST_START ; == 0, clear, not pressed.
    LDA #$01
    STA FLAG_MULTIPLAYER_GAME ; Set.
    LDA #$78
    JSR SET_OBJECT_PTR_L_A_H_0x00 ; Do.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn.
    LOW(RTN_SOUND_GOOD_BEEP)
    HIGH(RTN_SOUND_GOOD_BEEP)
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Reset timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend here. SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
    LDY #$00 ; P1 controller.
    JSR CTRL_READ_PORT_Y ; Read P1 controller.
    LDA #$20 ; Test select.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
    BNE SELECT_PRESSED ; If set, goto.
TEST_START: ; C:08AF, 0x0008AF
    LDA #$10 ; Test start.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Start pressed, goto.
    BNE START_PRESSED ; Pressed, goto.
    LDA OBJ_ATTR_TIMER[19],X ; Load.
    BEQ WAIT_TIMEOUT ; == 0, goto.
    RTS ; Leave.
WAIT_TIMEOUT: ; C:08BB, 0x0008BB
    LDA #$FF
    STA GAME_CURRENT_PLAYER ; Set ??
    LDA #$00
    STA FLAG_MULTIPLAYER_GAME ; Clear ??
START_PRESSED: ; C:08C3, 0x0008C3
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Game started <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    .db 00 ; NULL.
    .db 00
    JSR HOUSES_RELATED_PROBS_TODO_LATER ; Do ??
    LDY #$13 ; Obj.
    LDA #$00 ; Clear.
CLEAR_ATTRS_UNK: ; C:08CF, 0x0008CF
    STA OBJ_ATTR_731_UNK,Y ; Attr??
    DEY ; Obj--
    BPL CLEAR_ATTRS_UNK ; Positive, goto.
    LDA GAME_CURRENT_PLAYER ; Load player.
    BMI GAME_ATTRACT ; Negative, goto. Attract demo.
    JSR SETUP_CUSTOMERS_SCREEN ; Do.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show your customers.
    .db 0A
    .db 1B
    .db 59
    .db 4F
    .db 55
    .db 52
    .db 20
    .db 43
    .db 55
    .db 53
    .db 54
    .db 4F
    .db 4D
    .db 45
    .db 52
    .db 53
    .db 00
    JSR PPU_HELPER_ENABLE_RENDERING ; Show screen.
    JSR HOUSES_ROUTINE_SEED_CUSTOMER ; Do ??
    LDA #$F0
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Do ??
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show non-customers.
    .db 0A
    .db 1B
    .db 4E
    .db 4F
    .db 4E
    .db 2D
    .db 43
    .db 55
    .db 53
    .db 54
    .db 4F
    .db 4D
    .db 45
    .db 52
    .db 53
    .db 20
    .db 00
    JSR HOUSES_ROUTINE_SEED_NON-CUSTOMER ; Do.
    LDA #$F0
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Timer wait for customers consumption.
    LDA #$78
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Timer for non-customers consumption.
GAME_ATTRACT: ; C:091C, 0x00091C
    JSR LEVEL_INIT ; Init.
    JSR CLEAR_ALL_OBJECTS_USED ; Init.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn.
    LOW(RTN_GAME_START_DAY_OF_THE_WEEK)
    HIGH(RTN_GAME_START_DAY_OF_THE_WEEK)
    .db 60 ; Leave, done.
RTN_GAME_START_DAY_OF_THE_WEEK: ; C:0928, 0x000928
    LDA FLAG_MULTIPLAYER_GAME ; Load.
    BNE CLEAR_OBJECTS ; No days of the week again unless multiplayer.
    JSR INIT_GAMEPLAY_SCREEN_GRAPHICS/PALETTE ; Init.
    LDA GAME_CURRENT_PLAYER ; Load.
    BMI CLEAR_OBJECTS ; Negative, goto.
    LDA #$0C ; Seed screen pos.
    LDY #$0F
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Packet maker.
    JSR GAME_PLAYER_DAY_OF_THE_WEEK ; Day of the week to the buffer.
    JSR PPU_HELPER_ENABLE_RENDERING ; Enable rendering.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend to here.
CLEAR_OBJECTS: ; C:0945, 0x000945
    LDA #$01
    STA GAME_INDEX_HOUSE_ID_UPLOADING ; Set.
    LDY #$15 ; Obj. 21?
    LDA #$00 ; Val.
INDEX_POSITIVE_LOOP: ; C:094D, 0x00094D
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Clear.
    DEY ; Index--
    BPL INDEX_POSITIVE_LOOP ; Positive, do all.
GAME_PLAYER_START_WITH_TEXT_RTN: ; C:0953, 0x000953
    JSR INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING ; Init to first screen.
    LDA FLAG_MULTIPLAYER_GAME ; Load.
    BEQ SINGLE_PLAYER_DONT_SHOW_PLAYER_NUMBER ; == 0, goto.
    JSR INIT_GAMEPLAY_SCREEN_GRAPHICS/PALETTE ; Init screen.
    LDA #$0C
    LDY #$0F
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Do screen update.
    JSR GAME_PLAYER_DAY_OF_THE_WEEK ; Day of the week.
    LDA GAME_CURRENT_PLAYER ; Load.
    BNE SHOW_PLAYER_TWO ; != 0, goto.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show P1.
    .db 03
    .db 03
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 31
    .db 00
    JMP PLAYER_TEXT_SHOWN ; Goto.
SHOW_PLAYER_TWO: ; C:097C, 0x00097C
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show P2.
    .db 03
    .db 03
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 32
    .db 00
PLAYER_TEXT_SHOWN: ; C:098A, 0x00098A
    JSR PPU_HELPER_ENABLE_RENDERING ; Show it.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Do ??
    JSR INIT_PPU_COPIES/PPU_ADDR_0x2000/NO_RENDERING ; Do.
SINGLE_PLAYER_DONT_SHOW_PLAYER_NUMBER: ; C:0995, 0x000995
    LDA #$01
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; Switch GFX Bank for gameplay.
    DEC GAME_INDEX_HOUSE_ID_UPLOADING ; -= 2
    DEC GAME_INDEX_HOUSE_ID_UPLOADING
    LDA #$01
    STA HOUSE_FILE_STREAM_DATA_LOADED ; Set ??
    LDA #$0A
    STA VAL_CMP_UNK ; Set ??
    LDA #$7F
    STA **:$00BA ; Set ??
    LDA #$00
    STA PPU_UPDATE_ADDR_A+1 ; Clear ??
    STA **:$00B0
    STA **:$00C6
    LDX #$1F ; Index.
INDEX_POSITIVE: ; C:09B4, 0x0009B4
    STA ARRAY_UNK[32],X ; Clear.
    DEX ; Index--
    BPL INDEX_POSITIVE ; Positive, do all.
XSCROLL_NONZERO: ; C:09BA, 0x0009BA
    JSR GAME_PPU_RTN_A ; Do ??
    JSR GAME_PPU_RTN_B ; Do ??
    LDA PPU_SCROLL_X_COPY ; Load copy.
    BNE XSCROLL_NONZERO ; != 0, goto.
    JSR CLEAR_ALL_OBJECTS_USED ; Do ??
    JSR PTR_AFTER_JSR_TO_NMI_PTR ; Do.
    LOW(NMI_RTN_A) ; NMI.
    HIGH(NMI_RTN_A)
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn. <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    LOW(PROCESS_UNK_A)
    HIGH(PROCESS_UNK_A)
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn. <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    LOW(PROCESS_UNK_B)
    HIGH(PROCESS_UNK_B)
    LDA #$00 ; Val ??
    JSR SOUND_RELATED_INIT? ; Do ??
    RTS ; Leave.
INIT_GAMEPLAY_SCREEN_GRAPHICS/PALETTE: ; C:09DC, 0x0009DC
    JSR CLEAR_SCREEN_0x2000 ; Clear screen.
    LDA #$00
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; Set GFX bank.
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Palette.
    .db 00 ; Type?
    .db 0F ; Length?
    .db 3D ; Data.
    .db 1A
    .db 30
    .db 0F
    .db 3D
    .db 1A
    .db 38
    .db 0F
    .db 3D
    .db 1A
    .db 32
    .db 0F
    .db 3D
    .db 1A
    .db 05
    .db 0F
    .db 00
    .db 16
    .db 30
    .db 0F
    .db 36
    .db 0F
    .db 12
    .db 0F
    .db 00
    .db 38
    .db 22
    .db 0F
    .db 00
    .db 0F
    .db 30
    .db FF ; EOF.
    .db 60 ; Done, leave.
SEED_HIT_DETECT_OBJECT_Y_VS_ALL_OTHER_OBJECTS?: ; C:0A0A, 0x000A0A
    LDA #$04 ; Load test value, objs min.
    CMP OBJECTS_AVAILABLE? ; If _ objs
    BEQ RETURN_FAILURE_NO_HIT ; ==, goto.
    LDY #$18 ; Seed obj start.
Y_POSITIVE_LOOP: ; C:0A12, 0x000A12
    LDA OBJ_FLAG_ACTIVE/USED/STATUS[19],Y ; Load from obj.
    BPL TEST_NEXT_OBJ ; Positive, goto.
    LDA OBJ_ATTR_SCRADDR_H[19],Y ; Load ??
    BEQ TEST_NEXT_OBJ ; == 0, next.
    CPY PLAYER_OBJECT_ID ; If _ player
    BEQ TEST_NEXT_OBJ ; ==, skip.
    LDA OBJ_PTR_UNK_B_L[2],Y ; Load from obj.
    PHA ; Save it.
    CLC ; Prep add.
    ADC #$10 ; += 0x10
    STA OBJ_PTR_UNK_B_L[2],Y ; Store to obj.
    JSR ENGINE_HIT_DETECT_XOBJ_WITH_YOBJ ; Xobj hit detect with value.
    PLA ; Pull previous.
    STA OBJ_PTR_UNK_B_L[2],Y ; Store to.
    BCC TEST_NEXT_OBJ ; Ret CC, goto. No hit.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load Xobj.
    SEC ; Prep sub.
    SBC OBJ_PTR_UNK_B_L[2],Y ; Sub with Y obj.
    BCC TEST_NEXT_OBJ ; <, goto.
    CLC ; Prep add.
    ADC #$04 ; += 0x4
    STA OBJ_ATTR_TIMER[19],Y ; Store to, timer.
    INC OBJECTS_AVAILABLE? ; More objs now becauase this is gone.
    LDA #$B2
    STA OBJ_PROCESS_HANDLER_L[19],Y ; Move PTR 1AB2
    LDA #$9A
    STA OBJ_PROCESS_HANDLER_H[19],Y
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process sound.
    LOW(SOUND_NOISE_SFX_IDK_WHICH)
    HIGH(SOUND_NOISE_SFX_IDK_WHICH)
    .db 38 ; Ret CS, hit and done.
    .db 60 ; Leave.
TEST_NEXT_OBJ: ; C:0A54, 0x000A54
    .db 88 ; Obj--
    BPL Y_POSITIVE_LOOP ; Positive, keep testing.
RETURN_FAILURE_NO_HIT: ; C:0A57, 0x000A57
    CLC ; Seed no objs hit.
    RTS ; Leave.
OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER?: ; C:0A59, 0x000A59
    JSR SEED_HIT_DETECT_OBJECT_Y_VS_ALL_OTHER_OBJECTS? ; Detect.
    BCC NO_HIT ; None, leave.
    .db 68 ; Pull 4x. TODO: What addrs.
    .db 68
    .db 68
    .db 68
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend here.
    JSR SUB_HELPER_DESTROY_AND_FORWARD ; Do sub.
NO_HIT: ; C:0A68, 0x000A68
    RTS ; Leave.
SUB_HELPER_DESTROY_AND_FORWARD: ; C:0A69, 0x000A69
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    RTS ; Leave.
HELPER_HIT_DETECT_XOBJ_TO_PLAYER: ; C:0A70, 0x000A70
    LDY PLAYER_OBJECT_ID ; Load player object ID.
    JSR ENGINE_HIT_DETECT_XOBJ_WITH_YOBJ ; Test object to player.
    RTS ; Leave.
TEST_PLAYER_CRASH_VS_OBJECT_X_PASSED_RET_CC_NO_HIT: ; C:0A76, 0x000A76
    JSR HELPER_HIT_DETECT_XOBJ_TO_PLAYER ; Do sub.
    BCC NO_HIT ; No hit, goto.
    JSR PLAYER_CRASH_RTN
    SEC ; Ret hit.
NO_HIT: ; C:0A7F, 0x000A7F
    RTS ; Leave return CC of hit.
OBJ_HELP_HIT_DETECT_VS_PLAYER: ; C:0A80, 0x000A80
    JSR TEST_PLAYER_CRASH_VS_OBJECT_X_PASSED_RET_CC_NO_HIT ; Test hit.
    BCC NO_CRASH ; Ret CC.
    PLA ; Pull stack TODO what.
    PLA
    JMP ENGINE_HELPER_PULL_ADD'L_AND_SUSPEND ; Pull and sussy.
NO_CRASH: ; C:0A8A, 0x000A8A
    RTS ; Leave.
SCRIPT_TO_HARDWARE_COPY/??_AND_DESTROY_OBJ: ; C:0A8B, 0x000A8B
    LDA #$00
    STA GAME_VAR_FORWARD_CONTROL_HMM ; Clear.
    JSR PTR_AFTER_JSR_TO_NMI_PTR ; No NMI rtn.
    .db 00 ; NULL.
    .db 00
    LDA SCRIPT_X_SCROLL ; Move scroll X.
    STA PPU_SCROLL_X_COPY
    LDA SCRIPT_Y_SCROLL ; Move scroll Y.
    STA PPU_SCROLL_Y_COPY
    LDA SCRIPT_PPU_CTRL ; Move CTRL.
    STA PPU_CTRL_COPY
    LDX PLAYER_OBJECT_ID ; Load.
    JSR OBJECT_X_ID_DESTROY ; Destroy this object.
    LDX CURRENT_OBJ_PROCESSING ; Load other.
    RTS ; Leave.
PLAYER_CRASH_RTN: ; C:0AA8, 0x000AA8
    JSR SCRIPT_TO_HARDWARE_COPY/??_AND_DESTROY_OBJ ; Do ??
    JSR CREATE_PROCESS_WITH_PTR_PAST
    LOW(PLAYER_CRASHED)
    HIGH(PLAYER_CRASHED)
    .db 60 ; Leave.
PLAYER_CRASHED: ; C:0AB1, 0x000AB1
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data to.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    LDA #$DB ; Seed ??
    JSR SET_OBJECT_PTR_L_A_H_0x00 ; Do.
    LDA #$01 ; Seed DMC song. Crash.
    JSR ENGINE_SOUND_DMC_PLAY ; Do ??
    LDA #$F0 ; Seed suspend time.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend timer.
    JSR CLEAR_ALL_OBJECTS_USED ; Clean up objs.
    LDA GAME_CURRENT_PLAYER
    BPL PLAYER_DIED_IN_GAME_NOT_DEMO ; Positive, goto.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Back to the menu.
    LOW(DEMO_REENTER_MAIN_MENU)
    HIGH(DEMO_REENTER_MAIN_MENU)
    .db 60 ; Leave.
PLAYER_DIED_IN_GAME_NOT_DEMO: ; C:0AD2, 0x000AD2
    LDA GAME_INDEX_HOUSE_ID_UPLOADING ; Load ??
    CMP #$18 ; If _ #$18
    BCC ALL_HOUSES_NOT_PASSED ; <, goto.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create post-level report.
    LOW(LEVEL_FINISHED_REPORT_ROUTINE)
    HIGH(LEVEL_FINISHED_REPORT_ROUTINE)
    .db 60 ; Leave.
ALL_HOUSES_NOT_PASSED: ; C:0ADE, 0x000ADE
    DEC CURRENT_PLAYER_LIVES ; Lives--
    LDA CURRENT_PLAYER_LIVES ; Load val.
    BNE STILL_HAS_LIVES ; != 0, goto.
    JSR CREATE_PROCESS_WITH_PTR_PAST
    LOW(PAPERBOY_QUITS) ; Quit.
    HIGH(PAPERBOY_QUITS)
    .db 60 ; Leave.
STILL_HAS_LIVES: ; C:0AEA, 0x000AEA
    LDA PLAYER_LIVES_OTHER_PLAYER ; Load flag.
    BEQ TWO_PLAYER_GAME ; == 0, goto.
    JMP PLAYER_DIED_DURING_LEVEL ; Goto ??
TWO_PLAYER_GAME: ; C:0AF2, 0x000AF2
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process.
    LOW(GAME_PLAYER_START_WITH_TEXT_RTN) ; Do ??
    HIGH(GAME_PLAYER_START_WITH_TEXT_RTN)
    .db 60 ; Leave.
PROCESS_IN-GAME_COMPLETED: ; C:0AF8, 0x000AF8
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Put to obj.
    LOW(OBJ_FILE_UNK)
    HIGH(OBJ_FILE_UNK)
    LDA #$03 ; Seed sound.
    JSR SOUND_OVERRIDE_HELPER
    LDY INDEX_UNK_B ; Index.
    LDA ROM_DATA_UNK_A,Y ; Load ??
    LDY INDEX_UNK_A ; Reindex.
    CLC ; Prep add.
    ADC ROM_DATA_UNK_B,Y ; Add with other.
    LDY #$00 ; Index ??
    BCC ADD_NO_OVERFLOW ; No overflow, goto.
    INY ; Alt val.
ADD_NO_OVERFLOW: ; C:0B14, 0x000B14
    JSR ACCUMULATE_SEEDED_AL_YH ; Add 16-bit.
    LDA #$FF ; Suspend time.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend helper.
    LDA #$FF ; Moar time.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend.
    JSR CLEAR_ALL_OBJECTS_USED ; Clear all used.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process past.
    LOW(LEVEL_FINISHED_REPORT_ROUTINE)
    HIGH(LEVEL_FINISHED_REPORT_ROUTINE)
    .db 60 ; Leave.
ROM_DATA_UNK_A: ; C:0B2A, 0x000B2A
    .db 00
    .db 00
    .db 0A
    .db 14
    .db 1E
    .db 28
    .db 32
    .db 3C
    .db 46
    .db 50
    .db 5A
ROM_DATA_UNK_B: ; C:0B35, 0x000B35
    .db 00
    .db 00
    .db 64
    .db C8
    .db C8
    .db C8
    .db C8
    .db C8
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data to obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Set timer.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Set timer more/again.
    JSR CLEAR_ALL_OBJECTS_USED ; Clear all.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Make post-report.
    LOW(LEVEL_FINISHED_REPORT_ROUTINE)
    HIGH(LEVEL_FINISHED_REPORT_ROUTINE)
    .db 60
LEVEL_FINISHED_REPORT_ROUTINE: ; C:0B55, 0x000B55
    JSR SETUP_CUSTOMERS_SCREEN ; Setup.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Setup packet.
    .db 02
    .db 02
    .db 44
    .db 41
    .db 49
    .db 4C
    .db 59
    .db 20
    .db 52
    .db 45
    .db 50
    .db 4F
    .db 52
    .db 54
    .db 3A
    .db 00
    JSR GAME_PLAYER_DAY_OF_THE_WEEK ; Put day of the week.
    LDA FLAG_MULTIPLAYER_GAME ; Load flag.
    BEQ SKIP_MULTIPLAYER_DISPLAY ; Nope, goto.
    LDA GAME_CURRENT_PLAYER
    BNE SHOW_PLAYER_2 ; 0x1, show player 2.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show player.
    .db 02
    .db 04
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 31
    .db 00
    JMP SKIP_MULTIPLAYER_DISPLAY ; Reenter.
SHOW_PLAYER_2: ; C:0B87, 0x000B87
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show on screen.
    .db 02
    .db 04
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 32
    .db 00
SKIP_MULTIPLAYER_DISPLAY: ; C:0B95, 0x000B95
    JSR PPU_HELPER_ENABLE_RENDERING ; Show screen.
    JSR HOUSES_ROUTINE_SEED_UNK_CUSTOMER ; Seed.
    LDA #$F0
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Time suspend.
    LDA #$78
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Time suspend again.
    LDA #$00
    STA FILE_STREAM_UNK[2] ; Clear ptr, used as cust/non-cust count.
    STA FILE_STREAM_UNK+1
    LDY #$15 ; Object max.
OBJECT_POSITIVE_LOOP: ; C:0BAD, 0x000BAD
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load.
    CMP #$01 ; If _ #$01
    BNE VAL_NE_0x1 ; !=, goto.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load from obj.
    CMP #$01 ; If _ #$01
    BEQ OBJECT_IS_NOT_CUSTOMER ; ==, goto.
    LDA #$02
    STA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Set ??
    LDA #$FF
    STA OBJ_ATTR_DEEP_UNK[19],Y ; Set ??
    LDA #$80
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Set ??
    INC FILE_STREAM_UNK+1 ; Inc customer count.
    BNE VAL_NE_0x1 ; Always taken, always nonzero.
OBJECT_IS_NOT_CUSTOMER: ; C:0BCE, 0x000BCE
    INC FILE_STREAM_UNK[2] ; ++ ??
VAL_NE_0x1: ; C:0BD0, 0x000BD0
    DEY ; Obj---
    BPL OBJECT_POSITIVE_LOOP ; Positive, goto.
    LDA FILE_STREAM_UNK+1 ; Load cancelled.
    BEQ SHOW_PERFECT_DELIVERY ; == 0, goto.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show cancelled.
    .db 09
    .db 1B
    .db 43
    .db 41
    .db 4E
    .db 43
    .db 45
    .db 4C
    .db 4C
    .db 45
    .db 44
    .db 20
    .db 53
    .db 55
    .db 42
    .db 53
    .db 43
    .db 52
    .db 49
    .db 50
    .db 54
    .db 49
    .db 4F
    .db 4E
    .db 53
    .db 00
    JMP POST_CANCELATIONS ; Goto.
SHOW_PERFECT_DELIVERY: ; C:0BF7, 0x000BF7
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show the message.
    .db 0A
    .db 1B
    .db 50
    .db 45
    .db 52
    .db 46
    .db 45
    .db 43
    .db 54
    .db 20
    .db 44
    .db 45
    .db 4C
    .db 49
    .db 56
    .db 45
    .db 52
    .db 59
    .db 21
    .db 21
    .db 00
ATTRIBUTE_SUBSCRIBED_ALREADY: ; C:0C0F, 0x000C0F
    LDA #$16 ; Seed ??
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do ??
    TAY ; To Y index.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load ??
    CMP #$02 ; If _ #$02, not subscribed.
    BNE ATTRIBUTE_SUBSCRIBED_ALREADY ; != 0, rerun.
    LDA #$01
    STA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Mod status to subscribed.
    LDA OBJ_ATTR_UNK_649[19],Y ; Move ??
    STA OBJ_ATTR_DEEP_UNK[19],Y
    LDA #$80 ; Move attr ??
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show a resubscriber.
    .db 0C
    .db 19
    .db 41
    .db 20
    .db 52
    .db 45
    .db 53
    .db 55
    .db 42
    .db 53
    .db 43
    .db 52
    .db 49
    .db 42
    .db 45
    .db 52
    .db 21
    .db 00
POST_CANCELATIONS: ; C:0C41, 0x000C41
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend time.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Moar time.
    JSR CLEAR_ALL_OBJECTS_USED ; Clear all objs.
    LDA FILE_STREAM_UNK[2] ; Load count.
    BEQ PAPERBOY_QUITS ; == 0, leave, no more customers.
    INC CURRENT_PLAYER_DAY_OF_THE_WEEK ; Dawn of the next day.
    LDA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Load.
    CMP #$07 ; If _ #$07
    BEQ PAPERBOY_WINS ; ==, wins.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process.
    LOW(RTN_GAME_START_DAY_OF_THE_WEEK) ; Back into the game.
    HIGH(RTN_GAME_START_DAY_OF_THE_WEEK)
    RTS
PAPERBOY_QUITS: ; C:0C60, 0x000C60
    JSR CREATE_PROCESS_WITH_PTR_PAST
    LOW(PAPERBOY_QUITS) ; Quit code.
    HIGH(PAPERBOY_QUITS)
    RTS
PAPERBOY_WINS: ; C:0C66, 0x000C66
    JSR CREATE_PROCESS_WITH_PTR_PAST
    LOW(PAPERBOY_WINS) ; Wins code.
    HIGH(PAPERBOY_WINS)
    .db 60
PAPERBOY_QUITS: ; C:0C6C, 0x000C6C
    JSR NEWSPAPER_SCREEN_HELPER ; Titlescreen.
    LDA FLAG_MULTIPLAYER_GAME ; Load flag.
    BNE SHOW_PLAYER_LOST_MULTIPLAYER ; Set, goto, multiplayer.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show player lost.
    .db 04
    .db 08
    .db 50
    .db 41
    .db 50
    .db 45
    .db 52
    .db 42
    .db 4F
    .db 59
    .db 20
    .db 43
    .db 41
    .db 4C
    .db 4C
    .db 53
    .db 20
    .db 49
    .db 54
    .db 20
    .db 51
    .db 55
    .db 49
    .db 54
    .db 53
    .db 21
    .db 00
    JMP REENTER_GAME_OVER_MESSAGE_DISPLAY
SHOW_PLAYER_LOST_MULTIPLAYER: ; C:0C94, 0x000C94
    LDA GAME_CURRENT_PLAYER ; Load current player.
    BNE PLAYER_2_CALLS_QUITS ; Nonzero, was player 2.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Show P1 lost.
    .db 04
    .db 08
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 31
    .db 20
    .db 43
    .db 41
    .db 4C
    .db 4C
    .db 53
    .db 20
    .db 49
    .db 54
    .db 20
    .db 51
    .db 55
    .db 49
    .db 54
    .db 53
    .db 21
    .db 00
    JMP REENTER_GAME_OVER_MESSAGE_DISPLAY
PLAYER_2_CALLS_QUITS: ; C:0CB9, 0x000CB9
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; P2 "quit."
    .db 04
    .db 08
    .db 50
    .db 4C
    .db 41
    .db 59
    .db 45
    .db 52
    .db 20
    .db 32
    .db 20
    .db 43
    .db 41
    .db 4C
    .db 4C
    .db 53
    .db 20
    .db 49
    .db 54
    .db 20
    .db 51
    .db 55
    .db 49
    .db 54
    .db 53
    .db 21
    .db 00
    JMP REENTER_GAME_OVER_MESSAGE_DISPLAY ; Reenter.
PAPERBOY_WINS: ; C:0CDA, 0x000CDA
    JSR NEWSPAPER_SCREEN_HELPER ; Show HE'S DUNNIT.
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Display.
    .db 03
    .db 08
    .db 50
    .db 41
    .db 50
    .db 45
    .db 52
    .db 42
    .db 4F
    .db 59
    .db 20
    .db 52
    .db 45
    .db 54
    .db 49
    .db 52
    .db 45
    .db 53
    .db 20
    .db 49
    .db 4E
    .db 20
    .db 47
    .db 4C
    .db 4F
    .db 52
    .db 59
    .db 21
    .db 00
REENTER_GAME_OVER_MESSAGE_DISPLAY: ; C:0CFD, 0x000CFD
    JSR PPU_HELPER_ENABLE_RENDERING ; Show it.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspent time.
DEMO_REENTER_MAIN_MENU: ; C:0D05, 0x000D05
    JSR CLEAR_SCREEN_0x2000 ; Clear screen.
    LDA #$00
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; Switch GFX.
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Do palette.
    .db 00
    .db 12
    .db 3D
    .db 1A
    .db 30
    .db FF
    JSR SCREEN_UPDATE_AFTER_JSR_CODE_TO_SCREEN ; Do screen for initials.
    .db 0B
    .db 03
    .db 54
    .db 48
    .db 45
    .db 20
    .db 54
    .db 4F
    .db 50
    .db 20
    .db 54
    .db 45
    .db 4E
    .db 00
    JSR TOP_TEN_DISPLAY? ; Do.
    JSR TOP_TEN_B ; Do.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR PPU_HELPER_ENABLE_RENDERING ; Enable rendering.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    LDA LARGER_ARR+28 ; Load ??
    CMP #$50 ; If _ #$50
    BEQ VAL_EQ_0x50 ; ==, goto.
    LDX CURRENT_OBJ_PROCESSING ; Load current.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data ptr ??
    LOW(DATA_ARR_UNK) ; Load.
    HIGH(DATA_ARR_UNK)
    LDA LARGER_ARR+28 ; Load ??
    LSR A ; >> 2, /4.
    LSR A
    CLC ; Prep add.
    ADC #$06 ; Add with.
    TAY ; To Y ??
    STY **:$00A9 ; Store to.
    ASL A ; << 3, *8.
    ASL A
    ASL A
    CLC ; Prep add.
    ADC #$0A ; Add with.
    JSR SET_OBJECT_PTR_L_A_H_0x00 ; Forward.
    LDA #$15
    STA STREAM_HELPER ; Set ??
    ASL A ; << 3, *8.
    ASL A
    ASL A
    JSR CLEAR/SET_ARRAYS_A ; Set arrays.
    LDA LARGER_ARR+28 ; Load ??
    CLC ; Prep add.
    ADC #$05 ; Add with.
    STA FILE_STREAM_UNK+1 ; Store to.
WAIT_ENTER_INITIALS: ; C:0D6A, 0x000D6A
    LDA #$06 ; Val ??
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Set timer and active.
    JSR ENTER_INITIALS_HELPER_INPUT?
    CMP #$00 ; If _ #$00
    BEQ WAIT_ENTER_INITIALS ; ==, goto.
    JMP INITIALS_ENTERED ; Goto.
VAL_EQ_0x50: ; C:0D79, 0x000D79
    LDA GAME_CURRENT_PLAYER ; Load.
    BMI CURRENT_IS_ATTRACT ; Attract, goto.
    LDA #$FF
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend on screen.
    JMP INITIALS_ENTERED ; Goto.
CURRENT_IS_ATTRACT: ; C:0D85, 0x000D85
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR CTRL_TEST_SELECT/START_BOTH_CONTROLLERS ; Test.
    BNE CTRLS_SEL/START_PRESSED ; Set, goto, was pressed.
    LDA OBJ_ATTR_TIMER[19],X ; Load ??
    BEQ INITIALS_ENTERED ; == 0, expired, goto.
    RTS ; Leave.
CTRLS_SEL/START_PRESSED: ; C:0D98, 0x000D98
    JSR CLEAR_ALL_OBJECTS_USED ; Destroy objects.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process.
    LOW(SETUP_SELECT_PLAYERS_SCREEN)
    HIGH(SETUP_SELECT_PLAYERS_SCREEN)
    .db 60 ; Leave.
INITIALS_ENTERED: ; C:0DA1, 0x000DA1
    JSR CLEAR_ALL_OBJECTS_USED ; Clean up.
    LDA #$00
    STA CURRENT_PLAYER_LIVES ; Clear ??
    LDA PLAYER_LIVES_OTHER_PLAYER ; Load ??
    BEQ CREATE_PROCESS_UNK ; ==, goto.
    JMP PLAYER_DIED_DURING_LEVEL ; Goto otherwise.
CREATE_PROCESS_UNK: ; C:0DB0, 0x000DB0
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process ??
    LOW(REENTER_GAME_MENUS_WITHOUT_INTIAL_INIT) ; Re-enter.
    HIGH(REENTER_GAME_MENUS_WITHOUT_INTIAL_INIT)
    .db 60 ; Leave.
NMI_RTN_A: ; C:0DB6, 0x000DB6
    LDA PPU_UPDATE_ADDR_A+1 ; Load H addr.
    BEQ GET_TILE_UNDER_IN_OBJ_AND_ENABLE_RENDERING ; == 0, goto.
    JSR GAME_PPU_RTN_A ; Do if updated.
    JMP ENABLE_RENDERING ; Goto.
GET_TILE_UNDER_IN_OBJ_AND_ENABLE_RENDERING: ; C:0DC0, 0x000DC0
    JSR ENGINE_GET_SCREEN_GFX_UNDER_TILES ; Get tile under.
ENABLE_RENDERING: ; C:0DC3, 0x000DC3
    LDA #$18
    STA PPU_MASK_COPY ; Enable rendering.
    RTS ; Leave.
GAME_PPU_RTN_A: ; C:0DC8, 0x000DC8
    LDA PPU_UPDATE_ADDR_A+1 ; Load H.
    BEQ RTS ; == 0, leave.
    STA PPU_ADDR ; Store as addr.
    LDA PPU_UPDATE_ADDR_A[2] ; Load L.
    STA PPU_ADDR ; Set addr.
    LDX #$00 ; Index.
LOOP_BUFFER: ; C:0DD6, 0x000DD6
    LDA UPDATE_BUF_A[62],X ; Load from buf.
    STA PPU_DATA ; Store to PPU.
    INX ; Index++
    CPX #$20 ; If _ #$20
    BCC LOOP_BUFFER ; <, goto.
    LDA UPDATE_BUF_A_ADDL+1 ; Move other addr.
    STA PPU_ADDR
    LDA UPDATE_BUF_A_ADDL[2]
    STA PPU_ADDR
    LDA UPDATE_BUF_A_ADDL_DATA ; Load.
    LDY #$08 ; Count.
LOOP_OTHER_DATA: ; C:0DEF, 0x000DEF
    STA PPU_DATA ; Store data.
    DEY ; Y--
    BNE LOOP_OTHER_DATA ; != 0, loop.
    LDA #$94
    STA PPU_CTRL ; Set NMI, cfg.
    LDA GAME_NAMETABLE_BASE_ADDR?+1 ; Scrolly shit here.
    STA PPU_ADDR ; Store as addr.
    AND #$FC ; Keep 1111.1100
    STA GAME_NAMETABLE_BASE_ADDR?+1 ; Store to.
    LDA GAME_NAMETABLE_BASE_ADDR?[2] ; Load.
    STA PPU_ADDR ; Store as addr.
    AND #$1F ; Keep 0001.1111
    STA GAME_NAMETABLE_BASE_ADDR?[2] ; Store back.
    LDA PPU_SCROLL_Y_COPY ; Load Y scroll.
    LSR A ; >> 3, /8. To tile row.
    LSR A
    LSR A
    TAY ; To Y.
INDEX_LT_0x3E: ; C:0E12, 0x000E12
    INY ; ++
    CPY #$1E ; If _ #$1E
    BCC SKIP_BASE_SWAP ; <, goto.
    LDA GAME_NAMETABLE_BASE_ADDR?+1 ; Invert.
    EOR #$08 ; Invert base Y addr.
    STA GAME_NAMETABLE_BASE_ADDR?+1
    STA PPU_ADDR ; To ADDR.
    LDA GAME_NAMETABLE_BASE_ADDR?[2] ; Load other.
    STA PPU_ADDR ; Store as addr.
    LDY #$FF ; Seed ??
SKIP_BASE_SWAP: ; C:0E27, 0x000E27
    LDA UPDATE_BUF_A[62],X ; Load from buf.
    STA PPU_DATA ; Store to PPU data.
    INX ; Index++
    CPX #$3E ; If _ #$3E
    BCC INDEX_LT_0x3E ; <, goto.
    LDA #$90
    STA PPU_CTRL ; Set CTRL.
    LDA #$00
    STA PPU_UPDATE_ADDR_A+1 ; Clear addr update buf.
RTS: ; C:0E3B, 0x000E3B
    RTS ; Leave.
SHOW_NEW_TILES?: ; C:0E3C, 0x000E3C
    INC HOUSE_FILE_STREAM_POS ; ++ ??
    DEC HOUSE_FILE_STREAM_DATA_LOADED ; -- ??
    BNE SKIP_UNK ; != 0, goto.
    LDX GAME_INDEX_HOUSE_ID_UPLOADING ; Load.
    INX ; Index++
    CPX #$22 ; If _ #$22
    BCC LT_0x22 ; <, goto.
    JSR SCRIPT_TO_HARDWARE_COPY/??_AND_DESTROY_OBJ ; Do.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn.
    LOW(PROCESS_IN-GAME_COMPLETED)
    HIGH(PROCESS_IN-GAME_COMPLETED)
    RTS ; Leave.
LT_0x22: ; C:0E52, 0x000E52
    STX GAME_INDEX_HOUSE_ID_UPLOADING ; Store inc'd.
    LDA HOUSE_ID_ATTRS_A,X ; Move indexes to words.
    STA FILE_STREAM_UNK[2]
    LDA HOUSE_ID_ATTRS_B,X
    STA FILE_STREAM_UNK+1
    LDY #$00 ; Stream reset.
    STY HOUSE_FILE_STREAM_POS ; Clear.
    LDA [FILE_STREAM_UNK[2]],Y ; Load from ptr.
    STA HOUSE_FILE_STREAM_DATA_LOADED ; Stream data to.
    INC FILE_STREAM_UNK[2] ; ++
    BNE NO_HMOD
    INC FILE_STREAM_UNK+1 ; Inc H.
NO_HMOD: ; C:0E6C, 0x000E6C
    LDA ARRAY_UNK[32] ; Load arr.
    BEQ SKIP_UNK ; == 0, goto.
    JSR HOUSE_DATA_SUB_UNK ; Do.
SKIP_UNK: ; C:0E74, 0x000E74
    LDA #$00
    STA HOUSE_OBJ_INDEX_CURRENT ; Reset.
    LDX GAME_INDEX_HOUSE_ID_UPLOADING ; Load ID.
    DEX ; X--
    BMI HOUSE_IS_NEGATIVE ; Negative, goto.
    LDA **:$06AF,X ; Load ??
    BEQ HOUSE_IS_NEGATIVE ; == 0, goto.
    STX HOUSE_OBJ_INDEX_CURRENT ; Store nonzero.
HOUSE_IS_NEGATIVE: ; C:0E84, 0x000E84
    LDA #$20
    STA STREAM_COUNT_TODO[2] ; Set 0x2000
    LDA #$00
    STA STREAM_COUNT_TODO+1
    LDA FILE_STREAM_UNK[2] ; Move ??
    STA STREAM_INPUT[2]
    LDA FILE_STREAM_UNK+1
    STA STREAM_INPUT+1
    LDA #$55 ; Move ??
    STA STREAM_BUFFER_ADDR[2]
    LDA #$05 ; Move ??
    STA STREAM_BUFFER_ADDR+1
    JSR STREAM_PROCESS_FILES ; House to screen?
    LDA PPU_CTRL_COPY ; Load copy.
    ASL A ; << 1, *2.
    ORA #$08 ; Set ??
    STA PPU_UPDATE_ADDR_A+1 ; Store as addr.
    LDA PPU_SCROLL_Y_COPY ; Load Y.
    AND #$F8 ; Keep 1111.1000
    ASL A ; << 1
    ROL PPU_UPDATE_ADDR_A+1 ; Rotate into.
    ASL A
    ROL PPU_UPDATE_ADDR_A+1 ; 2x
    STA PPU_UPDATE_ADDR_A[2] ; Store back.
    LDA PPU_SCROLL_X_COPY ; Load X scroll.
    CLC ; Prep add.
    ADC #$08 ; Add with.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    TAX ; To X index.
    LDY #$00 ; Array index seed.
VAL_LT_0x20: ; C:0EBD, 0x000EBD
    LDA UPDATE_BUF_A+32,Y ; Load from upper.
    STA UPDATE_BUF_A[62],X ; Store to lower.
    INX ; Index++
    TXA ; X to A.
    AND #$1F ; Keep lower.
    TAX ; Back to X.
    INY ; Data++
    CPY #$20 ; If _ #$20
    BCC VAL_LT_0x20 ; <, loop.
    LDA PPU_UPDATE_ADDR_A+1 ; Load.
    ORA #$03 ; Set ??
    STA UPDATE_BUF_A_ADDL+1 ; Store back.
    LDA PPU_SCROLL_Y_COPY ; Load Y copy.
    LSR A ; >> 2, /4.
    LSR A
    AND #$38 ; Keep ??
    ORA #$C0 ; Set 1100.0000
    STA UPDATE_BUF_A_ADDL[2] ; Store to.
    LDY #$0F ; Seed ??
    LDA #$10 ; Seed test.
    BIT PPU_SCROLL_Y_COPY ; Test vs.
    BNE Y_SCROLL_SET ; !=, goto.
    LDY #$F0 ; Seed alt.
Y_SCROLL_SET: ; C:0EE7, 0x000EE7
    TYA ; Y to A.
    AND UPDATE_BUF_A_ADDL_DATA ; Keep.
    STA UPDATE_BUF_A_ADDL_DATA ; Store ??
    TYA ; Y to A.
    EOR #$FF ; Invert.
    LDY GAME_INDEX_HOUSE_ID_UPLOADING ; Load ID.
    AND OBJ_ATTR_DEEP_UNK[19],Y ; Keep.
    ORA UPDATE_BUF_A_ADDL_DATA ; Set with.
    STA UPDATE_BUF_A_ADDL_DATA ; Store to.
    LDA PPU_SCROLL_X_COPY ; Load.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    CLC ; Prep add.
    ADC PPU_UPDATE_ADDR_A[2] ; Add with.
    ADC #$20 ; Add with screen base.
    STA GAME_NAMETABLE_BASE_ADDR?[2] ; Store to, addr H.
    LDA PPU_UPDATE_ADDR_A+1 ; Load ??
    ADC #$00 ; Carry add.
    STA GAME_NAMETABLE_BASE_ADDR?+1 ; Store to, addr L.
    LDA **:$00C6 ; Load ??
    SEC ; Prep sub.
    SBC #$01 ; Sub with.
    AND #$1F ; Keep lower.
    STA **:$00C6 ; Store to.
    TAX ; To X index.
    LDA STREAM_INPUT[2] ; Move ??
    STA **:$06D1,X
    LDA STREAM_INPUT+1 ; Move ??
    STA ARRAY_UNK[32],X
    LDA STREAM_DATA_TYPE/COUNT ; Move ??
    STA **:$0711,X
    LDA #$1E ; Move ??
    STA STREAM_COUNT_TODO[2]
    LDA #$00 ; Move ??
    STA STREAM_COUNT_TODO+1
    LDA #$55 ; Move ??
    STA STREAM_BUFFER_ADDR[2]
    LDA #$05 ; Move ??
    STA STREAM_BUFFER_ADDR+1
    JSR MOVE_TYPE_TEST ; Do move.
    LDA STREAM_INPUT[2] ; Move ??
    STA FILE_STREAM_UNK[2]
    LDA STREAM_INPUT+1 ; Move ??
    STA FILE_STREAM_UNK+1
    LDA #$55 ; Move ??
    STA STREAM_BUFFER_ADDR[2]
    LDA #$05 ; Move ??
    STA STREAM_BUFFER_ADDR+1
    LDY #$1E ; Load ??
LOOP_Y_NONZERO: ; C:0F48, 0x000F48
    TXA ; X to A.
    CLC ; Prep add.
    ADC #$01 ; Add with.
    AND #$1F ; Keep lower.
    TAX ; To X index.
    LDA ARRAY_UNK[32],X ; Load ??
    BEQ NEXT_Y_LOOP ; ==, goto.
    STA STREAM_INPUT+1 ; Store nonzero.
    LDA **:$06D1,X ; Move ??
    STA STREAM_INPUT[2]
    LDA **:$0711,X ; Move ??
    STA STREAM_DATA_TYPE/COUNT
    LDA #$01 ; Move ??
    STA STREAM_COUNT_TODO[2]
    LDA #$00 ; Move ??
    STA STREAM_COUNT_TODO+1
    TXA ; Save X/Y.
    PHA
    TYA
    PHA
    JSR MOVE_TYPE_TEST ; Do move.
    PLA ; Restore X/Y.
    TAY
    PLA
    TAX
    LDA STREAM_INPUT[2] ; Move ??
    STA **:$06D1,X
    LDA STREAM_INPUT+1 ; Move ??
    STA ARRAY_UNK[32],X
    LDA STREAM_DATA_TYPE/COUNT ; Move ??
    STA **:$0711,X
NEXT_Y_LOOP: ; C:0F82, 0x000F82
    DEY ; Y--
    BNE LOOP_Y_NONZERO ; != 0, ,goto.
    RTS ; Leave.
PLAYER_CONTROLLER_UP_DOWN_HELPER: ; C:0F86, 0x000F86
    JSR SCRIPT_CONTROLLER_INPUT_RTN ; Do CTRL.
    LDA #$08 ; Test up.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test newly pressed.
    BEQ UP_NOT_NEWLY_PRESSED ; Not set, goto.
    LDA **:$00BA ; Load ??
    CLC ; Prep add.
    ADC #$02 ; Add with.
    BCS EXIT_UNK ; Overflow, goto.
    STA **:$00BA ; Store otherwise.
    BCC EXIT_UNK ; Always taken.
UP_NOT_NEWLY_PRESSED: ; C:0F9A, 0x000F9A
    LDA #$04 ; Button to test.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ DOWN_CLEAR ; Clear, goto.
    LDA APU_STATUS ; Load APU.
    AND #$10 ; Test todo.
    BNE TEST_SET ; Set, goto.
    LDA **:$00BA ; Load ??
    CMP #$40 ; If _ #$40
    BCC TEST_SET ; <, goto.
    LDA #$03 ; Set bike brake sound.
    JSR ENGINE_SOUND_DMC_PLAY ; Set sound play.
    JMP TEST_SET ; Goto.
DOWN_CLEAR: ; C:0FB5, 0x000FB5
    LDA **:$00BA ; Load ??
    CMP #$80 ; If _ #$80
    BCC EXIT_UNK ; <, goto.
TEST_SET: ; C:0FBB, 0x000FBB
    LDA **:$00BA ; Load ??
    SEC ; Prep sub.
    SBC #$02 ; Sub with.
    BCC EXIT_UNK ; Underflow, goto.
    CMP #$3F ; If _ $3F
    BCC EXIT_UNK ; <, goto.
    STA **:$00BA ; Store to.
EXIT_UNK: ; C:0FC8, 0x000FC8
    LDA **:$00BB ; Load.
    SEC ; Add extra.
    ADC **:$00BA ; Add with.
    STA **:$00BB ; Store to.
    LDA #$00 ; Seed clear.
    ROL A ; Rotate carry into.
    STA GAME_VAR_FORWARD_CONTROL_HMM ; Store to.
    BEQ EXIT_RESTORE_XOBJ ; Was clear, goto.
GAME_PPU_RTN_B: ; C:0FD6, 0x000FD6
    LDA PPU_SCROLL_X_COPY ; Move copied to script.
    STA SCRIPT_X_SCROLL
    LDA PPU_SCROLL_Y_COPY
    STA SCRIPT_Y_SCROLL
    LDA PPU_CTRL_COPY
    STA SCRIPT_PPU_CTRL
    INC PPU_SCROLL_X_COPY
    LDA PPU_SCROLL_Y_COPY
    SEC ; Move Y up screen.
    SBC #$01
    BCS NO_UNDERFLOW ; No underflow, still good.
    LDA PPU_CTRL_COPY ; Invert nametable base.
    EOR #$01
    STA PPU_CTRL_COPY
    LDA #$EF ; Re-seed scroll.
NO_UNDERFLOW: ; C:0FF3, 0x000FF3
    STA PPU_SCROLL_Y_COPY ; Store Y back.
    LDA PPU_SCROLL_X_COPY ; Load.
    AND #$07 ; Tile?
    CMP #$01 ; Showing part of a new tile?
    BNE EXIT_RESTORE_XOBJ
    JSR SHOW_NEW_TILES? ; Do.
EXIT_RESTORE_XOBJ: ; C:1000, 0x001000
    LDX CURRENT_OBJ_PROCESSING ; Restore.
    RTS
OBJ_RTN_0x0: ; C:1003, 0x001003
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    JSR TEST_HIT_UNK_TODO ; Do test ??
    BCS EXIT_DESTROY ; Destroy.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BMI RTS ; Negative, leave.
    BNE ATTR_NONZERO ; != 0, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$48 ; If _ #$48
    BCC RTS ; <, goto.
ATTR_NONZERO: ; C:1017, 0x001017
    LDA OBJ_PTR_UNK_A_H[2],X ; Load attr ??
    BMI DONT_PLAY_SOUND ; Negative, goto.
    BNE ATTR_NONZERO_B ; != 0, goto.
    LDA OBJ_SCREEN_POS_X[2],X ; Load ??
    CMP #$02 ; If _ #$02
    BCS DONT_PLAY_SOUND ; >=, goto.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE DONT_PLAY_SOUND ; != 0, goto.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Do sound.
    LOW(RTN_SOUND_UNK)
    HIGH(RTN_SOUND_UNK)
DONT_PLAY_SOUND: ; C:102C, 0x00102C
    LDA #$04 ; Forward amt.
    JSR ADVANCE_PTR_A_BY_A ; Do forward.
    JSR TEST_PLAYER_CRASH_VS_OBJECT_X_PASSED_RET_CC_NO_HIT ; Do test vs player.
    BCC RTS ; No hit, goto.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend here.
RTS: ; C:1039, 0x001039
    RTS ; Leave.
EXIT_DESTROY: ; C:103A, 0x00103A
    JSR OBJECT_X_ID_DESTROY ; Destroy the object.
    RTS ; Leave.
ATTR_NONZERO_B: ; C:103E, 0x00103E
    JSR COUNTER_DOWN_RET_VAL_UNK ; Do for value.
    AND #$E0 ; Keep upper.
    TAY ; To Y.
    LDA #$FF ; Seed ??
    JSR OUTPUT_PTR_A_RESULT ; Write to obj ??
    RTS ; Leave.
OBJ_RTN_0x1: ; C:104A, 0x00104A
    LDA #$1E ; Timer set.
    STA OBJ_ATTR_TIMER[19],X
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data ??
    LOW(SPRITE_DATA_FILE_B)
    HIGH(SPRITE_DATA_FILE_B)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE
    JSR SUB_TEST_IF_HITS_OBJS_AND_RET_TIMER
    CMP #$14 ; If _ #$14
    BCS RTS ; >=, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Move data.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_TEST_IF_HITS_OBJS_AND_RET_TIMER ; Do sub ??
    CMP #$0A ; If _ #$0A
    BCS RTS ; >=, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; New data.
    .db 21
    .db B3
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_TEST_IF_HITS_OBJS_AND_RET_TIMER ; Test.
    BEQ OBJ_RTN_0x1 ; ==, goto.
RTS: ; C:107A, 0x00107A
    RTS ; Leave.
SUB_TEST_IF_HITS_OBJS_AND_RET_TIMER: ; C:107B, 0x00107B
    JSR SUB_TEST_HIT_UNK_TODO ; Sub test destroy.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Detect vs player.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Detect vs ??
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward ??
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Return up.
OBJ_RTN_0xF: ; C:108B, 0x00108B
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward vars.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE RTS ; != 0, leave.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$D3 ; If _ #$D3
    BCC RTS ; <, leave.
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
RETURN_EQ_0x00: ; C:109D, 0x00109D
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Put to obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_TEST_OTHER_UNK ; Do sub.
    BNE RTS ; != 0, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data to obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR SUB_TEST_OTHER_UNK ; Test ??
    BEQ RETURN_EQ_0x00 ; ==, reset.
RTS: ; C:10B7, 0x0010B7
    RTS ; Leave.
SUB_TEST_OTHER_UNK: ; C:10B8, 0x0010B8
    JSR SUB_TEST_HIT_UNK_TODO ; Test destroy.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Do detect.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Do detect.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    LDY PLAYER_OBJECT_ID ; Load ID.
    LDA OBJ_SCREEN_POS_X[2],X ; Load obj.
    CMP OBJ_SCREEN_POS_X[2],Y ; Vs player.
    BEQ SKIP_ADVANCE ; Match, goto.
    BCC LT_PLAYER ; <, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Forward.
    JSR SET_OBJ_ATTR_0x40_UNK ; Set attr ??
    JMP SKIP_ADVANCE ; Goto.
LT_PLAYER: ; C:10D8, 0x0010D8
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance ??
SKIP_ADVANCE: ; C:10DB, 0x0010DB
    LDA OBJ_ATTR_TIMER[19],X ; Load ??
    BEQ EXIT_FLAG_UNK ; == 0, goto.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    AND #$3F ; Keep lower.
    BNE LOWER_SET ; != 0, goto.
    LDA #$00
    JSR ENGINE_SOUND_DMC_PLAY ; Sound dog barnking.
LOWER_SET: ; C:10EC, 0x0010EC
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$D3 ; If _ #$D3
    BCC LT_0xD3 ; <, goto.
    JSR RETRACT_PTR_B_BY_0x1 ; Do sub ??
    JMP EXIT_FLAG_UNK ; Goto.
LT_0xD3: ; C:10F8, 0x0010F8
    JSR ADVANCE_PTR_B_BY_0x1 ; Do ??
EXIT_FLAG_UNK: ; C:10FB, 0x0010FB
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load.
    AND #$0F ; Keep lower.
    RTS ; Leave.
OBJ_RTN_0x11: ; C:1100, 0x001100
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(SPRITE_DATA_FILE_R)
    HIGH(SPRITE_DATA_FILE_R)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Do.
    BEQ RET_NOT_SET ; Not set, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do.
    LOW(SPRITE_PTR_UNK)
    HIGH(SPRITE_PTR_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Forward and test ??
    BEQ OBJ_RTN_0x11 ; Clear, goto.
RET_NOT_SET: ; C:111A, 0x00111A
    RTS ; Leave.
OBJ_RTN_0x12: ; C:111B, 0x00111B
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data to obj.
    LOW(SPRITE_DATA_FILE_S)
    HIGH(SPRITE_DATA_FILE_S)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Forward.
    BEQ RTS ; Clear, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Forward.
    BEQ OBJ_RTN_0x12
RTS: ; C:1135, 0x001135
    RTS ; Leave.
OBJ_RTN_0x13: ; C:1136, 0x001136
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do to obj.
    LOW(SPRITE_DATA_FILE_T)
    HIGH(SPRITE_DATA_FILE_T)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Forward.
    BEQ RTS ; Clear, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do to obj.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR FORWARD_AND_FLAG_RET_UNK ; Forward.
    BEQ OBJ_RTN_0x13 ; == 0, goto.
RTS: ; C:1150, 0x001150
    RTS
FORWARD_AND_FLAG_RET_UNK: ; C:1151, 0x001151
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$08 ; Keep bit.
    RTS ; Return.
SETUP_CUSTOMERS_SCREEN: ; C:1159, 0x001159
    LDA #$41 ; File, 0x3041
    LDY #$B0
    JSR SETUP_FILE_PROCESS_ENTIRE_SCREEN ; Set up the screen.
    LDA #$00
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; GFX bank.
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Palette.
    .db 00 ; Index, BG.
    .db 1A
    .db 3D
    .db 1A
    .db 30
    .db FF
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Palette.
    .db 10 ; Index, sprites.
    .db 1A
    .db 3D
    .db 22
    .db 30
    .db 1A
    .db 0F
    .db 16
    .db 26
    .db FF
    .db 60 ; Leave.
OBJ_RTN_0x2: ; C:117C, 0x00117C
    LDA #$90
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_DETECT_HELPER_AND_RET_TIMER ; Do sub.
    BEQ FLAG_CLEAR ; == 0, goto.
    LSR A ; Shift it.
    BCS RTS ; CS, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    RTS ; Leave.
FLAG_CLEAR: ; C:1190, 0x001190
    LDA #$90
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR SUB_DETECT_HELPER_AND_RET_TIMER ; Do sub.
    BEQ OBJ_RTN_0x2 ; == 0, reset.
    LSR A ; Shift.
    BCS RTS ; CS, leave, done.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Forward.
RTS: ; C:11A3, 0x0011A3
    RTS ; Leave.
SUB_DETECT_HELPER_AND_RET_TIMER: ; C:11A4, 0x0011A4
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Do vs player.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Leave.
HOUSE_DATA_SUB_UNK: ; C:11B1, 0x0011B1
    LDA GAME_INDEX_HOUSE_ID_UPLOADING ; Load index.
    CMP #$17 ; If _ #$17
    BCC LT_0x17 ; <, goto.
    JMP HANDLE_SPECIAL_END_OF_LEVEL ; Goto.
LT_0x17: ; C:11BA, 0x0011BA
    TAY ; A to Y.
    LDA **:$066B,Y ; Load obj.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA FILE_STREAMS_L_TODO,Y ; Move fptr.
    STA FILE_STREAM_UNK[2]
    LDA FILE_STREAMS_H_TODO,Y
    STA FILE_STREAM_UNK+1
    LDY #$00 ; Stream reset.
    STY STREAM_HELPER ; Store to.
    LDA [FILE_STREAM_UNK[2]],Y ; Move loop count.
    STA TMP_00
    LDY #$01 ; Y=
LOOPS_TODO: ; C:11D4, 0x0011D4
    LDA [FILE_STREAM_UNK[2]],Y ; Load from file.
    TAX ; To X index.
    LDA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Load day of the week.
    CMP DAY_OF_THE_WEEK_ARR_DIFFICULTY?,X ; If _ arr
    BCC VAL_LT_CMP ; <, goto.
    LDX STREAM_HELPER ; Load index.
    TYA ; Y to A.
    STA **:$0745,X ; Store to ??
    INC STREAM_HELPER ; ++
VAL_LT_CMP: ; C:11E6, 0x0011E6
    TYA ; Y to A.
    CLC ; Prep add.
    ADC #$05 ; += 0x5, slot size.
    TAY ; Back to Y index.
    DEC TMP_00 ; --
    BNE LOOPS_TODO ; != 0, loop.
    LDA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Load day.
    CLC ; Prep add.
    ADC #$01 ; Add with.
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do helper.
    CLC ; Prep add.
    ADC #$01 ; Add with.
    CMP STREAM_HELPER ; If _ var
    BCC VAL_LT_CMP ; <, goto.
    LDA STREAM_HELPER ; Load max.
VAL_LT_CMP: ; C:1200, 0x001200
    STA **:$00A9 ; Store to.
RERUN_UNK: ; C:1202, 0x001202
    LDA STREAM_HELPER ; Load ??
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do ??
    PHA ; Save it.
    TAY ; To Y.
    LDA **:$0745,Y ; Load from arr ??
    TAY ; To Y index.
    LDA [FILE_STREAM_UNK[2]],Y ; Load from file.
    TAX ; To X index.
    LDA OBJ_ATTR_731_UNK,X ; Load attr ??
    BEQ ATTR_EQ_0x00 ; ==, goto.
    DEC OBJ_ATTR_731_UNK,X ; --
    PLA ; Pull value to discard.
    JMP RERUN_UNK ; Goto.
ATTR_EQ_0x00: ; C:121C, 0x00121C
    LDA #$04
    STA OBJ_ATTR_731_UNK,X ; Set ??
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER ; Setup obj.
    PLA ; Pull value.
    TAY ; To Y index.
    LDX STREAM_HELPER ; Load ??
    LDA **:$0744,X ; Load from.
    STA **:$0745,Y ; Store to.
    DEC STREAM_HELPER ; --
    DEC **:$00A9 ; --
    BNE RERUN_UNK ; != 0, loop.
    RTS ; Leave.
SUB_DOUBLE_FPTRS_DISPLAY?_HELPER: ; C:1235, 0x001235
    TYA ; Y to A.
    PHA ; Save value.
    LDA [FILE_STREAM_UNK[2]],Y ; Load from stream.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA FPTRS_SPECIAL_RTN_HELPER_L,Y ; Move fptr.
    STA TMP_00
    LDA FPTRS_SPECIAL_RTN_HELPER_M,Y
    STA TMP_01
    TYA ; Y to A.
    PHA ; Save it.
    JSR SUB_HELPER_TODO ; Do sub.
    TAX ; Obj ret to X.
    PLA ; Pull value.
    TAY ; To Y index.
    LDA SPRITE_ANIMATION_FILES_L,Y ; Move other fptr.
    STA TMP_00
    LDA SPRITES_ANIMATION_FILES_H,Y
    STA TMP_01
    JSR OBJECT_MOVE_PTR_AND_SEED_FROM_STREAM_DISPLAY? ; Do. Display?
    PLA ; Pull obj.
    TAY ; Value to Y.
    INY ; Stream++
    LDA [FILE_STREAM_UNK[2]],Y ; Move from stream to obj.
    STA OBJ_SCREEN_POS_X[2],X
    INY
    LDA [FILE_STREAM_UNK[2]],Y ; 2x
    STA OBJ_PTR_UNK_A_H[2],X
    INY
    LDA [FILE_STREAM_UNK[2]],Y ; 3x
    STA OBJ_PTR_UNK_B_L[2],X
    INY
    LDA [FILE_STREAM_UNK[2]],Y ; 4x
    STA OBJ_PTR_UNK_B_H[2],X
    RTS ; Leave.
HANDLE_SPECIAL_END_OF_LEVEL: ; C:1271, 0x001271
    CMP #$18 ; If _ #$18
    BNE HOUSE_ID_NE_0x18 ; !=, goto.
    LDA #$03
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; Switch GFX banks.
    JMP POST_SPECIAL_IDS ; Goto.
HOUSE_ID_NE_0x18: ; C:127D, 0x00127D
    CMP #$19
    BNE POST_SPECIAL_IDS ; !=, goto.
    LDA #$0A
    STA VAL_CMP_UNK ; Set ??
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create 
    LOW(PROCESS_UNK_SPECIAL_END_OF_LEVEL)
    HIGH(PROCESS_UNK_SPECIAL_END_OF_LEVEL)
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Colors from.
    .db 09
    .db 12
    .db 06
    .db 30
    .db 0F
    .db 26
    .db 06
    .db 30
    .db FF
    LDA #$01
    JSR SOUND_OVERRIDE_HELPER ; Override sound.
POST_SPECIAL_IDS: ; C:129B, 0x00129B
    LDY GAME_INDEX_HOUSE_ID_UPLOADING ; Index from.
    LDA **:$066B,Y ; Load data from.
    CMP #$15 ; If _ #$15
    BNE VAL_NE_0x15 ; !=, goto.
    LDA #$15
    STA FILE_STREAM_UNK[2] ; Move file.
    LDA #$93
    STA FILE_STREAM_UNK+1
    LDY #$00 ; Seed ??
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER ; Do ??
    JMP EXIT_RESTORE_XOBJ ; Goto.
VAL_NE_0x15: ; C:12B4, 0x0012B4
    CMP #$18 ; If _ #$18
    BNE VAL_NE_0x18 ; !=, goto.
    LDA #$1A
    STA FILE_STREAM_UNK[2] ; Move file ??
    LDA #$93
    STA FILE_STREAM_UNK+1
    LDY #$00 ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDY #$05 ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    JMP EXIT_RESTORE_XOBJ ; Exit.
VAL_NE_0x18: ; C:12CD, 0x0012CD
    CMP #$16
    BNE VAL_NE_0x16 ; !=, goto.
    LDA #$24
    STA FILE_STREAM_UNK[2] ; Move file ??
    LDA #$93
    STA FILE_STREAM_UNK+1
    LDY #$00 ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDA #$FF
    STA OBJ_ATTR_UNK_071[19],X ; Seet ??
    LDY #$05 ; File ??
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDA #$FF ; Set ??
    STA OBJ_ATTR_UNK_071[19],X
    LDY #$0A ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDA #$FF
    STA OBJ_ATTR_UNK_071[19],X ; Set ??
    JMP EXIT_RESTORE_XOBJ ; Exit.
VAL_NE_0x16: ; C:12F7, 0x0012F7
    CMP #$17 ; If _ #417
    BNE EXIT_RESTORE_XOBJ ; !=, goto.
    LDA #$33
    STA FILE_STREAM_UNK[2] ; Move ??
    LDA #$93
    STA FILE_STREAM_UNK+1
    LDY #$00 ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDY #$05 ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
    LDY #$0A ; File.
    JSR SUB_DOUBLE_FPTRS_DISPLAY?_HELPER
EXIT_RESTORE_XOBJ: ; C:1312, 0x001312
    LDX CURRENT_OBJ_PROCESSING ; X to curr obj.
    RTS ; Leave.
    .db 02
    .db E4
    .db 00
    .db E0
    .db FF
    .db 02
    .db BC
    .db 00
    .db F8
    .db FF
    .db 02
    .db 94
    .db 01
    .db F8
    .db FF
    .db 07
    .db A0
    .db 01
    .db 00
    .db 00
    .db 07
    .db DC
    .db 01
    .db C0
    .db FF
    .db 07
    .db AC
    .db 01
    .db 88
    .db FF
    .db 11
    .db 58
    .db 01
    .db B8
    .db FF
    .db 12
    .db B0
    .db 01
    .db B8
    .db FF
    .db 13
    .db 88
    .db 01
    .db A0
    .db FF
DAY_OF_THE_WEEK_ARR_DIFFICULTY?: ; C:1342, 0x001342
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 01
    .db 00
    .db 00
    .db 00
    .db 01
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
    .db 00
FPTRS_SPECIAL_RTN_HELPER_L: ; C:1356, 0x001356
    LOW(OBJ_RTN_0x0)
FPTRS_SPECIAL_RTN_HELPER_M: ; C:1357, 0x001357
    HIGH(OBJ_RTN_0x0)
    LOW(OBJ_RTN_0x1)
    HIGH(OBJ_RTN_0x1)
    LOW(OBJ_RTN_0x2)
    HIGH(OBJ_RTN_0x2)
    LOW(OBJ_RTN_0x3)
    HIGH(OBJ_RTN_0x3)
    LOW(OBJ_RTN_0x4)
    HIGH(OBJ_RTN_0x4)
    LOW(OBJ_RTN_0x5)
    HIGH(OBJ_RTN_0x5)
    LOW(OBJ_RTN_0x6)
    HIGH(OBJ_RTN_0x6)
    LOW(OBJ_RTN_0x7)
    HIGH(OBJ_RTN_0x7)
    LOW(OBJ_RTN_0x8)
    HIGH(OBJ_RTN_0x8)
    LOW(OBJ_RTN_0x9)
    HIGH(OBJ_RTN_0x9)
    LOW(OBJ_RTN_0xA)
    HIGH(OBJ_RTN_0xA)
    LOW(OBJ_RTN_0xB)
    HIGH(OBJ_RTN_0xB)
    LOW(OBJ_RTN_0xC)
    HIGH(OBJ_RTN_0xC)
    LOW(OBJ_RTN_0xD)
    HIGH(OBJ_RTN_0xD)
    LOW(OBJ_RTN_0xE)
    HIGH(OBJ_RTN_0xE)
    LOW(OBJ_RTN_0xF)
    HIGH(OBJ_RTN_0xF)
    LOW(OBJ_RTN_0x10)
    HIGH(OBJ_RTN_0x10)
    LOW(OBJ_RTN_0x11)
    HIGH(OBJ_RTN_0x11)
    LOW(OBJ_RTN_0x12)
    HIGH(OBJ_RTN_0x12)
    LOW(OBJ_RTN_0x13)
    HIGH(OBJ_RTN_0x13)
SPRITE_ANIMATION_FILES_L: ; C:137E, 0x00137E
    LOW(SPRITE_DATA_FILE_A)
SPRITES_ANIMATION_FILES_H: ; C:137F, 0x00137F
    HIGH(SPRITE_DATA_FILE_A)
    LOW(SPRITE_DATA_FILE_B)
    HIGH(SPRITE_DATA_FILE_B)
    LOW(SPRITE_DATA_FILE_C)
    HIGH(SPRITE_DATA_FILE_C)
    LOW(SPRITE_DATA_FILE_D)
    HIGH(SPRITE_DATA_FILE_D)
    LOW(SPRITE_DATA_FILE_E)
    HIGH(SPRITE_DATA_FILE_E)
    LOW(SPRITE_DATA_FILE_F)
    HIGH(SPRITE_DATA_FILE_F)
    LOW(SPRITE_DATA_FILE_G)
    HIGH(SPRITE_DATA_FILE_G)
    LOW(SPRITE_DATA_FILE_H)
    HIGH(SPRITE_DATA_FILE_H)
    LOW(SPRITE_DATA_FILE_I)
    HIGH(SPRITE_DATA_FILE_I)
    LOW(SPRITE_DATA_FILE_J)
    HIGH(SPRITE_DATA_FILE_J)
    LOW(SPRITE_DATA_FILE_K)
    HIGH(SPRITE_DATA_FILE_K)
    LOW(TMP_00) ; NULL.
    HIGH(TMP_00)
    LOW(SPRITE_DATA_FILE_M)
    HIGH(SPRITE_DATA_FILE_M)
    LOW(ANIM_FILE_N)
    HIGH(ANIM_FILE_N)
    LOW(SPRITE_DATA_FILE_O)
    HIGH(SPRITE_DATA_FILE_O)
    LOW(SPRITE_DATA_FILE_P)
    HIGH(SPRITE_DATA_FILE_P)
    LOW(TMP_00) ; NULL.
    HIGH(TMP_00)
    LOW(SPRITE_DATA_FILE_R)
    HIGH(SPRITE_DATA_FILE_R)
    LOW(SPRITE_DATA_FILE_S)
    HIGH(SPRITE_DATA_FILE_S)
    LOW(SPRITE_DATA_FILE_T)
    HIGH(SPRITE_DATA_FILE_T)
FILE_STREAMS_L_TODO: ; C:13A6, 0x0013A6
    LOW(FILE_A)
FILE_STREAMS_H_TODO: ; C:13A7, 0x0013A7
    HIGH(FILE_A)
    LOW(FILE_B)
    HIGH(FILE_B)
    LOW(FILE_C)
    HIGH(FILE_C)
    LOW(FILE_D)
    HIGH(FILE_D)
    LOW(FILE_E)
    HIGH(FILE_E)
    LOW(FILE_F)
    HIGH(FILE_F)
    LOW(FILE_G)
    HIGH(FILE_G)
    LOW(FILE_H)
    HIGH(FILE_H)
    LOW(FILE_I)
    HIGH(FILE_I)
    LOW(FILE_J)
    HIGH(FILE_J)
    LOW(FILE_K)
    HIGH(FILE_K)
    LOW(FILE_L)
    HIGH(FILE_L)
    LOW(FILE_M)
    HIGH(FILE_M)
FILE_A: ; C:13C0, 0x0013C0
    .db 02
    .db 00
    .db 00
    .db 00
    .db C0
    .db FF
    .db 00
    .db 00
    .db 00
    .db A0
    .db FF
FILE_B: ; C:13CB, 0x0013CB
    .db 05
    .db 10
    .db 18
    .db 01
    .db C0
    .db FF
    .db 01
    .db D0
    .db 01
    .db 90
    .db FF
    .db 03
    .db B0
    .db 01
    .db C0
    .db FF
    .db 06
    .db B0
    .db 01
    .db 98
    .db FF
    .db 05
    .db 00
    .db 02
    .db B0
    .db FF
FILE_C: ; C:13E5, 0x0013E5
    .db 05
    .db 0A
    .db 30
    .db 02
    .db 40
    .db FF
    .db 0B
    .db 90
    .db 01
    .db 80
    .db FF
    .db 0D
    .db C0
    .db 01
    .db 78
    .db FF
    .db 06
    .db 68
    .db 01
    .db D8
    .db FF
    .db 09
    .db D8
    .db 01
    .db 88
    .db FF
FILE_D: ; C:13FF, 0x0013FF
    .db 06
    .db 01
    .db 90
    .db 01
    .db D0
    .db FF
    .db 03
    .db C0
    .db 01
    .db B0
    .db FF
    .db 06
    .db 70
    .db 01
    .db D8
    .db FF
    .db 09
    .db 60
    .db 01
    .db F0
    .db FF
    .db 0F
    .db E0
    .db 01
    .db 84
    .db FF
    .db 0C
    .db E0
    .db 00
    .db FF
    .db 00
FILE_E: ; C:141E, 0x00141E
    .db 05
    .db 0A
    .db 30
    .db 02
    .db 40
    .db FF
    .db 06
    .db 90
    .db 01
    .db 88
    .db FF
    .db 0D
    .db B0
    .db 01
    .db 80
    .db FF
    .db 0B
    .db 58
    .db 01
    .db 78
    .db FF
    .db 04
    .db A0
    .db 01
    .db B0
    .db FF
FILE_F: ; C:1438, 0x001438
    .db 03
    .db 04
    .db A8
    .db 01
    .db A8
    .db FF
    .db 06
    .db 70
    .db 01
    .db D8
    .db FF
    .db 05
    .db 00
    .db 02
    .db B0
    .db FF
FILE_G: ; C:1448, 0x001448
    .db 03
    .db 08
    .db C0
    .db 01
    .db 78
    .db FF
    .db 06
    .db 70
    .db 01
    .db D8
    .db FF
    .db 0E
    .db 00
    .db 02
    .db B0
    .db FF
FILE_H: ; C:1458, 0x001458
    .db 01
    .db 06
    .db B0
    .db 01
    .db 98
    .db FF
FILE_I: ; C:145E, 0x00145E
    .db 01
    .db 06
    .db B0
    .db 01
    .db 88
    .db FF
FILE_J: ; C:1464, 0x001464
    .db 01
    .db 0F
    .db E0
    .db 01
    .db 84
    .db FF
FILE_K: ; C:146A, 0x00146A
    .db 01
    .db 06
    .db 90
    .db 01
    .db 88
    .db FF
FILE_L: ; C:1470, 0x001470
    .db 01
    .db 06
    .db 70
    .db 01
    .db D8
    .db FF
FILE_M: ; C:1476, 0x001476
    .db 01
    .db 06
    .db 70
    .db 01
    .db D8
    .db FF
HOUSES_ROUTINE_SEED_UNK_CUSTOMER: ; C:147C, 0x00147C
    LDA #$80 ; Val for customer.
    JMP HOUSE_TYPE_SEEDED_LAUNCH
HOUSES_ROUTINE_SEED_NON-CUSTOMER: ; C:1481, 0x001481
    LDA #$02 ; Seed non-customers.
    JMP HOUSE_TYPE_SEEDED_LAUNCH ; Ente.
HOUSES_ROUTINE_SEED_CUSTOMER: ; C:1486, 0x001486
    LDA #$01 ; Seed customers.
HOUSE_TYPE_SEEDED_LAUNCH: ; C:1488, 0x001488
    STA CUSTOMER_TYPE_DOING ; Set customer type doing.
    LDA #$00
    STA HOUSE_OBJ_INDEX_CURRENT ; Clear generating.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Spawn.
    LOW(RTN_HOUSE_CONTROLLER) ; Routine 0x1494
    HIGH(RTN_HOUSE_CONTROLLER)
    .db 60 ; Leave.
RTN_HOUSE_CONTROLLER: ; C:1494, 0x001494
    LDY HOUSE_OBJ_INDEX_CURRENT ; Y from.
LOOP_ALL_HOUSES: ; C:1496, 0x001496
    CPY #$16 ; If _ #$16
    BEQ EXIT_DESTROY_OBJ ; ==, goto.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load.
    CMP #$00 ; If _ #$00
    BEQ VAL_EQ_0x00 ; == 0, goto.
    LDA CUSTOMER_TYPE_DOING ; Load customer type doing.
    BMI HOUSE_TYPE_NEGATIVE_SET ; Negative, goto.
    CMP OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; If _ arr
    BEQ HOUSE_TYPE_NEGATIVE_SET ; Val EQ Obj.
VAL_EQ_0x00: ; C:14AA, 0x0014AA
    INY ; Obj++
    BNE LOOP_ALL_HOUSES ; Nonzero, loop.
HOUSE_TYPE_NEGATIVE_SET: ; C:14AD, 0x0014AD
    STY HOUSE_OBJ_INDEX_CURRENT ; Obj to.
    LDA #$0C ; Set A.
    LDY #$E4 ; Set B.
    JSR SET_A/B_ARRAYS_UNK ; Do.
    LDY HOUSE_OBJ_INDEX_CURRENT ; Get again.
OBJ_NONZERO: ; C:14B8, 0x0014B8
    TYA ; Save to stack.
    PHA
    LDA #$0A ; Advance?
    JSR ADVANCE_PTR_A_BY_A ; Advance.
    LDA #$0A ; Subvance lol.
    JSR RETRACT_PTR_B_BY_A ; Sub B.
    PLA ; Pull obj saved.
    TAY ; To Y.
    DEY ; Y--
    BNE OBJ_NONZERO ; != 0, loop.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data ptr.
    LOW(DATA_ADDR_UNK) ; 0x2E00
    HIGH(DATA_ADDR_UNK)
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load displaying.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load.
    TAY ; To index.
    LDA ATTR_DATA_LUT_HOUSE_GOOD/BAD?,Y ; Load 0x00/0x01
    STA OBJ_DATA_BYTE_FROM_PTR,X ; Store to Xobj.
    CPY #$01 ; If _ #$01, customer.
    BNE DO_BAD_BEEP ; !=, goto. Bad.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Do sound beep.
    LOW(RTN_SOUND_GOOD_BEEP)
    HIGH(RTN_SOUND_GOOD_BEEP)
    JMP ENTER_GOOD_BEEP ; Goto.
DO_BAD_BEEP: ; C:14E6, 0x0014E6
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Do bad sound beep.
    LOW(RTN_SOUND_BAD_BEEP)
    HIGH(RTN_SOUND_BAD_BEEP)
ENTER_GOOD_BEEP: ; C:14EB, 0x0014EB
    LDA #$10 ; Time to suspend?
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Make another rtn. More recursion. >:|
    LOW(RTN_HOUSE_CONTROLLER) ; TODO.
    HIGH(RTN_HOUSE_CONTROLLER)
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load index for us.
    INC HOUSE_OBJ_INDEX_CURRENT ; To next for later.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend us.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load from arr.
    BMI HOUSE_BLINKY? ; If negative, goto.
    RTS ; Leave, no more to do here.
HOUSE_BLINKY?: ; C:1502, 0x001502
    LDY #$00 ; Val ??
LOOP_SUSPEND_DATA_MOVE_LOOP_BLINKING_HOUSE?: ; C:1504, 0x001504
    TYA ; Index to A.
    EOR #$01 ; Invert bottom.
    TAY ; To Y index.
    LDA ATTR_DATA_LUT_HOUSE_GOOD/BAD?,Y ; Load from arr.
    STA OBJ_DATA_BYTE_FROM_PTR,X ; Store to process var.
    LDA #$0F
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Set ?? and suspend.
    JMP LOOP_SUSPEND_DATA_MOVE_LOOP_BLINKING_HOUSE? ; Goto.
EXIT_DESTROY_OBJ: ; C:1516, 0x001516
    JSR OBJECT_X_ID_DESTROY ; Clear us, we're too many.
    RTS ; Leave.
ATTR_DATA_LUT_HOUSE_GOOD/BAD?: ; C:151A, 0x00151A
    .db 01 ; 0x00 Bad.
    .db 00 ; 0x01 Good.
    .db 01 ; 0x02 Bad.
OBJ_RTN_0x3: ; C:151D, 0x00151D
    LDA #$06
    STA OBJ_ATTR_TIMER[19],X ; Set ??
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST
    LOW(SPRITE_DATA_FILE_D)
    HIGH(SPRITE_DATA_FILE_D)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_HELPER_OBJ_DETECTIONS ; Do ??
    BEQ TIMER_EQ_0x00 ; == 0, goto.
    RTS ; Leave.
TIMER_EQ_0x00: ; C:1530, 0x001530
    LDA #$06
    STA OBJ_ATTR_TIMER[19],X ; Set timer again.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Reseed data.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_HELPER_OBJ_DETECTIONS ; Do helper.
    BEQ OBJ_RTN_0x3 ; == 0, goto.
    RTS
SUB_HELPER_OBJ_DETECTIONS: ; C:1543, 0x001543
    JSR MOD_PTR_A/B_IF_VAR_SET
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Detect ??
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Detect ??
    JSR SUB_TEST_HIT_UNK_TODO ; Test ??
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Leave.
OBJ_RTN_0x4: ; C:1553, 0x001553
    JSR TEST_DETECT_DESTROY ; Test.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE RTS ; != 0, leave.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$90 ; If _ #$90
    BCC RTS ; <, leave.
OBJECT_RESET: ; C:1560, 0x001560
    LDA #$0C
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do to obj.
    LOW(SPRITE_DATA_FILE_E)
    HIGH(SPRITE_DATA_FILE_E)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR ADVANCE_AND_DETECT_HELPER ; Advance and detect.
    CMP #$09 ; If _ #$09
    BCS RTS ; >=, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR ADVANCE_AND_DETECT_HELPER ; Advance.
    CMP #$05 ; If _ #$05
    BCS RTS ; >=, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR ADVANCE_AND_DETECT_HELPER ; Advance andc timer.
    BEQ OBJECT_RESET ; == 0, reset.
RTS: ; C:1590, 0x001590
    RTS ; Leave.
ADVANCE_AND_DETECT_HELPER: ; C:1591, 0x001591
    JSR ADVANCE_PTR_A_BY_0x1
TEST_DETECT_DESTROY: ; C:1594, 0x001594
    JSR SUB_TEST_HIT_UNK_TODO ; Test destroy.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Test vs player.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Test.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Return it.
OBJ_RTN_0x5: ; C:15A4, 0x0015A4
    LDA #$FF ; Move ??
    STA OBJ_ATTR_UNK_071[19],X
    JSR HELPER_TEST_DESTROY_AND_FORWARD ; Do test and forward.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE RTS ; !=, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$BF ; If _ #$BF
    BCC RTS ; <, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do.
    LOW(FILE)
    HIGH(FILE)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do mod.
    JSR HIT_DETECT_VS_PLAYER_AND_FORWARD ; Do detect.
RTS: ; C:15C0, 0x0015C0
    RTS ; Leave.
HIT_DETECT_VS_PLAYER_AND_FORWARD: ; C:15C1, 0x0015C1
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Hit vs player.
HELPER_TEST_DESTROY_AND_FORWARD: ; C:15C4, 0x0015C4
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    RTS ; Leave.
HOUSES_RELATED_PROBS_TODO_LATER: ; C:15CB, 0x0015CB
    LDY #$09 ; Index ??
COUNT_POSITIVE: ; C:15CD, 0x0015CD
    TYA ; To A.
    CMP #$06 ; If _ #$06
    BCC UPDATE_OFFSET_IN_A ; <, goto. X from.
    SEC ; Prep sub.
    SBC #$06 ; Sub with to modulo easily.
UPDATE_OFFSET_IN_A: ; C:15D5, 0x0015D5
    TAX ; To X index.
    LDA UPDATE_OFFSET_DATA?,X ; Move from X to Y.
    STA OBJ_ATTR_UNK_758+1,Y ; Store to ??
    DEY ; Count--
    BPL COUNT_POSITIVE ; Positive, goto.
    LDA #$01 ; Val ??
    JSR SET_HOUSE_DATA? ; Do ??
    LDY #$09 ; 10 other.
COUNT_POSITIVE: ; C:15E6, 0x0015E6
    TYA ; To A.
    CMP #$06 ; If _ #$06
    BCC UPDATE_OFFSET_IN_A_2 ; <, goto.
    SEC ; Modulo.
    SBC #$06
UPDATE_OFFSET_IN_A_2: ; C:15EE, 0x0015EE
    TAX ; To X index.
    LDA UPDATE_OFFSET_DATA_B?,X ; Load.
    STA OBJ_ATTR_UNK_758+1,Y ; Move to.
    DEY ; Count--
    BPL COUNT_POSITIVE ; Positive, goto.
    LDA #$0C ; Val ??
    JSR SET_HOUSE_DATA? ; Do ??
    LDX #$00 ; Index.
    LDY #$00 ; Data.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ ; Move data.
    LDY #$0B ; Index.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDY #$16 ; Index.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$5B ; Index.
    LDY #$17 ; OBJ.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$62 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$69 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$70 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$77 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$7E ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$85 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$8C ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$93 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$9A ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    LDX #$A1 ; Index.
    INY ; Obj.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ
    RTS ; Leave.
SET_HOUSE_DATA?: ; C:1652, 0x001652
    STA TMP_00 ; Val to.
    LDA #$14
    STA TMP_01 ; Seed ??
VAL_NONZERO: ; C:1658, 0x001658
    LDY #$09 ; Count.
INDEX_NONZERO: ; C:165A, 0x00165A
    TYA ; To A.
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do ??
    TAX ; A to X.
    INX ; ++
    LDA OBJ_ATTR_UNK_758+1,X ; Load.
    PHA ; Save.
    LDA OBJ_ATTR_UNK_758+1,Y ; Load from Y.
    STA OBJ_ATTR_UNK_758+1,X ; Store to X.
    PLA ; Pull saved.
    STA OBJ_ATTR_UNK_758+1,Y ; Store to Y.
    DEY ; Index--
    BNE INDEX_NONZERO ; != 0, goto.
    LDY #$09 ; Index.
COMPARE_INDEX_TO_BELOW: ; C:1673, 0x001673
    LDA OBJ_ATTR_UNK_758+1,Y ; Load obj.
    CMP OBJ_ATTR_UNK_758[19],Y ; If _ attr.
    BNE SUB_COUNT ; !=, goto.
    DEC TMP_01 ; --
    BNE VAL_NONZERO ; != 0, goto.
SUB_COUNT: ; C:167F, 0x00167F
    DEY ; Index/count--
    BNE COMPARE_INDEX_TO_BELOW ; !=, goto.
    LDY TMP_00 ; Index from.
    LDX #$00 ; Index reset.
LOOP_X_INDEXES: ; C:1686, 0x001686
    TXA ; Clear A.
    PHA ; Save it.
    LDA OBJ_ATTR_UNK_758+1,X ; Load from index.
    TAX ; To X.
    JSR MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ ; Do ??
    INY ; Obj++
    PLA ; Restore X.
    TAX
    INX ; ++
    CPX #$0A ; If _ #$0A
    BCC LOOP_X_INDEXES ; <, goto.
    RTS ; Leave.
MOVE_HOUSE_DATA_INDEX_X_TO_YOBJ: ; C:1698, 0x001698
    LDA HOUSE_DATA_UNK_A,X ; Move 4x.
    STA HOUSE_ID_ATTRS_A,Y
    LDA HOUSE_DATA_UNK_B,X
    STA HOUSE_ID_ATTRS_B,Y
    LDA HOUSE_DATA_UNK_C,X
    STA **:$068D,Y
    LDA HOUSE_DATA_UNK_D,X
    STA **:$06AF,Y
    LDA HOUSE_DATA_UNK_E,X ; Load.
    CMP #$00 ; If _ #$00
    BNE DONT_ROTATE/COMBINE_UNK ; != 0, goto.
    LDA #$03 ; Load ??
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do.
    STA TMP_00 ; A to.
    ASL A ; << 2
    ASL A
    ORA TMP_00 ; Or with.
    ASL A ; << 2
    ASL A
    ORA TMP_00 ; Or with.
    ASL A ; << 2
    ASL A
    ORA TMP_00 ; Or with.
DONT_ROTATE/COMBINE_UNK: ; C:16CA, 0x0016CA
    STA OBJ_ATTR_DEEP_UNK[19],Y ; Store to.
    CMP #$FF ; If _ #$FF
    BNE VAL_NE_0xFF ; !=, goto.
    LDA #$00 ; Clear.
VAL_NE_0xFF: ; C:16D3, 0x0016D3
    STA OBJ_ATTR_UNK_649[19],Y ; Store nonzero/clear.
    CPY #$16 ; If _ #$16
    BCS OBJ_GTE_0x16 ; >=, goto.
    LDA HOUSE_DATA_UNK_F,X ; Move ??
    STA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y
    LDA #$00 ; Clear ??
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y
OBJ_GTE_0x16: ; C:16E5, 0x0016E5
    LDA HOUSE_DATA_UNK_G,X ; Move ??
    STA **:$066B,Y
    RTS ; Leave.
UPDATE_OFFSET_DATA?: ; C:16EC, 0x0016EC
    .db 07
    .db 0E
    .db 15
    .db 1C
    .db 23
    .db 2A
UPDATE_OFFSET_DATA_B?: ; C:16F2, 0x0016F2
    .db 07
    .db 0E
    .db 15
    .db 1C
    .db 23
    .db 2A
HOUSE_DATA_UNK_A: ; C:16F8, 0x0016F8
    .db 28
HOUSE_DATA_UNK_B: ; C:16F9, 0x0016F9
    .db B3
HOUSE_DATA_UNK_C: ; C:16FA, 0x0016FA
    .db 00
HOUSE_DATA_UNK_D: ; C:16FB, 0x0016FB
    .db 00
HOUSE_DATA_UNK_E: ; C:16FC, 0x0016FC
    .db 55
HOUSE_DATA_UNK_F: ; C:16FD, 0x0016FD
    .db 00
HOUSE_DATA_UNK_G: ; C:16FE, 0x0016FE
    .db 00
    .db 09
    .db B5
    .db 6F
    .db C7
    .db 00
    .db 01
    .db 01
    .db 02
    .db B8
    .db 3F
    .db C7
    .db FF
    .db 02
    .db 02
    .db 3E
    .db BB
    .db 9F
    .db C7
    .db 00
    .db 01
    .db 03
    .db 63
    .db BE
    .db CF
    .db C7
    .db FF
    .db 02
    .db 04
    .db 1A
    .db C1
    .db FF
    .db C7
    .db 00
    .db 01
    .db 05
    .db ED
    .db C3
    .db 2F
    .db C8
    .db FF
    .db 02
    .db 06
    .db 09
    .db B5
    .db 6F
    .db C7
    .db 00
    .db 01
    .db 07
    .db 02
    .db B8
    .db 3F
    .db C7
    .db FF
    .db 02
    .db 08
    .db 3E
    .db BB
    .db 9F
    .db C7
    .db 00
    .db 01
    .db 09
    .db 63
    .db BE
    .db CF
    .db C7
    .db FF
    .db 02
    .db 0A
    .db 1A
    .db C1
    .db FF
    .db C7
    .db 00
    .db 01
    .db 0B
    .db ED
    .db C3
    .db 2F
    .db C8
    .db FF
    .db 02
    .db 0C
    .db D1
    .db C8
    .db 00
    .db 00
    .db 55
    .db 00
    .db 00
    .db 73
    .db C9
    .db 00
    .db 00
    .db 55
    .db 00
    .db 00
    .db 96
    .db CD
    .db 00
    .db 00
    .db AA
    .db 00
    .db 00
    .db 8F
    .db D0
    .db 00
    .db 00
    .db FF
    .db 00
    .db 15
    .db C5
    .db D3
    .db 00
    .db 00
    .db AA
    .db 00
    .db 00
    .db 65
    .db D5
    .db 00
    .db 00
    .db FF
    .db 00
    .db 00
    .db C2
    .db D6
    .db 00
    .db 00
    .db AA
    .db 00
    .db 16
    .db 16
    .db D9
    .db 00
    .db 00
    .db AA
    .db 00
    .db 00
    .db 02
    .db DB
    .db 00
    .db 00
    .db FF
    .db 00
    .db 00
    .db 69
    .db DC
    .db 00
    .db 00
    .db AA
    .db 00
    .db 18
    .db 0F
    .db CB
    .db 00
    .db 00
    .db 55
    .db 00
    .db 17
    LDY #$64 ; Seed modulo, decimal 100
    JSR ENGINE_MODULO_HELPER ; Goto.
    CPY #$00 ; If _ #$00
    BEQ MODULO_NONE ; None, goto.
    INY ; ++
MODULO_NONE: ; C:17AA, 0x0017AA
    STY OBJ_ATTR_UNK_758+14 ; Store to obj.
    LDY #$0A ; Seed modulo decimal 10
    JSR ENGINE_MODULO_HELPER ; Modulo.
    INY ; Modulo++
    STY OBJ_ATTR_UNK_758+15 ; Store to.
    CLC ; Prep add.
    ADC #$01 ; Add with.
    STA OBJ_ATTR_UNK_758+16 ; Store to.
    LDA OBJ_ATTR_UNK_758+16 ; Load ??
    BNE RTS ; != 0, leave.
    LDA OBJ_ATTR_UNK_758+15 ; Load ??
    CMP #$01 ; If _ #$01
    BNE RTS ; !=, leave.
    LDA #$00
    STA OBJ_ATTR_UNK_758+15 ; Clear ??
RTS: ; C:17CD, 0x0017CD
    RTS ; Leave.
ENGINE_MODULO_HELPER: ; C:17CE, 0x0017CE
    STY TMP_00 ; Modulo value.
    LDY #$00 ; Seed times.
SUB_NO_UNDERFLOW: ; C:17D2, 0x0017D2
    CMP TMP_00 ; If _ modulo
    BCC RTS ; <, goto. Done.
    INY ; Modulo count++
    SEC ; Prep sub.
    SBC TMP_00 ; Sub with.
    BCS SUB_NO_UNDERFLOW ; No underflow, go again.
RTS: ; C:17DC, 0x0017DC
    RTS ; Leave.
    LDA #$01
    STA OBJ_ATTR_UNK_758+12 ; Set ??
    LDA #$03
    STA OBJ_ATTR_UNK_758+11 ; Set ??
    LDA #$00
    STA OBJ_ATTR_UNK_758+13 ; Clear ??
    STA OBJ_ATTR_UNK_758+14
    STA OBJ_ATTR_UNK_758+15
    STA OBJ_ATTR_UNK_758+16
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(**:$0763)
    HIGH(**:$0763)
    LDA #$E0 ; Move ??
    LDY #$E0
    JSR SET_A/B_ARRAYS_UNK ; Do.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Mod to here.
    RTS ; Leave.
PROCESS_UNK_SPECIAL_END_OF_LEVEL: ; C:1805, 0x001805
    LDA #$01
    STA OBJ_ATTR_UNK_758+18 ; Move ??
    LDA #$02
    STA OBJ_ATTR_UNK_758+17 ; Move ??
    LDA #$00
    STA **:$076B ; Clear ??
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST
    LOW(**:$0769) ; RAM ptr.
    HIGH(**:$0769)
    LDA #$E8 ; Seed ??
    LDY #$D8
    JSR SET_A/B_ARRAYS_UNK
    LDA #$00
    STA OBJ_ATTR_UNK_071[19],X ; Clear ??
    LDA #$05
    STA INDEX_UNK_A ; Move ??
    LDA #$06
REENTER: ; C:182B, 0x00182B
    STA INDEX_UNK_B ; Move ??
    LDA #$3C
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    LDY #$00 ; Seed ??
WAIT_TIMER: ; C:1835, 0x001835
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Stop here.
    LDA GAME_VAR_FORWARD_CONTROL_HMM ; Load ??
    BEQ WAIT_TIMER ; == 0, goto.
    INY ; ++
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BNE WAIT_TIMER ; != 0, goto.
    LDA INDEX_UNK_B ; Load ??
    SEC ; Prep sub.
    SBC #$01 ; Sub with.
    CMP #$01 ; If _ #$01
    BCS REENTER ; >=, goto.
    LDA INDEX_UNK_A ; Load ??
    SEC ; Prep sub.
    SBC #$01 ; Sub with.
    BCC SUB_UNDERFLOW ; Underflow, goto.
    CMP #$01 ; If _ #$01
    BNE VAL_NE_0x1 ; !=, goto.
    LDA #$00 ; Seed ??
VAL_NE_0x1: ; C:185A, 0x00185A
    STA INDEX_UNK_A ; Store ??
    LDA #$0A ; Seed ??
    JMP REENTER ; Goto.
SUB_UNDERFLOW: ; C:1862, 0x001862
    JSR SCRIPT_TO_HARDWARE_COPY/??_AND_DESTROY_OBJ ; Do and destroy.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create sound.
    LOW(C:0B3D)
    HIGH(C:0B3D)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handle here.
    RTS ; Leave.
PROCESS_PAPER_CREATE: ; C:186E, 0x00186E
    LDA VAL_CMP_UNK ; Load ??
    BEQ EXIT_NOT_AVAIL ; ==, goto.
    DEC OBJECTS_AVAILABLE? ; --
    BPL VALUE_POSITIVE ; Positive, goto.
    JMP EXIT_DESTROY_AND_AVAILABLE ; Exit destroy.
EXIT_NOT_AVAIL: ; C:1879, 0x001879
    JMP EXIT_DESTROY ; Exit.
VALUE_POSITIVE: ; C:187C, 0x00187C
    DEC VAL_CMP_UNK ; --
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    LDY PLAYER_OBJECT_ID ; Load player.
    LDA OBJ_SCREEN_POS_X[2],Y ; Load ??
    JSR CLEAR/SET_ARRAYS_A ; Do ??
    LDY PLAYER_OBJECT_ID ; Load player.
    LDA OBJ_PTR_UNK_B_L[2],Y ; Load player.
    SEC ; Prep sub.
    SBC #$14 ; Sub with.
    JSR SET_OBJECT_PTR_L_A_H_0x00 ; Do arrays.
RERUN: ; C:1896, 0x001896
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do in place.
    JSR PLAYER_RTN_TODO ; Do player.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler.
    JSR PLAYER_RTN_TODO ; Do player.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Sprite.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    JSR SET_OBJ_ATTR_0x40_UNK ; Set ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler.
    JSR PLAYER_RTN_TODO ; Do player.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Sprite.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler.
    JSR PLAYER_RTN_TODO ; Do player.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(FILE_UNK)
    HIGH(FILE_UNK)
    JMP RERUN ; Rerun player.
PLAYER_RTN_TODO: ; C:18C8, 0x0018C8
    LDA GAME_INDEX_HOUSE_ID_UPLOADING ; Load.
    CMP #$17 ; If _ #$17
    BCC VAL_LT_0x17 ; <, goto.
    JMP ALT_HOUSE_ID ; Goto.
VAL_LT_0x17: ; C:18D1, 0x0018D1
    LDY #$00 ; Seed ??
    LDA OBJ_ATTR_SCREEN_TILE_UNDER[19],X ; Load for player.
    CMP ROM_PLAYER_TILE_CHECKS ; If _ ROM
    BEQ CHECK_EQ_A ; ==, goto.
    INY ; ++ ??
    CMP CHECK_B ; If _ ROM
    BEQ CHECK_EQ_A ; ==, goto.
    INY ; ++ ??
    CMP CHECK_C
    BEQ CHECK_EQ_A
    INY ; ++ ??
    CMP CHECK_D
    BEQ CHECK_EQ_A
    INY ; ++ ??
    CMP CHECK_E
    BEQ CHECK_EQ_B
    INY ; ++ ??
    CMP CHECK_F
    BEQ CHECK_EQ_C
    INY ; ++ ??
    CMP CHECK_G
    BEQ CHECK_EQ_D
    INY ; ++ ??
    CMP CHECK_H
    BEQ CHECK_EQ_E
    INY ; ++ ??
    CMP CHECK_I ; If _ var
    BEQ CHECK_EQ_F_CRASHED ; ==, goto.
    CMP CHECK_J ; If _ var
    BEQ CHECK_EQ_G ; ==, goto.
    CMP CHECK_K ; If _ var
    BEQ CHECK_EQ_G ; ==, goto.
    CMP CHECK_L ; If _ var
    BEQ CHECK_EQ_G ; ==, goto.
    CMP CHECK_M ; If _ var
    BEQ CHECK_EQ_G ; ==, goto.
    JMP NO_CHECKS_EQ ; !=, goto.
CHECK_EQ_C: ; C:1922, 0x001922
    JMP DO_UNK_A ; Goto.
CHECK_EQ_D: ; C:1925, 0x001925
    JMP DO_UNK_B ; Goto.
CHECK_EQ_E: ; C:1928, 0x001928
    JMP DO_UNK_C ; Goto.
CHECK_EQ_A: ; C:192B, 0x00192B
    LDA #$00
    STA FILE_STREAM_UNK[2] ; Clear ??
    STA FILE_STREAM_UNK+1
    JSR SUB_UNK_TODO ; Do ??
    LDA #$04
    JSR ENGINE_SOUND_DMC_PLAY ; Window break.
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load house on.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load ??
    CMP #$01 ; If _ #$01
    BNE HOUSE_NOT_A_SUBSCRIPTION ; !=, not sub.
    LDA #$02
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Set attr.
CHECK_EQ_G: ; C:1947, 0x001947
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
HOUSE_NOT_A_SUBSCRIPTION: ; C:194A, 0x00194A
    LDA #$1E ; Add up.
    JSR ACCUMULATE_UNK_PTR? ; Do ??
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
CHECK_EQ_B: ; C:1952, 0x001952
    LDA #$00
    STA FILE_STREAM_UNK[2] ; Clear ??
    STA FILE_STREAM_UNK+1
    JSR SUB_UNK_TODO ; Do ??
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load ID.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load ??
    CMP #$01 ; If _ Subscribed
    BNE HOUSE_NOT_SUBSCRIBED ; !=, goto.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load val.
    CMP #$02 ; If _ #$02
    BEQ HOUSE_NOT_SUBSCRIBED ; ==, goto.
    LDA #$01
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Store as sub.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create ??
    LOW(HOUSE_SOUND_TODO)
    HIGH(HOUSE_SOUND_TODO)
    LDA #$4B
    JSR ACCUMULATE_UNK_PTR? ; Accumulate.
HOUSE_NOT_SUBSCRIBED: ; C:197A, 0x00197A
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
DO_UNK_A: ; C:197D, 0x00197D
    TYA ; Save Y.
    PHA
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process ??
    LOW(PROCESS_UNK_DELIVERY_A)
    HIGH(PROCESS_UNK_DELIVERY_A)
    PLA ; Restore Y.
    TAY
    JMP REENTER ; Reenter.
CHECK_EQ_F_CRASHED: ; C:1989, 0x001989
    TYA ; Save Y.
    PHA
    LDA #$01
    JSR ENGINE_SOUND_DMC_PLAY ; Play sound, crash.
    PLA ; Restore Y.
    TAY
    JMP REENTER
DO_UNK_B: ; C:1995, 0x001995
    TYA ; Save Y.
    PHA
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process ??
    LOW(PROCESS_UNK_DELIVERY_B)
    HIGH(PROCESS_UNK_DELIVERY_B)
    PLA ; Restore Y.
    TAY
    JMP REENTER
DO_UNK_C: ; C:19A1, 0x0019A1
    TYA ; Restore Y.
    PHA
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process ??
    LOW(PROCESS_UNK_DELIVERY_C_SOUND)
    HIGH(PROCESS_UNK_DELIVERY_C_SOUND)
    PLA ; Restore Y.
    TAY
REENTER: ; C:19AA, 0x0019AA
    LDA FILE_I_SPECIFIC_L,Y ; Move ??
    STA FILE_STREAM_UNK[2]
    LDA FILE_K_SPECIFIC_H,Y
    STA FILE_STREAM_UNK+1
    JSR SUB_UNK_TODO ; Do ??
    LDA #$1E
    JSR ACCUMULATE_UNK_PTR? ; Accumulate ??
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
ALT_HOUSE_ID: ; C:19BF, 0x0019BF
    LDA OBJ_SCREEN_POS_X[2],X ; Load ??
    CMP #$11 ; If _  #$11
    BCC VAL_LT_0x11 ; <, goto.
    LDY #$09 ; Seed ??
    LDA OBJ_ATTR_SCREEN_TILE_UNDER[19],X ; Load tile.
    CMP ROM_CMP_A ; If _ ROM
    BEQ VAL_EQ_A_SEED_0x1 ; ==, goto.
    CMP ROM_CMP_B ; If _ ROM
    BEQ VAL_EQ_B_SEED_0x2 ; ==, goto.
    INY ; ++ ??
    CMP ROM_CMP_C ; If _ ROM
    BEQ ROM_EQ_0X00 ; ==, goto.
VAL_LT_0x11: ; C:19DA, 0x0019DA
    JMP UNDERFLOW ; Goto ??
ROM_EQ_0X00: ; C:19DD, 0x0019DD
    LDA #$01
    STA FILE_STREAM_UNK[2] ; Set ??
    LDA #$01
    STA FILE_STREAM_UNK+1 ; Set ??
    JSR SUB_UNK_TODO ; Do ??
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create ??
    LOW(PROCESS_SOUND_UNK)
    HIGH(PROCESS_SOUND_UNK)
    LDA #$0A
    JSR ACCUMULATE_UNK_PTR? ; Move file.
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
VAL_EQ_B_SEED_0x2: ; C:19F5, 0x0019F5
    LDA #$02 ; Seed ??
    BNE VAL_SEEDED ; Seeded, goto.
VAL_EQ_A_SEED_0x1: ; C:19F9, 0x0019F9
    LDA #$01
VAL_SEEDED: ; C:19FB, 0x0019FB
    STA FILE_STREAM_UNK[2] ; Set ??
    LDA #$01
    STA FILE_STREAM_UNK+1 ; Set ??
    JSR SUB_UNK_TODO ; Do ??
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create sound.
    LOW(HOUSE_SOUND_TODO)
    HIGH(HOUSE_SOUND_TODO)
    LDA #$0A
    STA VAL_CMP_UNK ; Set ??
    LDA #$14
    JSR ACCUMULATE_UNK_PTR? ; Accumulate.
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
NO_CHECKS_EQ: ; C:1A15, 0x001A15
    LDA #$00
    STA ENGINE_UNK_PTR?[2] ; Clear ??
    STA ENGINE_UNK_PTR?+1
    LDY HOUSE_OBJ_INDEX_CURRENT ; Seed index.
    BEQ ID/VAL_EQ_0x00 ; ==, goto.
    LDA **:$06AF,Y ; Load ??
    BEQ ID/VAL_EQ_0x00 ; == 0, goto.
    STA TMP_01 ; Store val.
    LDA **:$068D,Y ; Load ??
    STA TMP_00 ; Store to ??
    LDA PPU_SCROLL_Y_COPY ; Load Y scroll.
    AND #$07 ; Keep tile.
    CLC ; Prep add.
    ADC #$B3 ; Add with.
    LSR A ; >> 3, /8.
    LSR A
    LSR A
    SEC ; Prep sub.
    SBC HOUSE_FILE_STREAM_POS ; Sub with.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA [TMP_00],Y ; Move from file.
    STA ENGINE_UNK_PTR?[2] ; Store to ??
    SEC ; Prep sub.
    SBC OBJ_SCREEN_POS_X[2],X ; Sub with X index.
    BCC UNDERFLOW ; <, goto.
    CMP #$0C ; If _ #$0C
    BCC VAL_LT_0xC ; <, goto.
    INY ; Stream += 2
    INY
    LDA [TMP_00],Y ; Move from file ??
    STA ENGINE_UNK_PTR?[2]
    SEC ; Prep sub.
    SBC OBJ_SCREEN_POS_X[2],X ; Sub with.
    BCC UNDERFLOW ; Underflow, go9to.
VAL_LT_0xC: ; C:1A52, 0x001A52
    INY ; Stream++
    LDA [TMP_00],Y ; Move from stream ??
    STA ENGINE_UNK_PTR?+1
ID/VAL_EQ_0x00: ; C:1A57, 0x001A57
    LDA ENGINE_UNK_PTR?+1 ; Load ??
    BEQ UNDERFLOW ; == 0, goto.
    JSR ENGINE_TABLE_SWITCH_ON_ARGUMENT ; Switch.
    .db 02 ; VAL, RTN_PTR, 0x00=DEFAULT/FAIL
    LOW(OBJ_RTN_A)
    HIGH(OBJ_RTN_A)
    .db 03
    LOW(OBJ_RTN_B)
    HIGH(OBJ_RTN_B)
    .db 09
    LOW(EXIT_DESTROY_AND_AVAILABLE)
    HIGH(EXIT_DESTROY_AND_AVAILABLE)
    .db 00 ; EOF.
UNDERFLOW: ; C:1A68, 0x001A68
    LDA OBJ_PTR_UNK_A_H[2],X ; Load ??
    BPL VAL_POSITIVE ; Positive, goto.
    JMP EXIT_DESTROY_AND_AVAILABLE ; Goto.
VAL_POSITIVE: ; C:1A6F, 0x001A6F
    LDA #$02 ; Sub by.
    JSR RETRACT_PTR_A_BY_A ; --
    LDA #$04 ; Seed ??
    LDY #$04
    JSR SCREEN_ADDR_THINGY_TODO ; Addr ??
    LDA OBJ_SCREEN_POS_X[2],X ; Load ??
    AND #$06 ; Keep ??
    BEQ RTS ; == 0, goto.
    PLA ; Pull RTN?
    PLA
RTS: ; C:1A83, 0x001A83
    RTS ; Leave.
OBJ_RTN_B: ; C:1A84, 0x001A84
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load ID.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load ??
    BNE OBJ_RTN_A ; != 0, goto.
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load ??
    CMP #$01 ; If _ #$01
    BNE OBJ_RTN_A ; !=, goto. Is sub.
    LDA #$01
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Set sub.
    LDA #$1E
    JSR ACCUMULATE_UNK_PTR? ; Acc ??
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Ptr ??
    LOW(HOUSE_SOUND_TODO)
    HIGH(HOUSE_SOUND_TODO)
OBJ_RTN_A: ; C:1AA1, 0x001AA1
    PLA ; Pull ??
    PLA
    LDA #$18 ; Set timer.
    STA OBJ_ATTR_TIMER[19],X ; Store.
    INC OBJECTS_AVAILABLE? ; ++
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Do process make.
    LOW(SOUND_NOISE_SFX_IDK_WHICH)
    HIGH(SOUND_NOISE_SFX_IDK_WHICH)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
MINI_HANDLER: ; C:1AB2, 0x001AB2
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BEQ TIMER_EXPIRED ; Expired, goto.
    JSR ADVANCE_PTR_B_BY_0x1 ; Forward.
TIMER_EXPIRED: ; C:1ABA, 0x001ABA
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward vars.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    ORA OBJ_PTR_UNK_A_H[2],X ; Combine with.
    BNE EXIT_DESTROY ; != 0, goto.
    RTS ; Leave.
EXIT_DESTROY_AND_AVAILABLE: ; C:1AC4, 0x001AC4
    INC OBJECTS_AVAILABLE? ; Available++
EXIT_DESTROY: ; C:1AC6, 0x001AC6
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
SUB_UNK_TODO: ; C:1ACA, 0x001ACA
    TYA ; Y to A.
    ASL A ; << 1, *2.
    TAY
    LDA FILE_PTRS_L,Y ; Move ??
    STA TMP_00
    LDA FILE_PTRS_H,Y
    STA TMP_01
    LDA OBJ_ATTR_SCRADDR_H[19],X ; Load ??
    LSR A ; >> 1, /2. To CC.
    STA TMP_03 ; Store to ??
    LDA OBJ_ATTR_SCRADDR_L[19],X ; Load ??
    ROR A ; >> 1, /2.
    LSR TMP_03 ; Rotate from.
    ROR A ; Rotate into.
    LSR A
    LSR A
    LSR A
    CLC ; Prep add.
    ADC FILE_STREAM_UNK+1 ; Add with.
    LSR TMP_03 ; >> 2, /4.
    LSR TMP_03
    BCC SHIFT_CC ; CC, goto.
    CLC ; Prep add.
    ADC #$1E ; Add with ??
SHIFT_CC: ; C:1AF3, 0x001AF3
    CMP #$3C ; If _ #$3C
    BCC VAL_LT_0x3C ; <, goto.
    SEC ; Prep sub.
    SBC #$3C ; Zero base it.
VAL_LT_0x3C: ; C:1AFA, 0x001AFA
    TAY ; To Y index.
    LDA OBJ_ATTR_SCRADDR_L[19],X ; Load ??
    SEC ; Prep sub.
    SBC FILE_STREAM_UNK[2] ; Sub with ??
    AND #$1F ; Keep lower.
    JSR SUB_UNK_A ; Do ??
    RTS ; Leave.
FILE_PTRS_L: ; C:1B07, 0x001B07
    LOW(FILE_UNK_A)
FILE_PTRS_H: ; C:1B08, 0x001B08
    HIGH(FILE_UNK_A)
    LOW(FILE_UNK_B)
    HIGH(FILE_UNK_B)
    LOW(FILE_UNK_C)
    HIGH(FILE_UNK_C)
    LOW(FILE_UNK_D)
    HIGH(FILE_UNK_D)
    LOW(FILE_UNK_E)
    HIGH(FILE_UNK_E)
    LOW(FILE_UNK_F)
    HIGH(FILE_UNK_F)
    LOW(FILE_UNK_G)
    HIGH(FILE_UNK_G)
    LOW(FILE_UNK_H)
    HIGH(FILE_UNK_H)
    LOW(FILE_UNK_I)
FILE_I_SPECIFIC_L: ; C:1B18, 0x001B18
    HIGH(FILE_UNK_I)
    LOW(FILE_UNK_J)
    HIGH(FILE_UNK_J)
    LOW(FILE_UNK_K)
FILE_K_SPECIFIC_H: ; C:1B1C, 0x001B1C
    HIGH(FILE_UNK_K)
    .db 01
    .db 01
    .db 00
    .db 02
    .db 01
    .db 01
    .db 01
    .db 01
OBJ_RTN_0x6: ; C:1B25, 0x001B25
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    JSR TEST_HIT_UNK_TODO ; Test.
    BCS RET_CS_DESTROY ; CS, goto.
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$20 ; Keep ??
    BEQ BIT_CLEAR ; Clear, goto.
    LDA #$03 ; Seed ??
BIT_CLEAR: ; C:1B35, 0x001B35
    STA OBJ_DATA_BYTE_FROM_PTR,X ; Store ??
    JSR HELPER_HIT_DETECT_XOBJ_TO_PLAYER ; Hit detect.
    BCS HIT ; Hit, goto.
    RTS ; Leave.
HIT: ; C:1B3E, 0x001B3E
    LDA #$0A
    STA VAL_CMP_UNK ; Set ??
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create ??
    LOW(PROCESS_SOUND_TODO)
    HIGH(PROCESS_SOUND_TODO)
    LDA #$05
    JSR ACCUMULATE_UNK_PTR? ; Accumulate.
RET_CS_DESTROY: ; C:1B4C, 0x001B4C
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
PROCESS_UNK_A: ; C:1B50, 0x001B50
    STX PLAYER_OBJECT_ID ; Store obj ??
    LDA #$04
    STA OBJECTS_AVAILABLE? ; Set ??
    LDA #$D8
    LDY #$D3
    JSR SET_A/B_ARRAYS_UNK ; Set ??
TILE_EQ: ; C:1B5D, 0x001B5D
    LDA #$02
    JSR SCRIPT_VAL_TO_FILE_AND_UP_MODS ; Do ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR PLAYER_CONTROLLER_THINGY ; Do ??
    BMI RET_NEGATIVE ; Negative, goto.
    BNE RET_NONZERO ; != 0, goto.
    JSR TILE_UNDER_EQ_0x5/0x6 ; Do ??
    BNE RTS ; !=, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
RTS: ; C:1B74, 0x001B74
    RTS ; Leave.
RET_NEGATIVE: ; C:1B75, 0x001B75
    JSR TILE_UNDER_EQ_0x5/0x6
    BEQ TILE_EQ ; ==, goto.
    LDA #$01
    JSR SCRIPT_VAL_TO_FILE_AND_UP_MODS ; Do ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Set handler.
    JSR PLAYER_CONTROLLER_THINGY ; Controller ??
    BMI CONTROLLER_NEGATIVE ; Negative, goto.
    BPL TILE_EQ ; Positive, goto.
CONTROLLER_NEGATIVE: ; C:1B89, 0x001B89
    LDA #$00
    JSR SCRIPT_VAL_TO_FILE_AND_UP_MODS ; Mod.
    JSR SET_OBJ_ATTR_0x40_UNK ; Do ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Pause.
    JSR PLAYER_CONTROLLER_THINGY ; Controller.
    BPL RET_NEGATIVE ; Positive, goto.
    JSR TILE_UNDER_EQ_0x5/0x6 ; TIle under.
    BEQ TILE_EQ ; ==, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Do ptr.
    LDA #$08 ; CMP ??
    CMP OBJ_SCREEN_POS_X[2],X ; If _ arr
    BCC RTS ; <, leave.
    STA OBJ_SCREEN_POS_X[2],X ; Store to, max?
RTS: ; C:1BA9, 0x001BA9
    RTS ; Leave.
RET_NONZERO: ; C:1BAA, 0x001BAA
    LDA #$03
    JSR SCRIPT_VAL_TO_FILE_AND_UP_MODS ; To file.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Here now.
    JSR PLAYER_CONTROLLER_THINGY ; Controller.
    BMI TILE_EQ ; Negative, goto.
    BEQ TILE_EQ ; == 0, goto.
    BNE VAL_NE ; !=, goto. To next line, mistake.
VAL_NE: ; C:1BBB, 0x001BBB
    LDA #$04 ; Val ??
    JSR SCRIPT_VAL_TO_FILE_AND_UP_MODS ; Do ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handle.
    JSR PLAYER_CONTROLLER_THINGY ; Controller.
    BMI RET_NONZERO ; Negative, goto.
    BEQ RET_NONZERO ; == 0, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    JSR TILE_UNDER_EQ_0x5/0x6 ; Tile under.
    BNE TILE_NE_VALS ; !=, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Goal ??
TILE_NE_VALS: ; C:1BD5, 0x001BD5
    LDA #$E8 ; Seed ??
    CMP OBJ_SCREEN_POS_X[2],X ; If _ arr
    BCS RTS ; >=, goto.
    STA OBJ_SCREEN_POS_X[2],X ; Store to alt.
RTS: ; C:1BDD, 0x001BDD
    RTS ; Leave.
SCRIPT_VAL_TO_FILE_AND_UP_MODS: ; C:1BDE, 0x001BDE
    STA FLAG_PLAYER_ANIMATION? ; Set ??
PLAYER_SET_ANIMATION_HELPER?: ; C:1BE0, 0x001BE0
    LDA FLAG_PLAYER_ANIMATION? ; Load ??
    ASL A ; << 2, *4.
    ASL A
    TAY ; To Y index.
    LDA #$04
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test up.
    BNE INC_OPTION_1 ; Pressed.
    LDA PPU_SCROLL_X_COPY ; Load.
    AND #$04 ; Test.
    BEQ USE_ARRAY_ASIS ; Clear.
INC_OPTION_1: ; C:1BF1, 0x001BF1
    INY ; Index += 2
    INY
USE_ARRAY_ASIS: ; C:1BF3, 0x001BF3
    LDA FILE_PTRS_L,Y ; Move vals.
    STA TMP_00
    LDA FILE_PTRS_H,Y
    STA TMP_01
    JSR OBJECT_MOVE_PTR_AND_SEED_FROM_STREAM_DISPLAY? ; Move and seed.
    LDA FLAG_PLAYER_ANIMATION? ; Load.
    BNE RTS ; != 0, goto.
    JSR SET_OBJ_ATTR_0x40_UNK ; Set bit.
RTS: ; C:1C07, 0x001C07
    RTS ; Leave.
FILE_PTRS_L: ; C:1C08, 0x001C08
    LOW(FILE_D)
FILE_PTRS_H: ; C:1C09, 0x001C09
    HIGH(FILE_D)
    LOW(FILE_B)
    HIGH(FILE_B)
    LOW(FILE_C)
    HIGH(FILE_C)
    LOW(FILE_C)
    HIGH(FILE_C)
    LOW(FILE_D)
    HIGH(FILE_D)
    LOW(FILE_B)
    HIGH(FILE_B)
    LOW(FILE_E)
    HIGH(FILE_E)
    LOW(FILE_F)
    HIGH(FILE_F)
    LOW(FILE_G)
    HIGH(FILE_G)
    LOW(FILE_H)
    HIGH(FILE_H)
TILE_UNDER_EQ_0x5/0x6: ; C:1C1C, 0x001C1C
    LDA OBJ_ATTR_SCREEN_TILE_UNDER[19],X ; Load ??
    CMP #$05 ; If _ #$05
    BEQ RTS ; ==, goto.
    CMP #$06 ; If _ #$06
RTS: ; C:1C25, 0x001C25
    RTS ; Return CC 5 <, CS >= 6
PLAYER_CONTROLLER_THINGY: ; C:1C26, 0x001C26
    JSR PLAYER_CONTROLLER_UP_DOWN_HELPER ; Do ctrl test for biking.
    JSR PLAYER_SET_ANIMATION_HELPER? ; Bike mod?
    LDA GAME_VAR_FORWARD_CONTROL_HMM ; Load ??
    BNE VAL_NONZERO ; != 0, goto.
    PLA ; Pull A.
    PLA
    RTS ; Leave.
VAL_NONZERO: ; C:1C33, 0x001C33
    LDA OBJ_ATTR_SCREEN_TILE_UNDER[19],X ; Load.
    BEQ EXIT_GOTO_A ; == 0, goto.
    LDY GAME_INDEX_HOUSE_ID_UPLOADING ; Load.
    CPY #$17 ; If _ #$17
    BCS VAL_GTE_0x17 ; >=, goto.
    LDY ROM_INDEX_INIT ; Load ??
Y_NE_0x00: ; C:1C41, 0x001C41
    CMP ROM_INDEX_COMPARE_VAL,Y ; If _ arr
    BEQ EXIT_GOTO_B ; ==, goto.
    DEY ; Y--
    BNE Y_NE_0x00 ; !=, loop.
EXIT_GOTO_A: ; C:1C49, 0x001C49
    JMP RETURN_CTRL_MOVEMENT_TEST_DIRECTION ; Goto.
EXIT_GOTO_B: ; C:1C4C, 0x001C4C
    JMP EXIT_B ; Goto.
VAL_GTE_0x17: ; C:1C4F, 0x001C4F
    LDY ROM_INDEX_UNK_A
INDEX_CHECK_LOOP: ; C:1C52, 0x001C52
    CMP ROM_ARR_UNK_A,Y ; If _ arr
    BEQ EXIT_GOTO_B ; ==, goto.
    DEY ; Y--
    BNE INDEX_CHECK_LOOP ; !=, goto.
    LDY ROM_INDEX_UNK_B
INDEX_CHECK_LOOP_B: ; C:1C5D, 0x001C5D
    CMP ROM_ARR_UNK_B,Y
    BEQ VAL_EQ_ARR ; ==, goto.
    DEY ; Index--
    BNE INDEX_CHECK_LOOP_B ; !=, goto.
    LDA **:$00B0 ; Load ??
    BNE VAL_EQ_ARR ; !=, goto.
    BEQ EXIT_GOTO_A ; == 0, goto.
VAL_EQ_ARR: ; C:1C6B, 0x001C6B
    PLA ; Pull ??
    SEC ; Prep sub.
    SBC #$05 ; Sub with.
    STA INDIRECT_THINGY_UNK ; Store to.
    PLA ; Pull ??
    SBC #$00 ; Carry sub.
    STA **:$00CF ; Store ??
    LDA #$31 ; Move timer.
    STA OBJ_ATTR_TIMER[19],X
    LDA #$FE ; Move ??
    STA **:$00AB
    LDA #$08 ; Move ??
    STA **:$00AA
    LDA #$00 ; Move ??
    STA **:$00AC
    LDA #$0A ; Move ??
    STA VAL_CMP_UNK
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Mod.
    JSR EXIT_UNK ; Do ??
    LDA **:$00AA ; Load ??
    CLC ; Prep add.
    ADC #$15 ; Add with.
    STA **:$00AA ; Store to.
    LDA **:$00AB ; Load ??
    ADC #$00 ; Carry add.
    STA **:$00AB ; Store to.
    LDA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Load pressed.
    PHA ; Save them.
    JSR SCRIPT_CONTROLLER_INPUT_RTN ; Read controller.
    PLA ; Pull buttons.
    STA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Restore newly pressed.
    LDA GAME_VAR_FORWARD_CONTROL_HMM ; Load ??
    BEQ RTS ; == 0, goto.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BNE VAL_NE_0x00 ; !=, goto.
    LDA #$0C ; Seed ??
    LDY #$04
    JSR SCREEN_ADDR_THINGY_TODO ; Addr thingy.
    LDA #$00
    STA **:$00B0 ; Clear ??
    STA OBJ_ATTR_SCREEN_TILE_UNDER[19],X ; Clear ??
    LDA #$D3
    STA OBJ_PTR_UNK_B_L[2],X ; Clear ??
    JMP [INDIRECT_THINGY_UNK] ; Goto.
VAL_NE_0x00: ; C:1CC5, 0x001CC5
    LDA **:$00AC ; Load ??
    CLC ; Prep add.
    ADC **:$00AA ; Add with.
    STA **:$00AC ; Store to.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    ADC **:$00AB ; Carry add.
    STA OBJ_PTR_UNK_B_L[2],X ; Store to.
    LDA #$02 ; Test button left?
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ BUTTON_CLEAR ; Clear, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Do.
    LDA #$08 ; CMP ??
    CMP OBJ_SCREEN_POS_X[2],X ; If _ arr
    BCC RTS ; <, goto.
    STA OBJ_SCREEN_POS_X[2],X ; Store to.
    JMP RTS ; Goto.
BUTTON_CLEAR: ; C:1CE6, 0x001CE6
    LDA #$01 ; Test right?
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ RTS ; ==, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    LDA #$E8 ; Val ??
    CMP OBJ_SCREEN_POS_X[2],X ; If _ arr
    BCS RTS ; >=, leave.
    STA OBJ_SCREEN_POS_X[2],X ; Store to, max.
RTS: ; C:1CF7, 0x001CF7
    RTS ; Leave.
EXIT_B: ; C:1CF8, 0x001CF8
    JSR PLAYER_CRASH_RTN ; Crash.
    PLA ; Pull extra addr.
    PLA
    RTS ; Leave.
RETURN_CTRL_MOVEMENT_TEST_DIRECTION: ; C:1CFE, 0x001CFE
    LDA #$0C ; Seed ??
    LDY #$04
    JSR SCREEN_ADDR_THINGY_TODO ; Do ??
    LDA #$02 ; Test left?
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ TEST_CLEAR ; Clear, goto.
    LDA #$FF ; Return negative.
    RTS ; Leave.
TEST_CLEAR: ; C:1D0E, 0x001D0E
    LDA #$01 ; Test right.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ TEST_RIGHT_CLEAR ; Clear, goto.
    LDA #$01 ; Return to right, positive.
    RTS
TEST_RIGHT_CLEAR: ; C:1D17, 0x001D17
    LDA #$00 ; No movement.
    RTS ; Leave.
    .db 37
    .db 40
    .db 53
    .db 8F
    .db 9A
    .db 9B
    .db 9C
    .db 9D
    .db 9E
    .db A7
    .db AB
    .db AD
    .db AE
    .db B2
    .db BA
    .db C2
    .db C3
    .db C4
    .db 27
    .db 73
    .db 74
    .db 75
    .db 7D
    .db 76
    .db 77
    .db 78
    .db 88
    .db 89
    .db 9A
LEVEL_INIT: ; C:1D37, 0x001D37
    LDA #$04
    STA CURRENT_PLAYER_LIVES ; Set ??
    STA PLAYER_LIVES_OTHER_PLAYER
    LDA FLAG_MULTIPLAYER_GAME ; Load.
    BNE VAL_NONZERO ; != 0, goto.
    STA PLAYER_LIVES_OTHER_PLAYER ; Clear.
VAL_NONZERO: ; C:1D43, 0x001D43
    LDA #$00
    STA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Clear ??
    STA GAME_DAY_OF_THE_WEEK_OTHER_PLAYER
    JSR INIT_MANY_UNK ; Do ??
    LDA #$01
    STA GAME_INDEX_HOUSE_ID_UPLOADING ; Set ??
    STA GAME_INDEX_HOUSE_ID_UPLOADING_ALTERNATE_PLAYER
    LDY #$2B ; Index.
INDEX_POSITIVE: ; C:1D54, 0x001D54
    LDA OBJ_HOUSE_STATUS_0x1_SUB_0x2_NOT[19],Y ; Load.
    STA **:$058B,Y ; Copy to.
    DEY ; Index--
    BPL INDEX_POSITIVE ; Positive, do all.
    RTS ; Leave.
PLAYER_DIED_DURING_LEVEL: ; C:1D5E, 0x001D5E
    JSR SWITCH_PLAYER_VARIABLES_AROUND ; Switch players.
    LDA GAME_INDEX_HOUSE_ID_UPLOADING ; Load ??
    CMP #$01 ; If _ #$01
    BNE EXIT_GAME_CONTINUE_PLAYER_START ; !=, goto, not continuing.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Start game.
    LOW(RTN_GAME_START_DAY_OF_THE_WEEK)
    HIGH(RTN_GAME_START_DAY_OF_THE_WEEK)
    .db 60 ; Leave.
EXIT_GAME_CONTINUE_PLAYER_START: ; C:1D6D, 0x001D6D
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process, start with text.
    LOW(GAME_PLAYER_START_WITH_TEXT_RTN)
    HIGH(GAME_PLAYER_START_WITH_TEXT_RTN)
    .db 60 ; Leave.
SWITCH_PLAYER_VARIABLES_AROUND: ; C:1D73, 0x001D73
    LDA GAME_CURRENT_PLAYER ; Load player.
    EOR #$01 ; Invert them.
    STA GAME_CURRENT_PLAYER ; Store back.
    LDA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Load current GOTW.
    LDY GAME_DAY_OF_THE_WEEK_OTHER_PLAYER ; Load other player.
    STA GAME_DAY_OF_THE_WEEK_OTHER_PLAYER ; Reverse stores.
    STY CURRENT_PLAYER_DAY_OF_THE_WEEK
    LDA CURRENT_PLAYER_LIVES ; Load lives current.
    LDY PLAYER_LIVES_OTHER_PLAYER ; Load other player.
    STA PLAYER_LIVES_OTHER_PLAYER ; Store reversed.
    STY CURRENT_PLAYER_LIVES
    LDA GAME_INDEX_HOUSE_ID_UPLOADING ; Load ??
    LDY GAME_INDEX_HOUSE_ID_UPLOADING_ALTERNATE_PLAYER
    STA GAME_INDEX_HOUSE_ID_UPLOADING_ALTERNATE_PLAYER
    STY GAME_INDEX_HOUSE_ID_UPLOADING
    LDY #$04 ; Load arr ??
INDEX_POSITIVE: ; C:1D93, 0x001D93
    LDA PLAYER_SCORE_CURRENT[5],Y ; Load ??
    PHA ; Save it.
    LDA PLAYER_ARR_UNK_OTHER_PLAYER[5],Y ; Load arr.
    STA PLAYER_SCORE_CURRENT[5],Y ; Store to.
    PLA ; Pull value.
    STA PLAYER_ARR_UNK_OTHER_PLAYER[5],Y ; Store it, reversed.
    DEY ; Index--
    BPL INDEX_POSITIVE ; Positive, goto.
    JSR PLAYER_RTN_UNK ; Do ??
    LDY #$41 ; Index ??
REVERSE_LOOP: ; C:1DA9, 0x001DA9
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load ??
    PHA ; Save value.
    LDA OBJ_HOUSE_ATTR_BLINKY?_OTHER_PLAYER,Y ; Load ??
    STA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Store to.
    PLA ; Pull value.
    STA OBJ_HOUSE_ATTR_BLINKY?_OTHER_PLAYER,Y ; Store it.
    DEY ; Index--
    BPL REVERSE_LOOP ; Positive, goto.
    RTS ; Leave.
OBJ_RTN_0x7: ; C:1DBB, 0x001DBB
    LDA #$50
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Wait.
    JSR OBJ_HELPER_TODO ; Do ??
    BEQ TIMER_EXPIRED ; == 0, goto.
    LSR A ; >> 1, /2.
    BCS SHIFT_CS ; CS, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    RTS ; Leave.
TIMER_EXPIRED: ; C:1DCF, 0x001DCF
    LDA #$50
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Hnadler here.
    JSR OBJ_HELPER_TODO ; Help.
    BEQ OBJ_RTN_0x7 ; == 0, goto.
    LSR A ; >> 1, /2.
    BCS SHIFT_CS ; CS, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Forward.
SHIFT_CS: ; C:1DE2, 0x001DE2
    RTS ; Leave.
OBJ_HELPER_TODO: ; C:1DE3, 0x001DE3
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    JSR SUB_TEST_HIT_UNK_TODO ; Test ??
    JSR HELPER_HIT_DETECT_XOBJ_TO_PLAYER ; Do ??
    BCC RET_CC
    LDA #$01
    STA **:$00B0 ; Set ??
RET_CC: ; C:1DF2, 0x001DF2
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Return it.
OBJ_RTN_0x8: ; C:1DF6, 0x001DF6
    JSR HELPER_TODO ; Do helper.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE VALUE_NONZERO ; !=, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$64 ; If _ #$64
    BCC VALUE_NONZERO ; <, goto.
    JSR HELPER_TODO_UNK ; Help.
FLAG_SET_CONTINUE: ; C:1E06, 0x001E06
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Data to.
    LOW(SPRITE_DATA_FILE_I)
    HIGH(SPRITE_DATA_FILE_I)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do handler.
    JSR OBJ_HELPER_ADVANCE/TEST ; Do ??
    BNE VALUE_NONZERO ; != 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(SPRITE_ANIM_FILE_UNK)
    HIGH(SPRITE_ANIM_FILE_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler here.
    JSR OBJ_HELPER_ADVANCE/TEST ; Do test.
    BNE FLAG_SET_CONTINUE ; !=, goto.
VALUE_NONZERO: ; C:1E20, 0x001E20
    RTS ; Leave.
OBJ_HELPER_ADVANCE/TEST: ; C:1E21, 0x001E21
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BEQ TIMER_EQ_0x00 ; == 0, ,goto.
HELPER_TODO: ; C:1E29, 0x001E29
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Detect.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Detect.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward ??
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$08 ; Keep lower.
    RTS ; Leave.
TIMER_EQ_0x00: ; C:1E3A, 0x001E3A
    PLA ; Pull RTS.
    PLA
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler here.
    JSR MAIN_ENTRY_B ; Do ??
    RTS ; Leave.
OBJ_RTN_0x9: ; C:1E43, 0x001E43
    LDA #$C0
    STA OBJ_ATTR_TIMER[19],X ; Set timer ??
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do to sprite.
    .db 79
    .db B2
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do ??
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Back.
    JSR SUB_HELP_RET_TIMER ; Helper.
    CMP #$91 ; If _ #$91
    BCS RTS ; >=, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(DATA_UNK)
    HIGH(DATA_UNK)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Handler.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance and retract.
    JSR RETRACT_PTR_B_BY_0x1
    JSR SUB_HELP_RET_TIMER ; Do helper.
    CMP #$61 ; If _ #$61
    BCS RTS ; >=, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(SPRITE_DATA_FILE_J) ; Ptr.
    HIGH(SPRITE_DATA_FILE_J)
    JSR SET_OBJ_ATTR_0x40_UNK ; Set ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do handler.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    JSR SUB_HELP_RET_TIMER ; Do sub.
    CMP #$31 ; If _ #$31
    BCS RTS ; >=, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; To obj.
    LOW(DATA_SPRITE?)
    HIGH(DATA_SPRITE?)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Mod handler.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Retract.
    JSR ADVANCE_PTR_B_BY_0x1 ; Advance.
    JSR SUB_HELP_RET_TIMER ; Do helper.
    BEQ OBJ_RTN_0x9 ; == 0, goto.
RTS: ; C:1E97, 0x001E97
    RTS ; Leave.
SUB_HELP_RET_TIMER: ; C:1E98, 0x001E98
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Test player.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Test ??
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    RTS ; Leave.
ROM_DATA_INIT_SCORES: ; C:1EA8, 0x001EA8
    .db 00
    .db 01
    .db 01
    .db 00
    .db 00
    .db 52
    .db 42
    .db 20
    .db 00
    .db 01
    .db 00
    .db 09
    .db 00
    .db 44
    .db 41
    .db 54
    .db 00
    .db 01
    .db 00
    .db 08
    .db 00
    .db 54
    .db 48
    .db 45
    .db 00
    .db 01
    .db 00
    .db 07
    .db 00
    .db 42
    .db 4F
    .db 59
    .db 00
    .db 01
    .db 00
    .db 06
    .db 00
    .db 42
    .db 46
    .db 20
    .db 00
    .db 01
    .db 00
    .db 05
    .db 00
    .db 4D
    .db 45
    .db 43
    .db 00
    .db 01
    .db 00
    .db 04
    .db 00
    .db 43
    .db 53
    .db 20
    .db 00
    .db 01
    .db 00
    .db 03
    .db 00
    .db 4A
    .db 45
    .db 53
    .db 00
    .db 01
    .db 00
    .db 02
    .db 00
    .db 50
    .db 43
    .db 54
    .db 00
    .db 01
    .db 00
    .db 01
    .db 00
    .db 4D
    .db 41
    .db 41
INIT_MANY_UNK: ; C:1EF8, 0x001EF8
    LDA #$07
    STA OBJ_PTR_RAM_DATA_UNK ; Set ??
    LDA #$04
    STA **:$07D5 ; Set ??
    LDA #$00
    STA OBJ_UNK_WORD[2] ; Clear ??
    STA OBJ_UNK_WORD+1
    STA **:$07D6
    LDY #$04 ; Index.
INDEX_POSITIVE: ; C:1F0D, 0x001F0D
    STA PLAYER_SCORE_CURRENT[5],Y ; Clear.
    STA PLAYER_ARR_UNK_OTHER_PLAYER[5],Y
    DEY ; Index--
    BPL INDEX_POSITIVE ; Positive, goto.
    LDY #$1B ; Index.
INDEX_POSITIVE: ; C:1F18, 0x001F18
    STA LARGER_ARR[29],Y ; Store.
    DEY ; Index--
    BPL INDEX_POSITIVE ; Do all positive.
    LDA #$01
    STA LARGER_ARR[29] ; Set ??
    RTS ; Leave.
ACCUMULATE_UNK_PTR?: ; C:1F24, 0x001F24
    LDY #$00 ; Why ??
ACCUMULATE_SEEDED_AL_YH: ; C:1F26, 0x001F26
    CLC ; Prep add.
    ADC OBJ_UNK_WORD[2] ; Add with.
    STA OBJ_UNK_WORD[2] ; Store to.
    TYA ; Y val to A, carry val seed extra.
    ADC OBJ_UNK_WORD+1 ; Carry add it.
    STA OBJ_UNK_WORD+1 ; Store result.
    RTS ; Leave.
PROCESS_UNK_B: ; C:1F31, 0x001F31
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST
    LOW(OBJ_PTR_RAM_DATA_UNK) ; Data ptr.
    HIGH(OBJ_PTR_RAM_DATA_UNK)
    LDA #$0A
    LDY #$30
    JSR SET_A/B_ARRAYS_UNK ; Do ??
    LDA #$00
    STA OBJ_ATTR_UNK_071[19],X ; Clear attr.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    LDA OBJ_UNK_WORD[2] ; Load ??
    SEC ; Prep sub.
    SBC #$01 ; -= 0x1
    TAY ; To Y.
    LDA OBJ_UNK_WORD+1 ; Load ??
    SBC #$00 ; Carry sub.
    BCC SUB_UNDERFLOW ; Underflow, goto.
    STY OBJ_UNK_WORD[2] ; Store result.
    STA OBJ_UNK_WORD+1
    LDY #$04 ; Load index.
Y_POSITIVE: ; C:1F56, 0x001F56
    LDA PLAYER_SCORE_CURRENT[5],Y ; Load ??
    CLC ; Prep add.
    ADC #$01 ; Add with.
    CMP #$0A ; If _ #$0A
    BCC LT_0xA ; <, goto.
    LDA #$00 ; Load value ??
LT_0xA: ; C:1F62, 0x001F62
    STA PLAYER_SCORE_CURRENT[5],Y ; Store to.
    BCC PLAYER_RTN_UNK ; CC, goto.
    DEY ; Y--
    BPL Y_POSITIVE ; Positive, goto.
PLAYER_RTN_UNK: ; C:1F6A, 0x001F6A
    LDX #$00 ; Seed ??
    LDY #$00
VAL_LT_0x5: ; C:1F6E, 0x001F6E
    LDA PLAYER_SCORE_CURRENT[5],Y ; Load value ??
    BNE VAL_NE_0x0 ; !=, goto.
    CPX #$00 ; If _ #$00
    BEQ VAL_EQ_0x00 ; ==, goto.
VAL_NE_0x0: ; C:1F77, 0x001F77
    CLC ; Prep add.
    ADC #$01 ; Add with.
    STA LARGER_ARR[29],X ; Store to.
    INX ; Index++
    CPY #$02 ; If _ #$02
    BNE VAL_EQ_0x00 ; !=, goto.
    LDA #$0B ; Move ??
    STA LARGER_ARR[29],X
    INX ; Index++
VAL_EQ_0x00: ; C:1F88, 0x001F88
    INY ; Index++
    CPY #$05 ; If _ #$05
    BCC VAL_LT_0x5 ; <, goto.
    LDA #$01 ; Move ??
VALUE_SEEDED: ; C:1F8F, 0x001F8F
    STA LARGER_ARR[29],X
    INX ; Index++
    CPX #$07 ; If _ #$07
    BEQ SUB_UNDERFLOW ; ==, goto.
    LDA #$00 ; Load ??
    BEQ VALUE_SEEDED ; ==, goto.
SUB_UNDERFLOW: ; C:1F9B, 0x001F9B
    LDX CURRENT_OBJ_PROCESSING ; Load ??
    JSR SUB_HELPER_A ; Do ??
    JSR SUB_HELPER_B ; Do ??
    RTS ; Leave.
SUB_HELPER_B: ; C:1FA4, 0x001FA4
    LDY #$03 ; Load lives cmp.
Y_NE_0x00: ; C:1FA6, 0x001FA6
    LDA VAL_UNK_A ; Load ??
    CPY CURRENT_PLAYER_LIVES ; If _ lives
    BCC LIVES_LT_PASSED ; <, goto.
    LDA #$00 ; Seed ??
LIVES_LT_PASSED: ; C:1FAF, 0x001FAF
    STA LARGER_ARR+20,Y ; Store to, clear.
    DEY ; Index--
    BNE Y_NE_0x00 ; !=, goto.
    RTS ; Leave.
SUB_HELPER_A: ; C:1FB6, 0x001FB6
    LDY #$09 ; Seed ??
INDEX_POSITIVE: ; C:1FB8, 0x001FB8
    LDA VAL_UNK_B ; Load ??
    CPY VAL_CMP_UNK ; If _ ??
    BCC VAL_LT_VAR ; <, goto.
    LDA #$00 ; Seed ??
VAL_LT_VAR: ; C:1FC1, 0x001FC1
    CPY #$05 ; If _ #$05
    BCC VAL_LT_0x5 ; <, goto.
    STA LARGER_ARR+9,Y ; Store to ??
    BCS SKIP_OTHER ; Goto.
VAL_LT_0x5: ; C:1FCA, 0x001FCA
    STA LARGER_ARR+7,Y ; Store to.
SKIP_OTHER: ; C:1FCD, 0x001FCD
    DEY ; Index--
    BPL INDEX_POSITIVE ; Positive, goto.
    RTS ; Leave.
TOP_TEN_B: ; C:1FD1, 0x001FD1
    LDY #$00 ; Seed arr index.
    LDA #$01
    STA FILE_STREAM_UNK[2] ; Set ??
RERUN: ; C:1FD7, 0x001FD7
    LDX #$00 ; Index ??
    LDA #$20 ; Space.
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; Store to arr.
    LDA FILE_STREAM_UNK[2] ; Load.
    CMP #$0A ; If _ #$0A
    BNE VAL_NE_0xA ; !=, goto.
    LDA #$31 ; Move ??
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index++
    LDA #$30 ; Move ??
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index++
    JMP ENTRY_TODO ; Goto.
VAL_NE_0xA: ; C:1FF3, 0x001FF3
    INX ; Index++
    CLC ; Prep add.
    ADC #$30 ; Add with.
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; Store to arr.
    INX ; Index++
ENTRY_TODO: ; C:1FFB, 0x001FFB
    LDA #$20 ; Move clear.
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index ++
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; 2x
    INX ; Index ++
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; 3x
    INX ; Index ++
VAL_LT_0x10: ; C:2009, 0x002009
    LDA SCORES_INITIALS_ARRAY,Y ; Load ??
    CPX #$0D ; If _ #$0D
    BCS STORE_SEEDED ; >=, goto.
    CPX #$05 ; If _ #$05
    BNE VAL_NE_0x5 ; !=, goto.
    CMP #$00 ; If _ #$00
    BNE VAL_NE_0x5 ; !=, goto.
    LDA #$20 ; Seed ??
    JMP STORE_SEEDED ; Goto.
VAL_NE_0x5: ; C:201D, 0x00201D
    CLC ; Prep add.
    ADC #$30 ; Add with.
STORE_SEEDED: ; C:2020, 0x002020
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; Store to.
    INX ; Index ++
    CPX #$08 ; If _ #$08
    BEQ MOVE_2C ; ==, goto.
    CPX #$0B ; If _ #$0B
    BNE VAL_NE_0xB ; !=, goto.
    LDA #$30 ; Move ??
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index ++
    LDA #$20 ; Move ??
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index++
    JMP VAL_NE_0xB ; Goto.
MOVE_2C: ; C:203B, 0x00203B
    LDA #$2C ; Move ??
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X
    INX ; Index++
VAL_NE_0xB: ; C:2041, 0x002041
    INY ; Index ++
    CPX #$10 ; If _ #$10
    BCC VAL_LT_0x10 ; <, goto.
    LDA #$00
    STA TOP_SCORE_DISLAY_PACKET_CREATION_AREA[5],X ; Clear ??
    STY FILE_STREAM_UNK+1 ; Store ??
    LDA FILE_STREAM_UNK[2] ; Load ??
    ASL A ; << 1, *2.
    CLC ; Prep add.
    ADC #$04 ; Add with.
    TAY ; To Y index.
    LDA #$08 ; Load ??
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Create packet.
    LDA #$C3
    LDY #$07 ; Do table PTR.
    JSR TEXT_FROM_PTR_TABLE ; Text from ptr.
    INC FILE_STREAM_UNK[2] ; ++
    LDA FILE_STREAM_UNK[2] ; Load ??
    CMP #$0B ; If _ #$0B
    BEQ RTS ; ==, goto.
    LDY FILE_STREAM_UNK+1 ; Load ??
    JMP RERUN ; Goto.
RTS: ; C:206D, 0x00206D
    RTS ; Leave.
ENTER_INITIALS_HELPER_INPUT?: ; C:206E, 0x00206E
    LDY **:$00A9 ; Seed ??
    LDA STREAM_HELPER ; Load ??
    JSR ENGINE_CREATE_UPDATE_PACKET_SCR_POS_XY_PASSED ; Do update packet.
    LDA **:$00A9 ; Load ??
    ASL A ; << 3, *8.
    ASL A
    ASL A
    CLC ; Prep add.
    ADC #$0A ; Add with.
    JSR SET_OBJECT_PTR_L_A_H_0x00 ; Clear obj.
    LDA STREAM_HELPER ; Load ??
    ASL A ; << 3, *8.
    ASL A
    ASL A
    JSR CLEAR/SET_ARRAYS_A ; Do.
    LDX FILE_STREAM_UNK+1 ; Load ??
    LDA SCORES_INITIALS_ARRAY,X ; Move ??
    STA FILE_STREAM_UNK[2]
    LDY GAME_CURRENT_PLAYER ; Load current player.
    JSR CTRL_READ_PORT_Y ; Do CTRL read for.
    LDA #$F0 ; Load ??
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test button.
    BEQ NO_BUTTONS_PRESSED ; Clear, goto.
    LDA #$01 ; Set ??
    JMP RTS
NO_BUTTONS_PRESSED: ; C:209F, 0x00209F
    LDA #$01 ; To test.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
    BNE TEST_SET_0x1 ; Set, goto.
    LDA #$02 ; Test bit.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BNE TEST_SET_0x2 ; Set, goto.
    LDA #$08 ; Load ??
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
    BNE TEST_SET_0x8 ; Set, goto.
    LDA #$04 ; Load ??
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test buttons.
    BNE TEST_SET_0x4 ; Set, goto.
    LDA #$00 ; Clear.
    JMP RTS ; Goto.
TEST_SET_0x4: ; C:20BC, 0x0020BC
    LDX FILE_STREAM_UNK[2] ; Load ??
    CPX #$41 ; If _ #$41
    BEQ VAL_EQ_0x41 ; ==, goto.
    CPX #$20 ; If _ #$20
    BNE VAL_NE_0x20 ; !=, goto.
    LDX #$5B ; Load ??
    JMP VAL_NE_0x20 ; Goto.
VAL_EQ_0x41: ; C:20CB, 0x0020CB
    LDX #$21 ; Seed ??
VAL_NE_0x20: ; C:20CD, 0x0020CD
    DEX ; X--
    JMP X_DEC_ENTRY ; Goto.
TEST_SET_0x8: ; C:20D1, 0x0020D1
    LDX FILE_STREAM_UNK[2] ; Load index.
    CPX #$5A ; If _ #$5A
    BEQ VAL_EQ_0x5A ; ==, goto.
    CPX #$20 ; If _ #$20
    BNE VAL_NE_0x20 ; !=, goto.
    LDX #$40 ; Seed ??
    JMP VAL_NE_0x20 ; Goto.
VAL_EQ_0x5A: ; C:20E0, 0x0020E0
    LDX #$1F ; Seed ??
VAL_NE_0x20: ; C:20E2, 0x0020E2
    INX ; Index++
    STX FILE_STREAM_UNK[2] ; Store to.
X_DEC_ENTRY: ; C:20E5, 0x0020E5
    STX **:$07F4 ; Store ??
    TXA ; X to A.
    LDX FILE_STREAM_UNK+1 ; Load ??
    STA SCORES_INITIALS_ARRAY,X ; Store to arr.
    LDX #$00 ; Clear ??
    STX **:$07F5
    LDA #$F4 ; Seed 0x7F4.
    LDY #$07 ; Load ??
    JSR TEXT_FROM_PTR_TABLE ; Do text ptr.
    LDA #$00 ; Clear ??
    JMP RTS ; Goto.
TEST_SET_0x2: ; C:20FF, 0x0020FF
    LDY STREAM_HELPER ; Load ??
    CPY #$15 ; If _ #$15
    BNE VAL_NE_0x15 ; !=, goto.
    LDY #$18 ; Load ??
    INC FILE_STREAM_UNK+1 ; += 2
    INC FILE_STREAM_UNK+1
    JMP ENTRY_UNK ; Goto.
VAL_NE_0x15: ; C:210E, 0x00210E
    DEC FILE_STREAM_UNK+1 ; --
ENTRY_UNK: ; C:2110, 0x002110
    DEY ; Y--
    JMP Y_STORE_RET_0x00 ; Goto.
TEST_SET_0x1: ; C:2114, 0x002114
    LDY STREAM_HELPER ; Load ??
    CPY #$17 ; If _ #$17
    BNE VAL_NE_0x17 ; !=, goto.
    LDY #$14 ; Load ??
    DEC FILE_STREAM_UNK+1 ; -= 2
    DEC FILE_STREAM_UNK+1
    JMP ENTRY_UNK ; Goto.
VAL_NE_0x17: ; C:2123, 0x002123
    INC FILE_STREAM_UNK+1 ; ++
ENTRY_UNK: ; C:2125, 0x002125
    INY ; Index++
Y_STORE_RET_0x00: ; C:2126, 0x002126
    STY STREAM_HELPER ; Store.
    LDA #$00 ; Clear ??
RTS: ; C:212A, 0x00212A
    RTS ; Leave.
TOP_TEN_DISPLAY?: ; C:212B, 0x00212B
    LDA #$50
    STA LARGER_ARR+28 ; Set ??
    LDX #$00 ; Seed index ??
    LDY #$48 ; Seed arr.
COMPARE_LOOP_A: ; C:2134, 0x002134
    LDA PLAYER_SCORE_CURRENT[5],X ; Load current.
    CMP SCORES_INITIALS_ARRAY,Y ; If _ arr
    BCC RTS ; <, goto.
    BEQ VAL_EQ_ARR ; ==, goto.
    BCS VAL_GTE_ARR ; >=, goto.
VAL_EQ_ARR: ; C:213F, 0x00213F
    INY ; Index++
    INX ; Index++
    CPX #$05 ; If _ #$05
    BEQ VAL_GTE_ARR ; ==, goto.
    JMP COMPARE_LOOP_A ; Goto.
VAL_GTE_ARR: ; C:2148, 0x002148
    LDY #$40
    STY FILE_STREAM_UNK[2] ; Store ??
    LDX #$00 ; Load index.
COMPARE_LOOP_B: ; C:214E, 0x00214E
    LDA PLAYER_SCORE_CURRENT[5],X ; Load.
    CMP SCORES_INITIALS_ARRAY,Y ; If _ arr
    BCC VAL_LT_ARR ; <, goto.
    BEQ VAL_EQ_ARR ; ==, goto.
    BCS VAL_GTE_ARR ; >=, goto.
VAL_EQ_ARR: ; C:2159, 0x002159
    INY ; Index++
    INX ; Index++
    CPX #$05 ; If _ #$05
    BEQ VAL_GTE_ARR ; ==, goto.
    JMP COMPARE_LOOP_B ; Goto.
VAL_GTE_ARR: ; C:2162, 0x002162
    LDY FILE_STREAM_UNK[2] ; Load ??
    LDX #$07 ; Load index.
INDEX_POISITIVE: ; C:2166, 0x002166
    LDA SCORES_INITIALS_ARRAY,Y ; Move.
    STA SCORE_INITIALS,Y
    INY ; Index++
    DEX ; Index--
    BPL INDEX_POISITIVE ; Positive.
    LDA FILE_STREAM_UNK[2] ; Load.
    SEC ; Prep sub.
    SBC #$08 ; Sub with.
    STA FILE_STREAM_UNK[2] ; Store to.
    BCC VAL_LT_ARR ; CC, goto.
    TAY ; To Y.
    LDX #$00 ; Load ??
    JMP COMPARE_LOOP_B ; Goto.
VAL_LT_ARR: ; C:217F, 0x00217F
    LDX #$00 ; Index ??
    LDA FILE_STREAM_UNK[2] ; Load.
    CLC ; Prep add.
    ADC #$08 ; Add with.
    STA LARGER_ARR+28 ; Store to.
    TAY ; To Y index.
MOVE_LOOP: ; C:218A, 0x00218A
    LDA PLAYER_SCORE_CURRENT[5],X ; Load.
    STA SCORES_INITIALS_ARRAY,Y ; Store to.
    INY ; Index++
    INX ; Index++
    CPX #$05 ; If _ #$05
    BEQ VAL_EQ_0x5 ; ==, goto.
    JMP MOVE_LOOP ; Goto.
VAL_EQ_0x5: ; C:2198, 0x002198
    LDA #$20 ; Space val.
LOOP_MOVE_BLANKS: ; C:219A, 0x00219A
    STA SCORES_INITIALS_ARRAY,Y ; Store to.
    INY ; Index++
    INX ; Index++
    CPX #$08 ; If _  #$08
    BEQ RTS ; ==, leave.
    JMP LOOP_MOVE_BLANKS ; Goto.
RTS: ; C:21A6, 0x0021A6
    RTS
OBJ_RTN_0xA: ; C:21A7, 0x0021A7
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do.
    LOW(SPRITE_DATA_FILE_K) ; File PTR.
    HIGH(SPRITE_DATA_FILE_K)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR SUB_HELP_TODO ; Do.
    BNE C:21C1
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST
    STA PPU_STATUS,Y
    ASL **:$0087
    JSR SUB_HELP_TODO
    BNE OBJ_RTN_0xA
    RTS
SUB_HELP_TODO: ; C:21C2, 0x0021C2
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    JSR MOD_VAR_PAT_A++/B-- ; Move diagonal? TODO confirm meaning.
    JSR SUB_TEST_HIT_UNK_TODO ; Test destroy.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Test vs player.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Test vs ??
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$10 ; Return ??
    RTS ; Leave.
OBJ_RTN_0xB: ; C:21D6, 0x0021D6
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load.
    BNE RTS ; != 0, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$60 ; If _ #$60
    BCC RTS ; <, goto.
    JSR COUNTER_DOWN_RET_VAL_UNK ; Count.
    AND #$3F ; Keep lower.
    CLC ; Prep add.
    ADC #$50 ; Add with.
    STA OBJ_ATTR_TIMER[19],X ; Store to timer.
RETURN_ZERO_LOOP: ; C:21EE, 0x0021EE
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init.
    LOW(ANIMATION_FILE_TODO) ; Seed ?? TODO useless shit.
    HIGH(ANIMATION_FILE_TODO)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    LDA OBJ_ATTR_TIMER[19],X ; Load.
    BEQ LOOP_FIRST_ANIM_PTR ; == 0, goto.
    JSR HELP_ADVANCE_TEST_BOTH_MOD_AND_EXTRA_MOD_AND_HIT_HMM ; Do.
    BEQ RTS ; = 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Anim file.
    LOW(ANIM_FILE_TODO)
    HIGH(ANIM_FILE_TODO)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BEQ LOOP_FIRST_ANIM_PTR ; == 0, goto.
    JSR HELP_ADVANCE_TEST_BOTH_MOD_AND_EXTRA_MOD_AND_HIT_HMM ; Do.
    BEQ RETURN_ZERO_LOOP ; == 0, loop.
    RTS ; Leave.
LOOP_FIRST_ANIM_PTR: ; C:2213, 0x002213
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Anim file.
    LOW(ANIM_FILE_TODO) ; Fptr.
    HIGH(ANIM_FILE_TODO)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_DOUBLE_ADVANCE_MOD_TEST_AND_DETECT_OTHER_UNK ; Do sub.
    BEQ RTS ; == 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init.
    LOW(ANIM_FILE_TODO)
    HIGH(ANIM_FILE_TODO)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_DOUBLE_ADVANCE_MOD_TEST_AND_DETECT_OTHER_UNK ; Do sub.
    BNE RTS ; != 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init.
    LOW(INIT_ANIM_FILE) ; Init.
    HIGH(INIT_ANIM_FILE)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_DOUBLE_ADVANCE_MOD_TEST_AND_DETECT_OTHER_UNK ; Advance.
    BEQ RTS ; == 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Animation file.
    LOW(ANIM_FILE_TODO) ; Animate.
    HIGH(ANIM_FILE_TODO)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR SUB_DOUBLE_ADVANCE_MOD_TEST_AND_DETECT_OTHER_UNK ; Do advance.
    BEQ LOOP_FIRST_ANIM_PTR ; == 0, goto.
RTS: ; C:2247, 0x002247
    RTS ; Leave.
HELP_ADVANCE_TEST_BOTH_MOD_AND_EXTRA_MOD_AND_HIT_HMM: ; C:2248, 0x002248
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    JMP MOD_PTRS_ON_VAR_AND_TEST_CRASH_ANIM_THINGY ; Goto.
SUB_DOUBLE_ADVANCE_MOD_TEST_AND_DETECT_OTHER_UNK: ; C:224E, 0x00224E
    JSR MOD_VAR_PAT_A++/B-- ; Advance both.
MOD_PTRS_ON_VAR_AND_TEST_CRASH_ANIM_THINGY: ; C:2251, 0x002251
    JSR MOD_PTR_A/B_IF_VAR_SET ; Mod.
    JSR TEST_PLAYER_CRASH_VS_OBJECT_X_PASSED_RET_CC_NO_HIT ; Test vs player.
    BCC PLATER_NOT_HIT ; Not hit, goto.
HIT_OTHER_OBJS?: ; C:2259, 0x002259
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init anim.
    LOW(ANIM_FILE) ; Fptr.
    HIGH(ANIM_FILE)
    .db 68 ; Pull onion layer.
    .db 68
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUSPEND_AFTER ; Do.
    RTS
PLATER_NOT_HIT: ; C:2267, 0x002267
    JSR SEED_HIT_DETECT_OBJECT_Y_VS_ALL_OTHER_OBJECTS? ; Hit detect.
    BCS HIT_OTHER_OBJS? ; CS, goto.
    JSR SUB_TEST_HIT_UNK_TODO ; Do sub.
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load.
    AND #$08 ; Keep.
    RTS ; Return.
SUSPEND_AFTER: ; C:2274, 0x002274
    JSR MOD_PTR_A/B_IF_VAR_SET ; PTR++
    JSR SUB_TEST_HIT_UNK_TODO ; Do sub.
    RTS ; Leave.
OBJ_RTN_0xC: ; C:227B, 0x00227B
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
RETURN_NONZERO: ; C:2280, 0x002280
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do animation.
    LOW(SPRITE_DATA_FILE_M)
    HIGH(SPRITE_DATA_FILE_M)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_HELPER_OBJECT_MAIN ; Do sub.
    BNE RTS ; != 0, goto.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do animation.
    LOW(ANIMATION_FILE_TODO_B) ; Anim.
    HIGH(ANIMATION_FILE_TODO_B)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR SUB_HELPER_OBJECT_MAIN ; Do sub.
    BNE RETURN_NONZERO
RTS: ; C:229A, 0x00229A
    RTS
SUB_HELPER_OBJECT_MAIN: ; C:229B, 0x00229B
    JSR TEST_PLAYER_CRASH_VS_OBJECT_X_PASSED_RET_CC_NO_HIT ; Test player vs us.
    BCC NO_HITS ; No hit, goto.
    PLA ; Pull a layer.
    PLA
LOOP_ANIMATION: ; C:22A2, 0x0022A2
    LDA #$04 ; Seed timer.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend/flag.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init anim ptr.
    LOW(SPRITE_DATA_FILE_M)
    HIGH(SPRITE_DATA_FILE_M)
    LDA #$04 ; Timer.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend/help.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init anim.
    LOW(ANIMATION_FILE_TODO_B)
    HIGH(ANIMATION_FILE_TODO_B)
    JMP LOOP_ANIMATION ; Goto.
NO_HITS: ; C:22B9, 0x0022B9
    JSR SUB_TEST_HIT_UNK_TODO ; Do sub test.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BNE TIMER_NONZERO ; != 0, goto.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Do sub.
    JMP EXIT_RETURN_FLAG_TODO ; Goto.
TIMER_NONZERO: ; C:22C7, 0x0022C7
    JSR COUNTER_DOWN_RET_VAL_UNK ; Do sub.
    AND #$03 ; Keep lower.
    BNE EXIT_RETURN_FLAG_TODO ; Set, goto.
    LDY PLAYER_OBJECT_ID ; Load player.
    LDA OBJ_SCREEN_POS_X[2],X ; Load Xobj.
    CMP OBJ_SCREEN_POS_X[2],Y ; If _ player
    BCC MOVE_EXTRA_PIXEL ; <, goto.
    BEQ EQ_PLAYER ; ==, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Do sub.
    JMP EQ_PLAYER ; Goto.
MOVE_EXTRA_PIXEL: ; C:22DF, 0x0022DF
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
EQ_PLAYER: ; C:22E2, 0x0022E2
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$D3 ; If _ #$D3
    BCC EXIT_RETURN_FLAG_TODO ; <, goto.
    JSR RETRACT_PTR_B_BY_0x1 ; Retract.
EXIT_RETURN_FLAG_TODO: ; C:22EB, 0x0022EB
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load.
    AND #$04 ; Keep flag.
    RTS ; Leave.
OBJ_RTN_0xD: ; C:22F0, 0x0022F0
    JSR MAIN_ENTRY_B ; Do helper.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE RTS ; Set, leave.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$64 ; If _ #$64
    BCC RTS ; <, leave.
    JSR HELPER_TODO_UNK ; Helper.
LOOP_SET: ; C:2300, 0x002300
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Init anim.
    LOW(ANIM_FILE_N)
    HIGH(ANIM_FILE_N)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR MAIN_ENTRA_A ; Do helper.
    BNE RTS ; Set, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do sub.
    LOW(ANIM_FILE) ; Do anim.
    HIGH(ANIM_FILE)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do suspend.
    JSR MAIN_ENTRA_A ; Main helper.
    BNE LOOP_SET ; Continue, loop.
RTS: ; C:231A, 0x00231A
    RTS ; Leave.
MAIN_ENTRA_A: ; C:231B, 0x00231B
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
    LDA OBJ_ATTR_TIMER[19],X ; Load ??
    BEQ EXIT_ONION_AND_SUSPEND_HELPER_LEAVE ; == 0, goto.
MAIN_ENTRY_B: ; C:2323, 0x002323
    JSR SUB_TEST_HIT_UNK_TODO ; Test.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Detect.
    JSR OBJ_HELP_HIT_DETECT_VS_ALL_OBJS_FOR_PAPER? ; Detect ??
    JSR MOD_PTR_A/B_IF_VAR_SET ; Forward ??
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$08 ; Keep bit.
    RTS ; Leave.
EXIT_ONION_AND_SUSPEND_HELPER_LEAVE: ; C:2334, 0x002334
    PLA ; Pull layer.
    PLA
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR MAIN_ENTRY_B ; Do helper.
    RTS ; Leave.
HELPER_TODO_UNK: ; C:233D, 0x00233D
    LDA #$40 ; Load ??
    JSR SAVE_ROTATE_B_HELPER_UNK ; Do helper.
    CLC ; Prep add.
    ADC #$4F ; Add with ??
    STA TMP_00 ; Store  to.
    LDY PLAYER_OBJECT_ID ; Load ID for player.
    LDA OBJ_SCREEN_POS_X[2],Y ; Load player.
    SEC ; Prep sub.
    SBC OBJ_SCREEN_POS_X[2],X ; Sub with.
    CLC ; Prep sub.
    ADC TMP_00 ; Add with.
    STA OBJ_ATTR_TIMER[19],X ; Store to.
    RTS ; Leave.
OBJ_RTN_0xE: ; C:2356, 0x002356
    JSR HELPER_TEST_TODO ; Do test.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE RTS ; != 0, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$BB ; If _ #$BB
    BCC RTS ; <, goto.
    LDA #$02
    JSR ENGINE_SOUND_DMC_PLAY ; Play car horn.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do handler.
    JSR HELPER_TEST_TODO ; Test.
RTS: ; C:236E, 0x00236E
    RTS ; Leave.
HELPER_TEST_TODO: ; C:236F, 0x00236F
    JSR SUB_TEST_HIT_UNK_TODO ; Do test.
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Do detect.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Do forward.
    JSR MOD_VAR_PAT_A++/B-- ; Advance.
    RTS ; Leave.
OBJ_RTN_0x10: ; C:237C, 0x00237C
    JSR MOD_PTR_A/B_IF_VAR_SET ; Do mod.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load.
    BNE RTS ; Set, leave.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$BF ; If _ #$BF
    BCC RTS ; <, leave.
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load index.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load house.
    CMP #$01 ; If _ #$01
    BNE VAL_NE_0x1 ; !=, goto.
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
VAL_NE_0x1: ; C:2396, 0x002396
    LDA #$FF
    STA OBJ_ATTR_TIMER[19],X ; Set timer.
VAL_EQ_0x00: ; C:239B, 0x00239B
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Do animation file.
    LOW(ANIM_FILE_PAIR_A) ; Anim file.
    HIGH(ANIM_FILE_PAIR_A)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR MAIN_HELPER ; Do sub.
    BNE RTS ; Set, leave.
    JSR INIT_OBJECT_ANIMATION_FILE_PTR_PAST ; Animation file.
    LOW(ANIM_FILE_PAIR_B)
    HIGH(ANIM_FILE_PAIR_B)
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR MAIN_HELPER ; Main helper.
    BEQ VAL_EQ_0x00 ; == 0, goto.
RTS: ; C:23B5, 0x0023B5
    RTS ; Leave.
MAIN_HELPER: ; C:23B6, 0x0023B6
    JSR OBJ_HELP_HIT_DETECT_VS_PLAYER ; Hit detect.
    JSR MOD_PTR_A/B_IF_VAR_SET ; Do mod.
    LDY PLAYER_OBJECT_ID ; Load player ID.
    LDA OBJ_SCREEN_POS_X[2],X ; Load Xobj.
    CMP OBJ_SCREEN_POS_X[2],Y ; If _ player
    BCC VAL_LT_VAR ; <, goto.
    BEQ VAL_EQ_0x00 ; == 0, goto.
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Do ptr.
    JSR SET_OBJ_ATTR_0x40_UNK ; Set.
    JMP VAL_EQ_0x00 ; Goto.
VAL_LT_VAR: ; C:23D0, 0x0023D0
    LDA OBJ_SCREEN_POS_X[2],X ; Load.
    BMI VAL_NEGATIVE ; Negative, goto.
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
VAL_NEGATIVE: ; C:23D7, 0x0023D7
    JSR ADVANCE_PTR_A_BY_0x1 ; Advance.
VAL_EQ_0x00: ; C:23DA, 0x0023DA
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BEQ EXIT_TEST_HIT_AND_RETURN_LOWER ; == 0, goto.
    LDY HOUSE_OBJ_INDEX_CURRENT ; Load house object.
    LDA OBJ_HOUSE_ATTR_BLINKY?[19],Y ; Load house.
    CMP #$01 ; If _ #$01
    BEQ TEST_UNK_LOWER_BITS ; ==, goto.
    LDA OBJ_SCREEN_POS_X[2],X ; Load pos.
    BPL TEST_UNK_LOWER_BITS ; Positive, goto.
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BNE VAL_NONZERO ; != 0, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$D3 ; If _ #$D3
    BCC VAL_LT_0xD3 ; <, goto.
VAL_NONZERO: ; C:23F6, 0x0023F6
    JSR RETRACT_PTR_B_BY_0x1 ; Do ptr.
    JMP TEST_UNK_LOWER_BITS ; Goto.
VAL_LT_0xD3: ; C:23FC, 0x0023FC
    JSR ADVANCE_PTR_B_BY_0x1 ; Advance.
    JMP TEST_UNK_LOWER_BITS ; Goto.
EXIT_TEST_HIT_AND_RETURN_LOWER: ; C:2402, 0x002402
    JSR SUB_TEST_HIT_UNK_TODO ; Do sub.
TEST_UNK_LOWER_BITS: ; C:2405, 0x002405
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$07 ; Keep lower.
    RTS ; Leave.
GAME_PLAYER_DAY_OF_THE_WEEK: ; C:240A, 0x00240A
    LDA CURRENT_PLAYER_DAY_OF_THE_WEEK ; Load ??
    ASL A ; << 1, *2.
    TAY ; To index.
    LDA DAYS_TEXT_PTR_L,Y ; Load lower.
    PHA ; Save char 1.
    LDA DAYS_TEXT_PTR_H,Y ; Load next to.
    TAY ; Char to Y.
    PLA ; Save char 2.
    JSR TEXT_FROM_PTR_TABLE ; Do.
    .db 60
DAYS_TEXT_PTR_L: ; C:241B, 0x00241B
    LOW(TEXT_MONDAY)
DAYS_TEXT_PTR_H: ; C:241C, 0x00241C
    HIGH(TEXT_MONDAY)
    LOW(TEXT_TUESDAY)
    HIGH(TEXT_TUESDAY)
    LOW(TEXT_WEDNESDAY)
    HIGH(TEXT_WEDNESDAY)
    LOW(TEXT_THURSDAY)
    HIGH(TEXT_THURSDAY)
    LOW(TEXT_FRIDAY)
    HIGH(TEXT_FRIDAY)
    LOW(TEXT_SATURDAY)
    HIGH(TEXT_SATURDAY)
    LOW(TEXT_SUNDAY)
    HIGH(TEXT_SUNDAY)
TEXT_MONDAY: ; C:2429, 0x002429
    .db 4D
    .db 4F
    .db 4E
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_TUESDAY: ; C:2430, 0x002430
    .db 54
    .db 55
    .db 45
    .db 53
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_WEDNESDAY: ; C:2438, 0x002438
    .db 57
    .db 45
    .db 44
    .db 4E
    .db 45
    .db 53
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_THURSDAY: ; C:2442, 0x002442
    .db 54
    .db 48
    .db 55
    .db 52
    .db 53
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_FRIDAY: ; C:244B, 0x00244B
    .db 46
    .db 52
    .db 49
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_SATURDAY: ; C:2452, 0x002452
    .db 53
    .db 41
    .db 54
    .db 55
    .db 52
    .db 44
    .db 41
    .db 59
    .db 00
TEXT_SUNDAY: ; C:245B, 0x00245B
    .db 53
    .db 55
    .db 4E
    .db 44
    .db 41
    .db 59
    .db 00
SCRIPT_CONTROLLER_INPUT_RTN: ; C:2462, 0x002462
    LDY GAME_CURRENT_PLAYER
    BMI CURRENT_PLAYER_IS_ATTRACTION ; Negative, not actual player. Attract mode.
    JSR CTRL_READ_PORT_Y ; Read player's port.
    LDA #$10 ; Test start.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test it.
    BEQ TEST_AB_BUTTONS ; Not pressed, goto.
    LDA APU_STATUS ; Load APU.
    AND #$10 ; Test DMC LC.
    BNE TEST_AB_BUTTONS ; Set, goto.
LOOP_WAIT_FOR_A/B/SEL/START: ; C:2476, 0x002476
    LDY GAME_CURRENT_PLAYER ; Load current.
    JSR CTRL_READ_PORT_Y ; Read CTRL.
    LDA #$F0 ; Test A/B/SEL/START
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
    BEQ LOOP_WAIT_FOR_A/B/SEL/START ; Not pressed, goto.
    RTS ; Leave.
CURRENT_PLAYER_IS_ATTRACTION: ; C:2482, 0x002482
    LDA APU_STATUS ; Load.
    AND #$10 ; Test DMC.
    BNE TEST_AB_BUTTONS ; Is set, goto.
    JSR CTRL_TEST_SELECT/START_BOTH_CONTROLLERS ; Test SEL/Start
    BNE EXIT_ATTRACT_TO_PLAYER_SELECT_SCREEN ; Pressed, goto, leaving.
    LDY #$00 ; P1 seed.
    JSR CTRL_READ_PORT_Y ; Read him.
    LDA #$30 ; Sel/Start
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test them.
    BNE EXIT_ATTRACT_TO_PLAYER_SELECT_SCREEN ; Set, goto.
    LDY #$01 ; P2.
    JSR CTRL_READ_PORT_Y ; Read it.
    LDA #$30 ; Sel/start.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test them.
    BNE EXIT_ATTRACT_TO_PLAYER_SELECT_SCREEN ; Set, goto.
    LDA #$00
    STA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Clear newly pressed.
    LDA OBJECTS_HANDLED_AND_DISPLAYED_FLAG/COUNT? ; Load ??
    AND #$7F ; Keep lower.
    BNE RTS ; != 0, goto.
    LDA #$80
    STA CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Inject A newly pressed.
TEST_AB_BUTTONS: ; C:24B2, 0x0024B2
    LDA #$C0 ; A/B buttons.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test them.
    BEQ RTS ; Not pressed, leave.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Process.
    LOW(PROCESS_PAPER_CREATE)
    HIGH(PROCESS_PAPER_CREATE)
RTS: ; C:24BD, 0x0024BD
    RTS
EXIT_ATTRACT_TO_PLAYER_SELECT_SCREEN: ; C:24BE, 0x0024BE
    JSR SCRIPT_TO_HARDWARE_COPY/??_AND_DESTROY_OBJ ; Hardware to 
    JSR CLEAR_ALL_OBJECTS_USED ; Clear all used.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create new process.
    LOW(SETUP_SELECT_PLAYERS_SCREEN) ; Goto.
    HIGH(SETUP_SELECT_PLAYERS_SCREEN)
    LDX #$F5 ; Fix the stack as this is recursive.
    TXS
    RTS ; Leave.
CTRL_TEST_SELECT/START_BOTH_CONTROLLERS: ; C:24CD, 0x0024CD
    LDY #$00 ; Controller index 0, P1.
    JSR CTRL_READ_PORT_Y
    LDA #$30 ; Buttons to test with bitwise AND. SEL/START.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test with zero flag.
    BNE RTS ; Any set, goto.
    LDY #$01 ; P2.
    JSR CTRL_READ_PORT_Y ; Read.
    LDA #$30 ; Test sel/start.
    BIT CONTROLLER_BUTTONS_NEWLY_PRESSED[2] ; Test.
RTS: ; C:24E1, 0x0024E1
    RTS ; Leave. Return 0/!0 test for buttons.
MOD_PTR_A/B_IF_VAR_SET: ; C:24E2, 0x0024E2
    LDA GAME_VAR_FORWARD_CONTROL_HMM ; Load flag?
    BEQ RTS ; Not set, leave.
MOD_VAR_PAT_A++/B--: ; C:24E6, 0x0024E6
    JSR OBJECT_MOVE_ATTR_A_BY_0x1 ; Mod ptr.
    JSR ADVANCE_PTR_B_BY_0x1
RTS: ; C:24EC, 0x0024EC
    RTS
NEWSPAPER_SCREEN_HELPER: ; C:24ED, 0x0024ED
    LDA #$0E ; File PTR. 0x2E0E
    LDY #$AE
UPLOAD_FILE_SET_PALETTE/GFX_TITLE_SCREEN: ; C:24F1, 0x0024F1
    JSR SETUP_FILE_PROCESS_ENTIRE_SCREEN ; Do.
    LDA #$00 ; GFX Bank.
    JSR SWITCH_GRAPHICS_TO_BANK_INDEXED ; Do.
    JSR MAKE_PPU_PALETTE_UPDATE_FROM_DATA_PAST_JSR ; Do.
    .db 00 ; Index of palette.
    .db 30
    .db 22
    .db 36
    .db 0F
    .db FF ; EOF.
    .db 20
    .db 61 ; $3F61
    .db 82 ; End.
    .db 15 ; Index into.
    .db 0F
    .db 16
    .db 30
    .db FF
    RTS ; Leave.
SELECT_SCREEN_FILE: ; C:250B, 0x00250B
    LDA #$0C ; 0x310C, play select screen bg file.
    LDY #$B1
    JMP UPLOAD_FILE_SET_PALETTE/GFX_TITLE_SCREEN ; Do rtn with ptr.
TEST_HIT_UNK_TODO: ; C:2512, 0x002512
    LDA OBJ_PTR_UNK_B_H[2],X ; Load ??
    BEQ EXIT_RET_CC ; == 0, goto.
    BMI EXIT_RET_CC ; Negative, goto.
    LDA OBJ_PTR_UNK_B_L[2],X ; Load ??
    CMP #$20 ; If _ #$20
    BCS EXIT_RET_CS ; >=, goto.
EXIT_RET_CC: ; C:251E, 0x00251E
    CLC ; Ret CC.
    RTS
EXIT_RET_CS: ; C:2520, 0x002520
    SEC ; Ret CS.
    RTS
SUB_TEST_HIT_UNK_TODO: ; C:2522, 0x002522
    JSR TEST_HIT_UNK_TODO ; Do ??
    BCC RTS ; CC, leave.
    PLA ; Pull RTS.
    PLA
    JMP ONION_PULL_AND_DESTROY_OBJECT ; Goto.
RTS: ; C:252C, 0x00252C
    RTS ; Leave.
ONION_PULL_AND_DESTROY_OBJECT: ; C:252D, 0x00252D
    PLA ; Pull sub addr.
    PLA
    JMP OBJECT_X_ID_DESTROY ; Destroy it.
ENGINE_HELPER_PULL_ADD'L_AND_SUSPEND: ; C:2532, 0x002532
    PLA
    PLA
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    RTS ; Leave.
    INC SND_DF_TODO ; ++
    LDA #$00 ; Clear prep.
    STA APU_SQ2_SWEEP ; Clear them!
    STA APU_SQ2_LTIMER
    LDA #$08
    STA APU_SQ2_LENGTH ; Set length.
    LDA #$B0 ; Load.
    ORA #$0F ; Set lower.
    STA APU_SQ2_CTRL ; Store to CTRL.
    LDY #$00 ; Seed ??
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
LOOP_TO_INDEX: ; C:2553, 0x002553
    CPY #$10 ; If _ #$10
    BNE LOOP_NE_TARGET ; !=, goto.
    DEC SND_DF_TODO ; --
    LDY #$04 ; Seed SQ2.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Clear.
    JSR OBJECT_X_ID_DESTROY ; Destroy us.
    JMP RTS ; Goto leave.
LOOP_NE_TARGET: ; C:2564, 0x002564
    LDA INDEX_LTIMER,Y ; Move indexed to LTIMER.
    STA APU_SQ2_LTIMER
    INY ; Index++
    LDA INDEX_LTIMER,Y ; Load pair.
    ORA #$08 ; Set ??
    INY ; Index++
    STA APU_SQ2_LENGTH ; Store length H.
    LDA #$32 ; Seed timer.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend.
    JMP LOOP_TO_INDEX ; Goto.
RTS: ; C:257C, 0x00257C
    RTS
INDEX_LTIMER: ; C:257D, 0x00257D
    .db 16 ; Data table for SFX.
    .db 01
    .db F8
    .db 00
    .db DD
    .db 00
    .db D0
    .db 00
    .db BA
    .db 00
    .db A5
    .db 00
    .db 93
    .db 00
    .db 8B
    .db 00
HOUSE_SOUND_TODO: ; C:258D, 0x00258D
    INC SND_DF_TODO ; ++
    LDA #$00
    STA APU_SQ2_SWEEP ; Clear sweeps.
    STA APU_SQ1_SWEEP
    STA APU_SQ2_LTIMER ; Clear length L's.
    STA APU_SQ1_LTIMER
    LDA #$08
    STA APU_SQ2_LENGTH ; Set TODO
    STA APU_SQ1_LENGTH
    LDA #$82
    STA APU_SQ2_CTRL ; Set TODO.
    STA APU_SQ1_CTRL
    LDY #$00 ; Init val for Y.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Do it.
LOOP_TO_TARGET: ; C:25B2, 0x0025B2
    CPY #$10 ; If _ #$10
    BNE INDEX_NE_0x10 ; !=, goto.
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    JMP RTS ; Goto RTS.
INDEX_NE_0x10: ; C:25BE, 0x0025BE
    LDA SQ2_LTIMER_DATA,Y ; Move timers.
    STA APU_SQ2_LTIMER
    LDA SQ1_LTIMER_DATA,Y
    STA APU_SQ1_LTIMER
    INY ; Move.
    LDA SQ2_LTIMER_DATA,Y ; Do pair.
    ORA #$08 ; Set ??
    STA APU_SQ2_LENGTH
    LDA SQ1_LTIMER_DATA,Y ; Same.
    ORA #$08
    STA APU_SQ1_LENGTH
    INY ; Data++
    LDA #$03 ; Seed suspend time.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Do helper.
    JMP LOOP_TO_TARGET ; Loop.
RTS: ; C:25E4, 0x0025E4
    RTS ; Leave.
SQ2_LTIMER_DATA: ; C:25E5, 0x0025E5
    .db 39
    .db 01
    .db 16
    .db 01
    .db F8
    .db 00
    .db EB
    .db 00
    .db D0
    .db 00
    .db BA
    .db 00
    .db A5
    .db 00
    .db 9C
    .db 00
SQ1_LTIMER_DATA: ; C:25F5, 0x0025F5
    .db D5
    .db 01
    .db A1
    .db 01
    .db 75
    .db 01
    .db 4B
    .db 01
    .db 39
    .db 01
    .db 16
    .db 01
    .db F8
    .db 00
    .db EB
    .db 00
RTN_SOUND_BAD_BEEP: ; C:2605, 0x002605
    INC SND_DF_TODO ; ++
    LDA #$01
    STA APU_SQ1_LTIMER ; Set timer.
    LDA #$98
    STA APU_SQ1_CTRL ; Set CTRL.
    LDA #$08
    STA SND_D9_TODO ; Set ??
    LDA #$0A
    STA APU_SQ1_LENGTH ; Set length.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    LDA SND_D9_TODO ; Load ??
    BEQ VAL_EQ_0x00 ; == 0, goto.
    DEC SND_D9_TODO ; --
    LDA SND_D9_TODO ; Load ??
    ORA #$90 ; Set 1001.0000
    STA APU_SQ1_CTRL ; Store to CTRL. TODO what do.
    JMP RTS ; Leave.
VAL_EQ_0x00: ; C:262D, 0x00262D
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
RTS: ; C:2632, 0x002632
    RTS ; Leave.
PROCESS_UNK_DELIVERY_B: ; C:2633, 0x002633
    INC SND_DF_TODO ; ++
    LDA #$01
    STA APU_SQ1_LTIMER ; Move timer L.
    LDA #$84
    STA APU_SQ1_CTRL ; Set ??
    LDA #$0A
    STA APU_SQ1_LENGTH ; Set length.
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
SOUND_OVERRIDE_HELPER: ; C:264A, 0x00264A
    STA SOUND_ARG_EXTRA_FILE ; Store arg.
    LDA #$01
    STA SOUND_TRIPLET_IDK[3] ; Set ??
    STA SOUND_TRIPLET_IDK+1
    STA SOUND_TRIPLET_IDK+2
    LDA #$00 ; Val.
    LDY SND_PROCESS_A_OBJ_ID ; Reset all sound timers for processes.
    STA OBJ_ATTR_TIMER[19],Y
    LDY SND_PROCESS_B_OBJ_ID
    STA OBJ_ATTR_TIMER[19],Y
    LDY SND_PROCESS_C_OBJ_ID
    STA OBJ_ATTR_TIMER[19],Y
    RTS ; Leave.
PROCESS_UNK_DELIVERY_A: ; C:2666, 0x002666
    INC SND_DF_TODO ; ++
    LDA #$07 ; Move noise ctrl.
    STA APU_NSE_CTRL
    LDY #$0F ; Seed start val.
    LDA #$08 ; Move length.
    STA APU_NSE_LENGTH
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    STY APU_NSE_LOOP ; Store Y to loop.
    DEY ; --
    BPL RTS ; Positive, leave.
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
RTS: ; C:2682, 0x002682
    RTS ; Leave.
RTN_SOUND_GOOD_BEEP: ; C:2683, 0x002683
    INC SND_DF_TODO ; ++
    LDA #$E0 ; Move timer L.
    STA APU_SQ1_LTIMER
    LDA #$98 ; Move SQ1 CTRL.
    STA APU_SQ1_CTRL
    LDA #$08 ; Move TODO.
    STA SND_D9_TODO
    LDA #$08 ; Move length.
    STA APU_SQ1_LENGTH
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend here.
    LDA SND_D9_TODO ; Load.
    BEQ EXIT_DESTROY ; == 0, goto.
    DEC SND_D9_TODO ; --
    LDA SND_D9_TODO ; Load.
    ORA #$90 ; SXet.
    STA APU_SQ1_CTRL ; Store to SQ1 CTRL.
    JMP RTS ; Leave.
EXIT_DESTROY: ; C:26AB, 0x0026AB
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
RTS: ; C:26B0, 0x0026B0
    RTS ; Leave.
PROCESS_SOUND_UNK: ; C:26B1, 0x0026B1
    INC SND_DF_TODO ; ++
    LDA #$E0 ; Move timer L.
    STA APU_SQ1_LTIMER
    LDA #$84 ; Move SQ1 CTRL.
    STA APU_SQ1_CTRL
    LDA #$08 ; Move SQ1 length.
    STA APU_SQ1_LENGTH
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
PROCESS_UNK_DELIVERY_C_SOUND: ; C:26C8, 0x0026C8
    INC SND_DF_TODO ; ++
    LDA #$00
    STA APU_SQ1_SWEEP ; Clear sweep and timer L.
    STA APU_SQ1_LTIMER
    LDA #$08
    STA APU_SQ1_LENGTH ; Set length.
    LDA #$A0 ; Load ??
    ORA #$0C ; Set ??
    STA APU_SQ1_CTRL ; Store to CTRL.
    LDA #$1E ; Move timer.
    STA OBJ_ATTR_TIMER[19],X
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    JSR COUNTER_DOWN_RET_VAL_UNK ; Load counter.
    LSR A ; >> 2, /4.
    LSR A
    STA APU_SQ1_LTIMER ; Store to SQ1 timer L.
    LDA OBJ_ATTR_TIMER[19],X ; Load our timer.
    BNE RTS ; != 0, goto.
    DEC SND_DF_TODO ; --
    LDY #$00 ; Seed SQ1.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Clear.
    JSR OBJECT_X_ID_DESTROY ; Destroy.
RTS: ; C:26FD, 0x0026FD
    RTS ; Leave.
SOUND_HELPER_CLEAR_SQ1_CTRL+Y: ; C:26FE, 0x0026FE
    LDA #$00
    STA APU_SQ1_CTRL,Y ; Clear Y ctrl.
    RTS ; Leave.
RTN_SOUND_UNK: ; C:2704, 0x002704
    LDA #$1F ; Set noise CTRL.
    STA APU_NSE_CTRL
    LDY #$0F ; Loop.
    STY APU_NSE_LOOP
    LDY #$08 ; Length.
    STY APU_NSE_LENGTH
    LDY #$01 ; Seed ??
    LDA #$3C ; Timer.
    STA OBJ_ATTR_TIMER[19],X ; Store it.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    CPY #$00 ; If _ #$00
    BEQ VAL_EQ_0x00 ; == 0, ,goto.
    LDY #$00 ; Seed val. DEY would make it 0x00 too hmm.
    LDA #$1F ; Noise CTRL.
    JMP NOISE_CTRL_SEEDED_A ; Goto.
VAL_EQ_0x00: ; C:2728, 0x002728
    INY ; Index++
    LDA #$10 ; Load CTRL.
NOISE_CTRL_SEEDED_A: ; C:272B, 0x00272B
    STA APU_NSE_CTRL ; Store CTRL.
    LDA OBJ_ATTR_TIMER[19],X ; Load timer.
    BNE RTS ; != 0, leave.
    LDY #$0C ; Seed channel.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Clear.
    JSR OBJECT_X_ID_DESTROY ; Destroy us.
RTS: ; C:273B, 0x00273B
    RTS ; Leave.
PROCESS_SOUND_TODO: ; C:273C, 0x00273C
    INC SND_DF_TODO ; ++ ??
    LDY #$00 ; Seed ??
    LDA #$A0 ; Move ??
    STA SOUND_STREAM_TODO[2]
    LDA #$A7 ; Move ??
    STA SOUND_STREAM_TODO+1
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Hold.
STREAM_RESET_START_LOOP: ; C:274B, 0x00274B
    LDY #$00 ; Stream index.
    LDA [SOUND_STREAM_TODO[2]],Y ; Load from stream.
    CMP #$FF ; If _ #$FF
    BEQ VAL_EQ_0xFF ; ==, goto.
    LDA [SOUND_STREAM_TODO[2]],Y ; Load from stream.
    BEQ STREAM_EQ_0x00 ; == 0, goto.
    TAX ; To X index.
    LDA #$9C ; Store CTRL.
    STA APU_SQ1_CTRL
    LDA TIMER_L_DATA_SQ1,X ; Move timer L.
    STA APU_SQ1_LTIMER
    JMP SYNC ; Goto.
STREAM_EQ_0x00: ; C:2766, 0x002766
    LDA #$00
    STA APU_SQ1_LTIMER ; Clear timer L.
    LDA #$90
    STA APU_SQ1_CTRL ; Set CTRL.
    LDX #$00 ; Seed data index.
SYNC: ; C:2772, 0x002772
    INY ; Stream++
    LDA [SOUND_STREAM_TODO[2]],Y ; Load from stream.
    ASL A ; >> 4, /8.
    ASL A
    ASL A
    ASL A
    ORA LENGTH_COMBINE_VAL,X ; Set bits.
    STA APU_SQ1_LENGTH ; Store length.
    LDY #$01 ; Stream index.
    LDA [SOUND_STREAM_TODO[2]],Y ; Load from stream.
    TAX ; To X index.
    LDA STREAM_ARRAY_TIMER_ARR,X ; Move timer from stream.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Do wait.
    LDA SOUND_STREAM_TODO[2] ; Load ??
    CLC ; Prep add.
    ADC #$02 ; Add with.
    STA SOUND_STREAM_TODO[2] ; Store back, advance val.
    LDA SOUND_STREAM_TODO+1 ; Ptr H.
    ADC #$00
    STA SOUND_STREAM_TODO+1 ; Store adjusted.
    JMP STREAM_RESET_START_LOOP ; Restart.
VAL_EQ_0xFF: ; C:279A, 0x00279A
    DEC SND_DF_TODO ; --
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
    .db 3A
    .db 01
    .db 3A
    .db 00
    .db 4B
    .db 00
    .db 48
    .db 00
    .db 45
    .db 00
    .db 48
    .db 00
    .db 42
    .db 00
    .db FF
    .db 00
SOUND_NOISE_SFX_IDK_WHICH: ; C:27B0, 0x0027B0
    LDA #$17
    STA APU_NSE_CTRL ; Store noise CTRL.
    LDY #$05 ; Seed count.
    JSR ENGINE_OBJECT_SUSPEND_IN_PLACE ; Suspend.
    STY APU_NSE_LOOP ; Store noise loop.
    LDA #$78
    STA APU_NSE_LENGTH ; Set length.
    DEY ; Y--
    BPL VAL_POSITIVE ; Positive, leave.
    JSR OBJECT_X_ID_DESTROY ; Destroy us.
VAL_POSITIVE: ; C:27C8, 0x0027C8
    RTS ; Leave.
SOUND_RELATED_INIT?: ; C:27C9, 0x0027C9
    STA SOUND_ARG_EXTRA_FILE ; Store arg.
    LDA #$00
    STA SND_DF_TODO ; Clear ??
    LDA #$00
    STA SOUND_TRIPLET_IDK[3] ; Clear ??
    STA SOUND_TRIPLET_IDK+1
    STA SOUND_TRIPLET_IDK+2
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create PTR past.
    LOW(SOUND_RELATED_PROCESS_A)
    HIGH(SOUND_RELATED_PROCESS_A)
    STA SND_PROCESS_A_OBJ_ID ; Store process ID.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create process.
    LOW(SOUND_RELATED_PROCESS_B)
    HIGH(SOUND_RELATED_PROCESS_B)
    STA SND_PROCESS_B_OBJ_ID ; Store process ID.
    JSR CREATE_PROCESS_WITH_PTR_PAST ; Create it.
    LOW(SOUND_RELATED_PROCESS_C)
    HIGH(SOUND_RELATED_PROCESS_C)
    STA SND_PROCESS_C_OBJ_ID ; Store ID.
    RTS ; Leave.
SOUND_FILES_L: ; C:27ED, 0x0027ED
    .db 56
SOUND_FILES_H: ; C:27EE, 0x0027EE
    .db AA
    .db 1C
    .db AC
    .db 28
    .db AC
    .db B6
    .db AD
DATA_INDEX_FIRE_IDK: ; C:27F5, 0x0027F5
    .db E0
DATA_INDEX_FIRE_PAIR: ; C:27F6, 0x0027F6
    .db AA
    .db 9C
    .db AC
    .db A8
    .db AC
    .db CE
    .db AD
FPTR_EXTRA_ARR_L: ; C:27FD, 0x0027FD
    LOW(EFILE_A)
FPTR_EXTRA_ARR_H: ; C:27FE, 0x0027FE
    HIGH(EFILE_A)
    LOW(EFILE_B)
    HIGH(EFILE_B)
    LOW(EFILE_C)
    HIGH(EFILE_C)
    .db D8
    LDA ROM_DATA_0xFD ; Load data.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA SOUND_FILES_L,Y ; Move sound files.
    STA SOUND_FILE_STREAM_BASED[2]
    LDA SOUND_FILES_H,Y ; Load files H.
    BEQ HIGH_EQ_0x00/STREAM_EQ_0xFF ; == 0, goto.
    STA SOUND_FILE_STREAM_BASED+1 ; Store H, valid.
    LDA #$00
    STA SOUND_TRIPLET_IDK[3] ; Clear ??
SYNC: ; C:2819, 0x002819
    LDY #$00 ; TAY would have been nice.
    LDA SOUND_TRIPLET_IDK[3] ; Load triplet.
    BNE SOUND_RELATED_PROCESS_A ; != 0, goto.
    LDA [SOUND_FILE_STREAM_BASED[2]],Y ; Load from file.
    CMP #$FF ; If _ #$FF
    BEQ SOUND_RELATED_PROCESS_A ; == 0, goto.
    LDA SND_DF_TODO ; Load ??
    BNE DF_NONZERO ; != 0, goto.
    LDA APU_STATUS ; Load status.
    AND #$10 ; Keep ??
    BNE DF_NONZERO ; Nonzero, goto.
    LDA [SOUND_FILE_STREAM_BASED[2]],Y ; Load file.
    BEQ FILE_EQ_0x00 ; == 0, goto.
    LDX #$01
    STX SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL ; Set ??
    ASL A ; << 1, *2.
    BCC SHIFT_CLEAR ; Clear, goto.
    LDX #$02
    STX SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL ; Set ??
SHIFT_CLEAR: ; C:283F, 0x00283F
    TAX ; To X index.
    LDA #$90 ; Seed ??
    ORA SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL ; Combine with.
    STA APU_SQ1_CTRL ; Store to.
    LDA TIMER_L_DATA_SQ1,X ; Move timer L.
    STA APU_SQ1_LTIMER ; Store to timer L.
    JMP SYNC ; Goto.
FILE_EQ_0x00: ; C:2850, 0x002850
    LDA #$00 ; Move SQ1 timer L.
    STA APU_SQ1_LTIMER
    LDA #$90 ; Set CTRL.
    STA APU_SQ1_CTRL
    LDX #$00 ; Seed ??
SYNC: ; C:285C, 0x00285C
    INY ; Stream++
    LDA [SOUND_FILE_STREAM_BASED[2]],Y ; Load from stream.
    CMP #$FF ; If _ #$FF
    BEQ HIGH_EQ_0x00/STREAM_EQ_0xFF ; ==, goto.
    ASL A ; << 4, *16.
    ASL A
    ASL A
    ASL A
    ORA LENGTH_COMBINE_VAL,X ; Set with X index.
    STA APU_SQ1_LENGTH ; Store to length.
DF_NONZERO: ; C:286D, 0x00286D
    LDY #$01 ; Stream index.
    LDA [SOUND_FILE_STREAM_BASED[2]],Y ; Load from file.
    CMP #$FF ; If _ #$FF
    BEQ HIGH_EQ_0x00/STREAM_EQ_0xFF ; == 0, goto.
    TAX ; To X.
    LDA STREAM_ARRAY_TIMER_ARR,X ; Load data.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Set timer with.
    LDA SOUND_FILE_STREAM_BASED[2] ; Ptr += 0x2
    CLC
    ADC #$02
    STA SOUND_FILE_STREAM_BASED[2]
    LDA SOUND_FILE_STREAM_BASED+1
    ADC #$00
    STA SOUND_FILE_STREAM_BASED+1
    JMP SYNC ; Goto.
HIGH_EQ_0x00/STREAM_EQ_0xFF: ; C:288C, 0x00288C
    LDY #$00 ; Seed SQ1.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Goto.
    LDX CURRENT_OBJ_PROCESSING ; Load processing ID.
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
SOUND_RELATED_PROCESS_B: ; C:2897, 0x002897
    LDA SOUND_ARG_EXTRA_FILE ; Load sound arg.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA DATA_INDEX_FIRE_IDK,Y ; Move ??
    STA SOUND_FIRE_B[2]
    LDA DATA_INDEX_FIRE_PAIR,Y ; Load ??
    BEQ VAL_EQ_0x00 ; == 0, goto.
    STA SOUND_FIRE_B+1 ; Store to var.
    LDA #$00
    STA SOUND_TRIPLET_IDK+1 ; Clear ??
LOOP_STREAM_RESET: ; C:28AB, 0x0028AB
    LDY #$00 ; Stream index.
    LDA SOUND_TRIPLET_IDK+1 ; Load ??
    BNE SOUND_RELATED_PROCESS_B ; != 0, goto.
    LDA [SOUND_FIRE_B[2]],Y ; Load file.
    CMP #$FF ; If _ #$FF
    BEQ SOUND_RELATED_PROCESS_B ; == 0, goto.
    LDA SND_DF_TODO ; Load ??
    BNE FILE_ALT_ALT ; != 0, goto.
    LDA APU_STATUS ; Load status.
    AND #$10 ; Get bit.
    BNE FILE_ALT_ALT ; != 0, goto.
    LDA [SOUND_FIRE_B[2]],Y ; Load.
    BEQ VAL_EQ_0x00 ; == 0, goto.
    LDX #$01 ; Load ??
    STX SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL ; Store index.
    ASL A ; << 1, *2.
    BCC SHIFT_CLEAR ; << 1, *2.
    LDX #$02 ; Seed combine.
    STX SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL
SHIFT_CLEAR: ; C:28D1, 0x0028D1
    TAX ; To X.
    LDA #$90 ; CTRL base.
    ORA SOUND_DA_SQ1_CTRL_GLOBAL_COMBINE_VAL ; Combine.
    STA APU_SQ2_CTRL ; Store ctrl.
    LDA TIMER_L_DATA_SQ1,X ; Load timer.
    STA APU_SQ2_LTIMER ; Store to SQ2 timer L.
    JMP SYNC ; Goto.
VAL_EQ_0x00: ; C:28E2, 0x0028E2
    LDA #$00
    STA APU_SQ2_LTIMER ; Clear timer L.
    LDA #$90
    STA APU_SQ2_CTRL ; Set CTRL.
    LDX #$00 ; Load index.
SYNC: ; C:28EE, 0x0028EE
    INY ; Stream++
    LDA [SOUND_FIRE_B[2]],Y ; Load from stream.
    CMP #$FF ; If _ #$FF
    BEQ VAL_EQ_0x00 ; == 0, goto.
    ASL A ; << 4, *16.
    ASL A
    ASL A
    ASL A
    ORA LENGTH_COMBINE_VAL,X ; Combine with.
    STA APU_SQ2_LENGTH ; Store to length.
FILE_ALT_ALT: ; C:28FF, 0x0028FF
    LDY #$01 ; Stream index.
    LDA [SOUND_FIRE_B[2]],Y ; Load from stream.
    CMP #$FF ; If _ #$FF
    BEQ VAL_EQ_0x00 ; == 0, goto.
    TAX ; To X.
    LDA STREAM_ARRAY_TIMER_ARR,X ; Load from arr.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend timer.
    LDA SOUND_FIRE_B[2] ; Ptr += 0x2
    CLC
    ADC #$02
    STA SOUND_FIRE_B[2]
    LDA SOUND_FIRE_B+1
    ADC #$00
    STA SOUND_FIRE_B+1
    JMP LOOP_STREAM_RESET ; Goto.
VAL_EQ_0x00: ; C:291E, 0x00291E
    LDY #$04 ; Seed SQ2.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Clear CTRL.
    LDX CURRENT_OBJ_PROCESSING ; Process ID.
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
SOUND_RELATED_PROCESS_C: ; C:2929, 0x002929
    LDA SOUND_ARG_EXTRA_FILE ; Load sound arg.
    ASL A ; << 2, *2.
    TAY ; To Y index.
    LDA FPTR_EXTRA_ARR_L,Y ; Move FPTR.
    STA EXTRA_FILE_POINTER_RAM[2]
    LDA FPTR_EXTRA_ARR_H,Y ; Load H.
    BEQ VAL_EQ_0x00 ; == 0, goto.
    STA EXTRA_FILE_POINTER_RAM+1 ; Store H.
    LDA SOUND_ARG_EXTRA_FILE ; Load arg.
    CMP #$01 ; If _ #$01
    BNE VAL_NE_0x1 ; !=, goto.
    INC SOUND_ARG_EXTRA_FILE ; ++
VAL_NE_0x1: ; C:2941, 0x002941
    LDA #$00
    STA SOUND_TRIPLET_IDK+2 ; Clear ??
LOOP_STREAM_CLEAR: ; C:2945, 0x002945
    LDY #$00 ; Stream reset.
    LDA SOUND_TRIPLET_IDK+2 ; Load.
    BNE SOUND_RELATED_PROCESS_C ; !=, goto.
    LDA [EXTRA_FILE_POINTER_RAM[2]],Y ; Load from file.
    CMP #$FF ; If _ #$FF
    BEQ SOUND_RELATED_PROCESS_C ; == 0, goto.
    LDA SND_DF_TODO ; Load ??
    BNE VAL_NE_0x1 ; !=, goto.
    LDA APU_STATUS ; Load status.
    AND #$10 ; Test bit.
    BNE VAL_NE_0x1 ; Set, goto.
    LDA [EXTRA_FILE_POINTER_RAM[2]],Y ; Load from stream.
    BEQ STREAM_EQ_0x00 ; == 0, goto.
    ASL A ; << 1, *2.
    TAY ; To Y index.
    LDA TIMER_L_DATA_SQ1,Y ; Move timer L.
    STA APU_TRI_LTIMER
    LDA LENGTH_COMBINE_VAL,Y ; Length combine from stream index.
    ORA #$08 ; Set ??
    STA APU_TRI_LENGTH ; Set length tri.
    LDY #$01 ; Stream index.
    LDA [EXTRA_FILE_POINTER_RAM[2]],Y ; Load from file.
    TAX ; To X.
    LDA STREAM_ARRAY_TIMER_ARR,X ; Load from arr on X.
    ASL A ; << 1, *2.
    STA APU_TRI_CTRL ; Store to.
    JMP VAL_NE_0x1 ; Goto.
STREAM_EQ_0x00: ; C:297F, 0x00297F
    LDA #$00 ; Clear.
    STA APU_TRI_CTRL ; Store.
VAL_NE_0x1: ; C:2984, 0x002984
    LDY #$01 ; Stream reset.
    LDA [EXTRA_FILE_POINTER_RAM[2]],Y ; Load from stream.
    CMP #$FF ; If _ #$FF
    BEQ VAL_EQ_0x00 ; == 0, goto.
    TAX ; To X index.
    LDA STREAM_ARRAY_TIMER_ARR,X ; Load from arr time to wait.
    JSR SUSPEND_OBJ_TIMER/FLAG_HELPER ; Suspend.
    LDA EXTRA_FILE_POINTER_RAM[2] ; Ptr += 0x2
    CLC
    ADC #$02
    STA EXTRA_FILE_POINTER_RAM[2]
    LDA EXTRA_FILE_POINTER_RAM+1
    ADC #$00
    STA EXTRA_FILE_POINTER_RAM+1
    JMP LOOP_STREAM_CLEAR ; Loop.
VAL_EQ_0x00: ; C:29A3, 0x0029A3
    LDY #$08 ; Channel CTRL Index.
    JSR SOUND_HELPER_CLEAR_SQ1_CTRL+Y ; Clear.
    JSR OBJECT_X_ID_DESTROY ; Destroy.
    RTS ; Leave.
TIMER_L_DATA_SQ1: ; C:29AC, 0x0029AC
    .db 00
LENGTH_COMBINE_VAL: ; C:29AD, 0x0029AD
    .db 00
    .db 59
    .db 04
    .db 1A
    .db 04
    .db 0C
    .db 04
    .db E2
    .db 03
    .db D5
    .db 03
    .db B0
    .db 03
    .db 99
    .db 03
    .db 78
    .db 03
    .db 46
    .db 03
    .db 19
    .db 03
    .db 11
    .db 03
    .db E2
    .db 02
    .db C6
    .db 02
    .db B9
    .db 02
    .db 9A
    .db 02
    .db 94
    .db 02
    .db 7D
    .db 02
    .db 73
    .db 02
    .db 50
    .db 02
    .db 2D
    .db 02
    .db 0D
    .db 02
    .db 09
    .db 02
    .db F4
    .db 01
    .db E7
    .db 01
    .db DB
    .db 01
    .db CF
    .db 01
    .db BF
    .db 01
    .db A3
    .db 01
    .db 8D
    .db 01
    .db 88
    .db 01
    .db 73
    .db 01
    .db 65
    .db 01
    .db 5C
    .db 01
    .db 4E
    .db 01
    .db 4A
    .db 01
    .db 3F
    .db 01
    .db 39
    .db 01
    .db 29
    .db 01
    .db 16
    .db 01
    .db 08
    .db 01
    .db 05
    .db 01
    .db FA
    .db 00
    .db F5
    .db 00
    .db ED
    .db 00
    .db E8
    .db 00
    .db DF
    .db 00
    .db D1
    .db 00
    .db C6
    .db 00
    .db C4
    .db 00
    .db BA
    .db 00
    .db B2
    .db 00
    .db AE
    .db 00
    .db A7
    .db 00
    .db A5
    .db 00
    .db 9F
    .db 00
    .db 9D
    .db 00
    .db 95
    .db 00
    .db 8B
    .db 00
    .db 84
    .db 00
    .db 82
    .db 00
    .db 7D
    .db 00
    .db 7A
    .db 00
    .db 77
    .db 00
    .db 74
    .db 00
    .db 6F
    .db 00
    .db 68
    .db 00
    .db 63
    .db 00
    .db 62
    .db 00
    .db 5D
    .db 00
    .db 59
    .db 00
    .db 57
    .db 00
    .db 53
    .db 00
    .db 52
    .db 00
    .db 50
    .db 00
    .db 4E
    .db 00
    .db 4A
    .db 00
STREAM_ARRAY_TIMER_ARR: ; C:2A46, 0x002A46
    .db 06
    .db 0C
    .db 18
    .db 30
    .db 60
    .db 24
    .db 09
    .db 12
    .db 07
    .db 0E
    .db 1C
    .db 38
    .db 70
    .db 2A
    .db 0A
    .db 15
    .db 00
    .db 0A
    .db 38
    .db 09
    .db 3A
    .db 09
    .db 3D
    .db 0F
    .db 3A
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 2D
    .db 09
    .db 2F
    .db 09
    .db 32
    .db 09
    .db 31
    .db 08
    .db 2F
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 38
    .db 09
    .db 3A
    .db 09
    .db 3D
    .db 0F
    .db 3A
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 2D
    .db 09
    .db 2F
    .db 09
    .db 32
    .db 09
    .db 31
    .db 08
    .db 2F
    .db 08
    .db 00
    .db 09
    .db 32
    .db 09
    .db 2F
    .db 0F
    .db 32
    .db 0F
    .db 2D
    .db 0D
    .db 00
    .db 0A
    .db 32
    .db 0F
    .db 35
    .db 0F
    .db 2F
    .db 0D
    .db 00
    .db 0A
    .db 2F
    .db 0F
    .db 32
    .db 0F
    .db 2D
    .db 0D
    .db 00
    .db 0A
    .db 32
    .db 0A
    .db 35
    .db 0A
    .db 38
    .db 0A
    .db 39
    .db 0A
    .db 00
    .db 0A
    .db 35
    .db 09
    .db 39
    .db 09
    .db 3A
    .db 0F
    .db 39
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 2A
    .db 09
    .db 2E
    .db 09
    .db 2F
    .db 09
    .db 2E
    .db 08
    .db 2A
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 35
    .db 09
    .db 39
    .db 09
    .db 3A
    .db 0F
    .db 39
    .db 08
    .db 00
    .db 0A
    .db 3A
    .db 0A
    .db 39
    .db 09
    .db 00
    .db 09
    .db 39
    .db 0A
    .db 38
    .db 09
    .db 00
    .db 09
    .db FF
    .db 00
    .db 00
    .db 0A
    .db 2A
    .db 09
    .db 2E
    .db 09
    .db 2F
    .db 0F
    .db 2E
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 1F
    .db 09
    .db 22
    .db 09
    .db 25
    .db 09
    .db 25
    .db 08
    .db 22
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 2A
    .db 09
    .db 2E
    .db 09
    .db 2F
    .db 0F
    .db 2E
    .db 00
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 1F
    .db 09
    .db 22
    .db 09
    .db 25
    .db 09
    .db 25
    .db 08
    .db 22
    .db 08
    .db 00
    .db 0A
    .db 21
    .db 0F
    .db 21
    .db 0F
    .db 1F
    .db 0D
    .db 00
    .db 0A
    .db 25
    .db 0F
    .db 25
    .db 0F
    .db 22
    .db 0D
    .db 00
    .db 0A
    .db 21
    .db 0F
    .db 21
    .db 0F
    .db 1F
    .db 0D
    .db 00
    .db 0A
    .db 25
    .db 0A
    .db 27
    .db 0A
    .db 29
    .db 0A
    .db 2A
    .db 0A
    .db 00
    .db 0A
    .db 27
    .db 09
    .db 2A
    .db 09
    .db 2E
    .db 0F
    .db 2A
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 1C
    .db 09
    .db 1F
    .db 09
    .db 22
    .db 09
    .db 1F
    .db 08
    .db 1C
    .db 08
    .db 00
    .db 0A
    .db 00
    .db 0A
    .db 27
    .db 09
    .db 2A
    .db 09
    .db 2E
    .db 0F
    .db 2A
    .db 08
    .db 00
    .db 0A
    .db 2F
    .db 0A
    .db 2F
    .db 09
    .db 00
    .db 09
    .db 2E
    .db 0A
    .db 2E
    .db 09
    .db 00
    .db 09
    .db FF
    .db 00
EFILE_A: ; C:2B68, 0x002B68
    .db 14
    .db 08
    .db 14
    .db 08
    .db 00
    .db 0A
    .db 1F
    .db 09
    .db 25
    .db 0F
    .db 25
    .db 09
    .db 25
    .db 08
    .db 1F
    .db 09
    .db 1C
    .db 08
    .db 1C
    .db 08
    .db 00
    .db 0A
    .db 1A
    .db 09
    .db 1C
    .db 08
    .db 1C
    .db 09
    .db 1C
    .db 09
    .db 1F
    .db 08
    .db 1A
    .db 09
    .db 14
    .db 08
    .db 14
    .db 08
    .db 00
    .db 0A
    .db 1F
    .db 09
    .db 25
    .db 0F
    .db 25
    .db 09
    .db 25
    .db 08
    .db 1F
    .db 09
    .db 1C
    .db 08
    .db 1C
    .db 08
    .db 00
    .db 0A
    .db 1A
    .db 09
    .db 1C
    .db 08
    .db 1C
    .db 09
    .db 1C
    .db 09
    .db 1C
    .db 08
    .db 1B
    .db 09
    .db 1A
    .db 0A
    .db 00
    .db 09
    .db 25
    .db 09
    .db 27
    .db 0F
    .db 27
    .db 09
    .db 27
    .db 08
    .db 25
    .db 09
    .db 1C
    .db 0A
    .db 00
    .db 09
    .db 27
    .db 09
    .db 2D
    .db 08
    .db 2D
    .db 09
    .db 2D
    .db 09
    .db 2D
    .db 08
    .db 27
    .db 09
    .db 1A
    .db 0A
    .db 00
    .db 09
    .db 25
    .db 09
    .db 27
    .db 0F
    .db 27
    .db 09
    .db 27
    .db 08
    .db 25
    .db 09
    .db 1C
    .db 0A
    .db 1F
    .db 0A
    .db 21
    .db 0A
    .db 22
    .db 0A
    .db 17
    .db 08
    .db 17
    .db 08
    .db 00
    .db 0A
    .db 22
    .db 09
    .db 27
    .db 0F
    .db 27
    .db 09
    .db 27
    .db 08
    .db 22
    .db 09
    .db 1F
    .db 08
    .db 1F
    .db 08
    .db 00
    .db 0A
    .db 1C
    .db 09
    .db 1F
    .db 08
    .db 1F
    .db 09
    .db 1F
    .db 09
    .db 22
    .db 08
    .db 1C
    .db 09
    .db 17
    .db 08
    .db 17
    .db 08
    .db 00
    .db 0A
    .db 22
    .db 09
    .db 27
    .db 0F
    .db 27
    .db 09
    .db 27
    .db 08
    .db 22
    .db 09
    .db 1F
    .db 0A
    .db 1F
    .db 0A
    .db 16
    .db 0A
    .db 1E
    .db 0A
    .db FF
    .db 00
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db FF
    .db 00
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 30
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 33
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 30
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 2E
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 2E
    .db 01
    .db 2A
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2F
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2F
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2A
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2F
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2F
    .db 01
    .db 28
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 30
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 33
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 30
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 2E
    .db 01
    .db 22
    .db 01
    .db 2A
    .db 01
    .db 2E
    .db 01
    .db 2A
    .db 01
    .db 20
    .db 01
    .db 28
    .db 01
    .db 2F
    .db 01
    .db 28
    .db 01
    .db 24
    .db 05
    .db 28
    .db 05
    .db 2C
    .db 05
    .db 2F
    .db 05
    .db 30
    .db 03
    .db FF
    .db 00
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 03
    .db FF
    .db 00
    .db 30
    .db 01
    .db 00
    .db 01
    .db 33
    .db 01
    .db 00
    .db 02
    .db 30
    .db 01
    .db 00
    .db 01
    .db 33
    .db 01
    .db 00
    .db 02
    .db 00
    .db 01
    .db 30
    .db 01
    .db 33
    .db 01
    .db 33
    .db 01
    .db 30
    .db 01
    .db 00
    .db 01
    .db 2F
    .db 01
    .db 00
    .db 01
    .db 32
    .db 01
    .db 00
    .db 02
    .db 2F
    .db 01
    .db 00
    .db 01
    .db 32
    .db 01
    .db 00
    .db 02
    .db 00
    .db 01
    .db 2F
    .db 01
    .db 32
    .db 01
    .db 32
    .db 01
    .db 2F
    .db 01
    .db 00
    .db 01
    .db 35
    .db 01
    .db 00
    .db 01
    .db 39
    .db 01
    .db 00
    .db 02
    .db 35
    .db 01
    .db 00
    .db 01
    .db 39
    .db 01
    .db 00
    .db 02
    .db 00
    .db 01
    .db 35
    .db 01
    .db 39
    .db 01
    .db 39
    .db 01
    .db 35
    .db 01
    .db 00
    .db 01
    .db 00
    .db 03
    .db 2A
    .db 05
    .db 2F
    .db 05
    .db 30
    .db 05
    .db 33
    .db 05
    .db 37
    .db 02
    .db 3A
    .db 02
    .db FF
    .db 00
EFILE_B: ; C:2D0C, 0x002D0C
    .db 00
    .db 02
    .db 26
    .db 00
    .db 26
    .db 00
    .db 26
    .db 00
    .db 26
    .db 00
    .db 1B
    .db 00
    .db 1B
    .db 00
    .db 1B
    .db 00
    .db 1B
    .db 00
    .db 13
    .db 00
    .db 13
    .db 00
    .db 13
    .db 00
    .db 13
    .db 00
    .db 0A
    .db 01
    .db 0D
    .db 01
    .db 0D
    .db 01
    .db 0D
    .db 01
    .db 0F
    .db 01
    .db 13
    .db 01
    .db 13
    .db 01
    .db 13
    .db 01
    .db 0F
    .db 01
    .db 13
    .db 01
    .db 13
    .db 01
    .db 13
    .db 01
    .db FF
    .db 00
EFILE_C: ; C:2D40, 0x002D40
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 11
    .db 01
    .db 24
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 17
    .db 01
    .db 2A
    .db 01
    .db 11
    .db 01
    .db 11
    .db 01
    .db 11
    .db 01
    .db 11
    .db 01
    .db 19
    .db 05
    .db 1C
    .db 05
    .db 1D
    .db 05
    .db 20
    .db 05
    .db 24
    .db 02
    .db 28
    .db 02
    .db FF
    .db 00
    .db 00
    .db 02
    .db 27
    .db 01
    .db 38
    .db 01
    .db 35
    .db 01
    .db 32
    .db 01
    .db 35
    .db 01
    .db 38
    .db 01
    .db 3A
    .db 01
    .db 32
    .db 01
    .db 2F
    .db 01
    .db 2F
    .db 01
    .db 00
    .db FF
    .db 00
    .db 02
    .db 00
    .db 03
    .db 00
    .db 03
    .db 00
    .db 02
    .db 00
    .db FF
    .db 00
    .db 02
    .db 14
    .db 00
    .db 25
    .db 00
    .db 14
    .db 00
    .db 22
    .db 00
    .db 14
    .db 00
    .db 1F
    .db 00
    .db 14
    .db 00
    .db 22
    .db 00
    .db 14
    .db 00
    .db 25
    .db 00
    .db 14
    .db 00
    .db 02
    .db 00
    .db 14
    .db 00
    .db 1B
    .db 00
    .db 14
    .db 00
    .db 02
    .db 00
    .db 00
    .db 01
    .db 00
    .db 01
    .db 00
    .db FF
DATA_ADDR_UNK: ; C:2E00, 0x002E00
    .db 02
    .db 01
    .db 00
    .db 12
    .db 13
DATA_ARR_UNK: ; C:2E05, 0x002E05
    .db 01
    .db 01
    .db 00
    .db 14
DATA_UNK: ; C:2E09, 0x002E09
    .db 02
    .db 01
    .db 01
    .db 15
    .db 16
SCREEN_FILE_TITLE: ; C:2E0E, 0x002E0E
    .db 62
    .db 00
    .db 9E
    .db 3B
    .db 3C
    .db 3D
    .db 3E
    .db 3F
    .db 40
    .db 00
    .db 41
    .db 42
    .db 43
    .db 44
    .db 45
    .db 46
    .db 47
    .db 48
    .db 49
    .db 4A
    .db 4B
    .db 4C
    .db 4D
    .db 4E
    .db 4F
    .db 00
    .db 50
    .db 51
    .db 52
    .db 53
    .db 54
    .db 53
    .db 55
    .db 09
    .db 00
    .db 8F
    .db 56
    .db 57
    .db 58
    .db 59
    .db 5A
    .db 5B
    .db 5C
    .db 5D
    .db 5E
    .db 5F
    .db 60
    .db 61
    .db 62
    .db 63
    .db 64
    .db 0A
    .db 00
    .db 86
    .db 3B
    .db 3C
    .db 3D
    .db 3E
    .db 3F
    .db 40
    .db 11
    .db 00
    .db 85
    .db 65
    .db 54
    .db 53
    .db 66
    .db 67
    .db 03
    .db 00
    .db 1F
    .db 68
    .db 48
    .db 00
    .db 82
    .db 69
    .db 6A
    .db 09
    .db 6B
    .db 82
    .db 6C
    .db 6A
    .db 0A
    .db 6B
    .db 03
    .db 00
    .db 86
    .db 6D
    .db 66
    .db 52
    .db 53
    .db 6E
    .db 00
    .db 02
    .db 6F
    .db 09
    .db 00
    .db 02
    .db 6F
    .db 8A
    .db 50
    .db 70
    .db 6E
    .db 71
    .db 6D
    .db 52
    .db 54
    .db 51
    .db 72
    .db 6E
    .db 03
    .db 00
    .db 88
    .db 73
    .db 51
    .db 53
    .db 51
    .db 52
    .db 6E
    .db 74
    .db 6F
    .db 02
    .db 00
    .db 85
    .db 75
    .db 76
    .db 77
    .db 78
    .db 79
    .db 02
    .db 00
    .db 02
    .db 6F
    .db 89
    .db 7A
    .db 66
    .db 53
    .db 7B
    .db 66
    .db 67
    .db 54
    .db 6E
    .db 50
    .db 04
    .db 00
    .db 83
    .db 7C
    .db 54
    .db 55
    .db 03
    .db 00
    .db 02
    .db 6F
    .db 8D
    .db 00
    .db 7D
    .db 7E
    .db 7F
    .db 80
    .db 81
    .db 82
    .db 83
    .db 84
    .db 85
    .db 6F
    .db 7C
    .db 66
    .db 02
    .db 65
    .db 83
    .db 67
    .db 6D
    .db 6E
    .db 06
    .db 00
    .db 86
    .db 7C
    .db 72
    .db 86
    .db 87
    .db 6E
    .db 88
    .db 02
    .db 6F
    .db 91
    .db 00
    .db 89
    .db 8A
    .db 8B
    .db 8C
    .db 8D
    .db 8E
    .db 8F
    .db 90
    .db 91
    .db 6F
    .db 92
    .db 51
    .db 67
    .db 54
    .db 86
    .db 6D
    .db 08
    .db 00
    .db 83
    .db 93
    .db 94
    .db 00
    .db 02
    .db 93
    .db 02
    .db 6F
    .db 89
    .db 00
    .db 95
    .db 96
    .db 97
    .db 98
    .db 99
    .db 9A
    .db 9B
    .db 9C
    .db 02
    .db 6F
    .db 82
    .db 93
    .db 00
    .db 02
    .db 93
    .db 81
    .db 00
    .db 04
    .db 93
    .db 04
    .db 00
    .db 04
    .db 93
    .db 82
    .db 00
    .db 9D
    .db 02
    .db 6F
    .db 89
    .db 9E
    .db 9F
    .db A0
    .db A1
    .db A2
    .db A3
    .db A4
    .db A5
    .db A6
    .db 02
    .db 6F
    .db 02
    .db 9D
    .db 81
    .db 93
    .db 02
    .db 00
    .db 83
    .db 9D
    .db 00
    .db 9D
    .db 02
    .db 93
    .db 09
    .db 00
    .db 02
    .db 6F
    .db 8F
    .db A7
    .db A8
    .db A9
    .db AA
    .db AB
    .db AC
    .db AD
    .db AE
    .db AF
    .db B0
    .db 6F
    .db 93
    .db 00
    .db 9D
    .db 93
    .db 0A
    .db 00
    .db 85
    .db 93
    .db 9D
    .db 93
    .db 00
    .db 9D
    .db 02
    .db 6F
    .db 02
    .db 00
    .db 8A
    .db B1
    .db B2
    .db B3
    .db B4
    .db B5
    .db B6
    .db B7
    .db B8
    .db 6F
    .db 00
    .db 02
    .db 93
    .db 81
    .db 9D
    .db 02
    .db 00
    .db 83
    .db 93
    .db 9D
    .db 93
    .db 04
    .db 00
    .db 84
    .db 9D
    .db 93
    .db 9D
    .db 00
    .db 02
    .db 93
    .db 02
    .db 6F
    .db 8B
    .db 00
    .db B9
    .db BA
    .db BB
    .db BC
    .db BD
    .db BE
    .db BF
    .db C0
    .db C1
    .db 6F
    .db 05
    .db 00
    .db 85
    .db 9D
    .db 93
    .db 9D
    .db 00
    .db 93
    .db 03
    .db 00
    .db 02
    .db 9D
    .db 82
    .db 93
    .db 00
    .db 02
    .db 9D
    .db 92
    .db 6F
    .db C2
    .db C3
    .db C4
    .db C5
    .db C6
    .db C7
    .db C8
    .db C9
    .db CA
    .db CB
    .db CC
    .db 6F
    .db 93
    .db 00
    .db 9D
    .db 93
    .db 00
    .db 02
    .db 9D
    .db 83
    .db 93
    .db 00
    .db 9D
    .db 03
    .db 00
    .db 06
    .db 68
    .db 84
    .db 6F
    .db 00
    .db 93
    .db 00
    .db 04
    .db 93
    .db 85
    .db 00
    .db CD
    .db 9D
    .db 00
    .db 6F
    .db 02
    .db 93
    .db 81
    .db 9D
    .db 02
    .db 00
    .db 83
    .db 93
    .db 9D
    .db 00
    .db 02
    .db 93
    .db 03
    .db 00
    .db 82
    .db 93
    .db 9D
    .db 04
    .db 93
    .db 82
    .db 6F
    .db 00
    .db 02
    .db 93
    .db 81
    .db 9D
    .db 02
    .db 00
    .db 83
    .db 93
    .db 9D
    .db 6A
    .db 02
    .db 6B
    .db 81
    .db CE
    .db 0A
    .db 6B
    .db 04
    .db 00
    .db 86
    .db 93
    .db 00
    .db 93
    .db 6A
    .db 6B
    .db CF
    .db 08
    .db 6B
    .db 8E
    .db D0
    .db 73
    .db 6D
    .db 52
    .db 51
    .db 00
    .db 92
    .db 66
    .db 92
    .db 6D
    .db 52
    .db 7C
    .db 51
    .db 70
    .db 03
    .db 00
    .db 81
    .db 93
    .db 02
    .db 9D
    .db 8A
    .db 93
    .db 6F
    .db D1
    .db 66
    .db 00
    .db 52
    .db 51
    .db 72
    .db 55
    .db 73
    .db 02
    .db 00
    .db 8D
    .db 6F
    .db 6E
    .db 71
    .db 51
    .db 92
    .db 6E
    .db 00
    .db 71
    .db 73
    .db 54
    .db 6D
    .db 65
    .db 88
    .db 08
    .db 00
    .db 90
    .db 6F
    .db D2
    .db 51
    .db 7C
    .db D3
    .db 00
    .db 7C
    .db 72
    .db 71
    .db D4
    .db D5
    .db D6
    .db 00
    .db 93
    .db 94
    .db 00
    .db 02
    .db 93
    .db 02
    .db 00
    .db 82
    .db 93
    .db 94
    .db 02
    .db 93
    .db 81
    .db 9D
    .db 04
    .db 00
    .db 81
    .db 9D
    .db 02
    .db 93
    .db 8C
    .db D7
    .db 00
    .db 93
    .db 9D
    .db 00
    .db 93
    .db D8
    .db 9D
    .db 93
    .db 9D
    .db 93
    .db D7
    .db 04
    .db 93
    .db 85
    .db 00
    .db 93
    .db 00
    .db 9D
    .db 93
    .db 02
    .db 9D
    .db 81
    .db 93
    .db 7F
    .db 00
    .db 43
    .db 00
FILE_CUSTOMERS_SCREEN: ; C:3041, 0x003041
    .db 20
    .db D9
    .db 1E
    .db DA
    .db 82
    .db DB
    .db D9
    .db 1D
    .db DC
    .db 83
    .db DD
    .db DE
    .db DF
    .db 1C
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 09
    .db DC
    .db 12
    .db E1
    .db 84
    .db E2
    .db DE
    .db E3
    .db E4
    .db 0A
    .db E1
    .db 20
    .db D9
    .db 10
    .db DA
    .db 83
    .db DB
    .db D9
    .db DF
    .db 0D
    .db DA
    .db 0F
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 1B
    .db DC
    .db 84
    .db DD
    .db DE
    .db DF
    .db E0
    .db 18
    .db DC
    .db 03
    .db E1
    .db 84
    .db E2
    .db DE
    .db E3
    .db E4
    .db 19
    .db E1
    .db 20
    .db D9
    .db 40
    .db 00
PLAY_SELECT_BG_FILE: ; C:310C, 0x00310C
    .db 62
    .db 00
    .db 9E
    .db 3B
    .db 3C
    .db 3D
    .db 3E
    .db 3F
    .db 40
    .db 00
    .db 41
    .db 42
    .db 43
    .db 44
    .db 45
    .db 46
    .db 47
    .db 48
    .db 49
    .db 4A
    .db 4B
    .db 4C
    .db 4D
    .db 4E
    .db 4F
    .db 00
    .db 50
    .db 51
    .db 52
    .db 53
    .db 54
    .db 53
    .db 55
    .db 09
    .db 00
    .db 8F
    .db 56
    .db 57
    .db 58
    .db 59
    .db 5A
    .db 5B
    .db 5C
    .db 5D
    .db 5E
    .db 5F
    .db 60
    .db 61
    .db 62
    .db 63
    .db 64
    .db 0A
    .db 00
    .db 86
    .db 3B
    .db 3C
    .db 3D
    .db 3E
    .db 3F
    .db 40
    .db 11
    .db 00
    .db 85
    .db 65
    .db 54
    .db 53
    .db 66
    .db 67
    .db 03
    .db 00
    .db 1F
    .db 68
    .db 7F
    .db 00
    .db 7F
    .db 00
    .db 7F
    .db 00
    .db 7F
    .db 00
    .db 7F
    .db 00
    .db 7F
    .db 00
    .db 26
    .db 00
    .db 0B
    .db 01
    .db 00
    .db 01
    .db 02
    .db 03
    .db 04
    .db 05
    .db 06
    .db 07
    .db 08
    .db 09
    .db 0A
    .db 0B
SPRITE_DATA_FILE_A: ; C:3170, 0x003170
    .db 04
    .db 03
    .db 02
    .db 0C
    .db 00
    .db 00
    .db 00
    .db 0D
    .db 0E
    .db 0F
    .db 00
    .db 10
    .db 11
    .db 12
    .db 13
FILE_UNK: ; C:317F, 0x00317F
    .db 01
    .db 01
    .db 00
VAL_UNK_B: ; C:3182, 0x003182
    .db 14
FILE_UNK: ; C:3183, 0x003183
    .db 01
    .db 01
    .db 00
    .db 15
FILE_UNK: ; C:3187, 0x003187
    .db 01
    .db 01
    .db 00
    .db 16
SPRITE_DATA_FILE_G: ; C:318B, 0x00318B
    .db 02
    .db 02
    .db 00
    .db 17
    .db 18
    .db 19
    .db 1A
    .db 01
    .db 01
    .db 00
VAL_UNK_A: ; C:3195, 0x003195
    .db 1B
FILE_UNK: ; C:3196, 0x003196
    .db 03
    .db 03
    .db 02
    .db 00
    .db 1C
    .db 00
    .db 1D
    .db 1E
    .db 1F
    .db 20
    .db 21
    .db 00
FILE_G: ; C:31A2, 0x0031A2
    .db 03
    .db 03
    .db 02
    .db 22
    .db 23
    .db 24
    .db 25
    .db 26
    .db 27
    .db 28
    .db 29
    .db 00
FILE_H: ; C:31AE, 0x0031AE
    .db 03
    .db 03
    .db 02
    .db 2A
    .db 2B
    .db 2C
    .db 2D
    .db 2E
    .db 2F
    .db 30
    .db 31
    .db 00
FILE_E: ; C:31BA, 0x0031BA
    .db 02
    .db 04
    .db 02
    .db 32
    .db 33
    .db 34
    .db 35
    .db 36
    .db 37
    .db 38
    .db 00
FILE_F: ; C:31C5, 0x0031C5
    .db 02
    .db 04
    .db 02
    .db 39
    .db 3A
    .db 3B
    .db 3C
    .db 3D
    .db 3E
    .db 3F
    .db 00
FILE_D: ; C:31D0, 0x0031D0
    .db 02
    .db 04
    .db 02
    .db 40
    .db 41
    .db 42
    .db 43
    .db 44
    .db 45
    .db 46
    .db 00
FILE_B: ; C:31DB, 0x0031DB
    .db 02
    .db 04
    .db 02
    .db 47
    .db 48
    .db 49
    .db 4A
    .db 4B
    .db 4C
    .db 4D
    .db 00
FILE_C: ; C:31E6, 0x0031E6
    .db 02
    .db 04
    .db 02
    .db 4E
    .db 4F
    .db 50
    .db 51
    .db 52
    .db 53
    .db 54
    .db 00
DATA_UNK: ; C:31F1, 0x0031F1
    .db 02
    .db 02
    .db 03
    .db 55
    .db 56
    .db 57
    .db 58
DATA_UNK: ; C:31F8, 0x0031F8
    .db 02
    .db 02
    .db 03
    .db 55
    .db 56
    .db 59
    .db 5A
SPRITE_DATA_FILE_P: ; C:31FF, 0x0031FF
    .db 02
    .db 02
    .db 03
    .db 5B
    .db 5C
    .db 5D
    .db 5E
ANIM_FILE_PAIR_A: ; C:3206, 0x003206
    .db 02
    .db 03
    .db 00
    .db 5F
    .db 60
    .db 61
    .db 62
    .db 63
    .db 64
ANIM_FILE_PAIR_B: ; C:320F, 0x00320F
    .db 02
    .db 03
    .db 00
    .db 65
    .db 66
    .db 67
    .db 68
    .db 69
    .db 6A
SPRITE_DATA_FILE_D: ; C:3218, 0x003218
    .db 02
    .db 04
    .db 01
    .db 6B
    .db 6C
    .db 6D
    .db 6E
    .db 6F
    .db 70
    .db 71
    .db 72
DATA_UNK: ; C:3223, 0x003223
    .db 02
    .db 04
    .db 01
    .db 6B
    .db 6C
    .db 73
    .db 74
    .db 75
    .db 76
    .db 77
    .db 78
SPRITE_DATA_FILE_E: ; C:322E, 0x00322E
    .db 02
    .db 03
    .db 00
    .db 79
    .db 00
    .db 7A
    .db 7B
    .db 7C
    .db 00
DATA_UNK: ; C:3237, 0x003237
    .db 02
    .db 03
    .db 00
    .db 79
    .db 00
    .db 7D
    .db 7E
    .db 7F
    .db 80
DATA_UNK: ; C:3240, 0x003240
    .db 02
    .db 03
    .db 00
    .db 79
    .db 00
    .db 7D
    .db 7E
    .db 81
    .db 00
SPRITE_DATA_FILE_F: ; C:3249, 0x003249
    .db 02
    .db 01
    .db 00
    .db 82
    .db 83
FILE: ; C:324E, 0x00324E
    .db 02
    .db 02
    .db 00
    .db 82
    .db 83
    .db 84
    .db 85
SPRITE_DATA_FILE_I: ; C:3255, 0x003255
    .db 03
    .db 05
    .db 03
    .db 86
    .db 87
    .db 88
    .db 89
    .db 8A
    .db 8B
    .db 8C
    .db 8D
    .db 8E
    .db 8F
    .db 90
    .db 91
    .db 92
    .db 93
    .db 94
SPRITE_ANIM_FILE_UNK: ; C:3267, 0x003267
    .db 03
    .db 05
    .db 03
    .db 86
    .db 87
    .db 88
    .db 89
    .db 8A
    .db 8B
    .db 8C
    .db 8D
    .db 8E
    .db 8F
    .db 90
    .db 91
    .db 95
    .db 96
    .db 97
SPRITE_DATA_FILE_J: ; C:3279, 0x003279
    .db 02
    .db 02
    .db 01
    .db 00
    .db 98
    .db 99
    .db 9A
DATA_SPRITE?: ; C:3280, 0x003280
    .db 02
    .db 02
    .db 01
    .db 9B
    .db 9C
    .db 9D
    .db 9E
DATA_UNK: ; C:3287, 0x003287
    .db 02
    .db 02
    .db 01
    .db 9F
    .db A0
    .db A1
    .db A2
SPRITE_DATA_FILE_K: ; C:328E, 0x00328E
    .db 02
    .db 04
    .db 00
    .db A3
    .db A4
    .db A5
    .db A6
    .db A7
    .db A8
    .db A9
    .db AA
    .db 02
    .db 04
    .db 00
    .db AB
    .db 00
    .db AC
    .db AD
    .db AE
    .db AF
    .db A9
    .db AA
ANIM_FILE: ; C:32A4, 0x0032A4
    .db 02
    .db 01
    .db 03
    .db B0
    .db B1
ANIMATION_FILE_TODO: ; C:32A9, 0x0032A9
    .db 02
    .db 02
    .db 03
    .db B2
    .db B3
    .db B4
    .db B5
INIT_ANIM_FILE: ; C:32B0, 0x0032B0
    .db 02
    .db 02
    .db 03
    .db B6
    .db B7
    .db B8
    .db B9
ANIM_FILE_TODO: ; C:32B7, 0x0032B7
    .db 02
    .db 02
    .db 03
    .db BA
    .db BB
    .db BC
    .db BD
ANIM_FILE_TODO: ; C:32BE, 0x0032BE
    .db 02
    .db 02
    .db 03
    .db BE
    .db BF
    .db C0
    .db C1
ANIM_FILE_N: ; C:32C5, 0x0032C5
    .db 03
    .db 03
    .db 02
    .db C2
    .db C3
    .db 00
    .db C4
    .db C5
    .db C6
    .db C7
    .db C8
    .db C9
ANIM_FILE: ; C:32D1, 0x0032D1
    .db 03
    .db 03
    .db 02
    .db C2
    .db C3
    .db 00
    .db C4
    .db CA
    .db CB
    .db C7
    .db CC
    .db CD
SPRITE_DATA_FILE_M: ; C:32DD, 0x0032DD
    .db 02
    .db 04
    .db 00
    .db CE
    .db CF
    .db D0
    .db D1
    .db D2
    .db D3
    .db D4
    .db D5
ANIMATION_FILE_TODO_B: ; C:32E8, 0x0032E8
    .db 02
    .db 04
    .db 00
    .db D6
    .db D7
    .db D8
    .db D9
    .db DA
    .db DB
    .db DC
    .db DD
SPRITE_DATA_FILE_O: ; C:32F3, 0x0032F3
    .db 05
    .db 05
    .db 00
    .db 00
    .db DE
    .db DF
    .db E0
    .db E1
    .db 00
    .db E2
    .db E3
    .db E4
    .db E5
    .db E6
    .db E7
    .db E8
    .db E9
    .db EA
    .db EB
    .db EC
    .db ED
    .db EE
    .db 00
    .db EF
    .db F0
    .db F1
    .db 00
    .db 00
SPRITE_DATA_FILE_B: ; C:330F, 0x00330F
    .db 02
    .db 03
    .db 01
    .db F2
    .db F3
    .db F4
    .db F5
    .db F6
    .db F7
DATA_UNK: ; C:3318, 0x003318
    .db 02
    .db 03
    .db 01
    .db F8
    .db F9
    .db FA
    .db FB
    .db FC
    .db FD
    .db 02
    .db 02
    .db 01
    .db FE
    .db FF
    .db FC
    .db FD
    .db 18
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 82
    .db 03
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 05
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 82
    .db 03
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 06
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 82
    .db 12
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 81
    .db 13
    .db 03
    .db 12
    .db 82
    .db 13
    .db 14
    .db 03
    .db 15
    .db 83
    .db 16
    .db 17
    .db 15
    .db 0D
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 27
    .db 00
    .db 82
    .db 10
    .db 11
    .db 05
    .db 00
    .db 82
    .db 10
    .db 11
    .db 0E
    .db 00
    .db 29
    .db 0C
    .db 81
    .db 0D
    .db 06
    .db 0E
    .db 82
    .db 0F
    .db 0B
    .db 0C
    .db 00
    .db 82
    .db 03
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 06
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 82
    .db 03
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 81
    .db 09
    .db 06
    .db 03
    .db 82
    .db 0A
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 18
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 23
    .db 01
    .db 06
    .db 18
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 22
    .db 01
    .db 06
    .db 18
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0C
    .db 01
    .db 06
    .db 3C
    .db 81
    .db 5E
    .db 02
    .db 3E
    .db 81
    .db 5F
    .db 06
    .db 3C
    .db 84
    .db 61
    .db 00
    .db 5A
    .db 51
    .db 0B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 06
    .db 3C
    .db 81
    .db 5E
    .db 02
    .db 3E
    .db 81
    .db 5F
    .db 06
    .db 3C
    .db 85
    .db 1E
    .db 61
    .db 56
    .db 5A
    .db 51
    .db 0B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0A
    .db 01
    .db 02
    .db 3C
    .db 85
    .db 48
    .db 49
    .db 48
    .db 49
    .db 5E
    .db 02
    .db 3E
    .db 8B
    .db 5F
    .db 3C
    .db 48
    .db 49
    .db 48
    .db 49
    .db 3C
    .db 1E
    .db 60
    .db 61
    .db 56
    .db 03
    .db 00
    .db 83
    .db 5A
    .db 00
    .db 5A
    .db 02
    .db 00
    .db 82
    .db 62
    .db 63
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 09
    .db 01
    .db 02
    .db 3C
    .db 85
    .db 40
    .db 41
    .db 40
    .db 41
    .db 5B
    .db 02
    .db 3E
    .db 91
    .db 5C
    .db 3C
    .db 40
    .db 41
    .db 40
    .db 41
    .db 3C
    .db 1E
    .db 5D
    .db 1E
    .db 2B
    .db 59
    .db 03
    .db 30
    .db 56
    .db 00
    .db 56
    .db 04
    .db 00
    .db 81
    .db 51
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 08
    .db 01
    .db 07
    .db 3C
    .db 02
    .db 3E
    .db 81
    .db 4E
    .db 06
    .db 3C
    .db 88
    .db 1E
    .db 57
    .db 1E
    .db 58
    .db 2B
    .db 59
    .db 03
    .db 30
    .db 06
    .db 00
    .db 82
    .db 5A
    .db 51
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 82
    .db 54
    .db 45
    .db 06
    .db 3C
    .db 02
    .db 3E
    .db 81
    .db 4E
    .db 05
    .db 3C
    .db 86
    .db 55
    .db 47
    .db 3F
    .db 1E
    .db 00
    .db 2A
    .db 08
    .db 03
    .db 84
    .db 30
    .db 56
    .db 00
    .db 51
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 83
    .db 33
    .db 44
    .db 45
    .db 04
    .db 3C
    .db 02
    .db 3E
    .db 81
    .db 4E
    .db 03
    .db 3C
    .db 82
    .db 4F
    .db 47
    .db 03
    .db 24
    .db 84
    .db 3F
    .db 00
    .db 1E
    .db 2A
    .db 08
    .db 03
    .db 81
    .db 30
    .db 02
    .db 00
    .db 81
    .db 51
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 84
    .db 33
    .db 29
    .db 44
    .db 45
    .db 02
    .db 3C
    .db 02
    .db 3E
    .db 84
    .db 4E
    .db 3C
    .db 4F
    .db 47
    .db 07
    .db 24
    .db 02
    .db 1E
    .db 04
    .db 3C
    .db 83
    .db 50
    .db 3C
    .db 2A
    .db 02
    .db 03
    .db 81
    .db 30
    .db 02
    .db 00
    .db 81
    .db 51
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 52
    .db 53
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 02
    .db 29
    .db 82
    .db 44
    .db 45
    .db 02
    .db 3E
    .db 82
    .db 46
    .db 47
    .db 09
    .db 24
    .db 82
    .db 3F
    .db 1E
    .db 02
    .db 3C
    .db 86
    .db 48
    .db 49
    .db 4A
    .db 4B
    .db 1E
    .db 3D
    .db 05
    .db 03
    .db 82
    .db 4C
    .db 4D
    .db 02
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 02
    .db 3E
    .db 0C
    .db 24
    .db 81
    .db 3F
    .db 02
    .db 3C
    .db 82
    .db 40
    .db 41
    .db 02
    .db 3C
    .db 83
    .db 1E
    .db 38
    .db 3D
    .db 04
    .db 03
    .db 82
    .db 42
    .db 43
    .db 03
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 02
    .db 29
    .db 82
    .db 39
    .db 3A
    .db 0D
    .db 24
    .db 81
    .db 3B
    .db 05
    .db 3C
    .db 84
    .db 1E
    .db 00
    .db 38
    .db 3D
    .db 09
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0C
    .db 24
    .db 81
    .db 1B
    .db 04
    .db 1C
    .db 82
    .db 37
    .db 1E
    .db 02
    .db 00
    .db 82
    .db 38
    .db 2A
    .db 09
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 0A
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0A
    .db 24
    .db 81
    .db 1B
    .db 05
    .db 1C
    .db 82
    .db 25
    .db 1E
    .db 03
    .db 00
    .db 83
    .db 1E
    .db 01
    .db 36
    .db 08
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 08
    .db 24
    .db 81
    .db 1B
    .db 07
    .db 1C
    .db 88
    .db 1D
    .db 2A
    .db 30
    .db 00
    .db 1E
    .db 01
    .db 34
    .db 35
    .db 08
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 82
    .db 19
    .db 22
    .db 02
    .db 29
    .db 81
    .db 23
    .db 06
    .db 24
    .db 81
    .db 1B
    .db 08
    .db 1C
    .db 87
    .db 2F
    .db 1E
    .db 2A
    .db 30
    .db 1E
    .db 01
    .db 31
    .db 03
    .db 01
    .db 81
    .db 32
    .db 06
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 07
    .db 01
    .db 84
    .db 19
    .db 22
    .db 29
    .db 23
    .db 04
    .db 24
    .db 81
    .db 1B
    .db 0A
    .db 1C
    .db 84
    .db 1D
    .db 1E
    .db 2A
    .db 2B
    .db 04
    .db 01
    .db 83
    .db 2C
    .db 2D
    .db 2E
    .db 06
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 08
    .db 01
    .db 83
    .db 19
    .db 22
    .db 23
    .db 02
    .db 24
    .db 81
    .db 1B
    .db 0B
    .db 1C
    .db 81
    .db 25
    .db 03
    .db 1E
    .db 04
    .db 01
    .db 83
    .db 26
    .db 27
    .db 28
    .db 07
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 09
    .db 01
    .db 83
    .db 19
    .db 1A
    .db 1B
    .db 0D
    .db 1C
    .db 81
    .db 1D
    .db 02
    .db 1E
    .db 81
    .db 1F
    .db 04
    .db 01
    .db 83
    .db 20
    .db 21
    .db 01
    .db 06
    .db 18
    .db 82
    .db 01
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 23
    .db 01
    .db 06
    .db 18
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 18
    .db 0D
    .db 01
    .db 05
    .db 1E
    .db 0A
    .db 3C
    .db 81
    .db 61
    .db 02
    .db 00
    .db 81
    .db 5A
    .db 02
    .db 00
    .db 81
    .db 51
    .db 03
    .db 01
    .db 04
    .db 67
    .db 82
    .db 01
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0C
    .db 01
    .db 02
    .db 1E
    .db 92
    .db 48
    .db A0
    .db 1E
    .db 3C
    .db 48
    .db 49
    .db 3C
    .db 48
    .db 49
    .db 3C
    .db 48
    .db 49
    .db 3C
    .db 1E
    .db 61
    .db 00
    .db 56
    .db 00
    .db 02
    .db 85
    .db 81
    .db 51
    .db 02
    .db 01
    .db 04
    .db 67
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 02
    .db 1E
    .db 8D
    .db 40
    .db 9F
    .db 1E
    .db 3C
    .db 40
    .db 41
    .db 3C
    .db 40
    .db 41
    .db 3C
    .db 40
    .db 41
    .db 3C
    .db 02
    .db 1E
    .db 03
    .db 3C
    .db 81
    .db 61
    .db 02
    .db 85
    .db 81
    .db 51
    .db 08
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0A
    .db 01
    .db 02
    .db 1E
    .db 8D
    .db 9D
    .db 9E
    .db 1E
    .db 3C
    .db 80
    .db 81
    .db 3C
    .db 80
    .db 81
    .db 3C
    .db 80
    .db 81
    .db 3C
    .db 02
    .db 1E
    .db 85
    .db 3C
    .db 48
    .db 49
    .db 1E
    .db 61
    .db 02
    .db 85
    .db 81
    .db 51
    .db 08
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 09
    .db 01
    .db 05
    .db 1E
    .db 0A
    .db 3C
    .db 02
    .db 1E
    .db 86
    .db 3C
    .db 40
    .db 41
    .db 1E
    .db 60
    .db 2A
    .db 02
    .db 03
    .db 83
    .db 09
    .db 03
    .db 9A
    .db 06
    .db 9B
    .db 81
    .db 9C
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 08
    .db 01
    .db 05
    .db 1E
    .db 0A
    .db 3C
    .db 02
    .db 1E
    .db 8A
    .db 3C
    .db 80
    .db 81
    .db 1E
    .db 5D
    .db 1E
    .db 58
    .db 2B
    .db 59
    .db 09
    .db 08
    .db 03
    .db 81
    .db 09
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 82
    .db 04
    .db 1C
    .db 81
    .db 86
    .db 0A
    .db 3C
    .db 82
    .db 87
    .db 3F
    .db 03
    .db 3C
    .db 8A
    .db 1E
    .db 75
    .db 1E
    .db 00
    .db 58
    .db 2B
    .db 59
    .db 09
    .db 98
    .db 99
    .db 06
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 05
    .db 01
    .db 81
    .db 7D
    .db 05
    .db 1C
    .db 81
    .db 86
    .db 08
    .db 3C
    .db 81
    .db 87
    .db 02
    .db 24
    .db 83
    .db 3C
    .db 48
    .db 49
    .db 03
    .db 1E
    .db 83
    .db 96
    .db 97
    .db 61
    .db 02
    .db 85
    .db 81
    .db 51
    .db 07
    .db 01
    .db 82
    .db 95
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 05
    .db 01
    .db 81
    .db 82
    .db 05
    .db 1C
    .db 81
    .db 86
    .db 06
    .db 3C
    .db 81
    .db 87
    .db 03
    .db 24
    .db 83
    .db 3C
    .db 40
    .db 41
    .db 03
    .db 1E
    .db 84
    .db 93
    .db 94
    .db 1E
    .db 61
    .db 02
    .db 85
    .db 85
    .db 00
    .db 5A
    .db 00
    .db 5A
    .db 51
    .db 02
    .db 01
    .db 83
    .db 92
    .db 01
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 7D
    .db 06
    .db 1C
    .db 81
    .db 86
    .db 04
    .db 3C
    .db 81
    .db 87
    .db 04
    .db 24
    .db 83
    .db 3C
    .db 80
    .db 81
    .db 03
    .db 1E
    .db 85
    .db 93
    .db 94
    .db 1E
    .db 60
    .db 61
    .db 02
    .db 00
    .db 85
    .db 56
    .db 00
    .db 56
    .db 85
    .db 51
    .db 03
    .db 01
    .db 82
    .db 95
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 82
    .db 06
    .db 1C
    .db 81
    .db 86
    .db 02
    .db 3C
    .db 81
    .db 87
    .db 04
    .db 24
    .db 81
    .db 8E
    .db 04
    .db 70
    .db 87
    .db 7A
    .db 8F
    .db 90
    .db 91
    .db 1E
    .db 5D
    .db 1E
    .db 05
    .db 3C
    .db 83
    .db 61
    .db 85
    .db 51
    .db 02
    .db 01
    .db 83
    .db 92
    .db 01
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 03
    .db 01
    .db 81
    .db 7D
    .db 07
    .db 1C
    .db 82
    .db 86
    .db 87
    .db 06
    .db 24
    .db 81
    .db 7F
    .db 04
    .db 70
    .db 86
    .db 88
    .db 03
    .db 89
    .db 8A
    .db 75
    .db 1E
    .db 02
    .db 3C
    .db 87
    .db 48
    .db 49
    .db 3C
    .db 1E
    .db 61
    .db 85
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 85
    .db 04
    .db 05
    .db 8B
    .db 8C
    .db 8D
    .db 0A
    .db 00
    .db 03
    .db 01
    .db 81
    .db 82
    .db 07
    .db 1C
    .db 81
    .db 7E
    .db 06
    .db 24
    .db 81
    .db 78
    .db 04
    .db 70
    .db 81
    .db 83
    .db 02
    .db 03
    .db 81
    .db 84
    .db 02
    .db 1E
    .db 02
    .db 3C
    .db 88
    .db 40
    .db 41
    .db 3C
    .db 1E
    .db 60
    .db 61
    .db 85
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 52
    .db 53
    .db 0C
    .db 00
    .db 02
    .db 01
    .db 81
    .db 7D
    .db 08
    .db 1C
    .db 81
    .db 7E
    .db 06
    .db 24
    .db 81
    .db 7F
    .db 02
    .db 70
    .db 81
    .db 79
    .db 03
    .db 3C
    .db 03
    .db 1E
    .db 02
    .db 3C
    .db 89
    .db 80
    .db 81
    .db 3C
    .db 1E
    .db 5D
    .db 1E
    .db 03
    .db 4C
    .db 4D
    .db 04
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 05
    .db 24
    .db 84
    .db 78
    .db 70
    .db 79
    .db 78
    .db 04
    .db 70
    .db 82
    .db 7A
    .db 7B
    .db 04
    .db 1C
    .db 87
    .db 7C
    .db 1E
    .db 75
    .db 1E
    .db 03
    .db 42
    .db 43
    .db 05
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 07
    .db 24
    .db 82
    .db 6A
    .db 74
    .db 04
    .db 70
    .db 81
    .db 77
    .db 05
    .db 1C
    .db 83
    .db 72
    .db 60
    .db 1E
    .db 09
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 06
    .db 24
    .db 82
    .db 6E
    .db 6F
    .db 04
    .db 70
    .db 81
    .db 71
    .db 05
    .db 1C
    .db 83
    .db 6B
    .db 5D
    .db 1E
    .db 0A
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 04
    .db 24
    .db 81
    .db 6A
    .db 02
    .db 1C
    .db 81
    .db 74
    .db 02
    .db 70
    .db 81
    .db 71
    .db 06
    .db 1C
    .db 83
    .db 65
    .db 75
    .db 1E
    .db 0B
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 76
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 03
    .db 24
    .db 81
    .db 6E
    .db 02
    .db 1C
    .db 83
    .db 6F
    .db 70
    .db 71
    .db 08
    .db 1C
    .db 83
    .db 72
    .db 1E
    .db 73
    .db 0B
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 0A
    .db 06
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 83
    .db 64
    .db 24
    .db 6A
    .db 0E
    .db 1C
    .db 82
    .db 6B
    .db 6C
    .db 03
    .db 01
    .db 04
    .db 67
    .db 04
    .db 01
    .db 83
    .db 3E
    .db 6D
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db 64
    .db 0F
    .db 1C
    .db 82
    .db 65
    .db 66
    .db 03
    .db 01
    .db 04
    .db 67
    .db 04
    .db 01
    .db 84
    .db 68
    .db 69
    .db 01
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 18
    .db 22
    .db 01
    .db 06
    .db 18
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0A
    .db 01
    .db 06
    .db 3C
    .db 81
    .db 5E
    .db 02
    .db 3E
    .db 81
    .db 5F
    .db 06
    .db 3C
    .db 81
    .db 61
    .db 02
    .db 00
    .db 81
    .db 51
    .db 03
    .db 01
    .db 06
    .db 18
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 09
    .db 01
    .db 06
    .db 3C
    .db 81
    .db 5E
    .db 02
    .db 3E
    .db 81
    .db 5F
    .db 06
    .db 3C
    .db 85
    .db 1E
    .db 61
    .db 00
    .db B0
    .db 51
    .db 0D
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 52
    .db 53
    .db 0C
    .db 00
    .db 08
    .db 01
    .db 02
    .db 3C
    .db 85
    .db 48
    .db 49
    .db 48
    .db 49
    .db 5E
    .db 02
    .db 3E
    .db 8D
    .db 5F
    .db 3C
    .db 48
    .db 49
    .db 48
    .db 49
    .db 3C
    .db 1E
    .db 60
    .db 61
    .db A8
    .db A9
    .db 51
    .db 07
    .db 01
    .db 84
    .db B1
    .db AB
    .db 4C
    .db 4D
    .db 02
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 07
    .db 01
    .db 02
    .db 3C
    .db 85
    .db 40
    .db 41
    .db 40
    .db 41
    .db 5B
    .db 02
    .db 3E
    .db 8E
    .db 5C
    .db 3C
    .db 40
    .db 41
    .db 40
    .db 41
    .db 3C
    .db 1E
    .db 5D
    .db 1E
    .db 61
    .db 00
    .db B0
    .db 51
    .db 05
    .db 01
    .db 85
    .db B1
    .db AB
    .db 03
    .db 42
    .db 43
    .db 03
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 02
    .db 3C
    .db 85
    .db 80
    .db 81
    .db 80
    .db 81
    .db 3C
    .db 02
    .db 3E
    .db 8F
    .db 4E
    .db 3C
    .db 80
    .db 81
    .db 80
    .db 81
    .db 3C
    .db 1E
    .db 57
    .db 1E
    .db 60
    .db 61
    .db A8
    .db A9
    .db 51
    .db 03
    .db 01
    .db 82
    .db B1
    .db AB
    .db 08
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 82
    .db 54
    .db 45
    .db 06
    .db 3C
    .db 02
    .db 3E
    .db 81
    .db 4E
    .db 05
    .db 3C
    .db 8D
    .db 55
    .db 47
    .db 3F
    .db 1E
    .db 5D
    .db 1E
    .db 61
    .db 00
    .db B0
    .db 51
    .db 01
    .db B1
    .db AB
    .db 0A
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 83
    .db 33
    .db 44
    .db 45
    .db 04
    .db 3C
    .db 02
    .db 3E
    .db 81
    .db 4E
    .db 03
    .db 3C
    .db 82
    .db 4F
    .db 47
    .db 03
    .db 24
    .db 89
    .db 3F
    .db 57
    .db 1E
    .db 60
    .db 61
    .db A8
    .db A9
    .db AA
    .db AB
    .db 08
    .db 03
    .db 81
    .db AC
    .db 03
    .db AD
    .db 81
    .db AE
    .db 04
    .db 07
    .db 82
    .db AF
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 84
    .db 33
    .db 29
    .db 44
    .db 45
    .db 02
    .db 3C
    .db 02
    .db 3E
    .db 84
    .db 4E
    .db 3C
    .db 4F
    .db 47
    .db 06
    .db 24
    .db 86
    .db 3F
    .db 1E
    .db 5D
    .db 1E
    .db 2B
    .db 59
    .db 09
    .db 03
    .db 81
    .db A7
    .db 05
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 02
    .db 29
    .db 82
    .db 44
    .db 45
    .db 02
    .db 3E
    .db 82
    .db 46
    .db 47
    .db 09
    .db 24
    .db 86
    .db 3F
    .db 57
    .db 1E
    .db 58
    .db 2B
    .db 59
    .db 07
    .db 03
    .db 81
    .db A7
    .db 07
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 02
    .db 3E
    .db 0C
    .db 24
    .db 86
    .db 3F
    .db 1E
    .db 00
    .db 50
    .db 3C
    .db 93
    .db 06
    .db 1E
    .db 85
    .db 3C
    .db 61
    .db 00
    .db 5A
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 02
    .db 29
    .db 82
    .db 39
    .db 3A
    .db 0D
    .db 24
    .db 91
    .db 3F
    .db 00
    .db 4A
    .db 4B
    .db 93
    .db 48
    .db A0
    .db 48
    .db A0
    .db 48
    .db A0
    .db 3C
    .db 1E
    .db 61
    .db 56
    .db 5A
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0E
    .db 24
    .db 02
    .db 3C
    .db 8E
    .db 93
    .db 40
    .db 9F
    .db 40
    .db 9F
    .db 40
    .db 9F
    .db 3C
    .db 1E
    .db 60
    .db 61
    .db 56
    .db 5A
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0D
    .db 24
    .db 81
    .db 3B
    .db 09
    .db 3C
    .db 87
    .db 1E
    .db 5D
    .db 60
    .db 61
    .db 56
    .db 5A
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0C
    .db 24
    .db 81
    .db 1B
    .db 08
    .db 1C
    .db 89
    .db 37
    .db 1E
    .db 75
    .db 5D
    .db 60
    .db 61
    .db 56
    .db 00
    .db 51
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 0A
    .db 24
    .db 81
    .db 1B
    .db 09
    .db 1C
    .db 81
    .db 25
    .db 02
    .db 1E
    .db 83
    .db 75
    .db 5D
    .db 1E
    .db 04
    .db 01
    .db 03
    .db 3C
    .db 82
    .db A6
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 33
    .db 03
    .db 29
    .db 81
    .db 23
    .db 08
    .db 24
    .db 81
    .db 1B
    .db 0B
    .db 1C
    .db 81
    .db 1D
    .db 02
    .db 1E
    .db 82
    .db 75
    .db 1E
    .db 03
    .db 01
    .db 81
    .db A4
    .db 03
    .db A2
    .db 83
    .db A5
    .db 01
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 82
    .db 19
    .db 22
    .db 02
    .db 29
    .db 81
    .db 23
    .db 06
    .db 24
    .db 81
    .db 1B
    .db 0C
    .db 1C
    .db 81
    .db 2F
    .db 04
    .db 1E
    .db 04
    .db 01
    .db 81
    .db A1
    .db 02
    .db A2
    .db 81
    .db A3
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 05
    .db 01
    .db 84
    .db 19
    .db 22
    .db 29
    .db 23
    .db 04
    .db 24
    .db 81
    .db 1B
    .db 0E
    .db 1C
    .db 81
    .db 1D
    .db 03
    .db 1E
    .db 0B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 83
    .db 19
    .db 22
    .db 23
    .db 02
    .db 24
    .db 81
    .db 1B
    .db 0F
    .db 1C
    .db 81
    .db 25
    .db 03
    .db 1E
    .db 0C
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 07
    .db 01
    .db 83
    .db 19
    .db 1A
    .db 1B
    .db 11
    .db 1C
    .db 81
    .db 1D
    .db 02
    .db 1E
    .db 81
    .db 1F
    .db 05
    .db 01
    .db 06
    .db 18
    .db 82
    .db 01
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 23
    .db 01
    .db 06
    .db 18
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 2B
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 18
    .db 23
    .db 01
    .db 04
    .db 67
    .db 04
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0C
    .db 01
    .db 12
    .db 3C
    .db 81
    .db 1F
    .db 03
    .db 01
    .db 04
    .db 67
    .db 05
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 52
    .db 53
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 02
    .db 3C
    .db 8E
    .db 48
    .db 49
    .db 48
    .db 49
    .db 3C
    .db 48
    .db 49
    .db 48
    .db 49
    .db 3C
    .db 48
    .db 49
    .db 48
    .db 49
    .db 02
    .db 3C
    .db 82
    .db 1E
    .db 1F
    .db 07
    .db 01
    .db 82
    .db B1
    .db AB
    .db 03
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 0A
    .db 01
    .db 02
    .db 3C
    .db 8E
    .db 40
    .db 41
    .db 40
    .db 41
    .db 3C
    .db 40
    .db 41
    .db 40
    .db 41
    .db 3C
    .db 40
    .db 41
    .db 40
    .db 41
    .db 02
    .db 3C
    .db 83
    .db 1E
    .db 60
    .db 1F
    .db 05
    .db 01
    .db 82
    .db B1
    .db AB
    .db 05
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 09
    .db 01
    .db 12
    .db 3C
    .db 84
    .db 1E
    .db 5D
    .db 1E
    .db 09
    .db 03
    .db 03
    .db 82
    .db 4C
    .db 4D
    .db 07
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 7D
    .db 12
    .db 1C
    .db 86
    .db 7C
    .db 1E
    .db 57
    .db 1E
    .db 03
    .db 09
    .db 02
    .db 03
    .db 82
    .db 42
    .db 43
    .db 08
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 04
    .db 0B
    .db 0C
    .db 00
    .db 06
    .db 01
    .db 81
    .db 82
    .db 12
    .db 1C
    .db 81
    .db 72
    .db 02
    .db 1E
    .db 83
    .db 2B
    .db 59
    .db 09
    .db 0C
    .db 03
    .db 81
    .db 09
    .db 04
    .db 03
    .db 82
    .db 0A
    .db 06
    .db 0C
    .db 00
    .db 05
    .db 01
    .db 81
    .db 7D
    .db 12
    .db 1C
    .db 81
    .db 6B
    .db 02
    .db 1E
    .db 84
    .db 03
    .db 2B
    .db 59
    .db C0
    .db 02
    .db C1
    .db 81
    .db C2
    .db 06
    .db 03
    .db 81
    .db A7
    .db 02
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 05
    .db 01
    .db 81
    .db 82
    .db 11
    .db 1C
    .db 81
    .db 65
    .db 02
    .db 1E
    .db 81
    .db 00
    .db 04
    .db 85
    .db 83
    .db 00
    .db B0
    .db 58
    .db 05
    .db 03
    .db 81
    .db BA
    .db 03
    .db 01
    .db 81
    .db 02
    .db 02
    .db 03
    .db 84
    .db BF
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 7D
    .db 12
    .db 1C
    .db 83
    .db B5
    .db B6
    .db BD
    .db 05
    .db 00
    .db 83
    .db A8
    .db A9
    .db 58
    .db 05
    .db 03
    .db 81
    .db BA
    .db 03
    .db 01
    .db 87
    .db 02
    .db 03
    .db BE
    .db 03
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 04
    .db 01
    .db 81
    .db 82
    .db 11
    .db 1C
    .db 83
    .db B3
    .db BC
    .db 1E
    .db 05
    .db 3C
    .db 81
    .db 61
    .db 02
    .db 85
    .db 81
    .db 58
    .db 05
    .db 03
    .db 81
    .db BA
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 07
    .db 83
    .db 08
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 03
    .db 01
    .db 81
    .db 7D
    .db 11
    .db 1C
    .db 83
    .db 65
    .db BB
    .db 1E
    .db 02
    .db 3C
    .db 85
    .db 48
    .db 49
    .db 3C
    .db 1E
    .db 61
    .db 02
    .db 85
    .db 81
    .db 58
    .db 05
    .db 03
    .db 81
    .db BA
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0B
    .db 01
    .db 81
    .db B9
    .db 09
    .db 24
    .db 82
    .db 3F
    .db 1E
    .db 02
    .db 3C
    .db 89
    .db 40
    .db 41
    .db 3C
    .db 1E
    .db 60
    .db 61
    .db 00
    .db B0
    .db 58
    .db 05
    .db 03
    .db 81
    .db BA
    .db 03
    .db 01
    .db 81
    .db 02
    .db 03
    .db 03
    .db 83
    .db 04
    .db 05
    .db 06
    .db 0C
    .db 00
    .db 0A
    .db 01
    .db 82
