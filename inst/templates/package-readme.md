## {{ module_name }}

{{ module_name }} translates {{ package }} to {{ language }}.

To use it, install {{ module_name }} and rdlocal

```r
pak::pak(c("eliocamp/rdlocal", "{{ module_name }}"))
```

Then, in your R session, load rdlocal and set your language 

```r
library(rdlocal)
Sys.setLanguage("{{ language }}")
```

{{ package }}'s documentation will now appear in your language. 


