# Document old LED display code
_Exported on 7/4/2025 at 15:27:48 EDT from Cursor (1.2.1)_

---

**User**

I have this piece of old code. It somehow relates to an LED display. Figure out what it does, explain it in a README.md file in this, and then write an annotated copy of the code explaining it in detail.

---

**Cursor**

I'll analyze this old assembly code to understand what it does and create the documentation you requested. Let me examine the code structure and logic first.

```markdown
# LED Display Flood Fill Algorithm

## Overview

This assembly code implements a **flood fill algorithm** for an LED display or bitmap graphics system. The code is written in x86 assembly language and appears to be from an older embedded system or graphics application.

## What It Does

The `FILLIN` subroutine performs a flood fill operation starting from a cursor position on an LED display. It fills connected pixels/bits in a horizontal line-by-line manner, similar to the paint bucket tool in graphics programs.

### Key Features

- **Dual Buffer System**: Uses both a main graphics buffer (`gbuffer`) and a work buffer (`fillpage`)
- **Horizontal Line Fill**: Fills pixels horizontally in alternating directions (left-to-right, then right-to-left)
- **Neighbor Detection**: Uses orthogonal neighbor checking to determine fill boundaries
- **Cursor-Based**: Starts filling from the current cursor position
- **Optional Copy Mode**: Can optionally copy filled pixels to the main buffer during operation

## Algorithm Flow

1. **Initialization**: Save cursor position and set up work buffers
2. **Line Scanning**: Fill pixels horizontally in the current line
3. **Neighbor Check**: Use `neighb` function to verify if pixels should be filled
4. **Direction Toggle**: Alternate between left-to-right and right-to-left scanning
5. **Boundary Detection**: Stop when reaching frame boundaries or when no more pixels need filling
6. **Cleanup**: Restore original cursor position and buffer states

## Data Structures

- `gbuffer`: Main graphics buffer containing the LED display data
- `fillpage`: Work buffer for flood fill operations
- `cursor`: Current cursor position in the buffer
- `cursbit`: Bit mask for the current cursor position
- `fcopyflg`: Flag to enable copying to main buffer during fill
- `fillflg`: Flag indicating if any pixels were changed in current pass
- `direction`: Fill direction flag

## Use Cases

This type of flood fill algorithm would be used in:
- LED matrix displays
- Simple graphics editors
- Embedded systems with bitmap displays
- Industrial control panels
- Early computer graphics applications

## Technical Notes

- Uses bit-level operations for efficient pixel manipulation
- Implements a scanline-based flood fill (not recursive)
- Designed for memory-constrained environments
- Optimized for horizontal pixel access patterns typical of LED displays
```

```plaintext
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
```

I've analyzed your old LED display code and created the requested documentation. Here's what I found:

## What the Code Does

This is a **scanline-based flood fill algorithm** for LED displays, written in x86 assembly language. It's similar to the "paint bucket" tool in graphics programs - it fills connected pixels starting from a cursor position.

## Key Features I Identified

1. **Dual Buffer System**: Uses both a main graphics buffer (`gbuffer`) and a work buffer (`fillpage`) for safe operations
2. **Horizontal Line Filling**: Fills pixels horizontally, alternating directions (left-to-right, then right-to-left)
3. **Neighbor Detection**: Uses a `neighb` function to check orthogonal neighbors before filling
4. **Bit-Level Operations**: Efficiently manipulates individual pixels using bit masks
5. **Memory Efficient**: Uses a scanline approach instead of recursion, making it suitable for embedded systems

## Files Created

1. **README.md** - Contains a comprehensive explanation of the algorithm, its features, data structures, and use cases
2. **annotated_code.asm** - The original code with extensive line-by-line annotations explaining each operation

The algorithm is quite sophisticated for its time, implementing a non-recursive flood fill that's optimized for horizontal pixel access patterns typical of LED matrix displays. It would have been used in industrial control panels, early graphics systems, or embedded applications where memory was limited but efficient graphics operations were needed.

The code shows good engineering practices like using work buffers to avoid corrupting the main display during operations and implementing boundary checking to prevent buffer overruns.

