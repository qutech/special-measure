**smdiagpar**(_scan_,_angle_,_cntr_,_`[`loops`]`_)

Given a scan _scan_, center it about zero, rotate it by an angle _angle_ in radians, then shift its center by _cntr_.  All other global transformations are removed.  Loops, if specified, gives loop numbers for the _x_ and _y_ axis of the scan.  If not given, the innermost two loops are assumed.

### Example ###
See known bugs, limitations.

### Known Bugs/Limitations ###

In order to rotate a scan, both the _x_ and _y_ channels must be in the setchan for the innermost loop.

No examples.