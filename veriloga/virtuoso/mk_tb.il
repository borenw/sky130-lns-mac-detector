/* mk_tb.il  --  load in the Virtuoso CIW:   load("mk_tb.il")
 *
 * Builds a schematic testbench  lns_lib/compare_tb/schematic  holding BOTH
 * Verilog-A DUTs (mult_detector + lns_detector) with DC sources for A,B,C,D,Vth
 * and a global gnd.  Operands are set to 25,30,12,40 ; the Vth source dc is the
 * design variable VTH (swept by ADE XL / compare.ocn).
 *
 * PREREQUISITE  -- import the two models first so their symbols exist:
 *   CIW > File > Import > Verilog-A...  ->  ../lns_detector.va  , target lib "lns_lib"
 *   CIW > File > Import > Verilog-A...  ->  ../mult_detector.va , target lib "lns_lib"
 *
 * This script places instances and sets source values (reliable, standard SKILL).
 * WIRING is left to the GUI because the auto-generated VA-symbol pin coordinates
 * are not known here: open the schematic, connect each source (+) to the matching
 * DUT pin, add pin/net labels  A B C D Vth  outM outL x y sM sL , then Check&Save.
 */

let( (lib cv place mkSrc)

    lib = "lns_lib"
    unless( ddGetObj(lib) dbCreateLib(lib) )
    cv = dbOpenCellViewByType(lib "compare_tb" "schematic" "schematic" "w")

    ;; place a symbol instance, erroring clearly if the master is missing
    place = lambda( (libN cellN name loc)
        let( (m)
            m = dbOpenCellViewByType(libN cellN "symbol" "" "r")
            unless( m error("missing %s/%s/symbol -- import the .va into lns_lib first" libN cellN))
            dbCreateInst(cv m name loc "R0") ))

    ;; place a DC vsource, set value (or variable), via CDF params
    mkSrc = lambda( (name val loc)
        let( (inst cdf)
            inst = place("analogLib" "vsource" name loc)
            cdf  = cdfGetInstCDF(inst)
            when( cdf
                cdf->srcType->value = "dc"
                cdf->vdc->value     = val )       ; val is a string: "25" or "VTH"
            inst ))

    ;; DUTs -- set the log model to the K=2 hardware form
    place(lib "mult_detector" "XM"  4.0:0.0)
    let( (xl cdf)
        xl  = place(lib "lns_detector" "XL"  4.0:-3.0)
        cdf = cdfGetInstCDF(xl)
        when( cdf  cdf->exact->value = "0"   cdf->kbits->value = "2" ))

    ;; sources + ground
    mkSrc("VA"   "25"  0.0:2.0)
    mkSrc("VB"   "30"  0.0:1.0)
    mkSrc("VC"   "12"  0.0:0.0)
    mkSrc("VD"   "40"  0.0:-1.0)
    mkSrc("VVth" "VTH" 0.0:-2.0)                  ; swept design variable
    place("analogLib" "gnd" "G0"  0.0:-3.5)

    schCheck(cv)
    dbSave(cv)
    printf("\n*** lns_lib/compare_tb/schematic created (7 instances placed).\n")
    printf("    Wire the sources to the DUT pins, label nets A B C D Vth outM outL x y sM sL,\n")
    printf("    Check&Save, then build the ADE XL test (see README) or run compare.ocn.\n\n")
    cv
)
