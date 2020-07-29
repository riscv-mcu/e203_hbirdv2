 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
// Designer   : Bob Hu
//
// Description:
//  This module to implement the extended CSR
//    current this is an empty module, user can hack it 
//    become a real one if they want
//
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_CSR_NICE//{
module e203_extend_csr(

  // The Handshake Interface 
  input          nice_csr_valid,
  output         nice_csr_ready,

  input   [31:0] nice_csr_addr,
  input          nice_csr_wr,
  input   [31:0] nice_csr_wdata,
  output  [31:0] nice_csr_rdata,

  input  clk,
  input  rst_n
  );

  assign nice_csr_ready = 1'b1;
  assign nice_csr_rdata = 32'b0;


endmodule
`endif//}
