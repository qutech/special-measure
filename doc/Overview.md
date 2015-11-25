# Introduction #

Special Measure provides a simple frontend for MATLAB's instrument control toolbox, allowing users to quickly set up flexible scans through parameter space.



---

# Quick Reference #
## Structures ##
  * [Scans\_new](Scans_new.md)
  * [smdata\_new](smdata_new.md)

## Functions ##
### Main measurement routine ###
| **[smrun](smrun.md)** | Run a scan. |
|:----------------------|:------------|

### Channel Control ###
| **[smset](smset.md)** |   Set channel values. |
|:----------------------|:----------------------|
| **[smget](smget.md)** |  Read channel values. |
| **[smprintchannels](smprintchannels.md)** | Print channel information |
| **[smprintrange](smprintrange.md)** |    Print range and rate information |

### Scan configuration ###
| **[smdiagpar](smdiagpar.md)**   | Configure scan rotation. |
|:--------------------------------|:-------------------------|
| **[smscanpar](smscanpar.md)**   | Set scan range and resolution. |
| **[smalintrafo](smalintrafo.md)** | Set up a rotated scan. |
| **[smprintscan](smprintscan.md)** | Print scan parameters. |

### Setup ###
| **[smaddchannel](smaddchannel.md)** | Create a new channel |
|:------------------------------------|:---------------------|
| **[sminitdisp](sminitdisp.md)** |   Configure  figure 1001 to display current channel values.  To disable this feature, close figure 1001. |

### Instrument Control ###
| **[smopen](smopen.md)**  |   Open instruments. |
|:-------------------------|:--------------------|
| **[smclose](smclose.md)** | Close instruments. |
| **[smprintinst](smprintinst.md)** |	 Print instrument information |

### Low-level Instrument I/O ###
| **[smprintf](smprintf.md)** | Wrapper for fprintf. |
|:----------------------------|:---------------------|
| **[smscanf](smscanf.md)** | Wrapper for fscanf. |
| **[smquery](smquery.md)** |  Wrapper for query. |


---

## Auxiliary functions ##
### Configuration and control of specific instruments ###

| **smarampYokoSR830dmm** | Set up linewise acquisition with dmm and/or lockin |
|:------------------------|:---------------------------------------------------|
| **smarampYokoSR830** |    Subset of above, no dmm support |
| **smarampYokoTDS** |      Set up linewise acquisition with TDS5104. |
| **smaDMMsnglmode** |	     Restore default sample parameters for DMM(s). |
| **smastopYokos**  |	     Stop ramps on Yokos. |

### Trigger routines (used as trigfn's) ###
| **smatrigYokoSR830dmm** | |
|:------------------------|:|
| **smatrigYokoTDS** |  |
| **smatrigYokoSR830** | (Obsolete, no longer maintained) |
| **smatrig** |  |


---

### Other routines, mainly used internally ###
| **smdispchan**   | Update display of current values |
|:-----------------|:---------------------------------|
| **smchanlookup** | Translation from channel name to index |
| **sminstlookup** | Translation form device name to index |
| **smchaninst**   | get instrument associated with a channel |