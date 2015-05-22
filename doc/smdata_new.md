# smdata #

Let's look at what is inside smdata
```
smdata=
 inst: [1x23 struct]
     channels: [1x67 struct]
    chandisph: 1.0012
     chanvals: [1x69 double]
     configch: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 37 38 39 56 29 52 53 54 55 30]
     configfn: {}
```

Lets see what each field is:

# smdata.inst #
smdata.inst is a struct array of all the instruments that special measure knows how to set, read, and control. It has
```
smdata.inst = 
1x23 struct array with fields:
    data
    datadim
    cntrlfn
    type
    device
    name
    channels
```
Let's discuss these out of order:

**device**: describes the type of instruments, for example "Yoko7651."

**name:** the name of the instrument, for example, "YOKO1." It is a user define field to help you keep track of the instrument and is helpful if more than one instrument of the same kind of "device" is present.

**type:** FIXME.

**cntrlfn:** Is a handle to the driver (function that controls the instruments) for the instrument. For example @smcYoko.
**channels:** Is a list (char array) of all of the channels that the instrument has. These can include channels that can be set, read, and both. For example "v1", "V2".

**datadim:** The size of values that may be read (set) from (by) the instrument. This is used if an instrument is capable of returning an array of values (e.g. an entire line scan). There is one datadim entry for each channel in the field smdata.inst(x).channels. An empty datadim implies a scalar value.

**data:** smdata.inst(x).data is where information about how to control the instrument is stored. For example, this field usually has a single field, smdata.inst(x).data.inst which is a matlab object handle such as GPIB, USB, VISA, etc.

## smdata.channels ##
smdata.channels has an entry for each channel, which represents some parameter, i.e. an input or and output of an instrument. There is currently no distinction between write and read channels. All channels should support a read operation, but it is up to the user to make sure that channels that do not support write operations (typically acquisition devices) are not used as set channels.

Let's see what's in smdata.channels:
```
smdata.channels(3)

ans = 

    1x67 struct array with fields:
    instchan
    rangeramp
    name
```

**name:**: the name of the channel, for example, 'voltage1' which must be a string.

**instchan:** this field is a 2 x 1 double that indicates which instrument, and channel (as indexed in smdata.inst(instrument).channels a certain channel refers to. For example,
```
smdata.channles(4).instchan = [3 4]
```
means that this channel is associated with smdata.inst(3).channels(4).

**rangeramp:** this field has 4 values: minimum allowed set value, maximum allowed set value, maximum allowed ramp rate, a software multiplier that will be used when setting the channel. For example
```
instchan: [2 32]
rangeramp: [-0.6000 0 0.0700 11]
name: '4a'
```
means that the channel named '4a' is associated with instrument 2, channel 32. It can be set from -.6 to 0 and a maximum ramp rate of .07/second. The rangeramep(4) of 11 means that if you issue the command
```
smset('4a',-.4)
```
channel 32 of instrument 2 will be set to -4.4.

## smdata.chandisph ##
is the matlab figure handle for the figure that shows all of the channels and their values. This handle is used to update the figure every time a channels is set or read.

## smdata.chanvals ##
This double stores the value of every entry in smadata.channels. It gets updated every time smset or smget is called (evey time a channels is set or read). For example, if smdata.channels(4).name = '4a', and smdata.chanvals(4)=.4 means that, if called,
```
smget('4a')
ans = 
0.4
```
WARNING: smdata.chanvals should not need to be manually manipulated. Change its entries with extreme caution.

## smdata.configch ##

smdata.configch is 1 x n double of all of the channels that will be logged at the beginning of each scan. They are references to smdata.channels. For example,
```
smdata.configch = [1 4 5 6 7]
```
means that the values of smdata.channels(1 4 5 6 7) will be logged (POOR NOTATION).

## smdata.configfn ##

a function that will be called when smrun is called. This should be a function handle.


### See Also ###
  * [Special Measure](SpecialMeasure.md)

### Bugs/Known Issues ###