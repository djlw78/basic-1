# basic

A very simple BASIC interpreter for Linux written in Intel assembly language using NASM and GNU Binutils

Originally written around Spring 2001 for Linux 2.2, recently updated

## Screenshot

![Screenshot](https://dl.dropboxusercontent.com/u/8069847/basic.png)

## Example program

<pre>
10 print "give me a number"
20 input ia
30 let ic = 0
40 for ib = 1 to ia
50 if ((ia%ib)=0) then let ic = (ic+1)
60 next
70 print "the number " ia " has " ic " factors"
</pre>
