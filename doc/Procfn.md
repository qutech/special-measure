## procfn ##
`procfns` are used to process incoming data during a scan (see [Scans\_new](Scans_new.md) for info on scans). They are more complicated than most of the other functions embedded in scans because they determine how data is allocated and gathered.

If a loop has `n` getchans and stores an additional `m` cells of processed data, its procfn will be a struct of length `m+n`. If data from a getchan does not need processing, you can leave its procfn empty. Each `procfn` has fields `fn` and `dim`.

`fn` is a struct that determines what processing to do. Its length is the number of processing functions for that channel. These are run in order, so data can be processed serially across fns.

`fn` has fields (terms defined below):
  * fn, args, which have the same format as for prefns, etc.
  * inchan, outchan: These are used to send new data from one channel to another. The data to be processed is taken from loop index inchan and placed in loop index outchan.
  * indata, outdata. Procfns with indata and outdata let you process both `newdata` and stored `data` (so data from different loops can be processed together). They also directly store the processed data as a data cell, rewriting it at each loop iteration.

`dim` gives the size of the processed data. If the dimension of processed data is different than defined for that channel in the inst's datadim, smrun has no way of knowing the size of data when creating cells to store data. Instead it is specified here. See Examples section for more info.

A few useful smrun concepts for understanding procfns
  * channel / data indices : Each getchan has two indices. One corresponds to the overall index (data index) within the scan, which counts from 1 for the first loop's first getchan across getchans and then loops. The other is the index within the loop (loop index), which counts up from 1 for the first getchan in each loop. The data index counts channels created by procfns: if there are 2 getchans in the first loop, plus an additional channel for processed data, and 1 getchan in the 2nd loop, the data index of the channel in the second loop is 4. Data index is used for indata / outdata, loop index for inchan / outchan.
  * `newdata` vs. `data`: At each iteration in a scan, `smget` gathers data from all the `getchans` in the current loop and stores it in the cell array `newdata`. Procfns with `inchans/outchans` only will process the `newdata` only. The indices of the `inchans/outchans` refer to loop indices. fns with `indata/outdata` fields and `inchan/outchan` fields can process stored data and `newdata` and assign the final data to both `newdata` with loop index `outchan` and `data` with the `outdata` index. However, the index for `indata/outdata` is not the overall data index, but the overall data index subtracting the overall data index at the for the last channel of the last loop. This means it can be negative if you want indata from an inner loop. Procfns with outdata also bypass storing the newdata in data, so you will have to send newdata to an additional channel to store it. See the final example for more info.

There are some useful rules to know for defining procfns:
  1. If there is an outdata but no indata, indata gets the value of outdata.
  1. If there is no inchan it gets the loop index.
  1. If there is a procfn.fn, but no outchan, it gets the value of inchan.
  1. If there is a dim in the procfn corresponding to the get chan, that sets the dim. Otherwise, it is taken from smdata.inst.datadim for the channel.
  1. Since data channels created via a procfn have no channel in smdata, they need to have dim defined.
  1. Data from multiple inchans will look like separate inputs to the procfn, so those functions should have inputs in form `function procfn(inchan1, inchan2)`
  1. If fn has a fn and an outchan not equal to its loop index, the output of fn will be stored in both the current loop index and the outchan index.

## Examples ##
**Example 1**

Send data from channel 1 to channel 3.  dim always needs to be set for channels created by procfns.
```
scan.loops(1).procfn(1).fn
         inchan: 1 
         outchan: 3
scan.loops(1).procfn(3).dim: 100
```

**Example 2**

Perform function to change the size of data in channel 1, by first reshaping 8000 datapoints into an 80 x 100 array, then averaging them to get a 1 x 100 array. dim needs to be set for channels where data changes size.

```
scan.loops(1).procfn(1).fn(1) 
      fn: @reshape 
      args: {[80,100]};          
scan.loops(1).procfn(1).fn(2) 
      fn: @mean 
      args: {};        
scan.loops(1).procfn(1).dim: 100
```

**Example 3**

Send data from channel 1 and 2 to channel 3, divide chan 1 data by chan 2 data.
```
   scan.loops(1).procfn(1).fn: []
   scan.loops(1).procfn(2).fn: [];
   scan.loops(1).procfn(3).fn 
         fn: @rdivide 
         args: {};
         inchan: [1,2]   
         outchan: [3]
   scan.loops(1).procfn(3).dim = 100
```

**Example 4**

For scan with 2 loops, where the Loop 1 has 2 getchans and Loop 2 has 1 getchan, analyze `data` from Loop 1 Channel 1 and the `newdata` from the Loop 2 Channel 1.
Note, your function will pull in all stored data from the 1st loop / 2nd chan, so you will need to write your function to ignore NaNs / other unimportant data.
```
loops(2).procfn(1): []
loops(2).procfn(2): 
   dim: 1 
   fn: 
      fn: @samp_proc
      args: {}
      inchan: 1
      outchan: 3
      indata: -1
      outdata: 2
loops(2).procfn(3): 
   dim: 1 
   fn: []
```
This stores the processed data in the 5th cell. The processed data from the most recent smget is stored in cell 4.