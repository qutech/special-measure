**smclose**(_`[`inst`]`)_

This closes a connection to a MATLAB instrument.  **It is not in general necessary to ever call this function unless an instrument crashes or reboots**, in which case it can be useful to _[smclose](smclose.md)_ and then _[smopen](smopen.md)_ it.  An example might be a VISA-USB instrument that was disconnected and reconnected, or a DecaDAC that has become desynchronized on communications.  _inst_ can be:

  * Empty, in which case all instruments in ` smdata.inst ` will be opened.
  * A vector of numbers, in which case instruments with those numbers will be opened.  See _[smprintinst](smprintinst.md)_.
  * A string, in which case the instrument with that name is opened.

### Example ###
```
smclose(2);  smopen(2);  % Close and re-open an instrument that crashed.
```


### See Also ###
  * _[smopen](smopen.md)_
  * _[smprintinst](smprintinst.md)_
  * The MATLAB manual on VISA/GPIB objects.
  * **[smdata](smdata.md)**