// SPDX-License-Identifier: 0BSD
//
// A collection of utility functions I've created and/or
// adapted for TempleOS.
//
// If you use any of these utilities, it would be cool if
// you mentioned my name somewhere and let me know my
// software is in your cool new project, but it's not
// necessary. I just ask that the software using these
// utilities respects Terry Davis' dignity.


// Random number generation ///////////////////////////////

// Fast ranged random function.
// Described here:
//   "Efficiently Generating a Number in a Range"
//   http://www.pcg-random.org/posts/bounded-rands.html
I64 RandRangeI64(I64 min=0, I64 max) {
  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}

// Graphics ///////////////////////////////////////////////

// Fills a buffer by linearly interpolating two colors
// through n steps in RGB space.
//
// Generally, the size of the buffer must equal the steps.
//
// If walk_back is enabled, it will walk back to the original
// color, in which case buffer must be of size (steps*2)-2
U0 InterpolateColors(CBGR48 *buf, I16 steps, CBGR48 c1, CBGR48 c2,
    Bool walk_back=FALSE) {
  I16 i;

  for (i=0;i<steps;i++) {
    buf[i].pad = 0;
    buf[i].r = (c2.r - c1.r) * i / steps + c1.r;
    buf[i].g = (c2.g - c1.g) * i / steps + c1.g;
    buf[i].b = (c2.b - c1.b) * i / steps + c1.b;
  }
  if (walk_back) {
    for (i=0;i<steps-2;i++) {
      buf[steps+i] = buf[steps-i-2];
    }
  }
}


// Sets the orientation of a sprite.
//   é: It's angle in radians.
//   is_flipped: If the sprite needs to flip.
U0 Target(F64 obj_x, F64 obj_y, F64 targ_x, F64 targ_y,
	F64 *obj_é, Bool *obj_is_flipped) {

  F64 delta_x = obj_x - targ_x;
  F64 delta_y = obj_y - targ_y;

  F64 hyp = Sqrt(delta_x`2 + delta_y`2);
  F64 é = ASin(delta_y / hyp);
  Bool is_flipped=FALSE;

  if (targ_x > obj_x) {
    is_flipped = TRUE;
  }

  // (Handle target being directly below object.)
  if (targ_y > obj_y && 1.57 < é < 1.58) é = -1.571;

  *obj_é = é;
  *obj_is_flipped = is_flipped;
}


// Draws a simulated dot-matrix display to the device context.
U0 DotMatrix(CDC *dc=gr.dc,I64 x, I64 y, I64 dot_diameter,
	I64 dot_spacing, U8 *string) {
  I64 i,j,k;
  I64 g; // matrix character graphic data


  // Character graphics data is stored in the 35 least significant
  // bits of an I64. It's a simple 5x7 1-bit-per-pixel format.

  for (i=0;i<StrLen(string);i++) {

    switch (string[i]) {
      case 'A': g=0b01110100011000111111100011000110001; break;
      case 'B': g=0b11110100011000111110100011000111110; break;
      case 'C': g=0b01110100011000010000100001000101110; break;
      case 'D': g=0b11110100011000110001100011000111110; break;
      case 'E': g=0b11111100001000011110100001000011111; break;
      case 'F': g=0b11111100001000011110100001000010000; break;
      case 'G': g=0b01110100011000010000101111000101110; break;
      case 'H': g=0b10001100011000111111100011000110001; break;
      case 'I': g=0b01110001000010000100001000010001110; break;
      case 'J': g=0b00001000010000100001000011000101110; break;
      case 'K': g=0b10001100101010011000101001001010001; break;
      case 'L': g=0b10000100001000010000100001000011111; break;
      case 'M': g=0b10001110111010110001100011000110001; break;
      case 'N': g=0b10001110011010110011100011000110001; break;
      case 'O': g=0b01110100011000110001100011000101110; break;
      case 'P': g=0b11110100011000111110100001000010000; break;
      case 'Q': g=0b01110100011000110001101011001001101; break;
      case 'R': g=0b11110100011000111110101001001010001; break;
      case 'S': g=0b01110100011000001110000011000101110; break;
      case 'T': g=0b11111001000010000100001000010000100; break;
      case 'U': g=0b10001100011000110001100011000101110; break;
      case 'V': g=0b10001100011000110001100010101000100; break;
      case 'W': g=0b10001100011000110001101011101110001; break;
      case 'X': g=0b10001100010101000100010101000110001; break;
      case 'Y': g=0b10001100010101000100001000010000100; break;
      case 'Z': g=0b11111000010001000100010001000011111; break;
      case '!': g=0b00100001000010000100001000000000100; break;
      case '.': g=0b00000000000000000000000000000000100; break;
      case '?': g=0b01110100010000100010001000000000100; break;
      case '0': g=0b01110100011001110101110011000101110; break;
      case '1': g=0b01100001000010000100001000010000100; break;
      case '2': g=0b01110100010000100010001000100011111; break;
      case '3': g=0b01110100010000100110000011000101110; break;
      case '4': g=0b00010001100101010010111110001000010; break;
      case '5': g=0b11111100001111000001000011000101110; break;
      case '6': g=0b01110100011000011110100011000101110; break;
      case '7': g=0b11111000010001000100010001000010000; break;
      case '8': g=0b01110100011000101110100011000101110; break;
      case '9': g=0b01110100011000101110000011000101110; break;
      case ' ': g=0; break;
      default:  g=0b01110100011000100010001000000000100; // "?"
    }

    for (j=0; j<7; j++) {
      for (k=0; k<5; k++) {
        if (g >> (34-(j*5+k))&1) {
          GrFillCircle(dc,(x+k*dot_spacing)+(i*dot_spacing*6),
		y+j*dot_spacing,,dot_diameter);
        }
      }
    }
  }
}
