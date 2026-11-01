\ PREVIEW BUFFERS \

create I-PREVIEW 0 c, 0 c, 0 c, 0 c,
                 1 c, 1 c, 1 c, 1 c,
                 0 c, 0 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create J-PREVIEW 0 c, 0 c, 0 c, 0 c,
                 2 c, 2 c, 2 c, 0 c,
                 0 c, 0 c, 2 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create L-PREVIEW 0 c, 0 c, 0 c, 0 c,
                 3 c, 3 c, 3 c, 0 c,
                 3 c, 0 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create T-PREVIEW 0 c, 0 c, 0 c, 0 c,
                 4 c, 4 c, 4 c, 0 c,
                 0 c, 4 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create O-PREVIEW 5 c, 5 c, 0 c, 0 c,
                 5 c, 5 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create S-PREVIEW 0 c, 6 c, 6 c, 0 c,
                 6 c, 6 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

create Z-PREVIEW 7 c, 7 c, 0 c, 0 c,
                 0 c, 7 c, 7 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,
                 0 c, 0 c, 0 c, 0 c,

: pice-to-buf ( n -- a )
  case
    I-PICE of I-PREVIEW endof
    J-PICE of J-PREVIEW endof
    L-PICE of L-PREVIEW endof
    T-PICE of T-PREVIEW endof
    O-PICE of O-PREVIEW endof
    S-PICE of S-PREVIEW endof
    Z-PICE of Z-PREVIEW endof
  endcase
;

: preview-buffer ( -- a )
  Next-pice-shape pice-to-buf ;
