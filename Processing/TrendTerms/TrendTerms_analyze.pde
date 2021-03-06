/*
  Project:     TrendTerms
  Name:        TrendTerms_analyze.pde
  Purpose:     Method for analyzing timelines of terms.
  
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2016-07-15
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