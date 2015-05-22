# Overview #
See the help for smrun `help smrun` or scan\_new for worthwhile documentation.

### Confguring the display ###
What data is displayed is defined in the disp field of the scan definition
struct. disp is a struct array with the fields listed below. Each element
of disp describes one subplot to be displayed in the data window (Figure 1000).

fields of _disp_:
  * _loop_: loop furing which to update display
  * _dim_: Dimension of data to be displayed, or 2 for plot or false-color image.
  * _channel_: Data channel to be shown. This is an index to all channels stored (i.e. those listed in loops(l).getchan for any loop l), starting with the slowest loop(?). If all channels are read in the same loop l, channel is simply the index of loops(l).getchan;

### Configuring Saving to Disk ###
How frequently data is saved to disk is controlled by scan.saveloop
saveloop is a numeric array; [_loop_, _interation_].  _iteration_ defaults to 1 if not specified.  _loop_ defaults to 2 if not specified.
Data will get saved to disk every _iteration_'th iteration of the loop _loop_, where 1 is the fastest loop.  For example:

```
scan.saveloop=[1 1]; % Save to disk with every data point.  Slow.
scan.saveloop=[1 5]; % Save to disk with every 5th data point.
scan.saveloop=[3];   % Save every time the third loop is incremented.
```

### Ramping channels ###
A writeable channel ch on instrument inst with
smdata.inst(inst).type(ch) set to 1 is considered as a ramping
channel, i.e. smset assumes that the device can autonomously generate
ramps. This feature is always used to change the value of the channel.
The maximum and default ramp rate is stored in smdata.

Ramps are also be used for measurements if scan.loops(i).ramptime < 0
In this latter case, smrun (the main measurement routine) only sets
the channel to the initial value and programs the endpoint of a ramp
and the ramp rate and then (optionally)
calls a trigger function to initiate a ramp.

### Specifying user functions in scan ###
Functions lists to be exectuted at various points
(prefn, postfn, datafn, procfn, trigfn) can be specified as
cell arrays of function handles or struct arrays with fields fn
(function handle) and args (cell array with user arguments to be passed).  Any function handle can be repaced by a string, which will be interpreted by MATLAB's `str2func`.

For more details, see the auxiliary function fncall at the end of `smrun.m`.


### Transformation functions ###

Channel transformation functions compute the channel value to be set
from the independent variables and other channel values.
Their first argument is a vector with the loop variables,
starting with the innermost loop.
the second one the current value of all channels, as stored in
smdata.chanvals. Those values are only updated by calls to
smset or smget. Channels returning arrays are not stored there.

Transformation fucntions (trafofn's) can be specified as a cell array of functions, or as a struct array with fields .fn and .args as described above.

**Example:**
```
scan.loops(1).trafofn{2} = @(x,y) (x(1)-2) * .2 + y(3); 
```
or
```
scan.loops(2).trafofn(1).fn = @(x,y,p) (x(1)-2) * .2 + p; 
scan.loops(2).trafofn(1).args = {5} 
```


The global transformation functions are applied to the independent variables
before the channel specific transformations. Currently, their only argument
is the loop variable vector.


### prefn ###
> prefunction get (fn.args, loop vars) as aruments.  INSERT EXAMPLE
### Known Bugs ###
This page is worthless.