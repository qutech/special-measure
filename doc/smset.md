**smset**(_channels_,_vals_,_`[`ramprate`]`_)

Set _channels_ to _vals_.  _channels_ can be a single string, a cell array of strings, a channel number, or a vector of channel numbers.  _vals_ can correspondingly be a single value, a cell array of values, or a vector of values.  If _ramprate_ is not specified, the default from [smdata.channels] is used.

Normally **smset** does not terminate until the ramp is complete.  However, if the ramprate is negative, it will set up the ramp for self-ramping channels but not wait for it to finish.  (This feature is chiefly used by [smrun](smrun.md).
### Examples ###
```
  smset('1a',-.123);            % sets '1a' to -.123
  smset(1:5,[ 0 0 0 0 0]);      % sets channels 1:5 (in smdata.channels) all to 0
  smset({'1b','2b'},{-.2,-.2}); %sets '1b' and '2b' to -.2 each
  smset('1a',-.4, .01);         % sets '1a' to -.4 ramping at .01/second
```
### See Also ###
  * [smget](smget.md)
  * [smprintchannels](smprintchannels.md)
  * [smprintrange](smprintrange.md)
  * [smdata](smdata.md) for a description of [smdata.channels].
