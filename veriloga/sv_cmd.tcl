# SimVision command script:  simvision <db>.trn -input sv_cmd.tcl
# Opens a waveform window and adds the comparison signals.
set db [lindex [database list] 0]
window new WaveWindow -name "VA compare"
waveform using [window find -match exact -name "VA compare"]
foreach s {outM outL Vth sL sM x y} {
    catch { waveform add -signals ${db}::$s }
}
