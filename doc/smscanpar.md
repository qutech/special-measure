scan = **smscanpar**(_scan_, _`[`cntr`]`_, _`[`rng`]`_, _`[`npoints`]`_, _`[`loops`]`_)

Set center, range and number of points for ` scan.loops(loops) `.
_loops_ defaults to ` 1:length(cntr) `.  Empty or omitted arguments are left unchanged.  `scan.consts` are set and `scan.configfn` is executed at the end if present and not empty.


Alternatively, if _cntr_ is `'gca'`, copy the range of the current plot to the scan.  This is handy for 'zooming in' on scans.
### See Also ###
  * [scan](scan.md)
  * [smdiagpar](smdiagpar.md)

### Known Bugs ###
> This documentation is poor.