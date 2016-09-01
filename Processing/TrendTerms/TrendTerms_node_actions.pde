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