**smopen**(_`[`inst`]`_)

For many interface types (serial, GPIB, VXI-11), MATLAB requires that you explicitly open a connection to the instrument before communications with it.  **smopen** begins communications with such instruments.  _inst_ can be:

  * Empty, in which case all instruments in {{{ smdata.inst }} will be opened.
  * A vector of numbers, in which case instruments with those numbers will be opened.  See _[smprintinst](smprintinst.md)_.
  * A string, in which case the instrument with that name is opened.

An instrument will only be opened if its status is currently "closed".
### Example ###
```
smopen(1:5);      % Open instruments 1-5
smopen('MyAWG');  % Open the instrument named MyAWG
smopen();         % Open all instruments
```

### See Also ###
  * _[smclose](smclose.md)_
  * _[smprintinst](smprintinst.md)_
  * The MATLAB manual on VISA/GPIB objects.
  * **[smdata](smdata.md)**

### Known Bugs/Limitations ###
_smopen_ only works on instruments where ` smdata.inst(x).data.inst ` is a handle to a MATLAB communications object.  It fails silently otherwise.

If one instrument fails to open, all later instruments will not be opened.