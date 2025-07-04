; ==================================================================
; LED Display Flood Fill Algorithm - Annotated Version
; ==================================================================
; This code implements a scanline-based flood fill algorithm for LED displays
; Uses x86 assembly language with bit-level operations for efficiency

; ==================================================================
; DATA DECLARATIONS
; ==================================================================

gbuffer     db    buffersize dup (?)     ; Main graphics buffer for LED display
fillpage    db    100h dup (0)           ; Work buffer for flood fill operations (256 bytes)
cursbit     db    10h                    ; Cursor bit mask - specifies which bit within a byte
cursor      dw    gbuffer+21h            ; Cursor pointer - current position in buffer
fcopyflg    db    on                     ; Copy flag - if ON, copy filled pixels to main buffer
fillflg     db    0                      ; Fill flag - indicates if any pixels were changed
direction   db    0                      ; Direction flag - controls fill direction

; ==================================================================
; MAIN FLOOD FILL ROUTINE
; ==================================================================

FILLIN:
    ; ------------------------------------------------------------------
    ; INITIALIZATION PHASE
    ; Save current cursor position and set up work buffers
    ; ------------------------------------------------------------------
    mov     bx, cursor                   ; Load cursor position into BX
    push    bx                           ; Save original cursor position on stack
    mov     di, bx                       ; DI = cursor position in main buffer
    and     bx, 0ff80h                   ; Mask to get start of current line (clear low 7 bits)
    mov     aldsadr, bx                  ; Store line start address
    pop     bx                           ; Restore cursor position
    push    bx                           ; Save it again for later restoration

    ; ------------------------------------------------------------------
    ; BUFFER SETUP
    ; Switch to work buffer for flood fill operations
    ; ------------------------------------------------------------------
    mov     aldsflg, 1                   ; Set display flag for main frame
    lea     si, fillpage                 ; SI = pointer to work buffer
    and     si, 0ff80h                   ; Align to line boundary
    and     bx, 7fh                      ; Get position within line (low 7 bits)
    or      bx, si                       ; BX = cursor position in work buffer
    mov     cursor, bx                   ; Update cursor to work buffer position
    call    clrfr                        ; Clear the work frame

    ; ------------------------------------------------------------------
    ; MAIN LOOP SETUP
    ; Initialize bit mask and direction flag
    ; ------------------------------------------------------------------
    mov     ch, cursbit                  ; CH = current bit mask for cursor
    mov     cl, 0ffh                     ; CL = direction flag (0FFh = forward)
    jmp     fl4                          ; Jump to pixel setting code

    ; ------------------------------------------------------------------
    ; FILL LOOP - HORIZONTAL LINE PROCESSING
    ; Process pixels horizontally, alternating direction each pass
    ; ------------------------------------------------------------------
FL2:
    mov     fillflg, 0                   ; Reset fill flag for new pass

FL3:
    ; Check if current pixel needs to be filled
    mov     al, [di]                     ; Load pixel from main buffer
    or      al, [bx]                     ; OR with work buffer pixel
    and     al, ch                       ; Test current bit position
    jnz     fl6                          ; If bit already set, skip this pixel

    ; ------------------------------------------------------------------
    ; NEIGHBOR CHECK
    ; Verify this pixel should be filled by checking neighbors
    ; ------------------------------------------------------------------
    mov     cursor, bx                   ; Update cursor for neighbor check
    mov     cursbit, ch                  ; Update bit mask for neighbor check
    call    neighb                       ; Check orthogonal neighbors
                                        ; (neighb function checks up/down/left/right)
    jz      fl6                          ; If no valid neighbors, skip pixel

FL4:
    ; ------------------------------------------------------------------
    ; PIXEL SETTING
    ; Turn on the pixel in work buffer and optionally main buffer
    ; ------------------------------------------------------------------
    mov     al, [bx]                     ; Load current work buffer byte
    or      al, ch                       ; Set the bit for current pixel
    mov     [bx], al                     ; Store back to work buffer

    cmp     fcopyflg, 0                  ; Check copy flag
    jz      fl5                          ; If copy disabled, skip main buffer update
    mov     al, [di]                     ; Load main buffer byte
    or      al, ch                       ; Set the bit
    mov     [di], al                     ; Store back to main buffer

FL5:
    mov     fillflg, 1                   ; Set fill flag - we changed a pixel

FL6:
    ; ------------------------------------------------------------------
    ; BOUNDARY DETECTION
    ; Check if we've reached the end of current line
    ; ------------------------------------------------------------------
    mov     ax, di                       ; Load current position
    xor     al, cl                       ; XOR with direction flag
    and     al, 7fh                      ; Check position within line
    jnz     fl7                          ; If not at boundary, continue

    ; Check if we've reached the end pixel of the line
    mov     al, ch                       ; Load bit mask
    add     al, cl                       ; Add direction flag
    and     al, 7fh                      ; Check result
    jnz     fl7                          ; If not at end pixel, continue

    ; ------------------------------------------------------------------
    ; LINE COMPLETION CHECK
    ; If we filled pixels in this pass, start new pass in opposite direction
    ; ------------------------------------------------------------------
    mov     al, fillflg                  ; Check if we filled any pixels
    and     al, 1
    jz      flb                          ; If no pixels filled, we're done
    xor     cl, 0ffh                     ; Toggle direction flag (FF<->00)
    jmp     fl2                          ; Start new pass

FL7:
    ; ------------------------------------------------------------------
    ; HORIZONTAL MOVEMENT
    ; Move cursor left or right based on direction flag
    ; ------------------------------------------------------------------
    or      cl, cl                       ; Test direction flag
    jz      fl9                          ; If zero, go left

    ; Move right
    clc                                  ; Clear carry flag
    rcr     ch, 1                        ; Rotate bit mask right
    jnc     fl3                          ; If no carry, stay in same byte
    inc     bx                           ; Move to next byte in work buffer
    inc     di                           ; Move to next byte in main buffer
    rcr     ch, 1                        ; Complete the bit rotation
    jmp     fl3                          ; Continue processing

FL9:
    ; Move left
    clc                                  ; Clear carry flag
    rcl     ch, 1                        ; Rotate bit mask left
    jnc     fl3                          ; If no carry, stay in same byte
    dec     bx                           ; Move to previous byte in work buffer
    dec     di                           ; Move to previous byte in main buffer
    rcl     ch, 1                        ; Complete the bit rotation
    jmp     fl3                          ; Continue processing

FLB:
    ; ------------------------------------------------------------------
    ; CLEANUP AND RETURN
    ; Restore original state and return to caller
    ; ------------------------------------------------------------------
    mov     aldsflg, 0                   ; Reset display flag
    mov     cursbit, ch                  ; Update final bit mask
    pop     bx                           ; Restore original cursor position
    mov     cursor, bx                   ; Update cursor variable
    ret                                  ; Return to caller

; ==================================================================
; ALGORITHM SUMMARY
; ==================================================================
; This flood fill algorithm works by:
; 1. Starting at the cursor position
; 2. Filling pixels horizontally in one direction until boundary
; 3. Switching direction and filling back
; 4. Repeating until no more pixels can be filled
; 5. Using neighbor checking to ensure only connected pixels are filled
; 6. Utilizing a work buffer to avoid affecting the main display during operation
; ==================================================================
