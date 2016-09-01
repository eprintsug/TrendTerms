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