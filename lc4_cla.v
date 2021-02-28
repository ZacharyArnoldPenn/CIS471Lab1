/* TODO: INSERT NAME AND PENNKEY HERE */
//Christopher Williams chrwill
/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

    wire g_one_zero = gin[1]|(pin[1]&gin[0]);
    wire p_one_zero = &pin[1:0];

    assign cout[0] = gin[0] | (pin[0]&cin);
    assign cout[1] = g_one_zero | (p_one_zero&cin);
    assign cout[2] = (gin[2]) | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & cin);

    assign gout = (gin[3] | (pin[3]&gin[2])) | ((pin[3]&pin[2]) & g_one_zero);
    assign pout = &pin[3:0];
  

    //gpn #(4) g (.gin(gin),.pin(pin),.cin(cin),.gout(gout),.pout(pout),.cout(cout));
  
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

  wire [15:0] g;
  wire [15:0] p;

  genvar i;
  for (i = 0; i < 16; i = i + 1) begin 
        gp1 gp(.a(a[i]),.b(b[i]),.g(g[i]),.p(p[i]));
  end

  wire [15:0] c;
  assign c[0] = cin;
  wire [3:0] g_inter;
  wire [3:0] p_inter;
  wire [3:0] c_inter;
  assign c_inter[0] = cin;

  genvar j;
  for (j = 0; j < 4; j = j + 1) begin 
    gp4 gp_inter(.gin(g[((j+1)*4)-1:((j+1)*4-4)]),
    .pin(p[((j+1)*4)-1:((j+1)*4-4)]),
    .cin(c_inter[j]),
    .gout(g_inter[j]),
    .pout(p_inter[j]),
    .cout(c[((j+1)*4)-1:((j+1)*4-3)]));
  end
  
  
  gp4 gp_last(.gin(g_inter),
        .pin(p_inter),
        .cin(cin),
        .gout(),
        .pout(),
        .cout(c_inter[3:1]));

  wire [15:0] c_final;

  assign c_final[0] = cin;
  assign c_final[1] = c[1];
  assign c_final[2] = c[2];
  assign c_final[3] = c[3];
  assign c_final[4] = c_inter[1];
  assign c_final[5] = c[5];
  assign c_final[6] = c[6];
  assign c_final[7] = c[7];
  assign c_final[8] = c_inter[2];
  assign c_final[9] = c[9];
  assign c_final[10] = c[10];
  assign c_final[11] = c[11];
  assign c_final[12] = c_inter[3];
  assign c_final[13] = c[13];
  assign c_final[14] = c[14];
  assign c_final[15] = c[15];

  assign sum = (a^b)^c_final;
  //assign sum = c_final;
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, 
   input wire [N-1:0] pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);

    //wire [((N*(N+1)/2)):0] clause;

    genvar i;
    generate
    for (i = 0; i < N; i = i + 1) begin
        wire [i:0] clause;
        genvar j;

        assign clause[0] = (&pin[i:0]) & cin;
        for (j = 1; j <= i; j = j + 1) begin 
            assign clause[j] = (&pin[i:j]) & gin[j-1];
        end

        assign cout[i] = |clause | gin[i];
    end
    endgenerate

    wire [N-1:0] clause2;
    genvar k;
    assign clause2[0] = 1'b0;
    for (k = 1; k <= N-1; k = k + 1) begin 
        assign clause2[k] = &pin[N-1:k] & gin[k-1];
    end

    assign gout = (|clause2) | gin[N-1];
    assign pout = &pin[N-1:0];
 
endmodule
