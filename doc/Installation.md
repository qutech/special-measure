# Installation #
Special Measure is best installed using the Mercurial version control system. For windows users, we recommend the GUI available at
http://tortoisehg.bitbucket.org/. See the Source page for further download instructions.

After creating a local clone, (http://code.google.com/p/special-measure/source/checkout) add the following directories to the MATLAB search path, where "install-dir" needs to be replaced by the complete installation directory:

```
install-dir\sm
install-dir\sm\procfn
install-dir\sm\channels
install-dir\sm GUI
```

# Startup #

To set up a MATLAB session for running SM, proceed as follows:
  * You need an instrument control toolbox. (ie., the National Instruments or Tektronix drivers)
  * Make sure the sm and sm/channels directories are in the path.
  * Make smdata accessible from the workspace by typing `global smdata;` This is necessary only once per Matlab session, or after a `clear global` command.
  * Load a rack from a MATLAB (.mat) file, e.g.
> > "load install-dir/sm/sm\_config/smdata\_base".
  * Open instruments with smopen. (Assuming they follow the standard convention discussed in section "Writing instrument drivers".)

The following examples for getting started can be found in  the `install-dir\config` directory:

`smsetup.m`: Create a rack (i.e. system configuration)<br>
<code>smsetup.m</code>: Reload a previosly created rack after restarting matlab<br>
<code>smscanconf.m</code>: Configure a simple scan<br>
<br>
Occasionally, it may be necessary to close and reopen instruments, for example to change certain properties such as the buffer size, or if the instrument crashes. For instruments following the standard convention, this can be done with <a href='smclose.md'>smclose</a> and <a href='smopen.md'>smopen</a>.<br>
<br>
<h3>See Also</h3>
<ul><li><a href='smdata.md'>smdata</a>
</li><li><a href='SpecialMeasure.md'>SpecialMeasure</a>