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
