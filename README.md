# vmdktool — VMDK file converter

Fork of `vmdktool` (https://manned.org/vmdktool, http://www.freshports.org/sysutils/vmdktool/).

```
SYNOPSIS
     vmdktool [-di] [-r fn1.raw] [-s fn2.raw] [-t sec] [[-c size] [-z zstr] -v
              fn3.vmdk] file

DESCRIPTION
     The vmdktool utility converts raw filesystems to the VMDK format and vice
     versa.  It can also produce information for a given VMDK file.

     vmdktool was written based on VMware Inc., Virtual Disk Format 1.1,
     Revision: 20071113 Version: 1.1 Item: NP-ENG-Q204-099,
     http://www.vmware.com/interfaces/vmdk.html, November 2007.

     The switches and command line arguments behave as follows:

         -c size
               Use disk capacity size rather than the size of file.  The size
               value is in bytes unless suffixed by one of the following:

                   k    kilobytes (1024 bytes).

                   M    megabytes (1048576 bytes).

                   G    gigabytes (1073741824 bytes).

                   T    terabytes (1099511627776 bytes).

                   P    petabytes (1125899906842624 bytes).

                   E    exabytes (1152921504606846976 bytes).

         -d    Increase diagnostics.

         -i    Show VMDK info from file.

         -r fn1.raw
               Read random vmdk data from file, write raw data to fn1.raw.

         -s fn2.raw
               Read stream vmdk data from file, write raw data to fn2.raw.

         -t sec
               Show VMDK table info at sector sec.

         -v fn3.vmdk
               Read raw data from file, write VMDK data to fn3.vmdk.

         -z zstr
               Set the deflate strength to zstr.

         file  A raw disk or VMDK image.  file is always the input file and is
               opened for reading.  If -v is being used, file may be a character
               device (but must be seekable).

     When using the -r or -s switches, the output file fn1.raw or fn2.raw will
     be the same.  The only difference is in how we read the vmdk file; using
     random access in a "whatever's convenient" manner, or as a stream, allowing
     file to be a character special file.

     A given VMDK must be stream-optimized in order for vmdktool to read it
     (with the -s switch) as a stream.  The inverse however is not true; any
     VMDK file may be read using random access.

EXAMPLES
     To obtain high level information about file.vmdk:
           vmdktool -i file.vmdk

     To convert a raw filesystem image fs.raw to a stream-optimized vmdk file:
           vmdktool -z9 -v fs.vmdk fn.raw

     To convert the same raw filesystem image but set the virtual disk size to
     2GB:
           vmdktool -c2G -z9 -vfs.vmdk fn.raw

     To modify the content of partition 1 on fs.vmdk, the following might be
     done on a FreeBSD system:
           vmdktool -s tmp.raw fs.vmdk
           unit=$(mdconfig -a -t vnode -f tmp.raw -n)
           mount /dev/md${unit}a /mnt
           echo added >/mnt/added
           umount /mnt
           mdconfig -du$unit
           vmdktool -vfs.vmdk -z9 tmp.raw
           rm tmp.raw

     To do the same on a linux system:
           vmdktool -s tmp.raw fs.vmdk
           bounds=$(echo p | sudo fdisk -u tmp.raw 2>/dev/null | grep tmp.raw1 |
           awk '{print $3, $4}')
           off=$((${bounds% *} * 512)); sz=$((${bounds#* } * 512 - $off))
           loop=$(losetup -o $off --sizelimit $sz -f --show tmp.raw)
           mount $loop /mnt
           echo added >/mnt/added
           umount /mnt
           losetup -d $loop
           vmdktool -vfs.vmdk -z9 tmp.raw
           rm tmp.raw

SEE ALSO
     fdisk(8), mdconfig(8), newfs(8).

HISTORY
     vmdktool was originally written by Brian Somers <brian@Awfulhak.org> in
     2009 after a great deal of frustration over not finding any free tools to
     create VMDK files.  It was updated and fixed as necessary and "donated" to
     various companies where the author worked, finally being released to the
     general public in 2012.  Shortly after this, support was added for the
     minor spec update from version 1.1 to version 5.0.

     Although developed under FreeBSD, vmdktool will build fairly easily under
     Linux and OSX.
```
