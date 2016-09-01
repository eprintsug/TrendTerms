# TrendTerms
Visualisation of terms in document abstracts

The TrendTerms package analyses the relevant terms in the abstract of an eprint and 
its related eprints, including their time evolution. Word statistics and positions 
from the Xapian search engine index are used to select the relevant terms and to 
calculate the relations between the terms. The terms and their relations are 
saved in graph XML files. The graph XML files are visualised using ProcessingJS 
or can be further analysed.

The package consists of
- a script and plugin to generate the graph files
- the ProcessingJS program (including the Processing source files) to visualize the
  TrendTerms graph files
- some JavaScript helper code
- phrase files in English and German
  
For a demo, see e.g. http://www.zora.uzh.ch/97201/
