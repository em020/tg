module abs_diff_line(cur_upper_pix, cur_middle_pix, cur_lower_pix, org_pix,
                     diff_UH_h, diff_UH_q, diff_UH_f,
                     diff_UQ_h, diff_UQ_q, diff_UQ_f,
                     diff_M_h , diff_M_q , diff_M_f ,
                     diff_LQ_h, diff_LQ_q, diff_LQ_f,
                     diff_LH_h, diff_LH_q, diff_LH_f);

  input [63:0] cur_upper_pix;
  input [63:0] cur_middle_pix;
  input [63:0] cur_lower_pix;
  input [63:0] org_pix;

  output [111:0] diff_UH_h;
  output [111:0] diff_UH_q;
  output [ 55:0] diff_UH_f;

  output [111:0] diff_UQ_h;
  output [111:0] diff_UQ_q;
  output [ 55:0] diff_UQ_f;

  output [111:0] diff_M_h;
  output [111:0] diff_M_q;
  output [ 55:0] diff_M_f;

  output [111:0] diff_LQ_h;
  output [111:0] diff_LQ_q;
  output [ 55:0] diff_LQ_f;

  output [111:0] diff_LH_h;
  output [111:0] diff_LH_q;
  output [ 55:0] diff_LH_f;

  // Follow the next diagram:
  // f   h q f q h   f <-- Index
  //
  // o   + + o + +   o <-- UF = Upper Full
  //
  // +   x x x x x   + <-- UH = Upper Half
  //     x x x x x     <-- UQ = Upper Quarter
  // o   x x o x x   o <-- M  = Middle
  //     x x x x x     <-- LQ = Lower Quarter
  // +   x x x x x   + <-- LH = Lower Half
  //
  // o   + + o + +   o <-- LF = Lower Full
  //
  // o --> Full pixel positions
  // x --> Fractional pixel positions
  // + --> Fractional pixel positions that are needed to calculate some 'x'
  //
  // Since the q pixels are twice than than the h pixels, they need to be held
  //  by wires of twice the size.
  //
  // To avoid padding of pixels, only the subpixels between the full pixels are
  //  calculated. This leaves only 7 half pixels and 14 quarter pixels for each
  //  line, each 8 bits wide, thus the wire width is 56 or 112.
  //
  // All subpixels are only calculated in 7 or 14 positions, thus the width of
  //  56 or 112 bits. The only exception is UH_f and LH_F because the extra
  //  result is needed for for the calculation of other sub-pixels

  wire [55:0]    UF_h;            
  wire [111:0]   UF_q;

  wire [55:0]    M_h;            
  wire [111:0]   M_q;

  wire [55:0]    LF_h;            
  wire [111:0]   LF_q;

  filter_half    fhu(cur_upper_pix,UF_h);
  filter_quarter fqu(cur_upper_pix,UF_q);

  filter_half    fhm(cur_middle_pix,M_h);
  filter_quarter fqm(cur_middle_pix,M_q);

  filter_half    fhl(cur_lower_pix,LF_h);
  filter_quarter fql(cur_lower_pix,LF_q);

  wire [63:0]     UH_f;
  wire [63:0]     LH_f;

  genvar          i;
  generate
    for(i=0; i<64; i=i+8) begin: UH_LH_f_gen
      assign UH_f[i+7:i] = (cur_upper_pix[i+7:i] + cur_middle_pix[i+7:i]) >> 1;
      assign LH_f[i+7:i] = (cur_lower_pix[i+7:i] + cur_middle_pix[i+7:i]) >> 1;
    end
  endgenerate

  wire [55:0]     UH_h;
  wire [55:0]     LH_h;

  generate
    for(i=0;i<56;i=i+8) begin: UH_LH_h_gen
      assign UH_h[i+7:i] = (UF_h[i+7:i] + M_h[i+7:i]) >> 1;
      assign LH_h[i+7:i] = (LF_h[i+7:i] + M_h[i+7:i]) >> 1;
    end
  endgenerate

  wire [111:0]    UH_q;
  wire [111:0]    LH_q;

  generate
    for(i=0;i<56;i=i+8) begin: UH_LH_q_gen
      assign UH_q[2*i+ 7:2*i  ] = (UH_f[i+ 7:i   ] + 3*UH_f[i+15:i+8]) >> 2;
      assign UH_q[2*i+15:2*i+8] = (UH_f[i+23:i+16] + 3*UH_f[i+15:i+8]) >> 2;

      assign LH_q[2*i+ 7:2*i  ] = (LH_f[i+ 7:i   ] + 3*LH_f[i+15:i+8]) >> 2;
      assign LH_q[2*i+15:2*i+8] = (LH_f[i+23:i+16] + 3*LH_f[i+15:i+8]) >> 2;
    end
  endgenerate

  wire [55:0]     UQ_h;
  wire [55:0]     LQ_h;
  wire [111:0]    UQ_q;
  wire [111:0]    LQ_q;

  generate
    for(i=0;i<56;i=i+8) begin: UQ_LQ_h_q_gen
      assign UQ_h[i+7:i] = (UF_h[i+7:i] + 3*M_h[i+7:i]) >> 2;
      assign LQ_h[i+7:i] = (LF_h[i+7:i] + 3*M_h[i+7:i]) >> 2;

      assign UQ_q[2*i+ 7:2*i  ] = (UF_q[2*i+ 7:2*i  ] + 3*M_q[2*i+ 7:2*i  ]) >> 2;
      assign UQ_q[2*i+15:2*i+8] = (UF_q[2*i+15:2*i+8] + 3*M_q[2*i+15:2*i+8]) >> 2;

      assign LQ_q[2*i+ 7:2*i  ] = (LF_q[2*i+ 7:2*i  ] + 3*M_q[2*i+ 7:2*i  ]) >> 2;
      assign LQ_q[2*i+15:2*i+8] = (LF_q[2*i+15:2*i+8] + 3*M_q[2*i+15:2*i+8]) >> 2;
    end
  endgenerate

  generate
    for(i=0; i<56; i=i+8) begin: abs_diff_generate
      abs_diff ad_UH_h(org_pix[i+ 7:i  ],UH_h[  i+ 7:  i  ],diff_UH_h[2*i+ 7:2*i  ]);
      abs_diff ad_UH_i(org_pix[i+15:i+8],UH_h[  i+15:  i+8],diff_UH_h[2*i+15:2*i+8]);
      abs_diff ad_UH_q(org_pix[i+ 7:i  ],UH_q[2*i+ 7:2*i  ],diff_UH_q[2*i+ 7:2*i  ]);
      abs_diff ad_UH_r(org_pix[i+15:i+8],UH_q[2*i+15:2*i+8],diff_UH_q[2*i+15:2*i+8]);
      abs_diff ad_UH_f(org_pix[i+7 :i  ],UH_h[  i+7 :  i  ],diff_UH_f[  i +7:  i  ]);

      abs_diff ad_UQ_h(org_pix[i+ 7:i  ],UQ_h[  i+ 7:  i  ],diff_UQ_h[2*i+ 7:2*i  ]);
      abs_diff ad_UQ_i(org_pix[i+15:i+8],UQ_h[  i+15:  i+8],diff_UQ_h[2*i+15:2*i+8]);
      abs_diff ad_UQ_q(org_pix[i+ 7:i  ],UQ_q[2*i+ 7:2*i  ],diff_UQ_q[2*i+ 7:2*i  ]);
      abs_diff ad_UQ_r(org_pix[i+15:i+8],UQ_q[2*i+15:2*i+8],diff_UQ_q[2*i+15:2*i+8]);
      abs_diff ad_UQ_f(org_pix[i+7 :i  ],UQ_h[  i+7 :  i  ],diff_UQ_f[  i +7:  i  ]);


      abs_diff ad_M_h(org_pix[i+ 7:i  ], M_h[  i+ 7:  i  ], diff_M_h[2*i+ 7:2*i  ]);
      abs_diff ad_M_i(org_pix[i+15:i+8], M_h[  i+15:  i+8], diff_M_h[2*i+15:2*i+8]);
      abs_diff ad_M_q(org_pix[i+ 7:i  ], M_q[2*i+ 7:2*i  ], diff_M_q[2*i+ 7:2*i  ]);
      abs_diff ad_M_r(org_pix[i+15:i+8], M_q[2*i+15:2*i+8], diff_M_q[2*i+15:2*i+8]);
      abs_diff ad_M_f(org_pix[i+15:i+8],cur_middle_pix[i+15:i+8],diff_M_f[i+7:i  ]);


      abs_diff ad_LQ_h(org_pix[i+ 7:i  ],LQ_h[  i+ 7:  i  ],diff_LQ_h[2*i+ 7:2*i  ]);
      abs_diff ad_LQ_i(org_pix[i+15:i+8],LQ_h[  i+15:  i+8],diff_LQ_h[2*i+15:2*i+8]);
      abs_diff ad_LQ_q(org_pix[i+ 7:i  ],LQ_q[2*i+ 7:2*i  ],diff_LQ_q[2*i+ 7:2*i  ]);
      abs_diff ad_LQ_r(org_pix[i+15:i+8],LQ_q[2*i+15:2*i+8],diff_LQ_q[2*i+15:2*i+8]);
      abs_diff ad_LQ_f(org_pix[i+7 :i  ],LQ_h[  i+7 :  i  ],diff_LQ_f[  i +7:  i  ]);

      abs_diff ad_LH_h(org_pix[i+ 7:i  ],LH_h[  i+ 7:  i  ],diff_LH_h[2*i+ 7:2*i  ]);
      abs_diff ad_LH_i(org_pix[i+15:i+8],LH_h[  i+15:  i+8],diff_LH_h[2*i+15:2*i+8]);
      abs_diff ad_LH_q(org_pix[i+ 7:i  ],LH_q[2*i+ 7:2*i  ],diff_LH_q[2*i+ 7:2*i  ]);
      abs_diff ad_LH_r(org_pix[i+15:i+8],LH_q[2*i+15:2*i+8],diff_LH_q[2*i+15:2*i+8]);
      abs_diff ad_LH_f(org_pix[i+7 :i  ],LH_h[  i+7 :  i  ],diff_LH_f[  i +7:  i  ]);

    end
  endgenerate


endmodule
