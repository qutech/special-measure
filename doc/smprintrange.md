**smprintrange**(_`[`ch`]`_)
> Print the range, ramp rate, and attenuation on _ch_.  _ch_ can
be a vector of channel numbers, a channel name, or a cell array of channel names.  If _ch_ is omitted, all channels are printed.

Factor is the ratio of the requested value to the actual channel output.  For example, an output with 10x external attenuation might have a
factor of 10.


### Example ###
```
>> smprintrange(1:5)
CH   Name               Min         Max  Rate (1/s)      Factor
---------------------------------------------------------------
 1   1a                -0.6           0        0.07          11
 2   2a                -0.6           0        0.07          11
 3   3a                -0.6           0        0.07          11
 4   4a                -0.6           0        0.07          11
 5   1b                -0.6           0        0.07          11

>> sprintrange('PlsRamp3')
CH   Name               Min         Max  Rate (1/s)      Factor
---------------------------------------------------------------
54   PlsRamp3        -0.014       0.014      1e+002          71
```

### See Also ###
  * [smprintchannels](smprintchannels.md)
  * [smdata](smdata.md)