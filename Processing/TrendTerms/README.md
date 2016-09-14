#TrendTerms - Processing(JS) code for visualisation of network graphs

This is the standalone Processing(JS) code for TrendTerms

TrendTerms reads a graph of terms, their timelines and their relations and visualizes 
it as a network.

The visualisation can be classified as a combination of the scaling circles, centralised
burst and ramification network graphs according to the typology used 
by Manuel Lima (Visual Complexity, Mapping Patterns of Information, Princeton, NY, 2011, 
ISBN 978-1-56898-936-5).

The coordinates of the terms are either fixed by the software that generates the term data,
or can be used as initial coordinates for an optimisation of the term positions.
If the optimisation is enabled (see terms.xml), a simple physical model is used that minimizes 
the forces between the nodes of the graph. The forces are made up of pairwise repulsions 
between the nodes and springs between pairwise nodes where there is an edge between. The 
spring force is proportional to the weight of the edge.

The graph data, defined as a set of nodes and edges, and configuration parameters for the 
look and feel of the graph are read from three XML files: terms.xml, edges.xml and 
configuration.xml. 
Examples files can be found in the data  directory.
The detailed format and description of the files is described in module TrendTerms_io.pde .
Their XML schemas are available in the directory xml_schemas.



