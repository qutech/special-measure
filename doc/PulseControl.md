# Introduction #

This is not real documentation.  These are notes on the changes enacted to allow multiple AWG's to be combined.

  1. smdata.inst(x).data can have a field "chain".  If chain is set to y and a jump is requested on smdata.inst(x), the jump is also executed on smdata.inst(y).   Chains can be recursive.  Please avoid loops.
  1. awgdata can be a struct array of awg's.  each awg can have a clk (clock rate), bits (bit depth), awgdata.awg (pointer to visa object in awgdata), slave (if set to 1, pulse groups begin with wait for triger), chans ( map of which channels the awg outputs, may be non-unique).
ie,
```
  awgdata(1).chans=[1 2 3 4];
  awgdata(1).clk=1e9;
  awgdata(1).bits=14;
  awgdata(2).chans=[3 4];
  awgdata(2).clk=1e10;
  awgdata(2).slave=1;
  awgdata(2).bits=10;
```
will set up awg2 (a 7k) to wait for awg1 to trigger it.  They will both output channels 3 and 4, so the markers on the 5k can be used in lieu of the markers on the 7k.

# Details #

Add your content here.  Format your content with:
  * Text in **bold** or _italic_
  * Headings, paragraphs, and lists
  * Automatic links to other wiki pages