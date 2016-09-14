/*
  Project:     TrendTerms
  Name:        TrendTerms_init.pde
  Purpose:     Methods for initialization of the graph and the node physics.
  
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