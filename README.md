# Eliminating Multipliers with K=1 Log / LNS Arithmetic — SkyWater 130 nm

Two RTL designs of the **same function** — `spike = (A·B + C·D) > Vth`, with
**12-bit** inputs (`A,B,C,D` ∈ 0…4095, 25-bit `Vth`) — built, verified,
synthesized on the open-source **sky130** HD standard-cell library, and compared
on **area and power**:

- **Design 1 (baseline):** exact multiplier — `A*B + C*D`, one comparator.
- **Design 2 (K=1 log / LNS):** *no multipliers*. Each input goes through a
  leading-one detector + 1 mantissa bit (K=1 log2), logs are added, combined with an
  LNS add `s = max(x,y) + F(|x−y|)` (small ROM), and compared in the log domain.

📄 **Live page:** https://borenw.github.io/sky130-lns-spike-detector/ · full writeup in
[`report/SUMMARY.md`](report/SUMMARY.md)

## Result

| Metric | Design 1 · multiplier | Design 2 · log K=1 | Design 2 / 1 |
|---|--:|--:|--:|
| Standard-cell area | 12015.27 µm² | **3569.67 µm²** | 0.297× (**−70.3%**) |
| Die size (x × y @65%) | 135.9 × 136.0 µm | **74.8 × 73.4 µm** | −70.3% |
| Std-cell count | 1476 | **416** | 0.282× |
| Multipliers (`$mul`) | 2 | **0** | eliminated |
| Energy / op (est.) | 9.714 pJ | 2.483 pJ | 0.256× |
| Power @ 50 MHz (est.) | 485.72 µW | **124.15 µW** | 0.256× (**−74.4%**) |
| Accuracy vs exact | reference | ≈5.60 % disagree | K=1 cost |
| Verification | PASS (= `exp_exact`) | PASS (= `exp_k1`) | both bit-exact |

**Takeaway:** dropping the two 12-bit multipliers for the K=1 log detector cuts area
~70 % and estimated power ~74 %, at a **≈5.6 % disagreement** with exact math
(concentrated in the mid dynamic range, zero at the extremes). The saving is far
larger than at 5-bit (−28 %) because multiplier area grows ~quadratically with width
while the log datapath grows ~linearly.

### Standard-cell floorplans (measured die x × y, same scale)

| Design 1 — multiplier | Design 2 — log K=1 |
|---|---|
| ![Design 1 layout](docs/mult_layout.png) | ![Design 2 layout](docs/log_layout.png) |

Both dies are drawn at the **same scale** — Design 2's dashed frame is Design 1's
footprint, so the ~4× area difference is literal. Colored by cell function:
🔵 flip-flops · 🟢 adder (xor/maj) · 🟡 mux · 🟣 logic · 🟠 clk/buf. The multiplier is
dominated by adder cells; the log design replaces them with logic + a small ROM/mux.

> **Note on the layout:** no place-and-route tool (OpenROAD/Innovus) was available on the
> build host, so the die x/y is a **standard-cell floorplan estimate** — the real
> synthesized cells packed into 2.72 µm rows at 65 % utilization — **not a routed
> layout**. A real `.gds` bounding-box file is emitted per design. The
> Design-2/Design-1 **ratio** is robust; the absolute x/y scales with the utilization
> assumption. Routed numbers would come from OpenROAD/OpenLane + OpenSTA.

## Reproduce

Needs `iverilog`, `yosys` (or `yowasp-yosys`), `python3`+`numpy`; `gdstk`+`cairosvg`
for the layout/page.

```bash
./run.sh                          # phases 1–7: model → verify → synth → power → floorplan → page
# or individual pieces:
python3 model/model.py            # golden model + emits rtl/lns_ftable.v (F-ROM)
# ... yosys synth via synth/run_*.ys ...
python3 model/floorplan.py        # die x/y + synth/*.gds + report/*_layout.svg
python3 model/build_page.py       # docs/index.html
```

## Layout

```
rtl/     mult_detector.v · log_detector.v · lod5.v · lns_add.v · lns_ftable.v (generated)
model/   model.py (golden + ROM gen) · power_area.py · floorplan.py · build_page.py
verif/   tb.v · vectors.csv · sim_report.txt
synth/   run_mult.ys · run_log.ys · *_netlist.v · *.gds · sky130_*.lib
report/  SUMMARY.md · model_accuracy.txt · elaboration.txt · power_area.csv · floorplan.csv · *_layout.svg
docs/    index.html (GitHub Pages) · layout PNGs
```

## Method notes

- **One golden model, no drift:** `model.py` is the spec for *both* designs and
  **emits the `F(d)` ROM** consumed by the Verilog, so model and hardware can't diverge.
- **Design 2's "correct" answer is the K=1 model, not exact math.** RTL is checked
  bit-exact to `spike_k1` (0 mismatches / 63,875 vectors); disagreement with exact math
  is the *approximation cost*, reported separately.
- **No latches, no multipliers** in Design 2 (yosys audit); both netlists fully mapped
  to sky130 cells with zero `$`-cells.
- Power is an analytic switching estimate `E = α(1+wire)·ΣCin·Vdd²`
  (Vdd=1.8 V, α=0.15, wire=1.0×, f=50 MHz); the ×baseline ratio is the robust figure.

*Standard-cell liberty `sky130_fd_sc_hd__tt_025C_1v80.lib` © Google/SkyWater, Apache-2.0.*
