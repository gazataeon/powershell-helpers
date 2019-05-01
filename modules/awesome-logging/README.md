# Awesome Logging Module

## Features
Pass a date( or not!) and get back a filename friendly string, handy for log files and the like!

## Acceptable date input formats
* `01/01/90` or `01/01/1990` string
* `01-01-90` or `01-01-1990` string
* `010190` or `01011990` string
* `dateTime` Object
* `01 January 1990 10:00:09` or `01 January 1990` string

## Output format options
Example: `-format a`

* A: "ddMMyyyy_hhmmss" 
* B: "dd-MM-yyyy_hhmmss"
* C: "dd-MM-yyyy"
* D: "ddMMyyyy"

Default is: "ddMMyyyy_hhmmss"

## Examples

### No date with format c

`invoke-hotDate -format c` 
```
01-05-2019
```

### Full text String date in format d

`invoke-hotDate -format d -mydate "20 February 2017 10:48:26"`
```
20022017
```

### Full text String date with no format specified 

`invoke-hotDate -mydate "20 February 2017 10:48:26"`
```
20022017_104826
```


### No date or format specified 

`invoke-hotDate`
```
01052019_120135
```