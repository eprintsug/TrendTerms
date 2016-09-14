/*
  Project:     TrendTerms
  Name:        TrendTerms_events.pde
  Purpose:     Methods for key and mouse events.
  
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