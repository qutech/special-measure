data = **smrun**(_scan_, _`[`filename`]`_)

data = **smrun**(_filename_) (will assume _scan_ = _smscan_)

Run a scan, optionally saving the result to a file.  See the page
documenting the [scan](scan.md) structure for help in designing scans.

### Examples ###
> Fixme -- write an example

### See Also ###
  * [smscanpar](smscanpar.md)
  * [smdiagpar](smdiagpar.md)
  * [smprintscan](smprintscan.md)


---

### Pseudocode for smrun ###
Set constant channels

Call configfn; ` scan=configfn(i).fn(scan,configfn(i).args{:}); `

Main loop
  * For loops needing update (outer first)
    * Set values and/or program ramps
    * call prefn
    * wait
    * trigger ramped channels if needed
  * end

  * For loops needing readout (inner first)
    * read data
    * call postfn
    * apply procfn
    * display data
    * save data if needed
    * call datafn
  * end
end

Save data.