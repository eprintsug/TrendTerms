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