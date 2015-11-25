# Writing Instrument Drivers #

Adding new instruments consists of two parts: writing a [control function](#Control_Function.md) and specifying the instrument information in [\*smdata.inst\*](#smdata.inst.md), a struct array with the following fields:

### smdata.inst ###

| cntrlfn  | Function handle of the control function |
|:---------|:----------------------------------------|
| data     | instrument specific data. An open MATLAB instrument object representing the instrument should be stored in data.inst, if a applicable. |
| datadim  | array with non-singleton data dimensions for each channel (no entry needed for singleton dimensions) |
| type	    | channel type, one element for each channel.  Set to 1 if a channel uses programmed ramps. |
| channels | channel names (char array) |
| device   | string with instrument indentifier. |
| name	    | optional name to distinguish different instruments of the same type. |

---
### Control functions ###

All communications with an instrument occurs through calls of
`smdata.inst().cntrlfn`, which has the following calling convention:

_val_ = **cntrlfn**(`[`_inst_, _channel_, _operation_`]`, _val_, _rate_)

inst and channel are the instrument and channel indices. Operation
determines what the function should do.

  1. read channel value. No further argument given. The return value can be matrix with the  dimensions given in `smdata.inst(inst).datadim(channel, :)`.
  1. set channel value to val. Rate argument will be given for channels with ramp functionality. The return value val should be the expected time required to complete the ramp to the set point.
  1. query remaining ramp time. Ramp rate used to program the last ramp is given in rate. This functionality is not used by smset (or anywhere else) at the time of writing.
  1. trigger previously programmed ramp.
  1. Arm acquisition device (optional)
  1. Configure acquisition device (optional) See smcATS660v2.m for examples on usage of 4 and 5.

If rate `<` 0 for ramped channels, a ramp is used in a measurement. In this case, the ramp should only be programmed and started later by a separate trigger function (see "Ramping channels").

How instruments are stored and addressed by the control function is
in principle arbitrary. However, I would recommend to follow the
convention that GPIB, serial, VISA, and similar instruments (i.e. those
controlled via the instrument control toolbox) be represented
by an instrument object stored in in smdata.inst().data.inst, which is
always kept open. smopen, smclose, smprintf, smscanf and smquery only
work for instruments following this convention.

For simple examples that can be adapted see for example smcHP1000A.m
or smctemplate.m, which is intended to be a starting point for writing new drivers.

### See Also ###
  * [smdata\_new](smdata_new.md)