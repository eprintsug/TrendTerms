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
 
  Uses:        Modules: TrendTerms_animate.pde, TrendTerms_analyze.pde, TrendTerms_api.pde, 
               TrendTerms_events.pde, TrendTerms_graph_classes.pde, TrendTerms_gui_classes.pde,
               TrendTerms_init.pde, TrendTerms_io.pde, traer_physics.pde
  
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
   - trend analysis
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
/*
  trends are analysed in two ways:
  - direction of trend (up, constant, down)
      trend is up if sum over differences in a given timeframe is larger than a positive threshold
      trend is constant if sum over differences in a given timeframe is between negative and positive threshold
      trend is down if sum over differences in a given timeframe is smaller than a negative threshold
  - size of trend (high, mid, low)
      trend size is high if at least two thirds of the data is in the upper third of the data
      trend size is mid if at least two thirds of the data is in the middle third of the data
      trend size is low if at least two thirds of the data is in the lower third of the data
*/  

void analyzeTrends()
{ 
  if (analysis_end.equals("9999"))
  {
    analysis_end = date;
  }
  
  int analysis_start_int = int(analysis_start);
  int analysis_end_int = int(analysis_end);
  
  float[] trenddir_distribution;
  float[] trendsize_distribution;
  float[] trend_boundaries;
  
  float trenddir_threshold = 0.1;
  float trendsize_segment = 0.667;
  
  trenddir_distribution = new float[3];
  trendsize_distribution = new float[3];
  trend_boundaries = new float[4];
  
  float total_max = 0.0;
  float total_min = 0.0;
  
  // find the maximum value
  for (int i = 0; i < node_count; i++)
  {
    Node node = (Node) nodes.get(i);
    total_max = max(node.trend_max,total_max);
  }
  
  float trend_range = total_max - total_min;
  trend_boundaries[0] = total_min;
  
  float trend_part_size = trend_range / 3;
  
  for (int i = 1; i <= 3; i++)
  {
    trend_boundaries[i] = total_min + i*trend_part_size;
  }
  
  // determine the distributions
  for (int i = 0; i < node_count; i++)
  {
    Node node = (Node) nodes.get(i);
    
    float trendsize_total = 0.0;
    float trenddir_total = 0.0;
    
    int count = 0;
    for (int t = analysis_start_int; t <= analysis_end_int; t++)
    {
      float diff = 0.0;
      float value = node.getTrendValue(str(t));
            
      if (count > 0)
      {
        float previous_value = node.getTrendValue(str(t-1));
        diff = value - previous_value;
      }
      count++;
      
      trendsize_total += value;
      trenddir_total += diff;
    }
    
    trendsize_total = min(trendsize_total / trendsize_segment / count, total_max);
    
    // trend size
    for (int j = 0; j < 3; j++)
    {
      if (trendsize_total >= trend_boundaries[j] && trendsize_total <= trend_boundaries[j+1])
      {
        node.trendsize = j - 1;
        trendsize_distribution[2 - j] += 1.0;
      }
    }
    
    // trend direction
    if (trenddir_total > trenddir_threshold)
    {
      node.trenddirection = 1;
      trenddir_distribution[0] += 1.0;
    }
    else if (trenddir_total < -trenddir_threshold )
    {
      node.trenddirection = -1;
      trenddir_distribution[2] += 1.0;
    }
    else 
    {
      node.trenddirection = 0;
      trenddir_distribution[1] += 1.0;
    }
  }
  
  // normalize distributions
  for (int i = 0; i < 3; i++)
  {
    trendsize_distribution[i] = trendsize_distribution[i] / node_count;
  }
  
  for (int i = 0; i < 3; i++)
  {
    trenddir_distribution[i] = trenddir_distribution[i] / node_count; 
  }
  
  
  trendsizehud.setTrendDistribution(trendsize_distribution);
  trenddirhud.setTrendDistribution(trenddir_distribution);
}
void doZoom()
{
  switch (hovered_object)
  { 
    case 1000001: // zoom in
      if (zoom < 1600) 
      {
        zoom = zoom + zoom_change;
        fscale = fscale_initial * zoom / 100.0;
        x_offset = x_offset - canvas_width * zoom_change / 200;
        y_offset = y_offset - canvas_height * zoom_change / 200;
      }
      break;
    case 1000003: // zoom out
      if (zoom > 50)
      {
        zoom = zoom - zoom_change;
        fscale = fscale_initial * zoom / 100.0;
        x_offset = x_offset + canvas_width * zoom_change / 200;
        y_offset = y_offset + canvas_height * zoom_change / 200;
      }
      break;
    
    default: 
      zoom_locked = false;
      break;
  }
}

void zoomIn()
{
  float zoom_diff = zoom * (1.0 - zoom_factor);
  zoom = zoom * zoom_factor;
  fscale = fscale * zoom_factor;
  x_offset = x_offset + canvas_width * zoom_diff / 200;
  y_offset = y_offset + canvas_height * zoom_diff / 200;
  
  if (fscale < fscale_initial)
  {
    zoom = zoom_initial;
    fscale = fscale_initial;
    x_offset = x_offset_initial;
    y_offset = y_offset_initial;
    animate_zoomin = false;
  }
}

// update the node positions from particle positions of physics simulation
void updateNodes() {
  for (int i = 0; i < node_count; i++) {
    Node node = (Node) nodes.get(i);
    Particle p = ps.getParticle(i);
    node.setPosition(p.position.x, p.position.y);    
  }
}

// method for centering graph to its centroid
void updateCentroid() {
  float xMin =  999999.9; //Float.POSITIVE_INFINITY,
  float xMax = -999999.9; //Float.NEGATIVE_INFINITY,
  float yMin =  999999.9; //Float.POSITIVE_INFINITY,
  float yMax = -999999.9; //Float.NEGATIVE_INFINITY;

  for (int i = 0; i < ps.numberOfParticles(); i++)
  {
    Particle p = ps.getParticle(i);
    xMax = max(xMax, p.position.x);
    xMin = min(xMin, p.position.x);
    yMin = min(yMin, p.position.y);
    yMax = max(yMax, p.position.y);
  }
  
  float deltaX = xMax - xMin;
  float deltaY = yMax - yMin;
  
  if ( deltaY > deltaX ) {
    centroid.setTarget(xMin + 0.5 * deltaX, yMin + 0.5 * deltaY, 1);
  } else {
    centroid.setTarget(xMin + 0.5 * deltaX, yMin + 0.5 * deltaY, 1);
  }
}

float getTotalVelocity(float x_off, float y_off)
{
  float total_velocity = 0;
  
  for (int i = 0; i < ps.numberOfParticles(); i++)
  {
    Particle p = ps.getParticle(i);
    float velocity_x = p.velocity.x;
    float velocity_y = p.velocity.y;

    Node node = (Node) nodes.get(i);

    stroke(40);
    strokeWeight(0.1);
    float vx = x_off + (node.x + 10*velocity_x) * fscale;
    float vy = y_off + (node.y + 10*velocity_y) * fscale;
    line(x_off + node.x * fscale,y_off + node.y * fscale, vx, vy);

    float vel = velocity_x * velocity_x + velocity_y * velocity_y;
    total_velocity += vel;
  }
  return total_velocity;
}
// API function for dynamic resizing
void resizeSketch(int sketch_width, int sketch_height)
{  
  float extent_prev = extent;
  extent = min(sketch_width, sketch_height);
  
  float extent_ratio = extent / extent_prev;
  
  x_offset = x_offset * sketch_width / canvas_width;
  y_offset = y_offset * sketch_height / canvas_height;
  
  fscale_initial = fscale_initial * extent_ratio;
  fscale = fscale * extent_ratio;
  
  canvas_width = sketch_width;
  canvas_height = sketch_height;
  
  timeline_position = canvas_height - timeline_height;
  
  x_mid = canvas_width / 2;
  y_mid = canvas_height / 2;
  
  label_threshold =  extent * label_threshold_rel;
  
  size(canvas_width, canvas_height);
  zoom_button.setPosition();
}

// API function for filtering of nodes
void findNodes(String find_string)
{
  filter_active = false;
  
  String find = find_string.toLowerCase();
  for (int i = 0; i < node_count; i++)
  {
    Node node = (Node) nodes.get(i);
    boolean filter_value = (node.term.indexOf(find) == 0);
    node.setFilter(filter_value);
    if (filter_value == false) filter_active = true;
  }
}
/*
  Key events
*/

void keyPressed() {
  if (mouse_in)
  {
    switch(keyCode) {
      case 37: // left cursor, drag left
        x_offset = x_offset - x_drag;
        break;
      case 39: // right cursor, drag right
        x_offset = x_offset + x_drag;
        break;
      case 38: // up cursor, drag up
        y_offset = y_offset - y_drag;
        break;
      case 40: // down cursor, drag down
        y_offset = y_offset + y_drag;
        break;
      case 48: // center view, 100% zoom
        x_offset = x_offset_initial;
        y_offset = y_offset_initial;
        zoom = zoom_initial;
        fscale = fscale_initial;
        break;  
    }
    switch(key) {
      case '+':  // zoom in
        if (zoom < 1600) {
          zoom = zoom + zoom_change;
          fscale = fscale_initial * zoom / 100.0;
          x_offset = x_offset - canvas_width * zoom_change / 200;
          y_offset = y_offset - canvas_height * zoom_change / 200;
        }
        break;
      case '-': // zoom out
        if (zoom > 50) {
          zoom = zoom - zoom_change;
          fscale = fscale_initial * zoom / 100.0;
          x_offset = x_offset + canvas_width * zoom_change / 200;
          y_offset = y_offset + canvas_height * zoom_change / 200;
        }
        break;
      case 'u': // select/deselect up trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == 1)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = 1;
          setTrendDirNodes(1, false);
        }
        break;
      case 'c': // select/deselect constant trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == 0)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = 0;
          setTrendDirNodes(0, false);
        }
        break;
      case 'd': // select/deselect down trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == -1)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = -1;
          setTrendDirNodes(-1, false);
        }
        break;
      case 'h': // select/deselect high trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == 1)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = 1;
          setTrendSizeNodes(1, false);
        }
        break;
      case 'm': // select/deselect mid trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == 0)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = 0;
          setTrendSizeNodes(0, false);
        }
        break;
      case 'l': // select/deselect low trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == -1)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = -1;
          setTrendSizeNodes(-1, false);
        }
        break;  
      case 'p': // turn on physics simulation
        animate_physics = true;
        break;
      case 's': // turn off physics simulation
        animate_physics = false;
        break;
    }
  }
}
/*
  Mouse events
*/
void mousePressed() {
  switch (hovered_object) {
    case -1: // no object chosen
      x_offset_drag = mouseX - x_offset;
      y_offset_drag = mouseY - y_offset;
      drag_locked = true;
      zoom_locked = false;
      cursor(HAND);
      break;
    case 1000001: // zoom in
      drag_locked = false;
      zoom_locked = true;
      hovered_object_prev = hovered_object;
      break;
    case 1000002: // center view, 100% zoom
      x_offset = x_offset_initial;
      y_offset = y_offset_initial;
      zoom = zoom_initial;
      fscale = fscale_initial;
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000003: // zoom out
      drag_locked = false;
      zoom_locked = true;
      hovered_object_prev = hovered_object;
      break;
    case 1000004:
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000005:
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000006:
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000007:
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000008:
      drag_locked = false;
      zoom_locked = false;
      break;
    case 1000009:
      drag_locked = false;
      zoom_locked = false;
      break;

    default:
      x_offset_drag = mouseX - x_offset;
      y_offset_drag = mouseY - y_offset;
      drag_locked = true;
      cursor(HAND);
      break;
  }
}

// mouse click handler
void mouseClicked() {
  if (hovered_object > -1 && hovered_object < 1000001) {
    if (nodes.get(hovered_object) != null)
    {
      Node node_clicked = (Node) nodes.get(hovered_object);
      // String term = escape(node_clicked.term);
      String term = node_clicked.term;
      String url = base_url + term;
      link(url);
    }
  }
  
  switch (hovered_object) {
    case 1000004: // select/deselect up trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == 1)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = 1;
          setTrendDirNodes(1, false);
        }
        break;
      case 1000005: // select/deselect constant trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == 0)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = 0;
          setTrendDirNodes(0, false);
        }
        break;
      case 1000006: // select/deselect down trend
        setTrendDirNodes(trenddir_selected, true);
        if (trenddir_selected == -1)
        {
          trenddir_selected = 9999;
        }
        else 
        {
          trenddir_selected = -1;
          setTrendDirNodes(-1, false);
        }
        break;
      case 1000007: // select/deselect high trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == 1)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = 1;
          setTrendSizeNodes(1, false);
        }
        break;
      case 1000008: // select/deselect mid trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == 0)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = 0;
          setTrendSizeNodes(0, false);
        }
        break;
      case 1000009: // select/deselect low trend
        setTrendSizeNodes(trendsize_selected, true);
        if (trendsize_selected == -1)
        {
          trendsize_selected = 9999;
        }
        else 
        {
          trendsize_selected = -1;
          setTrendSizeNodes(-1, false);
        }
        break;  
  }
}

// mouse release event handler
void mouseReleased() 
{
  drag_locked = false;
  zoom_locked = false;
  hovered_object_prev = -1;
  if (hovered_object > 1000000) hovered_object = -1;
  cursor(ARROW);
}

// mouse drag event handler, handles map drag
void mouseDragged() 
{
  if (drag_locked) 
  {
    x_offset = mouseX - x_offset_drag;
    y_offset = mouseY - y_offset_drag;
  }
}


// mouse move event handler
void mouseMoved() 
{
  if (drag_locked == false) {
    cursor(ARROW);
  }
}



void mouseOut()
{
  mouse_in = false;
  drag_locked = false;
  zoom_locked = false;
  hovered_object_prev = -1;
  cursor(ARROW);
}

void mouseOver()
{
  mouse_in = true;
}

// mouse wheel event handler, handles zoom
void mouseScrolled() {
  if (mouse_in) 
  {
    // float step = 0;             // Java mode
    float step = mouseScroll;   //JavaScript mode, comment out for Java mode
   
    if (zoom >= 50 && zoom <= 1600) {
      if (step > 0) {
        cursor(mouse_zoomplus,0,0);
        step = 1;
      }
      if (step < 0) {
        cursor(mouse_zoomminus,0,0);
        step = -1;
      }
      float zoom_change2 = zoom_change * step; 
      zoom = zoom + zoom_change2;
      
      if (zoom < 50) {
        float diff = 50 - zoom;
        zoom_change2 = zoom_change2 + diff;
        zoom = 50;
      }
      if (zoom > 400) {
        float diff = zoom - 400;
        zoom_change2 = zoom_change2 - diff;
        zoom = 400;
      }
      fscale = fscale_initial * zoom / 100.0;
      x_offset = x_offset - canvas_width * zoom_change2 / 200;
      y_offset = y_offset - canvas_height * zoom_change2 / 200;
    }
  }
}
class Node
{
  String id;
  String term;
  String term_lower;
  float x,y;
  float radius;
  String colorref;
  color base_color;
  int r,g,b;
  int trendsize;
  int trenddirection;
  boolean filter;
  ArrayList<Trend> trenddata;
  HashMap ref2trenddata;
  float trend_max;
  ArrayList<Integer> edge_indexes;
  
  // temporary variables, set by display() and reused in displayLabel()
  float x1,y1;                // current position
  float x1_start,y1_start;    // clip coordinate
  float x1_end,y1_end;        // clip coordinate
  float radius_s;             // current radius (scaled)
    
  // constructor
  Node(String id_init, String term_init, float x_init, float y_init, String colorref_init)
  {
    id = id_init;
    term = term_init;
    term_lower = term.toLowerCase();
    x = x_init;
    y = y_init;
    colorref = colorref_init;
     
    int colorref_index = (Integer) colorref2index.get(colorref);
    NodeColor temp_node_color = (NodeColor) node_colors.get(colorref_index);
    base_color = temp_node_color.color_value;
    
    // bitshifting to obtain rgb values
    r = (base_color >> 16) & 0xFF;
    g = (base_color >> 8) & 0xFF;
    b = base_color & 0xFF;
    
    filter = true;
    
    trenddata = new ArrayList<Trend>();
    ref2trenddata = new HashMap();
    edge_indexes = new ArrayList<Integer>();
    
    
    // set a minimal initial radius. Will be overwritten by setRadius()
    radius = 1.0;
  }
  
  // methods
  boolean display(float x_off, float y_off, float fscale, int mouse_x, int mouse_y, boolean layer)
  {
    boolean detect = false;
    x1 = x_off + x*fscale;
    y1 = y_off + y*fscale;
    
    radius_s = radius * fscale;
    
    x1_start = x1 - radius_s;
    x1_end = x1 + radius_s;
    y1_start = y1 - radius_s;
    y1_end = y1 + radius_s;
       
    boolean clip = (x1_end < 0 || x1_start > canvas_width || y1_end < 0 || y1_start > canvas_height);
    if (!clip)
    {
      if (filter)
      {
        fill(base_color);
      }
      else
      {
        fill(r,g,b,20);
      }
      noStroke();
      ellipse(x1,y1,radius_s,radius_s);
      
      fill(r-32,g-32,b-32,128);
      if (filter) 
      { 
        displayTrend(x1,y1,radius_s, trenddirection);
      }
           
      float deltax = float(mouse_x) - x1;
      float deltay = float(mouse_y) - y1;
      
      float r2 = radius_s * radius_s;
      float detect_r2 = deltax * deltax + deltay * deltay;
      
      detect = layer && ( detect_r2 < r2 );
      
      if (detect && filter)
      {
        displayTimeEvolution(x_off, y_off, fscale);
      }
    }
    return detect;
  }
  
  void displayTrend(float x1, float y1, float r, float direction)
  {
    float w =10;  // triangle base width
    float h = 10;  // triangle height
    float s = sqrt1_2;
    
    if (r > w) 
    {
      if (direction == 0)
      {
        triangle(x1 + r,y1,x1+r-h,y1+w/2,x1+r-h,y1-w/2);
      }
      else
      {
        triangle(
          x1 + s*r,y1 - direction*s*r,
          x1 + s*(r-h-w/2), y1 - direction*s*(r-h+w/2),
          x1 + s*(r-h+w/2), y1 - direction*s*(r-h-w/2)
        );
      }
    }
  }
  
  
  void displayTimeEvolution(float x_off, float y_off, float fscale)
  {
    // first unsorted, must be sorted
    int trenddata_count = trenddata.size();
   
    int a = 120;

    float dir_x = (x_mid - x_off - x * fscale) / x_mid;
    float dir_y = (y_mid - y_off - y * fscale) / y_mid;

    for (int i = 0; i < trenddata_count; i++)
    {
      int i_reverse = (trenddata_count - i - 1);
      float x_shift = i_reverse * dir_x * layershift_x;
      float y_shift = i_reverse * dir_y * layershift_y;
      float x1_shift = x1 + x_shift; 
      float y1_shift = y1 + y_shift;

      Trend current_trend = (Trend) trenddata.get(i);

      float radius_shift = radius_threshold * sqrt(current_trend.value) * fscale;

      fill(r,g,b, max(a - i_reverse * 10,0));
      stroke(r,g,b,max(240 - i_reverse * 10,0));
      strokeWeight(0.5);
      ellipse(x1_shift,y1_shift,radius_shift,radius_shift);
    }
  }
  
  void displayLabel(boolean detect)
  {    
    boolean clip = (x1_end < 0 || x1_start > canvas_width || y1_end < 0 || y1_start > canvas_height);
   
    
    if (filter_active)
    {
      if (!clip && (filter || detect ) ) text(term, x1, y1);
    }
    else
    {
      if (!clip && filter && (detect || radius_s > label_threshold)) text(term, x1, y1);
    }
  }
  
  void addTrend(int pointer, String ref, float value)
  {
    trenddata.add(new Trend(ref,value));
    ref2trenddata.put(ref,pointer);
  }
  
  float getTrendValue(String year)
  {
    float value = 0.0;
    String ref = (String) timepoint2id.get(year);
    
    if (ref2trenddata.get(ref) != null)
    {
      int trendindex = (Integer) ref2trenddata.get(ref);
      Trend current_trend = (Trend) trenddata.get(trendindex);
      value = current_trend.value;
    }
    return value;
  }
  
  void setTrendMax(float value)
  {
    trend_max = value;
  }
  
  void setTrendDirection(int value)
  {
    trenddirection = value;
  }
  
  void setTrendSize(int value)
  {
    trendsize = value;
  }
  
  void addEdgeIndex(int index)
  {
    edge_indexes.add(index);
  }
  
  int getEdgeCount()
  {
    return edge_indexes.size();
  }
  
  void setPosition(float x_init, float y_init) {
    x = x_init;
    y = y_init;
  }
  
  void setRadius(String year)
  { 
    if (timepoint2id.get(year) != null)
    {
      String ref = (String) timepoint2id.get(year);
      if (ref2trenddata.get(ref) != null)
      {
        int trendindex = (Integer) ref2trenddata.get(ref);   
        Trend current_trend = (Trend) trenddata.get(trendindex);
        radius = radius_threshold * sqrt(current_trend.value);
        if (radius < radius_lower)
        {
          radius = radius_lower;
        }
      }
    }
  }
  
  void setFilter(boolean filter_value)
  {
    filter = filter_value;
  }
}


class Edge
{
  String id;
  String from;
  String to;
  float weight;
  float weight_normed;
  int from_index;
  int to_index;
  
  // constructor
  Edge(String id_init, String from_init, String to_init, float weight_init, int from_index_init, int to_index_init)
  {
    id = id_init;
    from = from_init;
    to = to_init;
    weight = weight_init;
    from_index = from_index_init;
    to_index = to_index_init;
  }
  
  // methods
  void display(float x_off, float y_off, float fscale) 
  { 
    Node node_from = (Node) nodes.get(from_index);
    Node node_to = (Node) nodes.get(to_index);
    
    // centers of nodes
    float x_from = x_off + node_from.x * fscale;
    float y_from = y_off + node_from.y * fscale;
   
    float x_to = x_off + node_to.x * fscale;
    float y_to = y_off + node_to.y * fscale;
    
    // correct for radii
    float d = dist(x_from, y_from, x_to, y_to);
    float r_from = node_from.radius * fscale;
    float r_to = node_to.radius * fscale;
    
    float dx = x_to - x_from;
    float dy = y_to - y_from;
    
    float corr_from = r_from / d;
    float x_from_c = x_from + corr_from * dx;
    float y_from_c = y_from + corr_from * dy;
    
    float corr_to = r_to / d;
    float x_to_c = x_to - corr_to * dx;
    float y_to_c = y_to - corr_to * dy;
    
    stroke(edge_color);
    // stroke(192,192,192,weight);
    strokeWeight(edge_line_weight * weight_normed);
    
    line(x_from_c,y_from_c,x_to_c,y_to_c);
  }
  
  void setNormedWeight(float w)
  {
    weight_normed = w;
  }
}


class Trend
{
  String ref;
  float value;
  
  // constructor
  Trend(String ref_init, float value_init)
  {
    ref = ref_init;
    value = value_init;
  }
}

class TimeLine
{
  String id;
  float value;
  
  // constructor
  TimeLine(String id_init, float value_init)
  {
    id = id_init;
    value = value_init;
  }
}

class NodeColor
{
  String id;
  String name;
  String color_string;
  color color_value;
  
  // constructur
  NodeColor(String id_init, String name_init, String color_string_init)
  {
    id = id_init;
    name = name_init;
    color_string = color_string_init;
    color_value = unhex(color_string);
  }  
}
class ZoomButton
{ 
  int id;
  int zoom_plus,zoom_reset,zoom_minus;
  float x,y;
  int direction;   // not used yet: 0 = vertical, 1 = horizontal
  float button_size;
  float margin;
  float padding;
  int pos_x, pos_y; 
  color button_background;
  color button_color;
  
  
  // constructor
  ZoomButton(int id_init, float button_size_init, float margin_init, float padding_init, int pos_x_init, int pos_y_init, color button_background_init, color button_color_init)
  {
    id = id_init;
    zoom_plus = id;
    zoom_reset = id + 1;
    zoom_minus = id + 2;
    button_size = button_size_init;
    margin = margin_init;
    padding = padding_init;
    direction = 0;
    pos_x = pos_x_init;
    pos_y = pos_y_init;
    button_background = button_background_init;
    button_color = button_color_init;
    setPosition();
  }
  
  // methods
  void setPosition()
  {
    switch(pos_x)
    {
      case LEFT:
        x = margin;
        break;
      case CENTER:
        x = x_mid - button_size / 2;
        break;
      case RIGHT:
        x = canvas_width - margin - button_size;
        break;
      default:
        x = margin;
    }
    
    switch(pos_y)
    {
       case TOP:
         y = margin;
         break;
       case CENTER:
         y = y_mid - 1.5 * button_size;
         break;
       case BOTTOM:
         y = canvas_height - margin - 3 * button_size;
         break;
       default:
         y = margin;
    }
  }
  
  void display(int mouse_x, int mouse_y)
  {
    boolean button_touched = false;
    float x1 = x;
    float x2 = x + button_size;
    float y1 = y;
    float y2 = y + button_size;
    float y3 = y + 2*button_size;
    float y4 = y + 3*button_size;
    float button_mid = button_size/2;
    float pad2 = 2 * padding;
    
    stroke(button_color);
    strokeWeight(1);
    fill(button_background);
    
    rect(x1,y1,button_size,button_size*3,padding,padding,padding,padding);
    line(x1,y2,x2,y2);
    line(x1,y3,x2,y3);
    
    strokeWeight(2.0);
    noFill();
    line(x1 + pad2,y1 + button_mid,x2 - pad2,y1 + button_mid);
    line(x1 + button_mid,y1 + pad2, x1 + button_mid, y2 - pad2);
    ellipse(x1 + button_mid, y2 + button_mid, padding, padding);
    line(x1 + pad2,y3 + button_mid,x2 - pad2,y3 + button_mid);
    
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y1 && mouse_y < y2) 
    { 
      button_touched = true;
      hovered_object = zoom_plus;
    }
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y2 && mouse_y < y3) {
      button_touched = true;
      hovered_object = zoom_reset;
    }
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y3 && mouse_y < y4)
    { 
      button_touched = true;
      hovered_object = zoom_minus;
    }
    
    zoom_locked = (hovered_object == hovered_object_prev);
    if (button_touched == false) 
    { 
      hovered_object_prev = -1;
      if (hovered_object > 1000000) hovered_object = -1;
      zoom_locked = false;
    }
  }
}

class TrendHUD
{ 
  int id;
  int upper_id,mid_id,lower_id;
  float x,y;
  int direction;   // not used yet: 0 = vertical, 1 = horizontal
  float button_size;
  float margin;
  float padding;
  int pos_x, pos_y; 
  color button_background;
  color button_color;
  color dist_color;
  int r,g,b,a;
  String hud_font_name;
  PFont hud_font;
  String high, mid, low;
  float[] trend_distribution;
  
  // constructor
  TrendHUD(int id_init, float button_size_init, float margin_init, float padding_init, int pos_x_init, int pos_y_init, color button_background_init, color button_color_init, color dist_color_init, 
    String hud_font_name_init, String high_init, String mid_init, String low_init)
  {
    id = id_init;
    upper_id = id;
    mid_id = id + 1;
    lower_id = id + 2;
    high = high_init;
    mid = mid_init;
    low = low_init;
    button_size = button_size_init;
    margin = margin_init;
    padding = padding_init;
    direction = 0;
    pos_x = pos_x_init;
    pos_y = pos_y_init;
    button_background = button_background_init;
    button_color = button_color_init;
    dist_color = dist_color_init;
    
    float hud_font_size = button_size - 3.5 * padding;
    
    // bitshifting to obtain rgba values
    a = (dist_color >> 24) & 0xFF;
    r = (dist_color >> 16) & 0xFF;
    g = (dist_color >> 8) & 0xFF;
    b = dist_color & 0xFF;
    
    hud_font_name = hud_font_name_init;
    hud_font = createFont(hud_font_name, hud_font_size);
    high = high_init;
    mid = mid_init;
    low = low_init;
    trend_distribution = new float[3];
    setPosition();
  }
  
  // methods
  void setPosition()
  {
    switch(pos_x)
    {
      case LEFT:
        x = margin;
        break;
      case CENTER:
        x = x_mid - button_size / 2;
        break;
      case RIGHT:
        x = canvas_width - margin - button_size;
        break;
      default:
        x = margin;
    }
    
    switch(pos_y)
    {
       case TOP:
         y = margin;
         break;
       case CENTER:
         y = y_mid - 1.5 * button_size;
         break;
       case BOTTOM:
         y = canvas_height - margin - 3 * button_size;
         break;
       default:
         y = margin;
    }
  }
  
  void display(int mouse_x, int mouse_y)
  {
    float x1 = x;
    float x2 = x + button_size;
    float y1 = y;
    float y2 = y + button_size;
    float y3 = y + 2*button_size;
    float y4 = y + 3*button_size;
    
    float pad2 = 2 * padding;
    
    float button_mid = 0.5 * button_size;
    
    float dist_x1 = x2 - pad2;
    float dist_y1 = y1 + padding;
    float dist_w = padding;
    float dist_h = y4 - y1 - pad2;
    
    stroke(button_color);
    strokeWeight(1);
    fill(button_background);
    rect(x1,y1,button_size,button_size*3,padding,padding,padding,padding);
    
    // draw distribution
    noStroke();
    float dist_yb = dist_y1;
    
    for (int i = 0; i < 3; i++)
    {
      fill(r,g,b,a - i*64);
      float h = trend_distribution[i] * dist_h; 
      rect(dist_x1,dist_yb,dist_w,h);
      dist_yb += h;
    }
    
    stroke(button_color);
    strokeWeight(1);
    noFill();
    rect(dist_x1,dist_y1,dist_w,dist_h);
    
    // draw labels
    float label_x1 = x1 + padding;
    float label_y1 = y1 + button_mid;
    float label_y2 = label_y1 + button_size;
    float label_y3 = label_y2 + button_size;
    noStroke();
    fill(button_color);
    textFont(hud_font);
    textAlign(LEFT, CENTER);
    text(high, label_x1, label_y1);
    text(mid, label_x1, label_y2);
    text(low, label_x1, label_y3);
    
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y1 && mouse_y < y2) 
    { 
      hovered_object = upper_id;
    }
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y2 && mouse_y < y3) {
      hovered_object = mid_id;
    }
    if (mouse_x > x1 && mouse_x < x2 && mouse_y > y3 && mouse_y < y4)
    { 
      hovered_object = lower_id;
    }
    zoom_locked = false;
  }
  
  void setTrendDistribution(float[] trend_distribution_init)
  {
    trend_distribution = trend_distribution_init;
  }
}
void initConfiguration() 
{
  node_font = createFont(node_font_name, node_font_size);
  textFont(node_font);
  node_font_height = textAscent() + textDescent();
  
  version_font = createFont(version_font_name, version_font_size);
  timeline_font = createFont(timeline_font_name, timeline_font_size);
}

void initGraph()
{
  calcEdgeWeights(); 
}


void calcEdgeWeights()
{
  float edge_weight_max = 0;
  
  // find maximum edge weight
  for (int i = 0; i < edge_count; i++)
  {
    Edge edge = (Edge) edges.get(i);
    edge_weight_max = max(edge_weight_max, edge.weight);
  }
    
  // normalize edge weights
  for (int i = 0; i < edge_count; i++)
  {
    Edge edge = (Edge) edges.get(i);
    float edge_weight_normed = edge.weight / edge_weight_max;
    edge.setNormedWeight(edge_weight_normed);
  }
}

void initPhysics()
{
  ps.clear();
  tick_time = tick_time_base * 500 / edge_count;

  for (int i = 0; i < node_count; i++) {
    Node node = (Node) nodes.get(i);
    ps.makeParticle(1.0, node.x, node.y, 0.0);
  }
  
  // add pairwise repulsions
  for (int i = 0; i < node_count ; i++) {
    Particle p = ps.getParticle(i);
    for (int j = 0; j < i; j++) {
      Particle q = ps.getParticle(j);
      ps.makeAttraction(p,q,repulsion,0);
    }
  }
  
  // add springs for edges
  for (int i = 0; i < edge_count; i++) {
    Edge edge = (Edge) edges.get(i);
    int node_index1 = edge.from_index;
    int node_index2 = edge.to_index;
    Node node1 = (Node) nodes.get(node_index1);
    Node node2 = (Node) nodes.get(node_index2);
    float spring_distance = node1.radius + node2.radius;
    float spring_force = spring_constant * edge.weight_normed;
    Particle p = ps.getParticle(node_index1);
    Particle q = ps.getParticle(node_index2);
    ps.makeSpring(p,q,spring_force,spring_damping,spring_distance);
    ps.makeAttraction(p,q,edge.weight_normed,0);
  }
  
  physics_initialized = true;
}
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
void setTrendDirNodes(int set_direction, boolean set_filter)
{
  for (int i = 0; i < node_count; i++)
  {
    Node node = (Node) nodes.get(i);
    
    if (node.trenddirection != set_direction)
    {
      node.filter = set_filter;
    }
  }
}

void setTrendSizeNodes(int set_size, boolean set_filter)
{
  for (int i = 0; i < node_count; i++)
  {
    Node node = (Node) nodes.get(i);
    
    if (node.trendsize != set_size)
    {
      node.filter = set_filter;
    }
  }
}
import java.util.Iterator;

// Traer Physics 3.0
// Terms from Traer's download page, http://traer.cc/mainsite/physics/
//   LICENSE - Use this code for whatever you want, just send me a link jeff@traer.cc
//
// traer3a_01.pde 
//   From traer.physics - author: Jeff Traer
//     Attraction              Particle                     
//     EulerIntegrator         ParticleSystem  
//     Force                   RungeKuttaIntegrator         
//     Integrator              Spring
//     ModifiedEulerIntegrator Vector3D          
//
//   From traer.animator - author: Jeff Traer   
//     Smoother                                       
//     Smoother3D                  
//     Tickable     
//
//   New code - author: Carl Pearson
//     UniversalAttraction
//     Pulse
//

// 13 Dec 2010: Copied 3.0 src from http://traer.cc/mainsite/physics/ and ported to Processingjs,
//              added makeParticle2(), makeAttraction2(), replaceAttraction(), and removeParticle(int) -mrn (Mike Niemi)
//  9 Feb 2011: Fixed bug in Euler integrators where they divided by time instead of 
//              multiplying by it in the update steps,
//              eliminated the Vector3D class (converting the code to use the native PVector class),
//              did some code compaction in the RK solver,
//              added a couple convenience classes, UniversalAttraction and Pulse, simplifying 
//              the Pendulums sample (renamed to dynamics.pde) considerably. -cap (Carl Pearson)
// 24 Mar 2011: Changed the switch statement in ParticleSystem.setIntegrator() to an if-then-else
//              to avoid an apparent bug introduced in Processing-1.1.0.js where the 
//              variable, RUNGE_KUTTA, was not visible inside the switch statement.
//              Changed ModifiedEulerIntegrator to use the documented PVector interfaces to work with pjs. -mrn
//  8 Jan 2013: Added "import java.util.Iterator" so it will now work in the Processing 2.0 IDE,
//              just flip the mode buttion in the upper right corner of the IDE between "JAVA" to "JAVASCRIPT".

//===========================================================================================
//                                      Attraction
//===========================================================================================
// attract positive repel negative
//package traer.physics;
public class Attraction implements Force
{
  Particle one;
  Particle b;
  float k;
  boolean on = true;
  float distanceMin;
  float distanceMinSquared;
	
  public Attraction( Particle a, Particle b, float k, float distanceMin )
  {
    this.one = a;
    this.b = b;
    this.k = k;
    this.distanceMin = distanceMin;
    this.distanceMinSquared = distanceMin*distanceMin;
  }

  protected void        setA( Particle p )            { one = p; }
  protected void        setB( Particle p )            { b = p; }
  public final float    getMinimumDistance()          { return distanceMin; }
  public final void     setMinimumDistance( float d ) { distanceMin = d; distanceMinSquared = d*d; }
  public final void     turnOff()                     { on = false; }
  public final void     turnOn()	              { on = true;  }
  public final void     setStrength( float k )        { this.k = k; }
  public final Particle getOneEnd()                   { return one; }
  public final Particle getTheOtherEnd()              { return b; }
  
  public void apply() 
  { if ( on && ( one.isFree() || b.isFree() ) )
      {
        PVector a2b = PVector.sub(one.position, b.position, new PVector());
        float a2bDistanceSquared = a2b.dot(a2b);

	if ( a2bDistanceSquared < distanceMinSquared )
	   a2bDistanceSquared = distanceMinSquared;

	float force = k * one.mass0 * b.mass0 / (a2bDistanceSquared * (float)Math.sqrt(a2bDistanceSquared));

        a2b.mult( force );

	// apply
        if ( b.isFree() )
	   b.force.add( a2b );	
        if ( one.isFree() ) {
           a2b.mult(-1f);
	   one.force.add( a2b );
        }
      }
  }

  public final float   getStrength() { return k; }
  public final boolean isOn()        { return on; }
  public final boolean isOff()       { return !on; }
} // Attraction

//===========================================================================================
//                                    UniversalAttraction
//===========================================================================================
// attract positive repel negative
public class UniversalAttraction implements Force {
  public UniversalAttraction( float k, float distanceMin, ArrayList targetList )
  {
    this.k = k;
    this.distanceMin = distanceMin;
    this.distanceMinSquared = distanceMin*distanceMin;
    this.targetList = targetList;
  }
  
  float k;
  boolean on = true;
  float distanceMin;
  float distanceMinSquared;
  ArrayList targetList;
  public final float    getMinimumDistance()          { return distanceMin; }
  public final void     setMinimumDistance( float d ) { distanceMin = d; distanceMinSquared = d*d; }
  public final void     turnOff()                     { on = false; }
  public final void     turnOn()	              { on = true;  }
  public final void     setStrength( float k )        { this.k = k; }
  public final float   getStrength() { return k; }
  public final boolean isOn()        { return on; }
  public final boolean isOff()       { return !on; }

  
  public void apply() 
  { 
    if ( on ) {
        for (int i=0; i < targetList.size(); i++ ) {
          for (int j=i+1; j < targetList.size(); j++) {
            Particle a = (Particle)targetList.get(i);
            Particle b = (Particle)targetList.get(j);
            if ( a.isFree() || b.isFree() ) {
              PVector a2b = PVector.sub(a.position, b.position, new PVector());
              float a2bDistanceSquared = a2b.dot(a2b);
              if ( a2bDistanceSquared < distanceMinSquared )
              a2bDistanceSquared = distanceMinSquared;
              float force = k * a.mass0 * b.mass0 / (a2bDistanceSquared * (float)Math.sqrt(a2bDistanceSquared));
              a2b.mult( force );

              if ( b.isFree() ) b.force.add( a2b );	
              if ( a.isFree() ) {
                 a2b.mult(-1f);
      	         a.force.add( a2b );
              }
            }
          }
        }
    }
  }
} //UniversalAttraction

//===========================================================================================
//                                    Pulse
//===========================================================================================
public class Pulse implements Force {
  public Pulse( float k, float distanceMin, PVector origin, float lifetime, ArrayList targetList )
  {
    this.k = k;
    this.distanceMin = distanceMin;
    this.distanceMinSquared = distanceMin*distanceMin;
    this.origin = origin;
    this.targetList = targetList;
    this.lifetime = lifetime;
  }
  
  float k;
  boolean on = true;
  float distanceMin;
  float distanceMinSquared;
  float lifetime;
  PVector origin;
  ArrayList targetList;
  
  public final void     turnOff() { on = false; }
  public final void     turnOn()  { on = true;  }
  public final boolean  isOn()    { return on; }
  public final boolean  isOff()   { return !on; }
  public final boolean  tick( float time ) { 
    lifetime-=time; 
    if (lifetime <= 0f) turnOff(); 
    return on;
  }
  
  public void apply() {
    if (on) {
      PVector holder = new PVector();
      int count = 0;
      for (Iterator i = targetList.iterator(); i.hasNext(); ) {
        Particle p = (Particle)i.next();
        if ( p.isFree() ) {
          holder.set( p.position.x, p.position.y, p.position.z );
          holder.sub( origin );
          float distanceSquared = holder.dot(holder);
          if (distanceSquared < distanceMinSquared) distanceSquared = distanceMinSquared;
          holder.mult(k / (distanceSquared * (float)Math.sqrt(distanceSquared)) );
          p.force.add( holder );
        }
      }
    }
  }
}//Pulse

//===========================================================================================
//                                      EulerIntegrator
//===========================================================================================
//package traer.physics;
public class EulerIntegrator implements Integrator
{
  ParticleSystem s;
	
  public EulerIntegrator( ParticleSystem s ) { this.s = s; }
  public void step( float t )
  {
    s.clearForces();
    s.applyForces();
		
    for ( Iterator i = s.particles.iterator(); i.hasNext(); )
      {
	Particle p = (Particle)i.next();
	if ( p.isFree() )
          {
	    p.velocity.add( PVector.mult(p.force, t/p.mass0) );
	    p.position.add( PVector.mult(p.velocity, t) );
	  }
      }
  }
} // EulerIntegrator

//===========================================================================================
//                                          Force
//===========================================================================================
// May 29, 2005
//package traer.physics;
// @author jeffrey traer bernstein
public interface Force
{
  public void    turnOn();
  public void    turnOff();
  public boolean isOn();
  public boolean isOff();
  public void    apply();
} // Force

//===========================================================================================
//                                      Integrator
//===========================================================================================
//package traer.physics;
public interface Integrator 
{
  public void step( float t );
} // Integrator

//===========================================================================================
//                                    ModifiedEulerIntegrator
//===========================================================================================
//package traer.physics;
public class ModifiedEulerIntegrator implements Integrator
{
  ParticleSystem s;
  public ModifiedEulerIntegrator( ParticleSystem s ) { this.s = s; }
  public void step( float t )
  {
    s.clearForces();
    s.applyForces();
		
    float halft = 0.5f*t;
//    float halftt = 0.5f*t*t;
    PVector a = new PVector();
    PVector holder = new PVector();
    
    for ( int i = 0; i < s.numberOfParticles(); i++ )
      {
	Particle p = s.getParticle( i );
	if ( p.isFree() )
	  { // The following "was"s was the code in traer3a which appears to work in the IDE but not pjs
            // I couln't find the interface Carl used in the PVector documentation and have converted
            // the code to the documented interface. -mrn
            
            // was in traer3a: PVector.div(p.force, p.mass0, a);
            a.set(p.force.x, p.force.y, p.force.z);
            a.div(p.mass0);

	    //was in traer3a: p.position.add( PVector.mult(p.velocity, t, holder) );
            holder.set(p.velocity.x, p.velocity.y, p.velocity.z);
            holder.mult(t);
            p.position.add(holder);

	    //was in traer3a: p.position.add( PVector.mult(a, halft, a) );
            holder.set(a.x, a.y, a.z);
            holder.mult(halft); // Note that the original Traer code used halftt ( 0.5*t*t ) here -mrn
            p.position.add(holder);

            //was in traer3a: p.velocity.add( PVector.mult(a, t, a) );
            holder.set(a.x, a.y, a.z);
            holder.mult(t);
            p.velocity.add(a);
	  }
      }
  }
} // ModifiedEulerIntegrator

//===========================================================================================
//                                         Particle
//===========================================================================================
//package traer.physics;
public class Particle
{
  PVector position = new PVector();
  PVector velocity = new PVector();
  PVector force = new PVector();
  protected float    mass0;
  protected float    age0 = 0;
  protected boolean  dead0 = false;
  boolean            fixed0 = false;
	
  public Particle( float m )
  { mass0 = m; }
  
  // @see traer.physics.AbstractParticle#distanceTo(traer.physics.Particle)
  public final float distanceTo( Particle p ) { return this.position.dist( p.position ); }
  
  // @see traer.physics.AbstractParticle#makeFixed()
  public final Particle makeFixed() {
    fixed0 = true;
    velocity.set(0f,0f,0f);
    force.set(0f, 0f, 0f);
    return this;
  }
  
  // @see traer.physics.AbstractParticle#makeFree()
  public final Particle makeFree() {
    fixed0 = false;
    return this;
  }

  // @see traer.physics.AbstractParticle#isFixed()
  public final boolean isFixed() { return fixed0; }
  
  // @see traer.physics.AbstractParticle#isFree()
  public final boolean isFree() { return !fixed0; }
    
  // @see traer.physics.AbstractParticle#mass()
  public final float mass() { return mass0; }
  
  // @see traer.physics.AbstractParticle#setMass(float)
  public final void setMass( float m ) { mass0 = m; }
    
  // @see traer.physics.AbstractParticle#age()
  public final float age() { return age0; }
  
  protected void reset()
  {
    age0 = 0;
    dead0 = false;
    position.set(0f,0f,0f);
    velocity.set(0f,0f,0f);
    force.set(0f,0f,0f);
    mass0 = 1f;
  }
} // Particle

//===========================================================================================
//                                      ParticleSystem
//===========================================================================================
// May 29, 2005
//package traer.physics;
//import java.util.*;
public class ParticleSystem
{
  public static final int RUNGE_KUTTA = 0;
  public static final int MODIFIED_EULER = 1;
  protected static final float DEFAULT_GRAVITY = 0;
  protected static final float DEFAULT_DRAG = 0.001f;	
  ArrayList  particles = new ArrayList();
  ArrayList  springs = new ArrayList();
  ArrayList  attractions = new ArrayList();
  ArrayList  customForces = new ArrayList();
  ArrayList  pulses = new ArrayList();
  Integrator integrator;
  PVector    gravity = new PVector();
  float      drag;
  boolean    hasDeadParticles = false;
  
  public final void setIntegrator( int which )
  {
    //switch ( which )
    //{
    //  case RUNGE_KUTTA:
    //	  this.integrator = new RungeKuttaIntegrator( this );
    //	  break;
    //  case MODIFIED_EULER:
    //	  this.integrator = new ModifiedEulerIntegrator( this );
    //	  break;
    //}
    if ( which==RUNGE_KUTTA )
       this.integrator = new RungeKuttaIntegrator( this );
    else
    if ( which==MODIFIED_EULER )
       this.integrator = new ModifiedEulerIntegrator( this );
  }
  
  public final void setGravity( float x, float y, float z ) { gravity.set( x, y, z ); }

  // default down gravity
  public final void     setGravity( float g ) { gravity.set( 0, g, 0 ); }
  public final void     setDrag( float d )    { drag = d; }
  public final void     tick()                { tick( 1 ); }
  public final void     tick( float t )       {
    integrator.step( t );
    for (int i = 0; i<pulses.size(); ) {
    	Pulse p = (Pulse)pulses.get(i);
    	p.tick(t);
    	if (p.isOn()) { i++; } else { pulses.remove(i); }
    }
    if (pulses.size()!=0) for (Iterator i = pulses.iterator(); i.hasNext(); ) {
      Pulse p = (Pulse)(i.next());
      p.tick( t );
      if (!p.isOn()) i.remove();
    }
  }
  
  public final Particle makeParticle( float mass, float x, float y, float z )
  {
    Particle p = new Particle( mass );
    p.position.set( x, y, z );
    particles.add( p );
    return p;
  }
  
  public final int makeParticle2( float mass, float x, float y, float z )
  { // mrn
    makeParticle(mass, x, y, z);
    return particles.size()-1;
  }
  
  public final Particle makeParticle() { return makeParticle( 1.0f, 0f, 0f, 0f ); }
  
  public final Spring   makeSpring( Particle a, Particle b, float ks, float d, float r )
  {
    Spring s = new Spring( a, b, ks, d, r );
    springs.add( s );
    return s;
  }
  
  public final Attraction makeAttraction( Particle first, Particle b, float k, float minDistance )
  {
    Attraction m = new Attraction( first, b, k, minDistance );
    attractions.add( m );
    return m;
  }
  
  public final int makeAttraction2( Particle a, Particle b, float k, float minDistance )
  { // mrn
    makeAttraction(a, b, k, minDistance);
    return attractions.size()-1; // return the index 
  }

  public final void replaceAttraction( int i, Attraction m )
  { // mrn
    attractions.set( i, m );
  }  

  public final void addPulse(Pulse pu){ pulses.add(pu); }

  public final void clear()
  {
    particles.clear();
    springs.clear();
    attractions.clear();
    customForces.clear();
    pulses.clear();
  }
  
  public ParticleSystem( float g, float somedrag )
  {
    setGravity( 0f, g, 0f );
    drag = somedrag;
    integrator = new RungeKuttaIntegrator( this );
  }
  
  public ParticleSystem( float gx, float gy, float gz, float somedrag )
  {
    setGravity( gx, gy, gz );
    drag = somedrag;
    integrator = new RungeKuttaIntegrator( this );
  }
  
  public ParticleSystem()
  {
  	setGravity( 0f, ParticleSystem.DEFAULT_GRAVITY, 0f );
    drag = ParticleSystem.DEFAULT_DRAG;
    integrator = new RungeKuttaIntegrator( this );
  }
  
  protected final void applyForces()
  {
    if ( gravity.mag() != 0f )
      {
        for ( Iterator i = particles.iterator(); i.hasNext(); )
	  {
            Particle p = (Particle)i.next();
            if (p.isFree()) p.force.add( gravity );
	  }
      }
      
    PVector target = new PVector();
    for ( Iterator i = particles.iterator(); i.hasNext(); )
      {
        Particle p = (Particle)i.next();
        if (p.isFree()) p.force.add( PVector.mult(p.velocity, -drag, target) );

      }
      
    applyAll(springs);
    applyAll(attractions);
    applyAll(customForces);
    applyAll(pulses);
      
    
  }
  
  private void applyAll(ArrayList forces) {
    if( forces.size()!=0 ) for ( Iterator i = forces.iterator(); i.hasNext(); ) ((Force)i.next()).apply();
  }
  
  protected final void clearForces()
  {
    for (Iterator i = particles.iterator(); i.hasNext(); ) ((Particle)i.next()).force.set(0f, 0f, 0f);
  }
  
  public final int        numberOfParticles()              { return particles.size(); }
  public final int        numberOfSprings()                { return springs.size(); }
  public final int        numberOfAttractions()            { return attractions.size(); }
  public final Particle   getParticle( int i )             { return (Particle)particles.get( i ); }
  public final Spring     getSpring( int i )               { return (Spring)springs.get( i ); }
  public final Attraction getAttraction( int i )           { return (Attraction)attractions.get( i ); }
  public final void       addCustomForce( Force f )        { customForces.add( f ); }
  public final int        numberOfCustomForces()           { return customForces.size(); }
  public final Force      getCustomForce( int i )          { return (Force)customForces.get( i ); }
  public final Force      removeCustomForce( int i )       { return (Force)customForces.remove( i ); }
  public final void       removeParticle( int i )          { particles.remove( i ); } //mrn
  public final void       removeParticle( Particle p )     { particles.remove( p ); }
  public final Spring     removeSpring( int i )            { return (Spring)springs.remove( i ); }
  public final Attraction removeAttraction( int i )        { return (Attraction)attractions.remove( i ); }
  public final void       removeAttraction( Attraction s ) { attractions.remove( s ); }
  public final void       removeSpring( Spring a )         { springs.remove( a ); }
  public final void       removeCustomForce( Force f )     { customForces.remove( f ); }
} // ParticleSystem

//===========================================================================================
//                                      RungeKuttaIntegrator
//===========================================================================================
//package traer.physics;
//import java.util.*;
public class RungeKuttaIntegrator implements Integrator
{	
  ArrayList originalPositions = new ArrayList();
  ArrayList originalVelocities = new ArrayList();
  ArrayList k1Forces = new ArrayList();
  ArrayList k1Velocities = new ArrayList();
  ArrayList k2Forces = new ArrayList();
  ArrayList k2Velocities = new ArrayList();
  ArrayList k3Forces = new ArrayList();
  ArrayList k3Velocities = new ArrayList();
  ArrayList k4Forces = new ArrayList();
  ArrayList k4Velocities = new ArrayList();
  ParticleSystem s;

  public RungeKuttaIntegrator( ParticleSystem s ) { this.s = s;	}
  
  final void allocateParticles()
  {
    while( s.particles.size() > originalPositions.size() ) {
        originalPositions.add( new PVector() );
		originalVelocities.add( new PVector() );
		k1Forces.add( new PVector() );
		k1Velocities.add( new PVector() );
		k2Forces.add( new PVector() );
		k2Velocities.add( new PVector() );
		k3Forces.add( new PVector() );
		k3Velocities.add( new PVector() );
		k4Forces.add( new PVector() );
		k4Velocities.add( new PVector() );
    }
  }
  
  private final void setIntermediate(ArrayList forces, ArrayList velocities) {
    s.applyForces();
    for ( int i = 0; i < s.particles.size(); ++i )
      {
	Particle p = (Particle)s.particles.get( i );
	if ( p.isFree() )
	  {
	    ((PVector)forces.get( i )).set( p.force.x, p.force.y, p.force.z );
	    ((PVector)velocities.get( i )).set( p.velocity.x, p.velocity.y, p.velocity.z );
            p.force.set(0f,0f,0f);
	  }
      }
  }
  
  private final void updateIntermediate(ArrayList forces, ArrayList velocities, float multiplier) {
    PVector holder = new PVector();
    
    for ( int i = 0; i < s.particles.size(); ++i )
      {
	Particle p = (Particle)s.particles.get( i );
	if ( p.isFree() )
	  {
	  		PVector op = (PVector)(originalPositions.get( i ));
            p.position.set(op.x, op.y, op.z);
            p.position.add(PVector.mult((PVector)(velocities.get( i )), multiplier, holder));		
			PVector ov = (PVector)(originalVelocities.get( i ));
            p.velocity.set(ov.x, ov.y, ov.z);
            p.velocity.add(PVector.mult((PVector)(forces.get( i )), multiplier/p.mass0, holder));	
          }
       }
  }
  
  private final void initialize() {
    for ( int i = 0; i < s.particles.size(); ++i )
      {
	Particle p = (Particle)(s.particles.get( i ));
	if ( p.isFree() )
	  {		
	    ((PVector)(originalPositions.get( i ))).set( p.position.x, p.position.y, p.position.z );
	    ((PVector)(originalVelocities.get( i ))).set( p.velocity.x, p.velocity.y, p.velocity.z );
	  }
	p.force.set(0f,0f,0f);	// and clear the forces
      }
  }
  
  public final void step( float deltaT )
  {	
    allocateParticles();
    initialize();       
    setIntermediate(k1Forces, k1Velocities);
    updateIntermediate(k1Forces, k1Velocities, 0.5f*deltaT );
    setIntermediate(k2Forces, k2Velocities);
    updateIntermediate(k2Forces, k2Velocities, 0.5f*deltaT );
    setIntermediate(k3Forces, k3Velocities);
    updateIntermediate(k3Forces, k3Velocities, deltaT );
    setIntermediate(k4Forces, k4Velocities);
		
    /////////////////////////////////////////////////////////////
    // put them all together and what do you get?
    for ( int i = 0; i < s.particles.size(); ++i )
      {
	Particle p = (Particle)s.particles.get( i );
	p.age0 += deltaT;
	if ( p.isFree() )
	  {
	    // update position
	    PVector holder = (PVector)(k2Velocities.get( i ));
            holder.add((PVector)k3Velocities.get( i ));
            holder.mult(2.0f);
            holder.add((PVector)k1Velocities.get( i ));
            holder.add((PVector)k4Velocities.get( i ));
            holder.mult(deltaT / 6.0f);
            holder.add((PVector)originalPositions.get( i ));
            p.position.set(holder.x, holder.y, holder.z);
            							
	    // update velocity
	    holder = (PVector)k2Forces.get( i );
	    holder.add((PVector)k3Forces.get( i ));
            holder.mult(2.0f);
            holder.add((PVector)k1Forces.get( i ));
            holder.add((PVector)k4Forces.get( i ));
            holder.mult(deltaT / (6.0f * p.mass0 ));
            holder.add((PVector)originalVelocities.get( i ));
	    p.velocity.set(holder.x, holder.y, holder.z);
	  }
      }
  }
} // RungeKuttaIntegrator

//===========================================================================================
//                                         Spring
//===========================================================================================
// May 29, 2005
//package traer.physics;
// @author jeffrey traer bernstein
public class Spring implements Force
{
  float springConstant0;
  float damping0;
  float restLength0;
  Particle one, b;
  boolean on = true;
    
  public Spring( Particle A, Particle B, float ks, float d, float r )
  {
    springConstant0 = ks;
    damping0 = d;
    restLength0 = r;
    one = A;
    b = B;
  }
  
  public final void     turnOff()                { on = false; }
  public final void     turnOn()                 { on = true; }
  public final boolean  isOn()                   { return on; }
  public final boolean  isOff()                  { return !on; }
  public final Particle getOneEnd()              { return one; }
  public final Particle getTheOtherEnd()         { return b; }
  public final float    currentLength()          { return one.distanceTo( b ); }
  public final float    restLength()             { return restLength0; }
  public final float    strength()               { return springConstant0; }
  public final void     setStrength( float ks )  { springConstant0 = ks; }
  public final float    damping()                { return damping0; }
  public final void     setDamping( float d )    { damping0 = d; }
  public final void     setRestLength( float l ) { restLength0 = l; }
  
  public final void apply()
  {	
    if ( on && ( one.isFree() || b.isFree() ) )
      {
        PVector a2b = PVector.sub(one.position, b.position, new PVector());

        float a2bDistance = a2b.mag();	
	
	if (a2bDistance!=0f) {
          a2b.div(a2bDistance);
        }

	// spring force is proportional to how much it stretched 
	float springForce = -( a2bDistance - restLength0 ) * springConstant0; 
	
        PVector vDamping = PVector.sub(one.velocity, b.velocity, new PVector());
        
        float dampingForce = -damping0 * a2b.dot(vDamping);
		               				
	// forceB is same as forceA in opposite direction
	float r = springForce + dampingForce;
		
	a2b.mult(r);
	    
	if ( one.isFree() )
	   one.force.add( a2b );
	if ( b.isFree() )
	   b.force.add( PVector.mult(a2b, -1, a2b) );
      }
  }
  protected void setA( Particle p ) { one = p; }
  protected void setB( Particle p ) { b = p; }
} // Spring

//===========================================================================================
//                                       Smoother
//===========================================================================================
//package traer.animator;
public class Smoother implements Tickable
{
  public Smoother(float smoothness)                     { setSmoothness(smoothness);  setValue(0.0F); }
  public Smoother(float smoothness, float start)        { setSmoothness(smoothness); setValue(start); }
  public final void     setSmoothness(float smoothness) { a = -smoothness; gain = 1.0F + a; }
  public final void     setTarget(float target)         { input = target; }
  public void           setValue(float x)               { input = x; lastOutput = x; }
  public final float    getTarget()                     { return input; }
  public final void     tick()                          { lastOutput = gain * input - a * lastOutput; }
  public final float    getValue()                      { return lastOutput; }
  public float a, gain, lastOutput, input;
} // Smoother

//===========================================================================================
//                                      Smoother3D
//===========================================================================================
//package traer.animator;
public class Smoother3D implements Tickable
{
  public Smoother3D(float smoothness)
  {
    x0 = new Smoother(smoothness);
    y0 = new Smoother(smoothness);
    z0 = new Smoother(smoothness);
  }
  public Smoother3D(float initialX, float initialY, float initialZ, float smoothness)
  {
    x0 = new Smoother(smoothness, initialX);
    y0 = new Smoother(smoothness, initialY);
    z0 = new Smoother(smoothness, initialZ);
  }
  public final void setXTarget(float X) { x0.setTarget(X); }
  public final void setYTarget(float X) { y0.setTarget(X); }
  public final void setZTarget(float X) { z0.setTarget(X); }
  public final float getXTarget()       { return x0.getTarget(); }
  public final float getYTarget()       { return y0.getTarget(); }
  public final float getZTarget()       { return z0.getTarget(); }
  public final void setTarget(float X, float Y, float Z)
  {
    x0.setTarget(X);
    y0.setTarget(Y);
    z0.setTarget(Z);
  }
  public final void setValue(float X, float Y, float Z)
  {
    x0.setValue(X);
    y0.setValue(Y);
    z0.setValue(Z);
  }
  public final void setX(float X)  { x0.setValue(X); }
  public final void setY(float Y)  { y0.setValue(Y); }
  public final void setZ(float Z)  { z0.setValue(Z); }
  public final void setSmoothness(float smoothness)
  {
    x0.setSmoothness(smoothness);
    y0.setSmoothness(smoothness);
    z0.setSmoothness(smoothness);
  }
  public final void tick()         { x0.tick(); y0.tick(); z0.tick(); }
  public final float x()           { return x0.getValue(); }
  public final float y()           { return y0.getValue(); }
  public final float z()           { return z0.getValue(); }
  public Smoother x0, y0, z0;
} // Smoother3D

//===========================================================================================
//                                      Tickable
//===========================================================================================
//package traer.animator;
public interface Tickable
{
  public abstract void tick();
  public abstract void setSmoothness(float f);
} // Tickable
