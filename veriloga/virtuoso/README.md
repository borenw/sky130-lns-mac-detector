# Schematic + ADE XL testbench (Virtuoso)

A Cadence **schematic** testbench and **ADE XL** setup that instantiate the two
Verilog-A models (`../mult_detector.va`, `../lns_detector.va`) and sweep `Vth`,
comparing `outM` (exact multiplier) against `outL` (log/LNS).

> These are GUI artifacts. They were **not** built on this host — headless Virtuoso
> is broken here (crashes/hangs on `-nograph`). The scripts below are standard SKILL/
> OCEAN to run in a real Virtuoso session; the underlying simulation is already
> validated by the direct Spectre run (`../spectre_run/RESULTS.md`).

## Environment (host `tau`)

```
export PATH=/usr/local/packages/cadence_2021/IC618/tools.lnx86/dfII/bin:$PATH
export PATH=/usr/local/packages/cadence_2021/SPECTRE201/tools.lnx86/bin:$PATH
export CDS_LIC_FILE=/usr/local/packages/cadence_2021/license.dat
# cds.lib in this dir already: DEFINE lns_lib ./lns_lib + SOFTINCLUDE ~/cds.lib (analogLib, basic)
virtuoso &      # display :1
```

## 1 — Import the Verilog-A models (creates symbols)

CIW ▸ **File ▸ Import ▸ Verilog-A…**
- Verilog-A file `../lns_detector.va`  → target library **`lns_lib`**, create symbol → OK
- Verilog-A file `../mult_detector.va` → target library **`lns_lib`**, create symbol → OK

Now `lns_lib/lns_detector/symbol` and `lns_lib/mult_detector/symbol` exist, with
pins `A B C D Vth` and the exposed outputs (`x y s lA…` / `p1 p2 s` / `out`).

## 2 — Build the schematic testbench

Fast path — CIW ▸ `load("mk_tb.il")` places both DUTs, the five DC sources
(A=25, B=30, C=12, D=40, Vth=**VTH**), and a gnd, and sets `XL` to `exact=0 kbits=2`.
Then in the schematic **wire** each source to the matching DUT pin, add net/pin
labels **`A B C D Vth outM outL x y sM sL`**, and **Check & Save**.

Manual path — new cellview `lns_lib/compare_tb/schematic`, then:

| instance | cell | key settings |
|---|---|---|
| `XM` | `lns_lib/mult_detector` | (exact baseline) |
| `XL` | `lns_lib/lns_detector` | `exact=0`, `kbits=2` |
| `VA VB VC VD` | `analogLib/vsource` | dc = `25 30 12 40` |
| `VVth` | `analogLib/vsource` | dc = `VTH` (design variable) |
| `G0` | `analogLib/gnd` | — |

Wire `XM` and `XL` to the **same** A,B,C,D,Vth nets; name the mult output `outM`, the
log output `outL`, and (optionally) the internal nets `x y sM sL` for probing.

## 3 — ADE XL test + Vth sweep

CIW ▸ **Launch ▸ ADE XL** → *Create new view* in `lns_lib` (e.g. `compare_adexl`).
1. **Tests ▸ add** `lns_lib compare_tb schematic`; simulator `spectre`.
2. **Design Variables ▸** `VTH = 600` (Copy From Design picks it up).
3. **Analyses ▸ dc**: *Sweep variable* = `VTH`, start `0`, stop `2000`, step `2`.
4. **Outputs ▸** add signals `outM` and `outL` (and `x y sM sL` to save/plot).
5. **Run**. Plot `outM` and `outL` vs `VTH`.

## 4 — Headless alternative (OCEAN)

Once the schematic exists, skip the ADE XL GUI:
```
ocean -replay compare.ocn      # DC-sweeps VTH, plots outM/outL, prints the flip points
```

## Expected result (verified in Spectre 20.1)

| | flips at Vth |
|--|--|
| `outM` exact multiplier | **1230** ( = A·B+C·D ) |
| `outL` log/LNS, K=2 | **1024** ( = 2^sL ) |

→ **disagreement band Vth ∈ [1024, 1228]** — identical to the RTL and to the direct
`spectre tb_compare.scs` run in [`../spectre_run/RESULTS.md`](../spectre_run/RESULTS.md).
