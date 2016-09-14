/*
  Project:     TrendTerms
  Name:        TrendTerms_io.pde
  Purpose:     Loads configuration and data.
  
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2015-11-07
  Modified:    -
      
  Comment:     -
 
  Uses:        Modules: TrendTerms.pde, TrendTerms_animate.pde, TrendTerms_analyze.pde, 
               TrendTerms_api.pde, TrendTerms_events.pde, TrendTerms_graph_classes.pde, 
               TrendTerms_gui_classes.pde, TrendTerms_init.pde, TrendTerms_io.pde, 
               TrendTerms_node_actions.pde, traer_physics.pde
  
  Copyright:   2015, University of Zurich, IT Services
  License:     The TrendTerms code is Open Source Software. It is released under the 
               GNU GPL (General Public License). For more information, see 
               http://www.opensource.org/licenses/gpl-license.php
               
               THE TrendTerms code IS PROVIDED TO YOU "AS IS", AND WE MAKE NO EXPRESS 
               OR IMPLIED WARRANTIES WHATSOEVER WITH RESPECT TO ITS FUNCTIONALITY, OPERABILITY, 
               OR USE, INCLUDING, WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, 
               FITNESS FOR A PARTICULAR PURPOSE, OR INFRINGEMENT. WE EXPRESSLY DISCLAIM ANY 
               LIABILITY WHATSOEVER FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR SPECIAL 
               DAMAGES, INCLUDING, WITHOUT LIMITATION, LOST REVENUES, LOST PROFITS, LOSSES RESULTING 
               FROM BUSINESS INTERRUPTION OR LOSS OF DATA, REGARDLESS OF THE FORM OF ACTION OR LEGAL 
               THEORY UNDER WHICH THE LIABILITY MAY BE ASSERTED, EVEN IF ADVISED OF THE POSSIBILITY 
               OR LIKELIHOOD OF SUCH DAMAGES. 
               
               By using this code, you agree to the specified terms.             
  
  Requires:    Processing Development Environment (PDE), http://www.processing.org/
  Generates:   The PDE exports (menu File > Export) code and data to a web-export directory. 
*/

/*

  loodConfiguration() method for loading configuration parameters from an XML file
  
  The format of the XML file must be as follows:
  
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
    <trendanalysis start="2008" end="2012"/>
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
  
  
  Description of elements:
  
  Description of <configuration> element:
    One <configuration> element must be used. It contains as sub-elements one <callback>, <node>, <edge>, <colors>, 
    <version>, <timeline>, <depthlayers>, <trendanalysis> and <huds> element.
    
  Description of <callback> element:
    One <callback> element must be used. It contains one subelement <base_url>.
  
  Description of <base_url> element:
    One element must be used. Contains base URL which is used to construct the URL for calling the web page 
    upon clicking a node. String.
    
  Description of the <node> element:
    One element must be used. Contains one subelement <font>.
    
  Description of the node/font element:
    Used for the node label. One element must be used. 
    
    Attributes:
      name: (String) Name of the font to be used.
      size: (Float)  Size of the font in points.
    
  Description of <edge> element:
    One element must be used. Describes configuration for edge drawing. Contains subelements <line_weight> and <color>.
    
  Description of edge/line_weight element:
    One element must be used. Describes line weight for edges. Float.
    
  Description of edge/color element:
    One element must be used. Describes color of edge. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
  
  Description of <colors> element:
    One element must be used. Describes colors for node drawing. Contains one or more subelement <set>.
    
  Description of colors/set element:
    One or several elements can be used. Describes a set of node colors. Contains one or more color elements.
    (Currently only one set is read in).
    
    Attributes:
      id:   (Integer) Unique id of set. 
      name: (String)  Name of set.
  
  Description of colors/set/color element:
    One or several elements can be used. Describes a node color.
    
    Attributes:
      id:    (String) Unique id of the color.
      name:  (String) An arbitrary name of the color (just for a human reader).
      value: (String) Color value in RGB mode. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
  
  Description of <version> element:
    One element must be used. Describes configuration of the version message. Contains one <font> sub-element.
    
  Description of version/font element:
    One element must be used. 
  
    Attributes:
      name:  (String) Font name used for version message.
      size:  (Float)  Font size used for version message in pt.
      color: (String) Color used for version message in RGB mode. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
  
  Description of <timeline> element:
    One element must be used. Describes configuration of the timeline. Contains one <background> and one <font> sub-element.
  
  Description of timeline/background element:
    One element must be used. Background color of the timeline. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
    
  Description of timeline/font element:
    One element must be used. 
  
    Attributes:
      name:  (String) Font name used for version message.
      size:  (Float)  Font size used for version message in pt.
      color: (String) Color used for version message in RGB mode. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
  
  Description of <depthlayers> element:
    One element must be used. Describes the 3D-like shift of the displayed timeline distribution when a node is hovered.
    
    Attributes:
      xshift: (Float)  Shift in x direction in pixels. 
      yshift: (Float)  Shift in y direction in pixels.
      color:  (String) Color of the layer indicating the 3D effect. Currently not displayed. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
    
  Description of <trendanalysis> element:
    One element must be specified. Defines the year boundaries for the analysis of the trends (size, direction) of a term timeline.
    
    Attributes:
      start: (String) Start year.
      end:   (String) End year. If = 9999, finds the end year of the timeline itself.
  
  Description of <huds> element:
    One element must be used. Defines the configuration of the "head-up-displays" (HUDs). Contains the sub-elements <zoombutton>, 
    <trenddirhud> and <trendsizehud>.
    
  
  Description of <zoombutton> element:
    One element must be used. Describes size, position and color of the zoom button HUD.
    
    Attributes:
      size:       (Float) Size (width) in pixels.
      margin:     (Float) Margin to canvas border in pixels.
      padding:    (Float) Padding value to button label in pixels.
      align:      (String) Horizontal position in canvas. Can be "left", "center" or "right".
      valign:     (String) Vertical position in canvas. Can be "top", "center" or "bottom".
      background: (String) Color value of background. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      color:      (String) Color value of border and labels. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      
  Description of <trenddirhud> element:
    One element must be used. Describes size, position, font and color of the trend direction HUD.
    
    Attributes:
      size:       (Float) Size (width) in pixels.
      margin:     (Float) Margin to canvas border in pixels.
      padding:    (Float) Padding value to button label in pixels.
      align:      (String) Horizontal position in canvas. Can be "left", "center" or "right".
      valign:     (String) Vertical position in canvas. Can be "top", "center" or "bottom".
      background: (String) Color value of background. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      color:      (String) Color value of border and labels. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      distcolor:  (String) Color value for distribution graph. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      font:       (String) Font used for labels.
      high:       (String) Label used for high range indicator.
      mid:        (String) Label used for mid range indicator.
      low:        (String) Label used for low range indicator.

   Description of <trendsizehud> element:
    One element must be used. Describes size, position, font and color of the trend size HUD.
    
    Attributes:
      size:       (Float) Size (width) in pixels.
      margin:     (Float) Margin to canvas border in pixels.
      padding:    (Float) Padding value to button label in pixels.
      align:      (String) Horizontal position in canvas. Can be "left", "center" or "right".
      valign:     (String) Vertical position in canvas. Can be "top", "center" or "bottom".
      background: (String) Color value of background. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      color:      (String) Color value of border and labels. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      distcolor:  (String) Color value for distribution graph. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
      font:       (String) Font used for labels.
      high:       (String) Label used for high range indicator.
      mid:        (String) Label used for mid range indicator.
      low:        (String) Label used for low range indicator.

  XML Schema:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="configuration">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="callback"/>
          <xs:element ref="node"/>
          <xs:element ref="edge"/>
          <xs:element ref="colors"/>
          <xs:element ref="version"/>
          <xs:element ref="timeline"/>
          <xs:element ref="depthlayers"/>
          <xs:element ref="trendanalysis"/>
          <xs:element ref="huds"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="callback">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="base_url"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="base_url" type="xs:string"/>
    <xs:element name="node">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="font"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="edge">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="line_weight"/>
          <xs:element ref="color"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="line_weight" type="xs:decimal"/>
    <xs:element name="colors">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="set"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="set">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="color"/>
        </xs:sequence>
        <xs:attribute name="id" use="required" type="xs:integer"/>
        <xs:attribute name="name" use="required" type="xs:NCName"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="version">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="font"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="timeline">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="background"/>
          <xs:element ref="font"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="background" type="xs:NCName"/>
    <xs:element name="depthlayers">
      <xs:complexType>
        <xs:attribute name="color" use="required" type="xs:integer"/>
        <xs:attribute name="xshift" use="required" type="xs:integer"/>
        <xs:attribute name="yshift" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="trendanalysis">
      <xs:complexType>
        <xs:attribute name="end" use="required" type="xs:integer"/>
        <xs:attribute name="start" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="huds">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="zoombutton"/>
          <xs:element ref="trenddirhud"/>
          <xs:element ref="trendsizehud"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="zoombutton">
      <xs:complexType>
        <xs:attribute name="align" use="required" type="xs:NCName"/>
        <xs:attribute name="background" use="required" type="xs:NCName"/>
        <xs:attribute name="color" use="required" type="xs:NCName"/>
        <xs:attribute name="margin" use="required" type="xs:integer"/>
        <xs:attribute name="padding" use="required" type="xs:integer"/>
        <xs:attribute name="size" use="required" type="xs:integer"/>
        <xs:attribute name="valign" use="required" type="xs:NCName"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="trenddirhud">
      <xs:complexType>
        <xs:attribute name="align" use="required" type="xs:NCName"/>
        <xs:attribute name="background" use="required" type="xs:NCName"/>
        <xs:attribute name="color" use="required" type="xs:NCName"/>
        <xs:attribute name="distcolor" use="required" type="xs:NCName"/>
        <xs:attribute name="font" use="required" type="xs:NCName"/>
        <xs:attribute name="high" use="required"/>
        <xs:attribute name="low" use="required"/>
        <xs:attribute name="margin" use="required" type="xs:integer"/>
        <xs:attribute name="mid" use="required"/>
        <xs:attribute name="padding" use="required" type="xs:integer"/>
        <xs:attribute name="size" use="required" type="xs:integer"/>
        <xs:attribute name="valign" use="required" type="xs:NCName"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="trendsizehud">
      <xs:complexType>
        <xs:attribute name="align" use="required" type="xs:NCName"/>
        <xs:attribute name="background" use="required" type="xs:NCName"/>
        <xs:attribute name="color" use="required" type="xs:NCName"/>
        <xs:attribute name="distcolor" use="required" type="xs:NCName"/>
        <xs:attribute name="font" use="required" type="xs:NCName"/>
        <xs:attribute name="high" use="required" type="xs:NCName"/>
        <xs:attribute name="low" use="required" type="xs:NCName"/>
        <xs:attribute name="margin" use="required" type="xs:integer"/>
        <xs:attribute name="mid" use="required" type="xs:NCName"/>
        <xs:attribute name="padding" use="required" type="xs:integer"/>
        <xs:attribute name="size" use="required" type="xs:integer"/>
        <xs:attribute name="valign" use="required" type="xs:NCName"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="font">
      <xs:complexType>
        <xs:attribute name="color" type="xs:NCName"/>
        <xs:attribute name="name" use="required" type="xs:NCName"/>
        <xs:attribute name="size" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="color">
      <xs:complexType mixed="true">
        <xs:attribute name="id" type="xs:integer"/>
        <xs:attribute name="name" type="xs:NCName"/>
        <xs:attribute name="value" type="xs:NMTOKEN"/>
      </xs:complexType>
    </xs:element>
  </xs:schema>
  
*/

void loadConfiguration(String fname) 
{ 
  HashMap align2value;
  HashMap valign2value;
  
  align2value = new HashMap();
  align2value.put("left", LEFT);
  align2value.put("center", CENTER);
  align2value.put("right", RIGHT);
  
  valign2value = new HashMap();
  valign2value.put("top", TOP);
  valign2value.put("center", CENTER);
  valign2value.put("bottom", BOTTOM);
  
  XML xml_configuration = loadXML(fname);
  
  // callback URL configuration
  XML xml_callback = xml_configuration.getChild("callback");
  XML xml_base_url = xml_callback.getChild("base_url");
  base_url = xml_base_url.getContent();
  
  // node configuration
  XML xml_node = xml_configuration.getChild("node");
  XML xml_node_font = xml_node.getChild("font");
  node_font_name = xml_node_font.getString("name");
  node_font_size = xml_node_font.getFloat("size"); 
  
  // edge configuration
  XML xml_edge = xml_configuration.getChild("edge");
  XML xml_edge_line_weight = xml_edge.getChild("line_weight");
  edge_line_weight = float(xml_edge_line_weight.getContent());
  XML xml_edge_color = xml_edge.getChild("color");
  String edge_color_string = xml_edge_color.getContent();
  edge_color = unhex(edge_color_string);
  
  // color configuration
  XML [] xml_colors = xml_configuration.getChildren("colors/set/color");
  node_color_count = xml_colors.length;
  
  for (int i = 0; i < node_color_count; i++)
  {
    XML xml_color = xml_colors[i];
    String color_id = xml_color.getString("id");
    String color_name = xml_color.getString("name");
    String color_value = xml_color.getString("value");
    node_colors.add(new NodeColor(color_id,color_name,color_value));
    colorref2index.put(color_id,i);
  }

  // version HUD configuration
  XML xml_version_font = xml_configuration.getChild("version/font");
  version_font_name = xml_version_font.getString("name");
  version_font_size = xml_version_font.getFloat("size");
  String version_font_color_string = xml_version_font.getString("color");
  version_font_color = unhex(version_font_color_string);
  
  // timeline configuration
  XML xml_timeline_font = xml_configuration.getChild("timeline/font");
  timeline_font_name = xml_timeline_font.getString("name");
  timeline_font_size = xml_timeline_font.getFloat("size");
  String timeline_font_color_string = xml_timeline_font.getString("color");
  timeline_font_color = unhex(timeline_font_color_string);
  XML xml_timeline_background = xml_configuration.getChild("timeline/background");
  String timeline_background_string = xml_timeline_background.getContent();
  timeline_background = unhex(timeline_background_string);
  
  // depth layers configuration
  XML xml_depthlayers = xml_configuration.getChild("depthlayers");
  layershift_x = xml_depthlayers.getFloat("xshift");
  layershift_y = xml_depthlayers.getFloat("yshift");
  String layer_color_string = xml_depthlayers.getString("color");
  layer_color = unhex(layer_color_string);
  
  // trend analysis configuration
  XML xml_trendanalysis = xml_configuration.getChild("trendanalysis");
  analysis_start = xml_trendanalysis.getString("start");
  analysis_end = xml_trendanalysis.getString("end");
  
  // Heads-Up-Displays (HUDs)
  // zoombutton configuration
  XML xml_zoombutton = xml_configuration.getChild("huds/zoombutton");
  zoombutton_size = xml_zoombutton.getFloat("size");
  zoombutton_margin = xml_zoombutton.getFloat("margin");
  zoombutton_padding = xml_zoombutton.getFloat("padding");
  
  String zoombutton_align_string = xml_zoombutton.getString("align").toLowerCase();
  if (align2value.get(zoombutton_align_string) != null)
  {
    zoombutton_align = (Integer) align2value.get(zoombutton_align_string);
  }
  else
  {
    zoombutton_align = LEFT;
  }
  
  String zoombutton_valign_string = xml_zoombutton.getString("valign").toLowerCase();
  if (valign2value.get(zoombutton_valign_string) != null)
  {
    zoombutton_valign = (Integer) valign2value.get(zoombutton_valign_string);
  }
  else
  {
    zoombutton_valign = TOP;
  }
  
  String zoombutton_background_string = xml_zoombutton.getString("background");
  zoombutton_background = unhex(zoombutton_background_string);
  
  String zoombutton_color_string = xml_zoombutton.getString("color");
  zoombutton_color = unhex(zoombutton_color_string);
  
  // trend direction HUD configuration
  XML xml_trenddirhud = xml_configuration.getChild("huds/trenddirhud");
  trenddirhud_size = xml_trenddirhud.getFloat("size");
  trenddirhud_margin = xml_trenddirhud.getFloat("margin");
  trenddirhud_padding = xml_trenddirhud.getFloat("padding");
  
  String trenddirhud_align_string = xml_trenddirhud.getString("align").toLowerCase();
  if (align2value.get(trenddirhud_align_string) != null)
  {
    trenddirhud_align = (Integer) align2value.get(trenddirhud_align_string);
  }
  else
  {
    trenddirhud_align = LEFT;
  }
  
  String trenddirhud_valign_string = xml_trenddirhud.getString("valign").toLowerCase();
  if (valign2value.get(trenddirhud_valign_string) != null)
  {
    trenddirhud_valign = (Integer) valign2value.get(trenddirhud_valign_string);
  }
  else
  {
    trenddirhud_valign = TOP;
  }
  
  String trenddirhud_background_string = xml_trenddirhud.getString("background");
  trenddirhud_background = unhex(trenddirhud_background_string);
  
  String trenddirhud_color_string = xml_trenddirhud.getString("color");
  trenddirhud_color = unhex(trenddirhud_color_string);
  
  String trenddirhud_distcolor_string = xml_trenddirhud.getString("distcolor");
  trenddirhud_distcolor = unhex(trenddirhud_distcolor_string);
  
  trenddirhud_font = xml_trenddirhud.getString("font");
  trenddirhud_high = xml_trenddirhud.getString("high");
  trenddirhud_mid = xml_trenddirhud.getString("mid");
  trenddirhud_low= xml_trenddirhud.getString("low");
  
  // trend size HUD configuration
  XML xml_trendsizehud = xml_configuration.getChild("huds/trendsizehud");
  trendsizehud_size = xml_trendsizehud.getFloat("size");
  trendsizehud_margin = xml_trendsizehud.getFloat("margin");
  trendsizehud_padding = xml_trendsizehud.getFloat("padding");
  
  String trendsizehud_align_string = xml_trendsizehud.getString("align").toLowerCase();
  if (align2value.get(trendsizehud_align_string) != null)
  {
    trendsizehud_align = (Integer) align2value.get(trendsizehud_align_string);
  }
  else
  {
    trendsizehud_align = LEFT;
  }
  
  String trendsizehud_valign_string = xml_trendsizehud.getString("valign").toLowerCase();
  if (valign2value.get(trendsizehud_valign_string) != null)
  {
    trendsizehud_valign = (Integer) valign2value.get(trendsizehud_valign_string);
  }
  else
  {
    trendsizehud_valign = TOP;
  }
  
  String trendsizehud_background_string = xml_trendsizehud.getString("background");
  trendsizehud_background = unhex(trendsizehud_background_string);
  
  String trendsizehud_color_string = xml_trendsizehud.getString("color");
  trendsizehud_color = unhex(trendsizehud_color_string);
  
  String trendsizehud_distcolor_string = xml_trendsizehud.getString("distcolor");
  trendsizehud_distcolor = unhex(trendsizehud_distcolor_string);
  
  trendsizehud_font = xml_trendsizehud.getString("font");
  trendsizehud_high = xml_trendsizehud.getString("high");
  trendsizehud_mid = xml_trendsizehud.getString("mid");
  trendsizehud_low= xml_trendsizehud.getString("low");
  
  align2value.clear();
  valign2value.clear();
}

/*

  loadData() method for loading all nodes and edges from a node XML and an edge XML file. 
  
  Nodes and edges are being deduplicated.

  The format of the node XML file must be as follows:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <graph>
    <optimize value="true"/>
    <timeline count="43" dates="1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016"/>
    <terms count="41">
      <term id="33" value="atp" x="0.241" y="0.477" colorref="4">
        <trend count="43" data="0,0.129,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.008,0,0.004,0.008,0.008,0.024,0.012,0.020,0.024,0.008,0.032,0.024,0.060,0.081,0.073,0.077,0.121,0.097,0.069,0.065,0.065,0.028"/>
      </term>
      <term id="32" value="compromised" x="0.662" y="0.297" colorref="4">
        <trend count="43" data="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.004,0.012,0.008,0,0.012,0,0,0,0.012,0,0.012,0.040,0.060,0.065,0.048,0.113,0.109,0.101,0.093,0.016"/>
      </term>
      .
      .
      .
      <term id="5" value="fork" x="0.756" y="0.454" colorref="4">
        <trend count="43" data="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.004,0.004,0.004,0.012,0.012,0.012,0.004,0.012,0.008,0.008,0.012,0.040,0.012,0.032,0.016"/>
      </term>
    </terms>
  </graph>
  
  
  Description of <graph> element:
    Root element. One element must be used. It contains the elements <optimize>, <timeline>, and <terms>.
    
  Description of <optimize> element:
    One element must be used. Boolean for enabling/disabling physics optimization.
    
    Attributes:
      value:  (String) true for physics enabled, false for physics off.
      
  Description of <timeline> element:
    One element must be used. Describes the values of the time axis.
    
    Attributes:
      count: (Integer) Number of dates in dates attribute.
      dates: (String)  Comma-separated list of years that make up the timeline.
  
  Description of <terms> element:
    One element must be used. Contains one or several <term> elements.
    
    Attributes:
      count: (Integer) Number of terms in graph.
  
  Description of <term> element:
    For each node in the graph, one <term ...> element must be used.
    Each <term ...> element has one sub-element <trend ...>
    
    Attributes:
      id:       (String)  Unique identification for the node.
      value:    (String)  Node label
      x:        (Float)   x coordinate (relative coordinate in a coordinate system x = 0 ... 1)
      y:        (Float)   y coordinate (relative coordinate in a coordinate system y = 0 ... 1)
      colorref: (Integer) Reference to id of color
      
   Description of <trend> element:
    One element must be used. Describes the trend values of the term.
    
    Attributes:
      count: (Integer) Number of values in data attribute.
      data:  (String)  Comma-separated list of values that make up the trend along the timeline.
  
  
  XML Schema:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="graph">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="optimize"/>
          <xs:element ref="timeline"/>
          <xs:element ref="terms"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="optimize">
      <xs:complexType>
        <xs:attribute name="value" use="required" type="xs:boolean"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="timeline">
      <xs:complexType>
        <xs:attribute name="count" use="required" type="xs:integer"/>
        <xs:attribute name="dates" use="required"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="terms">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="term"/>
        </xs:sequence>
        <xs:attribute name="count" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="term">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="trend"/>
        </xs:sequence>
        <xs:attribute name="colorref" use="required" type="xs:integer"/>
        <xs:attribute name="id" use="required" type="xs:integer"/>
        <xs:attribute name="value" use="required" type="xs:NCName"/>
        <xs:attribute name="x" use="required" type="xs:decimal"/>
        <xs:attribute name="y" use="required" type="xs:decimal"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="trend">
      <xs:complexType>
        <xs:attribute name="count" use="required" type="xs:integer"/>
        <xs:attribute name="data" use="required"/>
      </xs:complexType>
    </xs:element>
  </xs:schema>
  
  
  The format of the edge XML file must be as follows:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <graph>
    <edges count="334">
      <e id="127" f="40" t="1" w="1"/>
      <e id="32" f="21" t="1" w="2"/>
      .
      .
      .
      <e id="78" f="5" t="1" w="1"/>
    </edges>
  </graph>
  
  Description of <graph> element:
    Root element. One element must be used. It contains the element <edges>.
    
  Description of <edges> element:
    One element must be used. Contains one or several <e> elements.
    
    Attributes:
      count: (Integer) Number of edges in graph.
  
  Description of the <e ...> element:
    For each edge in the graph, one <e ...> element must be used.
    
    Attributes:
      id: (String) Unique id for the edge
      f:  (String) Id of the start node  (from node)
      t:  (String) Id of the end node  (to node)
      w:  (Float)  Edge weight
   
      
  XML Schema:
   
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="graph">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="edges"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="edges">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="e"/>
        </xs:sequence>
        <xs:attribute name="count" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="e">
      <xs:complexType>
        <xs:attribute name="f" use="required" type="xs:integer"/>
        <xs:attribute name="id" use="required" type="xs:integer"/>
        <xs:attribute name="t" use="required" type="xs:integer"/>
        <xs:attribute name="w" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
  </xs:schema>
*/


void loadData(String f_termdata, String f_edgedata)
{
  xml_nodedata = loadXML(f_termdata);
  
  XML xml_optimize = xml_nodedata.getChild("optimize");
  String string_optimize = xml_optimize.getString("value");
  optimize = (string_optimize.toLowerCase().equals("true"));

  loadTimeline();
  loadNodes();
  loadEdges(f_edgedata);
}

void loadTimeline()
{
  XML xml_timeline = xml_nodedata.getChild("timeline");
  
  timeline_count = xml_timeline.getInt("count");
  String timeline_dates = xml_timeline.getString("dates");
  
  String[] dates = split( timeline_dates, ',');
  
  last_date = 0;

  for (int i = 0; i < timeline_count; i++)
  {
    String id = str(i);
    timepoint2id.put(dates[i],id);
    timeline.add(new TimeLine(id,float(dates[i])));
    last_date = max(last_date,int(dates[i]));
  }
  
  if (date.equals(""))
  {
    date = str(last_date);
  }
}

void loadNodes()
{
  XML [] xml_nodes = xml_nodedata.getChildren("terms/term");
  int node_count_temp = xml_nodes.length;

  node_count = 0;
  for (int i = 0; i < node_count_temp; i++)
  {
    XML xml_node = xml_nodes[i];
    String id = xml_node.getString("id");
    String term_value = xml_node.getString("value");
    float x = xml_node.getFloat("x");
    float y = xml_node.getFloat("y");
    String colorref = xml_node.getString("colorref");
    
    float x_init = x * canvas_width;
    float y_init = y * canvas_height;
    
    boolean node_added = addNode(id,term_value,x_init,y_init,colorref);
    
    if (node_added) {
      Node current_node = (Node) nodes.get(node_count);
      
      // load trend
      XML xml_trends = xml_node.getChild("trend");
      int trend_count = xml_trends.getInt("count");
      String trend_data = xml_trends.getString("data");
 
      String[] trendvalues = split(trend_data, ",");
      
      float trend_max = 0.0;
      
      for (int j = 0; j < trend_count; j++)
      {
        String ref = str(j);
        float trend_value = float(trendvalues[j]);
        current_node.addTrend(j, ref, trend_value);
        trend_max = max(trend_max,trend_value);
      }
      current_node.setRadius(date);
      current_node.setTrendMax(trend_max);
      node_count++;
    }
  }
  
  // dispose for garbage collection
  xml_nodedata = null;
}

void loadEdges(String f_edgedata)
{
  xml_edgedata = loadXML(f_edgedata);
  XML [] xml_edges = xml_edgedata.getChildren("edges/e");
  edge_count = 0;
  
  int edge_count_temp = xml_edges.length;
  
  for (int i = 0; i < edge_count_temp; i++)
  {
    XML xml_edge = xml_edges[i];
    String id = xml_edge.getString("id");
    String from = xml_edge.getString("f");
    String to = xml_edge.getString("t");
    float weight = xml_edge.getFloat("w");
    
    // for performance reasons - n*(n-1)/2 combinations to check -
    // we don't do a duplicate test here 
    
    // test whether the two referenced nodes exist
    if (node2index.get(from) != null && node2index.get(to) != null)
    {
      int node_index_from = (Integer) node2index.get(from);
      int node_index_to = (Integer) node2index.get(to);
       
      edges.add(new Edge(id,from,to,weight,node_index_from,node_index_to));
      
      Node node_from = (Node) nodes.get(node_index_from);
      Node node_to = (Node) nodes.get(node_index_to);
      
      node_from.addEdgeIndex(edge_count);
      node_to.addEdgeIndex(edge_count);
        
      edge_count++;     
    }
  }
  
  // dispose for garbage collection
  xml_edgedata = null;
}


boolean addNode(String id, String term_value, float x, float y, String colorref)
{
  // deduplicate nodes
  boolean duplicate = false;
  boolean added = false;
  
  for (int j = 0; j < node_count; j++) {
    Node node = (Node) nodes.get(j);
    if (node.id.equals(id)) {
      duplicate = true;
    }
  }
  
  if (duplicate == false) {
    node2index.put(id,node_count);
    nodes.add(new Node(id,term_value,x,y,colorref));
    added = true;
  }
  return added;
}