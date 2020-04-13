# Compare-Objects.ps1
Compare-Objects.ps1 will show you the attributes that differ between two objects. Just feed it the type of object and the names of the two you want to compare, and it will do the rest for you. Add the "-verbose" switch for more information.

<p>Hands up if you&rsquo;ve tried to compare 2 objects of some type to see what &ndash; if any &ndash; differences there are between them?</p>
<p>I tried and gave up. PowerShell&rsquo;s native &ldquo;Compare-Object&rdquo; isn&rsquo;t very helpful. It will tell you IF there&rsquo;s a difference, but it&rsquo;s not particularly forthcoming.</p>
<p>Borne of that experience comes &ldquo;Compare-Objects.ps1&rdquo;. You might see some similarities here with two of my other scripts (<a href="https://greiginsydney.com/compare-pkicertificates-ps1/" target="_blank">Compare-PkiCertificates</a> &amp; <a href="https://greiginsydney.com/update-sfbcertificate-ps1/" target="_blank">Update-SfbCertificate.ps1</a>) as the comparison engine is essentially the same between them.</p>
<p>Feed this script the &ldquo;type&rdquo; of the object and the names of two of them, and it will present a tabular comparison, highlighting all those attributes that differ.</p>
<p>All of these formats are valid input examples:</p>
<pre>Compare-Objects.ps1 &ndash;type csuser &ndash;object1 &ldquo;greig&rdquo; &ndash;object2 &ldquo;jessica&rdquo;
Compare-Objects.ps1 &ndash;type csuser &ndash;object1 greig &ndash;object2 jessica
Compare-Objects.ps1 get-csuser greig jessica</pre>
<p>Armed with the above input the script performs two "get-" commands to query the objects, then feeds the results into my differencing engine. The "get-" is implied in the command-line input, and the script will cope fine if you absent-mindedly include it,  like in the last example above.</p>
<p>If you&rsquo;ve already captured the objects, you can feed them to the script and it will compare them directly, skipping the &ldquo;get&rdquo; step:</p>
<pre>Compare-Objects.ps1 &ndash;type $null &ndash;object1 $greig &ndash;object2 $jessica
Compare-Objects.ps1 $null $greig $jessica</pre>
<p>&nbsp;</p>
<p>For more information add the &ldquo;-verbose&rdquo; switch, and if you don&rsquo;t want it querying my blog in search of an update, use &ldquo;-SkipUpdateCheck&rdquo;.</p>
<h3>Examples</h3>
<p>One of my earliest requirements was to compare client policies in Skype for Business. Here&rsquo;s the script doing that for me, condensing 86 attributes down to the 4 that differ:</p>
<pre>PS: C:\&gt;.\Compare-Objects.ps1 csclientpolicy Hotdesking SkypeUI -Verbose</pre>
<p><img id="199301" src="/site/view/file/199301/1/Compare-CsClientPolicy.png" alt="" width="600" /></p>
<p>Two users?</p>
<pre>PS: C:\&gt;.\Compare-Objects.ps1 csuser greig jessica</pre>
<p><img id="199302" src="/site/view/file/199302/1/Compare-CsUser.png" alt="" width="600" /></p>
<p>VMs:</p>
<p><img id="199303" src="/site/view/file/199303/1/Compare-vm.png" alt="" width="600" /></p>
<p>&hellip; even Disks:</p>
<pre>PS:&gt;.\Compare-Objects.ps1 -Type disk 0 1 -Verbose</pre>
<p><img id="199304" src="/site/view/file/199304/1/Compare-Disk.png" alt="" width="600" /></p>
<h3>Bugs?</h3>
<p>If you encounter any object types or attributes that report errors, please let me know in the questions here (or in the comments&nbsp;<a href="https://greiginsydney.com/compare-objects.ps1" target="_blank">back on my blog</a>) and I&rsquo;ll do my best to  cater for them.</p>
<p>I will admit to drawing a blank with a couple of exchange attributes, as you can see from the errors thrown when I compare two mailbox databases:</p>
<p><img id="199305" src="/site/view/file/199305/1/Compare-MailboxDatabases.png" alt="" width="600" /></p>
<h3>The Wheel, reinvented</h3>
<p>In the process of writing this post I stumbled upon Jamie Nelson&rsquo;s post on the TechNet blog &ldquo;<a href="https://blogs.technet.microsoft.com/janesays/2017/04/25/compare-all-properties-of-two-objects-in-windows-powershell/" target="_blank">Compare  all properties of two objects in Windows PowerShell</a>&rdquo;, in which he provides a neat function in 22 lines of code that basically does all of the above. Yes, I cursed a little at that belated finding, but kudos Jamie for stepping into the breach.</p>
<h3>Revision History</h3>
<p>v1.1 &ndash; 20th May 2018</p>
<ul>
<li>When queried, the PowerShell ISE reports the screen width is 0. Script now checks for zero and forces width to 80 </li>
<li>Added override switch &lsquo;-width&rsquo; for extra user control. I assume this is only ever going to be needed by die-hard ISE users ;-) </li>
<li>Allowed the script to accept a -type of $null so the user can pass in entire objects to be compared, rather than just strings (see examples) </li>
<li>Added a &lsquo;select-object&rsquo; to only compare the FIRST instance if what&rsquo;s passed in/returned is an array of more than 1 object, and displays a warning </li>
<li>Added pipeline handling so you can pipe objects to the script (run get-help -full) </li>
</ul>
<p>v1.0 - 5th May 2018. This is the initial release.</p>
<p>&nbsp;</p>
<p>- G.</p>
