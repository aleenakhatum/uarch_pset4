# uarch_pset4

Supported Instructions: 
    ADD
    - 01 /r	ADD r/m16,r16
    - 05 id	(ADD EAX,imm32)	
    - 83 /0 ib (ADD r/m32,imm8)

    MOV
    - B8+ rd (MOV r32,imm32)

    JMP
    - E9 cd	(JMP rel32)

    HLT
    - F4 (Halt)

How to Run:
1. Copy the Entire Directory of Files
2. Go to pset4/testbench and input test cases the same as the two example formats (ctrlflow.hex, deptest.hex) where there is no 0x in front of the bytes and each byte is on a new line. Name the file as follows: <X.hex> where X is the name of the test case.
3. Go to pset4/src/fetch/instr_mem.v and change the name of the file that is being accessed.

Do in MobaX
Compile Command: <vcs -debug_all -f master>
Run Command: <./simv>
Open DVE: <dve>