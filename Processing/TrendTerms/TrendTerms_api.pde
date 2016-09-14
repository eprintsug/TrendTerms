/*
  Project:     TrendTerms
  Name:        TrendTerms_api.pde
  Purpose:     API methods for resizing and filtering.
  
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