
// This is the top-level of the filter module, which you must implement.

// Module Description:
// Simple 2D image low-pass filter module.
// Convolves input image with 3x3 kernel:
//  [ 1 2 1 ]
//  [ 2 4 2 ] * 1/16
//  [ 1 2 1 ]
// Input pixels that fall outside of the image are assumed to be 0.
// Output is rounded to nearest integer.

module hw_dut #(
    parameter XB        = 10,
    parameter YB        = 10,
    parameter PB        = 8
) (
    // system
    input   wire                clk,
    input   wire                rst,                // active-high synchronous reset

    // configuration
    // will be static for at least 8 cycles before rst is released
    input   wire    [XB-1:0]    cfg_width,          // width of image in pixels; 0 based ('d0 = 1 pixel wide)
    input   wire    [YB-1:0]    cfg_height,         // height of image in pixels; 0 based ('d0 = 1 pixel high)

    // unfiltered pixel input stream (row-major)
    // data is transferred on each clock edge where ready and valid are both asserted
    output  reg                 px_in_ready,
    input   wire                px_in_valid,
    input   wire    [PB-1:0]    px_in_data,         // unfiltered pixel data

    // filtered pixel output stream (row-major)
    // data is transferred on each clock edge where ready and valid are both asserted
    input   wire                px_out_ready,
    output  reg                 px_out_valid,
    output  reg                 px_out_last_y,      // asserts for all pixels in last row
    output  reg                 px_out_last_x,      // asserts for last pixel in each row
    output  reg     [PB-1:0]    px_out_data,        // filtered pixel data

    // status
    output  reg                 done                // asserts once last pixel has been accepted by output consumer
);

// TODO: implement this module

endmodule

