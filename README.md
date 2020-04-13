# Compare-Objects.ps1
Compare-Objects.ps1 will show you the attributes that differ between two objects. Just feed it the type of object and the names of the two you want to compare, and it will do the rest for you. Add the "-verbose" switch for more information.

Hands up if you've tried to compare 2 objects of some type to see what - if any - differences there are between them?
I tried and gave up. PowerShell's native "Compare-Object" isn't very helpful. It will tell you IF there's a difference, but it's not particularly forthcoming.
Borne of that experience comes "Compare-Objects.ps1". You might see some similarities here with two of my other scripts (<a href="https://greiginsydney.com/compare-pkicertificates-ps1/" target="_blank">Compare-PkiCertificates</a> &amp; <a href="https://greiginsydney.com/update-sfbcertificate-ps1/" target="_blank">Update-SfbCertificate.ps1</a>) as the comparison engine is essentially the same between them.
Feed this script the "type" of the object and the names of two of them, and it will present a tabular comparison, highlighting all those attributes that differ.
All of these formats are valid input examples:
```powershell
Compare-Objects.ps1 -type csuser -object1 "greig" -object2 "jessica"
Compare-Objects.ps1 -type csuser -object1 greig -object2 jessica
Compare-Objects.ps1 get-csuser greig jessica
```
Armed with the above input the script performs two "get-" commands to query the objects, then feeds the results into my differencing engine. The "get-" is implied in the command-line input, and the script will cope fine if you absent-mindedly include it,  like in the last example above.
If you've already captured the objects, you can feed them to the script and it will compare them directly, skipping the "get" step:
```powershell
Compare-Objects.ps1 -type $null -object1 $greig -object2 $jessica
Compare-Objects.ps1 $null $greig $jessica
```
For more information add the "-verbose" switch, and if you don't want it querying my blog in search of an update, use "-SkipUpdateCheck".
### Examples
One of my earliest requirements was to compare client policies in Skype for Business. Here's the script doing that for me, condensing 86 attributes down to the 4 that differ:
```powershell
PS: C:> .\Compare-Objects.ps1 csclientpolicy Hotdesking SkypeUI -Verbose
```
<img id="199301" src="/site/view/file/199301/1/Compare-CsClientPolicy.png" alt="" width="600" />
Two users?
```powershell
PS: C:> .\Compare-Objects.ps1 csuser greig jessica
```
<img id="199302" src="/site/view/file/199302/1/Compare-CsUser.png" alt="" width="600" />
VMs:
<img id="199303" src="/site/view/file/199303/1/Compare-vm.png" alt="" width="600" />
... even Disks:
```powershell
PS: C:> .\Compare-Objects.ps1 -Type disk 0 1 -Verbose
```
<img id="199304" src="/site/view/file/199304/1/Compare-Disk.png" alt="" width="600" />
### Bugs?
If you encounter any object types or attributes that report errors, please let me know in the questions here (or in the comments <a href="https://greiginsydney.com/compare-objects.ps1" target="_blank">back on my blog</a>) and I'll do my best to  cater for them.
I will admit to drawing a blank with a couple of exchange attributes, as you can see from the errors thrown when I compare two mailbox databases:
<img id="199305" src="/site/view/file/199305/1/Compare-MailboxDatabases.png" alt="" width="600" />
### The Wheel, reinvented
In the process of writing this post I stumbled upon Jamie Nelson's post on the TechNet blog "<a href="https://blogs.technet.microsoft.com/janesays/2017/04/25/compare-all-properties-of-two-objects-in-windows-powershell/" target="_blank">Compare  all properties of two objects in Windows PowerShell</a>", in which he provides a neat function in 22 lines of code that basically does all of the above. Yes, I cursed a little at that belated finding, but kudos Jamie for stepping into the breach.
### Revision History
v1.1 - 20th May 2018
- When queried, the PowerShell ISE reports the screen width is 0. Script now checks for zero and forces width to 80
- Added override switch &lsquo;-width' for extra user control. I assume this is only ever going to be needed by die-hard ISE users ;-) 
- Allowed the script to accept a -type of $null so the user can pass in entire objects to be compared, rather than just strings (see examples)
- Added a &lsquo;select-object' to only compare the FIRST instance if what's passed in/returned is an array of more than 1 object, and displays a warning
- Added pipeline handling so you can pipe objects to the script (run get-help -full)

v1.0 - 5th May 2018. This is the initial release.
 

<br>

\- G.

<br>

This script was originally published at [https://greiginsydney.com/compare-objects-ps1/](https://greiginsydney.com/compare-objects-ps1/).

