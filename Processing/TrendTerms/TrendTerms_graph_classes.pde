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