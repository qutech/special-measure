


# VISA Errors #
These are errors common to all VISA (most USB and ethernet devices)
connected devices.

```
??? Error using ==> icinterface.fprintf at 147
VISA: The connection for the given session has been lost.
```

USB and Ethernet VISA connections will be closed if the device is disconnected or rebooted.  **[smclose](smclose.md)** and **[smopen](smopen.md)** the device.

# AWG Errors #
```
-500,"Power On"
```

The AWG was just turned on.  Harmless, ignore.

```
"Sequence/Waveform loading error; E11203 - AWGC:RUN"
```
No waveform defined for one of the channels.  Probably the AWG is not in sequence mode.