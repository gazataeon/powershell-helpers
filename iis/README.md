# iis-counter-check.ps1
This is monitor for requests executing to automate when executing requests hits 100 and stays at 100 for 5 mins then we would need to recycle the app pools.
This is usually because the webapp has hung

```
#W3SVC_W3WP
#list all counters (EXAMPLE)
#$meh = Get-Counter -ListSet * | Select-Object CounterSetName, CounterSetType, Description, Paths 

#list all active request counters (EXAMPLE)
#get-counter -counter "\\$env:computername\\ASP.NET Apps v4.0.30319(__Total__)\Requests Executing"

#get for specific site (EXAMPLE)
#Get-Counter -Counter '\W3SVC_W3WP(mywebapp.mycompany.com)\Active Requests'
```

* Ensure you have iis scripting tools feature installed for this to all work!