# TrendTerms
## Visualisation of terms in document abstracts

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

## Requirements

- EPrints 3.3.x with installed Search::Xapian extension. For details see 
https://wiki.eprints.org/w/API:EPrints/Plugin/Search/Xapian
- JQuery is required for scaling the visualisation canvas.


## General setup

The setup procedure consists of the following steps

- Installation of the required files
- Configuration of the look of the visualisation
- Initial generation of trendterms data
- Linking the trendterms_data directory
- Initial test
- Full generation of trendterms data
- Running updates


## Installation

Copy the content of the bin and cfg directories to the respective 
{eprints_root}/archives/{yourarchive}/bin and {eprints_root}/archives/{yourarchive}/cfg 
directories.


## Configuration

### Configure the position of the TrendTerms visualisation

archives/{archive}/cfg/cfg.d/z_trendterms.pl allows you to configure the position 
of the TrendTerms box in the summary page of an eprint.

If you use a custom archives/{archive}/cfg/cfg.d/eprint_render.pl to render the 
summary page, you can turn off the box in archives/{archive}/cfg/cfg.d/z_trendterms.pl by
setting

$c->{plugins}->{"Screen::EPrint::Box::TrendTerms"}->{params}->{disable} = 1;

You can then copy the code in the render() and make_trendtermsbox() in 
archives/{archive}/cfg/plugins/EPrints/Plugin/Screen/EPrint/Box/TrendTerms.pm over to 
eprint_render.pl and adapt it to your needs.


### Edit the look of your visualisation

You can configure the look of your visualisation (fonts, colors, position of the HUDs, ...) in 
archives/{archive}/cfg/static/trendterms/configuration.xml:

```XML
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <callback>
    <base_url>/cgi/search/advanced?abstract=</base_url>
  </callback>
  <node>
    <font name="Verdana" size="12"/>
  </node>
  <edge>
    <line_weight>2.0</line_weight>
    <color>FF808080</color>
  </edge>
  <colors>
    <set id="1" name="general">
      <color id="1" name="red" value="80FF0000"/>
      <color id="2" name="orange" value="80FF6633"/>
      <color id="3" name="yellow" value="80FFCC33"/>
      <color id="4" name="green" value="8000FF00"/>
      <color id="5" name="blue" value="800000FF"/>
      <color id="6" name="pink" value="80FF33CC"/>
    </set>
  </colors>
  <version>
    <font name="Verdana" size="8" color="FFC0C0C0"/>
  </version>
  <timeline>
    <background>C0E0E0E0</background>
    <font name="Verdana" size="8" color="E0808080"/>
  </timeline>
  <depthlayers xshift="5" yshift="5" color="20282828"/>
  <trendanalysis start="2008" end="9999"/>
  <huds>
    <zoombutton size="30" margin="6" padding="5" align="right" valign="top" background="C0FFFFFF"
      color="E0808080"/>
    <trenddirhud size="30" margin="6" padding="5" align="left" valign="top" background="C0FFFFFF"
      color="E0808080" distcolor="E033CCFF" font="Verdana" high="↗" mid="→" low="↘"/>
    <trendsizehud size="30" margin="6" padding="5" align="left" valign="center"
      background="C0FFFFFF" color="E0808080" distcolor="E033CCFF" font="Verdana" high="H" mid="M"
      low="L"/>
  </huds>
</configuration>
```

Some explanations:

The `<base_url>` element contains the callback URL fragment for an advanced search in the  
eprints' abstracts when a user clicks on a term.

All fonts sizes are in pt.

All color values are 4-Byte hexadecimal values in the order ARGB (alpha, red, green, blue channel). 
A value of FF for the alpha channel means that the color is opaque, smaller values increase transparency.

The `<colors>` and `<set>` element group the colors used for the nodes. Currently, only one
set is read by the visualisation. You can define as many `<color>` elements as you wish. The
`name` attributes can be filled with arbitrary values, they are just here for your documentation.

`<depthlayers>` defines the pseudo-3D effect used to display the time variation of a hovered node. 
The `xshift` and `yshift` attributes are in pixels. The `color` attribute is not used currently (it was in
a earlier version to indicate depth).

`<trendanalysis>` is used to define the year boundaries for the analysis of the timelines used 
by the filter HUDs ("head-up-display"), e.g. trend direction and trend size HUD. If `end="9999"` 
is specified, the upper boundary is determined by the TrendTerms visualisation.

`<huds>` stands for "head-up-displays". These are the buttons that are displayed when a 
user mouse-hovers the canvas. There is a HUD for the zoom buttons, one for the filter by
trend direction, and one for the filter by trend size. For the latter two, the TrendTerms 
visualisation applies analysis algorithms to the data.

The detailed format (including XML Schemas) is described in 
[TrendTerms_io.pde](https://github.com/eprintsug/TrendTerms/blob/master/Processing/TrendTerms/TrendTerms_io.pde)


### Restart the web server

After you have edited the configuration files, restart the web server.


## Initial generation of TrendTerms data

To initialize and test your setup, create TrendTerms graph data for a single eprintid (note that 
the eprint should have an abstract)

```
sudo -u apache {eprints_root}/archives/{repo}/bin/generate_trendterms {repo} 1 --verbose 
```

The generate_trendterms script does the following:
- It creates the directory `{eprints_root}/archives/{archive}/html/trendterms_data`
- For eprint 1, it creates two files in this directory which together make a graph
  - terms_1.xml containing the terms (=nodes of the graph) and its timelines
  - edges_1.xml containing the edges of the graph

(as a side note: the format of the TrendTerms graph files is described in  
https://github.com/eprintsug/TrendTerms/blob/master/Processing/TrendTerms/TrendTerms_io.pde
https://github.com/eprintsug/TrendTerms/tree/master/Processing/TrendTerms/xml_schemas )


### Linking the trendterms_data directory

The trendterms_data directory must be linked to all your language-specific HTML trendterms
directories so that the data can be accessed by the Processing code. Do the following:

```
cd {eprints_root}/archives/{repo}/html/{language}/trendterms/
ln -s {eprints_root}/archives/{repo}/html/trendterms_data data
```

Repeat these commands for every language, e.g. en, de, and so on.

### Initial test

In your browser, load the summary page of the eprint for which the TrendTerms data was
created above.

The TrendTerms should be displayed in a box at the end of the summary page.

If the graph is displayed, you are nearly set. If there are less than 100 terms,
the optimization of the term positions should start, otherwise, you will just see 4 or 5
concentric rings of bubbles.

Mouse-hover the graph to check whether the HUDs do appear.
Hover over a term to display the timeline.
Try the zoom buttons.
Click on a term to check whether the advanced search of the publications does work 
(see Edit the look of your visualisation).


### The TrendTerms Visualisation

The TrendTerms visualisation uses a physical model to optimize the positions of the terms.
To each pair of terms, a repulsive force is assigned. To each pair of terms that are connected
with an edge (e.g. which have a close distance in the abstract), a spring force is a assigned.
The spring strength is inversely proportional to the distance between two terms. Terms 
that have high connectivity are initially placed to the center, terms with low connectivity outside.
The positions are optimized until the total force is below a given threshold.
Optimisation is only carried out for graphs with less than 100 terms.


## Generating the TrendTerms data: The generate_trendterms script

Now a full run to generate the TrendTerms data must be carried out:

```
sudo -u apache {eprints_root}/archives/{repo}/bin/generate_trendterms {repo}
```

Depending on the number of eprints, this may take a long time. Assume 
a computation time of about 1 hour per 1'000 eprints.
Be also prepared that your file system has reserved enough space for the graph files. 
About 1.5 GB are required for 100'000 eprints.

`sudo -u apache {eprints_root}/archives/{repo}/bin/generate_trendterms --help` lists all options.



## Running updates

There are two options in for running updates with the generate_trendterms script:

`--update`: Generates TrendTerms graph files for a daily segment of eprints, so that
within one month all eprints are processed once, including the newly added eprints.
`--new`: Generates TrendTerms graph files only for eprints that were
added to the live archive yesterday.

For a small repository with a few 1000 eprints, we recommend to use the `--update` option. 
This keeps the TrendTerms data for all eprints up-to-date.

For a large repository with several 10000 eprints, we recommend to use `--new` in a nightly
cronjob, which reduces processing time to about 10-15 minutes, and to carry out a 
a complete run every 6-12 months.

`--new` has the following effect: 
The terms and edges for the new eprints are correctly calculated. However, because IDF 
has changed because documents have been added to the total document set 
(for IDF, see theory below), the term selection in the graph for the older eprints is now 
only approximative, since terms may have been dropped out because their WDF\*IDF value for a
given document may be now lower than the given boundary for selection. However, we assume, 
that IDF only changes slowly, but recommend to carry out periodically complete runs to 
correct for the IDF change.


## Theory behind the selection of terms

In information retrieval, the product WDF*IDF is a popular expression for the weight of a
term in relevance ranking.

WDF(i) is the within-document-frequency of a term i in a document. It remains constant.
IDF(i) = 1 / DF(i) is the inverse of the document frequency DF(i), which is the number of 
documents that contain the term i in a document set. This value changes with addition of
new documents to the document set.

Theoretically, plotting WDF\*IDF against the frequency of a term in a complete document set
should yield a bell-like curve. Very frequent terms have a low WDF\*IDF because of their high
IDF value - these are the stop words. Terms which are highly specific have a low WDF\*IDF too,
because of their low WDF. Thus, choosing terms with a WDF\*IDF above a given boundary should
yield relevant terms that occur also several times in a document set.
 
The Xapian search engine stores both WDF and DF with the terms. These can be used to 
calculate WDF*IDF.

The generate_trendterms script processes an eprint in 3 passes:

Pass 1: Selection of terms within the own abstract

The steps of pass 1 are:

*	Get abstract terms + WDF + positions. Filter stop words.
*	Get DF --> IDF
*	Filter terms: choose WDF*IDF within boundary conditions --> set of terms {F1}
*	For all combinations of terms in the set {F1}, sum up distance-dependent edge weights. 
Distance is calculated from positions of the terms
*	Coloring of the term bubbles is done according to the edge weights


Pass 2: Selection of related terms in abstracts of related eprints

This pass is carried out analogously to pass 1. Abstracts of related eprints are found by
carrying out queries for every term in {F1} that has a DF > 1. This leads to n < |{F1}| 
queries. The new terms are added to set {F2}.

Pass 3: Get timelines

The timelines are gathered for all terms of the combined set {F1 ∪ F2}



## Editing the Processing code (for developers)

The TrendTerms.pde file being used in the EPrints repo can be found in cfg/static/trendterms 
and can be used as is.

If you need or want to modify the visualisation itself, the individual functional modules 
of the Processing code are available in Processing/TrendTerms. From these, you can create
the combined TrendTerms.pde with the help of the Processing Development Environment 
(aka "Processing"). 

Processing can be obtained from

https://www.processing.org/download/

After you have installed Processing, the JavaScript mode must be installed as
well. Start Processing, and create a new sketch. In the top right corner of the 
Processing window, there is a dropdown menu called "Java". Choose "Add mode ...", and 
select "JavaScript Mode" from the list, then choose "Install".
 
Copy the folder "TrendTerms" to your sketchbook location (see Processing Preferences, where
you can configure the sketchbook location).

Switch to JavaScript mode and edit the modules.

To create TrendTerms.pde, use menu File > Export. A directory web-export is created in the
TrendTerms folder that contains TrendTerms.pde and all other necessary files. 
The visualisation can be tested by loading index.html in a Web browser.  