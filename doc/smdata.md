# smdata #
Structure elements
  * **[inst](#smdata.inst.md)** A list of the defined instruments
  * **[channels](#smdata.channels.md)** A list of the defined channels.

| configch  | blah. |
|:----------|:------|
| configfn  |  |
| chandisph |  |
| chanvals  |  |


### smdata.inst ###
  * data
  * datadim
  * ctrlfn
  * type
  * device
  * name
  * channels

### smdata.channels ###
> instchan   [instrument index, channel index w.r.t. instrument's
> > channels]

> rangeramp: First two elements are lower and upper limit.
> > Third element determines ramp rate (in 1/s).
> > 4th element is the conversion factor; requested value
> > > is multiplied by this before sending to the
> > > instrument.
> > > name	   Channel name (string).

### See Also ###
  * [Special Measure](SpecialMeasure.md)

### Bugs/Known Issues ###
This page is incomplete and possibly inaccurate.