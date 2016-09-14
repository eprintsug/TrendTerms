/* @pjs crisp="true"; pauseOnBlur="true"; preload="../trendterms/navigation/mouse_zoomminus.png,../trendterms/navigation/mouse_zoomplus.png"; */

/*
  Project:     TrendTerms
  Name:        TrendTerms.pde
  Purpose:     Displays terms and their trends in a term cloud.
  
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2015-11-07
  Modified:    2016-06-05 Changed timeline/trend I/O
               2016-06-20 Improved resize behaviour
               2016-07-15 Added trend analysis
      
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
   TODO
   - searching/filtering
   - zoom to target
   - pinch zoom (probably with p5js)
   
   TODO Data Model
   - extract abstracts : use linguistic analysis (Apache NLP, RiTa, TreeTagger, Standford POS tagger or similar)
   - node.js for physics optimization?
   
   TODO long term
   - migrate to p5js
*/


/* 
  Global variables
*/

String version = "TrendTerms 1.0";

// Canvas parameters
int canvas_width = 400;
int canvas_height = 300;
float x_mid;
float y_mid;
float timeline_height = 50;
float timeline_position;


// animation parameters
boolean optimize;
boolean animate_zoomin = true;
boolean animate_physics = false;

// file names
String f_configuration;
String f_terms;
String f_edges;

// ArrayList sizes for nodes, edges, node colors, and timelines 
int node_count;
int edge_count;
int node_color_count;
int timeline_count;

// Graph variables
XML xml_nodedata;
XML xml_edgedata;
ArrayList<Node> nodes;
ArrayList<Edge> edges;
ArrayList<NodeColor> node_colors;
ArrayList<TimeLine> timeline;
HashMap node2index;
HashMap colorref2index;
HashMap timepoint2id;

// Date used for display of nodes (usually last date of timeline)
// see TrendTerms_io, loadTimeline()
String date = "2013";
int last_date;

// Thresholds;
float extent;
float density = 0.02; // (50 nodes per height unit)
float radius_threshold = 10;
float radius_lower = 2;

float label_threshold_rel = 0.02;
float label_threshold;
float velocity_threshold = 0.2;

// Map scale
float zoom_initial = 100.0;
float fscale_initial = 1.0;
float fscale;

// Zoom animation parameters
float zoom_start = 300;
float fscale_start = 3.0;
float zoom_factor = 0.95;
float zoom;

// x,y offset for mouse drag
float x_offset_drag;
float y_offset_drag;
float x_zoom_offset_drag;

// Mouse/keyboard events
PImage mouse_zoomplus;
PImage mouse_zoomminus;
boolean drag_locked = false;
boolean zoom_locked = false;
boolean mouse_in = false;

// Map position
float x_offset_initial = 0.0;
float y_offset_initial = 0.0;
float x_offset;
float y_offset;

// changes in drag (pixel) and zoom (percent);
float x_drag = 2;
float y_drag = 2;
float zoom_change = 5;

// Parameters for setting up the physical system (Traer physics library)
ParticleSystem ps;
Smoother3D centroid;
boolean physics_initialized = false;
float gravity = 0.0;
float drag = 0.1;
float spring_constant = 0.01;
float spring_damping = 0.1;
float repulsion = -2.0;
float repulsion_distance = 0.5;
float tick_time_base = 0.1;
float tick_time;

// Configuration parameter for nodes and edges
String base_url;
PFont node_font;
String node_font_name;
float node_font_size;
float node_font_height;

float edge_line_weight;
color edge_color;

// Parameters and fonts for version HUD
PFont version_font;
String version_font_name;
float version_font_size;
color version_font_color;

// Parameters and fonts for timeline axis
PFont timeline_font;
String timeline_font_name;
float timeline_font_size;
color timeline_font_color;
color timeline_background;

// Timeline layers
float layershift_x;
float layershift_y;
color layer_color;

// Mouse detection
int hovered_object;
int hovered_object_prev = -1;

// Zoom button
ZoomButton zoom_button;
float zoombutton_size;
float zoombutton_margin;
float zoombutton_padding;
int zoombutton_align;
int zoombutton_valign; 
color zoombutton_background;
color zoombutton_color;

// Trend analysis
String analysis_start;
String analysis_end;

// Trend direction HUD
TrendHUD trenddirhud;
float trenddirhud_size;
float trenddirhud_margin;
float trenddirhud_padding;
int trenddirhud_align;
int trenddirhud_valign; 
color trenddirhud_background;
color trenddirhud_color;
color trenddirhud_distcolor;
String trenddirhud_font;
String trenddirhud_high;
String trenddirhud_mid;
String trenddirhud_low;
int trenddir_selected;

// Trend size HUD
TrendHUD trendsizehud;
float trendsizehud_size;
float trendsizehud_margin;
float trendsizehud_padding;
int trendsizehud_align;
int trendsizehud_valign; 
color trendsizehud_background;
color trendsizehud_color;
color trendsizehud_distcolor;
String trendsizehud_font;
String trendsizehud_high;
String trendsizehud_mid;
String trendsizehud_low;
int trendsize_selected;

// Filter parameter
boolean filter_active = false;

// mathematical constants
float sqrt1_2;


void setup()
{
  String mydata = this.param("mydata");
  String myconfig = this.param("myconfig");
  
  if (mydata == null)
  {
    f_terms = "trendterms/terms.xml";
    f_edges = "trendterms/edges.xml";
  }
  else
  {
    f_terms = "../trendterms/data/terms_" + mydata + ".xml";
    f_edges = "../trendterms/data/edges_" + mydata + ".xml";
  }
  
  if (myconfig == null)
  {
    f_configuration = "trendterms/configuration.xml";
  }
  else
  {
    f_configuration = myconfig;
  }

  nodes = new ArrayList();
  edges = new ArrayList();
  node_colors = new ArrayList();
  timeline = new ArrayList();
  node2index = new HashMap();
  colorref2index = new HashMap();
  timepoint2id = new HashMap();
  
  // setup particle system
  ps = new ParticleSystem(gravity, drag);
  centroid = new Smoother3D( 0.8 );
  
  timeline_position = canvas_height - timeline_height;
  
  x_mid = canvas_width / 2;
  y_mid = canvas_height / 2;
   
  x_offset = x_offset_initial;
  y_offset = y_offset_initial;
    
  if (animate_zoomin)
  {
    float zoom_diff = zoom_start - zoom_initial;
    x_offset = x_offset - canvas_width * zoom_diff / 200;
    y_offset = y_offset - canvas_height * zoom_diff / 200;
    zoom = zoom_start;
    fscale = fscale_start;
  }
  else 
  {
    zoom = zoom_initial;
    fscale = fscale_initial;
  }
  
  size(400,300);
  
  extent = min(canvas_width, canvas_height);
  label_threshold =  extent * label_threshold_rel;
  
  noLoop();
  drawLoading();

  // read additional mouse cursor images
  mouse_zoomplus = loadImage("../trendterms/navigation/mouse_zoomplus.png");
  mouse_zoomminus = loadImage("../trendterms/navigation/mouse_zoomminus.png");
  
  loadConfiguration(f_configuration);
  loadData(f_terms,f_edges);
  
  zoom_button = new ZoomButton(1000001, zoombutton_size, zoombutton_margin, zoombutton_padding, zoombutton_align, zoombutton_valign, zoombutton_background, zoombutton_color);
  trenddirhud = new TrendHUD(1000004, trenddirhud_size, trenddirhud_margin, trenddirhud_padding, trenddirhud_align, trenddirhud_valign, trenddirhud_background, 
    trenddirhud_color, trenddirhud_distcolor, trenddirhud_font, trenddirhud_high, trenddirhud_mid, trenddirhud_low);
  trendsizehud = new TrendHUD(1000007, trendsizehud_size, trendsizehud_margin, trendsizehud_padding, trendsizehud_align, trendsizehud_valign, trendsizehud_background, 
    trendsizehud_color, trendsizehud_distcolor, trendsizehud_font, trendsizehud_high, trendsizehud_mid, trendsizehud_low);
  
  getTrendTermsCanvasSize();
  initConfiguration();
  initGraph();
  analyzeTrends();
  
  animate_physics = optimize;
  hovered_object = -1;
  sqrt1_2 = sqrt(2) / 2;
  
  colorMode(RGB,255);
  ellipseMode(RADIUS);
  smooth();
  loop();
}


void draw()
{
  background(255);
  // drawLayers();
  
  hovered_object = drawNodes();
  if (hovered_object >= 0 && hovered_object < 1000001) drawEdges(hovered_object); 
    
  drawNodeLabels(hovered_object);
  drawVersion();
  
  if (hovered_object >= 0 && hovered_object < 1000001) drawTimeline(hovered_object);
  
  // animate zoom in if required
  if (animate_zoomin) zoomIn();
  
  if (mouse_in)
  {
    zoom_button.display(mouseX, mouseY);
    if (zoom_locked) doZoom();
    trenddirhud.display(mouseX, mouseY);
    trendsizehud.display(mouseX, mouseY);
  }
 
  // update physics simulation if required
  if (animate_physics)
  {
    if (!physics_initialized) initPhysics();
    ps.tick(tick_time);
    updateCentroid();
    centroid.tick();
    updateNodes();
    float total_velocity = getTotalVelocity(x_offset, y_offset);
    animate_physics = (total_velocity > velocity_threshold);
  }
}


int drawNodes()
{
  hovered_object = -1;
  boolean hovered = false;
  
  for (int i = 0; i < node_count; i++)
  {
    Node display_node = (Node) nodes.get(i);
    boolean layer = true;
    hovered = display_node.display(x_offset, y_offset, fscale, mouseX, mouseY, layer);
    if (hovered)
    {
      hovered_object = i;
    }
  }
  
  return hovered_object;
}


void drawNodeLabels(int active_node)
{
  textFont(node_font);
  fill(8);
  textAlign(CENTER, CENTER);
  
  for (int i = 0; i < node_count; i++)
  {
    Node display_node = (Node) nodes.get(i);
    boolean hovered = (active_node == i);
    display_node.displayLabel(hovered);
  }
}


void drawEdges(int active_node)
{
  
  Node node = (Node) nodes.get(active_node);
  
  if (node.filter) 
  {
    for (int i = 0; i < node.getEdgeCount(); i++)
    {
      int edge_index = node.edge_indexes.get(i);
      Edge current_edge = (Edge) edges.get(edge_index);
      current_edge.display(x_offset, y_offset, fscale);
    }
  }
}


void drawTimeline(int active_node)
{
  // we first assume regular data
  // TODO irregular time points
   
  // bezier points 
  float x1,y1,x2,y2,bx1,by1,bx2,by2;
  
  float text_y;
  
  Node node = (Node) nodes.get(active_node);
  if (node.filter) 
  {
    int trenddata_count = node.trenddata.size();
    
    float t_dist = canvas_width / trenddata_count;
    float t_offset = t_dist/4;
    float y_offset = canvas_height - 0.1 * timeline_height;
    float data_height = 0.8 * timeline_height;
    float bezier_width = t_dist/5;
    
    fill(timeline_background);
    noStroke();
    rect(0,timeline_position,canvas_width,timeline_height);
    
    stroke(timeline_font_color);
    strokeWeight(0.2);
    
    // draw raster
    textFont(timeline_font);
    fill(timeline_font_color);
    textAlign(LEFT,TOP);
    
    float raster_width = textWidth("2000 ");
    float tick_timepoint = 0.0;
    
    TimeLine timepoint = (TimeLine) timeline.get(0);
    float raster_x = t_offset;
    line(raster_x,timeline_position,raster_x,canvas_height);
    String time_string = str(int(timepoint.value));    
    text(time_string, raster_x + 2, timeline_position + 2);
    
    for (int i = 1; i < timeline_count - 1; i++)
    {
      tick_timepoint += t_dist;
      if (tick_timepoint > raster_width)
      {
        timepoint = (TimeLine) timeline.get(i);
        raster_x = t_offset + i * t_dist;
        line(raster_x,timeline_position,raster_x,canvas_height);
        time_string = str(int(timepoint.value));    
        text(time_string, raster_x + 2, timeline_position + 2);
        tick_timepoint = 0.0;
      }
    }
    
    timepoint = (TimeLine) timeline.get(timeline_count - 1);
    raster_x = t_offset + timeline_count * t_dist;
    line(raster_x,timeline_position,raster_x,canvas_height);
    time_string = str(int(timepoint.value));    
    text(time_string, raster_x + 2, timeline_position + 2);
    
    
    color current_color = node.base_color;
    // bitshifting to obtain rgb values
    int r = (current_color >> 16) & 0xFF;  
    int g = (current_color >> 8) & 0xFF;   
    int b = current_color & 0xFF;
    
    strokeWeight(2);
    stroke(r,g,b,255);
    noFill();
       
    Trend trend_start = (Trend) node.trenddata.get(0);
    
    x1 = 0.0;
    y1 = y_offset - trend_start.value * data_height;
    bx1 = bezier_width;
    by1 = y1;
    x2 = t_offset;
    y2 = y1;
    bx2 = t_offset - bezier_width;
    by2 = y2;
     
    bezier(x1,y1,bx1,by1,bx2,by2,x2,y2);
    
    for (int i = 0; i < trenddata_count - 1; i++)
    {
       Trend trend1 = (Trend) node.trenddata.get(i);
       Trend trend2 = (Trend) node.trenddata.get(i+1);
       x1 = t_offset + i * t_dist;
       y1 = y_offset - trend1.value * data_height;
       bx1 = x1 + bezier_width;
       by1 = y1;
       x2 = t_offset + (i + 1) * t_dist;
       y2 = y_offset - trend2.value * data_height;
       bx2 = x2 - bezier_width;
       by2 = y2;
       
       bezier(x1,y1,bx1,by1,bx2,by2,x2,y2);
    }
    
    Trend trend_end = (Trend) node.trenddata.get(trenddata_count - 1);
    
    x1 = t_offset + (trenddata_count - 1) * t_dist;
    y1 = y_offset - trend_end.value * data_height;
    bx1 = x1 + bezier_width;
    by1 = y1;
    x2 = canvas_width;
    y2 = y1;
    bx2 = x2 - bezier_width;
    by2 = y2;
     
    bezier(x1,y1,bx1,by1,bx2,by2,x2,y2);
    
    textFont(node_font);
    fill(timeline_font_color);
    textAlign(LEFT,CENTER);
    if (trend_start.value < 0.5)
    {
      text_y = timeline_position + 0.4 * timeline_height;
    }
    else
    {
      text_y = timeline_position + 0.7 * timeline_height;
    }
    text(node.term, t_offset + 2, text_y);
  }
}


void drawLayers()
{
   float rect_x = 0.0;
   float rect_y = 0.0;
  
   float rect_width = canvas_width;
   float rect_height = canvas_height;
  
   noStroke();
  
   fill(layer_color);
   for (int i = 0; i < timeline_count; i++)
   {
     rect(rect_x,rect_y,rect_width,rect_height);
     rect_x += layershift_x;
     rect_y += layershift_y;
     rect_width -= 2 * layershift_x;
     rect_height -= 2 * layershift_y;
   }
}


void drawLoading()
{
  background(255);
  PFont loading_font;
  
  pushMatrix();
  loading_font = createFont("Verdana", 24);
  textFont(loading_font);
  textAlign(CENTER, CENTER);
  translate(canvas_width/2, canvas_height/2);
  fill(128);  
  text("Loading ...", 0,0);
  popMatrix();
}


void drawVersion() 
{
  int version_x = canvas_width - 5;
  int version_y = canvas_height - 5;
  
  textFont(version_font);
  textAlign(RIGHT,BOTTOM);
  fill(version_font_color);
  text(version,version_x,version_y);
}