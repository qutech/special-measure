# Introduction #

Special Measure provides a simple frontend for MATLAB's instrument control toolbox, allowing users to quickly set up flexible scans through parameter space.

# Installation #
Please see [Installation](Installation.md) for install instructions.

# Quick Reference #

Please see the [Overview](Overview.md) page for a list of Special Measure functions,
and [Error Messages](ErrorMessages.md) for a list of common error messages and what to do.

# Configuration Data #
  * [scan](Scans_new.md) (structure)
  * [smdata](smdata_new.md) (global structure)


# Structure of Special Measure #

### Instruments and channels ###

Each hardware device is represented by an instrument (not to be confused with
MATLAB instrument objects) that contains information about how to control it
and what channels (see below) it provides. This information roughly corresponds
to the hardcoded instrument drivers and channel array in Labview SM.


The channel concept is very similar to that of Labview SM - each channel
represents some parameter, input or output value of an instrument.
In most cases, it will be some physical quantity.
There is currently no distinction between write and read channels.
All channels should support a read operation, but it is
up to the user to make sure that channels that do not support write operations
(typically acqusition devices) are not used as set channels.
Writeable channels should always accept and return a single double, but
read-only channels can also return matrices of arbitrary dimension - e.g.
a vector representing a complete scan line.
Writeable channels can be self ramping, in which case its variable can be
ramped by the corresponding instrument. If available, this feature is always
used to set channel values (function smset), and can also be used for
measurements.

Information about instruments, channels (i.e. the rack) and other
configuration is stored in the global struct smdata. Channels and
instruments are stored in the struct array smdata.channels and smdata.inst.
Major changes to smdata.inst are only required when adding new instruments
or updating drivers, but it may occasionally be necessary to change certain
instrument parameters, such as the data dimension for read channels.



### Specifying instruments and channels ###

---

Internally, channels and instruments are identified by their indices
to the struct arrays smdata.inst and smdata.channels.  These indices
(printed at the beginning of each line by smprintchannels and
smprintinst can also be used to specify channels and instruments in
function arguments, including scan definition. Alternatively, channel
and instruments names can be used. Lists of names can be given as a
char arrays or cell vectors of strings. The conversion from names to
indices is typically done with smchanlookup and sminstlookup.
Channel names should always be unique. Instruments can be called by their
instrument type identifier (smdata.inst().device, e.g. SR830) if there is only
one such instrument in the rack, or an optional name, which should be unique
amongst instrument types and names. Instruments with a name should generally
be called by that name.

### Adding and removing channels ###

---

To add a channel, use the [smaddchannel](smaddchannel.md) function. Note that depending
on the instrument, further configuration may be necessary.
(Particularly for channels to be ramped for data taking, or matrix-valued
channels).

To remove one or several channels ch, just type "[smdata](smdata#channels.md).channels(ch) = `[]`;"
Note that this will change the indices of all subsequent channels.


### Displaying configuration ###

---

Use the smprint**function to display the most important configuration
information.**


### Displaying the current channel values ###

---

The current values of all scalar channels can be displayed in figure 1001
if this figure is initialized by calling "sminitdisp". The displayed values
will be updated by every call of smget and smset for each channel.
To disable this feature, close figure 1001.


### Specifying a scan ###

---

The measurement task to be excecuted by [smrun](smrun.md) is defined by a [scan](Scans_new.md) struct passed to [smrun](smrun.md). For explanations of its fields, see [scan](Scans_new.md).
Note that some of the parameters are optional.