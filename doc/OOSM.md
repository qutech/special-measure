# Introduction #

Mikey's ideas. Please add/comment/criticize, etc.

## Summary ##
The goal is to use OO programming to improve special measure. In particular, this aims to make reading and writing instrument drivers and creating instruments easier.
each instrument is a class that inherits from a superclass sminst. Each inst has an array of sminstchans, which are the channels. The instrument overloads the functions set, get, trigger, arm, etc. The superclass sminst defaults to calling the cntlfn for the instruments to keep things backward compatible.

## Classes ##
### sminst ###
superclass of instruments. each instrument will inherit and overload methods. It has properties: matlabobject, cntlfn, channels (see sminstchan), name.
Objects that inherit from this will overload useful methods, including a constructor, which will make defining instruments **much** more straight forward.

### sminstchan ###
channels that are part of an instrument. these are incredibly simple object, but allow for some specialize functionality if you want. It has properties: setable (boolean), name, HWramp, lims, datadim, datatype
It is unclear how much of this should be party of smdata.inst.channels and how much should be part of smdata.channels.

# Implementation and Changes #
smdata.inst is now a **cell** array because matlab does not allow arrays of different objects, even if they inherit from the same class. This means that lots of smdata.inst(x) need to change to smdata.inst{x} which will be annoying to find.
smset and smget would change reasonably trivially to call get(inst,chan) or set(instr,chan,val) etc instead of calling a cntlfn.

# Pros and Cons #
  * Much easier to write new drivers and create new instruments.
  * Code is much easier to read
  * development is tricky: matlab does not deal with having two versions of the same class in memory. there are also other object oriented oddities in matlab. this means you need to have a clear idea of what you want.