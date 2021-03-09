---
title: "Working HARder to fix page loads"
author: "Donal Phipps"
date: "09/03/2021"
output: html_document
---

## An r-script to plot and simplify HAR file data

This script reads in data from an HTTP ARchive format, pulls out some key variables and creates a few simple plots to help understand those requests which appear to be occupying the most time during page load.

It reads in the following variables from the .har file: 

- **url**: the URL of the request
- **time**: the time (in ms) taken to complete the request
- **request_method**: the type of HTTP request method (/verb)
- **response_size**: the size, in bytes, of the given request
- **page**: the page from which the request was initated
- **domain**: the domain of the request. This is extracted by the script from the request url
- **mf_int**: ("Mouseflow Interactive") - does this request appear to be made by Mouseflow in response to user interactions with the page (i.e. it may not represent the page weight, only the time and size used for Mouseflow to track user behaviour on the page). The assumption is made that any requests made to the domain mouseflow.com, followed by 'dom' or 'events' may be Mouseflow Interactive requests

[Read more about generating .har files](https://confluence.atlassian.com/kb/generating-har-files-and-analyzing-web-requests-720420612.html)

## Running the script

### Install R

Make sure that you have installed R on your machine. This can be downloaded from the Comprehensive R Archive Network (CRAN). [Access the download page](https://cran.r-project.org/mirrors.html).

If you are using brew, it's nice and easy:

```{console}
brew install r
```

To check that R has been installed correctly, you can run the following at the terminal:

```{console}
which Rscript
# /usr/local/bin/Rscript
```

## Run the script

From the terminal, call the R interpreter (`Rscript`), followed by the script filename, followed by the path to the .har file which you would like to analyse.

Example: 

```{console}
Rscript harfile-output.R my_har_file.har 
```

Depending on what you see when typing `which Rscript`, you can typically call `/usr/local/bin/Rscript` if the call to `Rscript` doesn't work as expected.

You must only supply a single argument to a .har file after calling the R script. 

## Output

If successful, the script should create the following new files:

1. "./tabular_har_{pagename}.csv": a csv containing each of the variables which have been selected from the source .har file
2. "./scatter_{pagename}.png": a scatterplot which charts each request, showing response size on the X axis and download time on the Y axis. 
3. "./scatter_{pagename}_top20.png": a scatterplot based on #2, which has been filtered to show only the top 20 requests (theoretically, the "worst offenders") by response time.
4. "./requests_{pagename}.csv": a bar chart showing the aggregated time for requests, grouped by domain. This chart is intended to illustrate which domains are using the most request time during page download.

## Issues

In case of problems with the script, please contact me via Teams or email - I'm a bit rubbish at responding to github issues. 
