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