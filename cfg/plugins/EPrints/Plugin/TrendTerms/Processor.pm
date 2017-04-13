######################################################################
#
#  TrendTerms::Processor plugin - identify trend terms in an eprint
#
######################################################################
#
#  Copyright 2016 University of Zurich. All Rights Reserved.
#
#  Martin Brändle
#  Zentrale Informatik
#  Universität Zürich
#  Stampfenbachstr. 73
#  CH-8006 Zürich
#
#  The plug-ins are free software; you can redistribute them and/or modify
#  them under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The plug-ins are distributed in the hope that they will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with EPrints 3; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
######################################################################


=head1 NAME

EPrints::Plugin::TrendTerms::Processor - identify trend terms in an eprint

=head1 DESCRIPTION

This plugin identifies relevant trend terms of an abstract (or title) in an eprint.
From this set of terms, it also tries to find related terms in related documents.
The whole set is written as a graph of nodes and edges to an XML file that can be 
visualised.

=head1 METHODS

=over 4

=item $plugin = EPrints::Plugin::TrendTerms::Processor->new( %params )

Creates a new TrendTerms Processor plugin.

=item generate_trendterms

Identifies the trend terms for a given eprint

=back

=cut

package EPrints::Plugin::TrendTerms::Processor;

use strict;
use warnings;

use utf8;
use Search::Xapian;
use XML::LibXML;

use base 'EPrints::Plugin';

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "TrendTerms::Processor";
	$self->{visible} = "all";

	return $self;
}

#
# The basic idea is to get the terms and their frequency from the Xapian
# database index
#
# To avoid processing too large arrays, we need to go in several passes
# 1. Get the terms of the current document and their relations
# 2. For all terms, get the related documents and their terms with relations
# 3. find minimal and maximal edgecounts and assign colors 
# 4. For all terms, determine their timelines
# 5. calculate initial positions on graph (distribute nodes according to their edgecount)
# 6. Write node and edge files 
#
# Passes 1 and 2 are subdivided into the following steps
# .1 identify the terms in abstract, get wdf, assign id
# .2 get estimated document frequencies for terms --> idf
# .3 calculate idf * wdf
# .4 get terms that have idf * wdf > threshold
# .5 get positions of filtered terms in abstract  (or in Xapian document)
# .6 for all combinations, aggregate weights and store in an edge
# 



sub generate_trendterms
{
	my ($plugin) = @_;
	
	my $session = $plugin->{session};
	my $eprint = $plugin->{eprint};
	my $param = $plugin->{param};
	
	my $termname2id;
		
	return unless ($eprint->is_set( "abstract" ) );
	
	my $eprintid = $eprint->get_value( "eprintid" );
	my $terms_found;
	my $found_id;
	my $subjectid;
	my $terms;
	my $edges;
	my $term_count = 0;
	my $edge_count = 0;
	my $year_min;
	my $year_max;

	my $path = $session->config( "variables_path" ) . "/xapian";
	my $xapian = Search::Xapian::Database->new( $path );
	$xapian->reopen();
	
	my $doccount = $xapian->get_doccount;
		
	my $query = Search::Xapian::Query->new(
		Search::Xapian::OP_AND(),
		Search::Xapian::Query->new( 'eprintid:' . $eprintid )
	);
	
	my $enq = $xapian->enquire( $query );
	
	my @matches = $enq->matches(0, $doccount);

	#
	# .1-.4 identify terms, get wdf, assign id
	# .5 get positions of terms
	#
	
	foreach my $match (@matches)
	{
		($terms_found, $found_id) = get_terms($match, 'abstract:', '');
		$subjectid = get_subject( $match );
	
		#
		# .2-.4 get idfs, wdf*idf, and terms with wdf*idf within threshold
		#
		foreach my $termid (keys %$terms_found)
		{
			my $termname = $terms_found->{$termid}->{term};
			my $field = $terms_found->{$termid}->{field};
			my $term_doccount = $xapian->get_termfreq( $field . $termname );
			
			my $idf = $doccount / $term_doccount;
			my $wdfidf =  $terms_found->{$termid}->{wdf} * $idf;
			
			if ( $wdfidf > $param->{wdfidf_lower} && $wdfidf < $param->{wdfidf_upper} )
			{
				$terms->{$term_count}->{term} = $termname;
				$terms->{$term_count}->{field} = $field;
				$terms->{$term_count}->{wdf} = $terms_found->{$termid}->{wdf};
				$terms->{$term_count}->{wdfidf} = $wdfidf;
				$terms->{$term_count}->{doccount} = $term_doccount;
				$terms->{$term_count}->{positions} = $terms_found->{$termid}->{positions};
				$terms->{$term_count}->{first_position} = $terms_found->{$termid}->{first_position};
				$terms->{$term_count}->{colorref} = 0;
				$terms->{$term_count}->{edgecount} = 0;
				$terms->{$term_count}->{x} = 0.0;
				$terms->{$term_count}->{y} = 0.0;
				
				$termname2id->{$termname} = $term_count;
				
				$term_count++;
			}
		}
		
		#
		# .6 aggregate weights and store in an edge
   		#
		($terms, $edges) = get_edges( $terms, $edge_count );
		
	}
	$plugin->{termname2id} = $termname2id;

	#
	# 2. get the terms of the related documents
	#
	($terms, $edges) = get_related_documents( $plugin, $terms, $term_count, $edges, $edge_count, $eprintid, $subjectid );
	
	#
	# 3. find minimal and maximal edgecounts and assign colors 
	#
	$terms = assign_colors( $terms, $param );
	
	#
	# 4. determine the timeline of each term
	#
	($terms, $year_min, $year_max) = get_timelines( $plugin, $terms );
	
	$param->{year_min} = $year_min;
	$param->{year_max} = $year_max;
   
	#
	# 4.1 normalize the timelines (max value = 1.0)
	#
	$terms = normalize_timelines( $terms );
	
	# 5. calculate the start positions on the graph
	$terms = graph_positions( $terms, $param );
   
	#
	# 6. and finally save the graph
	#
	save_graph($plugin, $eprintid, $terms, $edges);
	
	return;
}


sub get_terms
{
	my ($match, $field, $find_term) = @_;
	
	my $foundterms;
	my $found_id = -1;
	
	my $termid = 0;

	my $stopper = Search::Xapian::SimpleStopper->new( get_stopwords() );
	
	my $doc = $match->get_document();
	my $termlist_iterator = $doc->termlist_begin;
	
	$termlist_iterator->skip_to( $field );
	  
	while ( $termlist_iterator ne $doc->termlist_end )
	{
		my $term = $termlist_iterator->get_termname();
	
		if ($term =~ /^$field/)
		{
			$term =~ s/^$field//;
			
			# filter stop words and numbers
			if ( !$stopper->stop_word( $term ) && $term !~ /[-+]?[0-9]*\.?[0-9]/ )
			{
				$found_id = $termid if ($term eq $find_term);
				$foundterms->{$termid}->{term} = $term;
				$foundterms->{$termid}->{field} = $field;
				$foundterms->{$termid}->{wdf} = $termlist_iterator->get_wdf();
				my @positions = get_positions($termlist_iterator);
				$foundterms->{$termid}->{positions} = \@positions;
				$foundterms->{$termid}->{first_position} = $positions[0];
				$termid++;
			}
		}
		$termlist_iterator++;
	}
	
	return ($foundterms, $found_id); 
}

sub get_positions
{
	my ($termlist_iterator ) = @_;
	
	my @positions;
	
	my $position_iterator = $termlist_iterator->positionlist_begin;
	
	while ( $position_iterator ne $termlist_iterator->positionlist_end )
	{
		my $position = $position_iterator->get_termpos();
		push @positions, $position;
		$position_iterator++;
	}
	
	return @positions;
}

sub get_subject
{
	my ($match) = @_;
	
	my $subjectid = '';
	my $doc = $match->get_document();
	my $termlist_iterator = $doc->termlist_begin;
	
	while ( $termlist_iterator ne $doc->termlist_end )
	{
		my $subject = $termlist_iterator->get_termname();

		($subjectid = $subject) =~ s/subjects:// if ($subject =~ /subjects\:/);
		$termlist_iterator++;
	}
	
	return $subjectid;
}

sub get_related_documents
{
	my ($plugin, $terms, $term_count, $edges, $edge_count, $eprintid, $subjectid) = @_;
	
	my $param = $plugin->{param};
	my $session = $plugin->{session};
	my $termname2id = $plugin->{termname2id}; 
	
	my $found_id;
	my $related_distance = $param->{related_distance};
	
	my $path = $session->config( "variables_path" ) . "/xapian";
	my $xapian = Search::Xapian::Database->new( $path );
	
	$xapian->reopen();
	my $qp = Search::Xapian::QueryParser->new( $xapian );
	
	$qp->set_default_op( Search::Xapian::OP_AND() );
	$qp->add_prefix( "abstract", "abstract:");
	$qp->add_prefix( "eprintid", "eprintid:");
	$qp->add_prefix( "subjects", "subjects:");
	
	#
	# Pass 1 - build up list of related terms
	#
	my $related_terms = {};
	
	foreach my $termid (keys %$terms)
	{
		my $doccount = $terms->{$termid}->{doccount};
		my $wdfidf_query = $terms->{$termid}->{wdfidf};
		my $first_pos = $terms->{$termid}->{first_position};
		
		# query only if the term occurs in several documents
		if ($doccount > 1)
		{
			my $queryfield = $terms->{$termid}->{field};
			my $queryterm = $terms->{$termid}->{term};
			
			my $enq = $xapian->enquire( $qp->parse_query ( $queryfield . $queryterm . ' AND subjects:' . $subjectid . ' NOT eprintid:' . $eprintid ));
	
			my @matches = $enq->matches(0, $doccount);
			my $related_doccount = scalar(@matches);
			
			foreach my $match (@matches)
			{
				my $terms_found;
				($terms_found, $found_id) = get_terms($match, 'abstract:', $queryterm);
			
				foreach my $relid (keys %$terms_found)
				{
					my $termname = $terms_found->{$relid}->{term};
					
					#
					# process term only if it is not in the inner set
					#
					if (!defined $termname2id->{$termname})
					{
						my $field = $terms_found->{$relid}->{field};
						my $term_doccount = $xapian->get_termfreq( $field . $termname );
						
						my $idf = $doccount / $term_doccount;
						my $wdf = $terms_found->{$relid}->{wdf};
						
						#
						# candidate for storing - check whether it is close enough to the search term,
						# i.e. do some sort of pre-fetching the edges
						#
							
						my $related = 0;
							
						FINDRELATED: for my $related_pos ( @{ $terms_found->{$relid}->{positions} } )
						{
							for my $found_pos ( @{ $terms_found->{$found_id}->{positions} } )
							{
								$related = ($related_pos >= $found_pos - $related_distance && $related_pos <= $found_pos + $related_distance );
								last FINDRELATED if $related;
							}
						}
							
						if ($related)
						{
							# add it to the list to be processed in pass 2
							$related_terms->{$termname}->{count}++;
							$related_terms->{$termname}->{wdf_normalized} += $wdf / $related_doccount;
							$related_terms->{$termname}->{idf} = $idf;
							$related_terms->{$termname}->{first_position} = $first_pos;
							
							push @{$related_terms->{$termname}->{edges}}, $termid;
						}
					}
				}
			}
		}
	}
	# end of pass 1
		
	#
	# Pass 2 - choose the related terms that have WDFIDF > threshold and occur in many documents
	#
	foreach my $related_name (keys %$related_terms)
	{
		my $wdf = $related_terms->{$related_name}->{wdf_normalized};
		
		my $idf = $related_terms->{$related_name}->{idf};
		my $wdfidf = $wdf * $idf;
		my $related_count = $related_terms->{$related_name}->{count};
		
		if ( $wdfidf > $param->{wdfidf_lower_related} && $related_count > $param->{related_threshold} )
		{
			my $id;
			if ( !defined $termname2id->{$related_name} )
			{
				$termname2id->{$related_name} = $term_count;
				$id = $term_count;
				$term_count++;
			}
			else
			{
				$id = $termname2id->{$related_name};
			}
							
			$terms->{$id}->{term} = $related_name;
			$terms->{$id}->{field} = '';
			$terms->{$id}->{wdf} = $wdf;
			$terms->{$id}->{wdfidf} = $wdfidf;
			$terms->{$id}->{doccount} = $related_terms->{$related_name}->{count};
			$terms->{$id}->{positions} = ();
			$terms->{$id}->{first_position} = $related_terms->{$related_name}->{first_position};
			$terms->{$id}->{colorref} = $param->{num_colors};
			$terms->{$id}->{x} = 0.0;
			$terms->{$id}->{y} = 0.0;
							
			# add the edges
			foreach my $fromid (@{$related_terms->{$related_name}->{edges}})
			{
				$edges->{$edge_count}->{from} = $fromid;
				$edges->{$edge_count}->{to} = $id;
				$edges->{$edge_count}->{weight} += 0.1;
				
				$terms->{$fromid}->{edgecount}++;
				$terms->{$id}->{edgecount}++;
							
				$edge_count++;
				
				$edges->{$edge_count}->{from} = $id;
				$edges->{$edge_count}->{to} = $fromid;
				$edges->{$edge_count}->{weight} += 0.1;
				
				$terms->{$id}->{edgecount}++;
				$terms->{$fromid}->{edgecount}++;
				
				$edge_count++;
			}
		}
	}
	
	return ($terms, $edges);
}


sub get_timelines
{
	my ($plugin, $terms) = @_;
	
	my $session = $plugin->{session};
	my $term2timeline = $plugin->{term2timeline};
	my $term2timeline_limit = $plugin->{param}->{term2timeline_limit};
	
	my $path = $session->config( "variables_path" ) . "/xapian";
	my $xapian = Search::Xapian::Database->new( $path );
	$xapian->reopen();
	
	my $min = 10000;
	my $max = 0;
	
	foreach my $termid (keys %$terms)
	{
		my $timeline;
		my $doccount = $terms->{$termid}->{doccount};

		my $queryfield = $terms->{$termid}->{field};
		my $queryterm = $terms->{$termid}->{term};
		
		if (!defined $term2timeline->{$queryterm}->{id})
		{
			my $query = Search::Xapian::Query->new(
				Search::Xapian::OP_AND(),
				Search::Xapian::Query->new( $queryfield . $queryterm )
			);
			
			my $enq = $xapian->enquire( $query );
			my @matches = $enq->matches(0, $doccount);
			
			$timeline = get_timeline( \@matches );
		
			if (scalar keys %$term2timeline < $term2timeline_limit)
			{
				$term2timeline->{$queryterm}->{id} = $termid;
				
				# cache a copy of the timeline
				foreach my $t (keys %{$timeline->{timepoints}})
				{
					$term2timeline->{$queryterm}->{timeline}->{timepoints}->{$t}->{value} = $timeline->{timepoints}->{$t}->{value};
				}
				$term2timeline->{$queryterm}->{timeline}->{year_min} = $timeline->{year_min};
				$term2timeline->{$queryterm}->{timeline}->{year_max} = $timeline->{year_max};
				$term2timeline->{$queryterm}->{timeline}->{value_max} = $timeline->{value_max};
			}
		}
		else
		{
			# retrieve the cached timeline
			foreach my $t (keys %{$term2timeline->{$queryterm}->{timeline}->{timepoints}})
			{
				$timeline->{timepoints}->{$t}->{value} = $term2timeline->{$queryterm}->{timeline}->{timepoints}->{$t}->{value};
			}
			$timeline->{year_min} = $term2timeline->{$queryterm}->{timeline}->{year_min};
			$timeline->{year_max} = $term2timeline->{$queryterm}->{timeline}->{year_max};
			$timeline->{value_max} = $term2timeline->{$queryterm}->{timeline}->{value_max};
		}
				
		$terms->{$termid}->{timeline} = $timeline;
		
		$min = $timeline->{year_min} if $timeline->{year_min} < $min;
		$max = $timeline->{year_max} if $timeline->{year_max} > $max;
	}
	
	return ($terms, $min, $max);
}


sub get_timeline
{
	my ($matches) = @_;
	
	my $fetch_timeline;
	my $year_min = 10000;
	my $year_max = 0;
	my $max = 0;
	
	foreach my $match (@$matches)
	{
		my $doc = $match->get_document();

		my $termlist_iterator = $doc->termlist_begin;
		
		$termlist_iterator->skip_to( 'date:');
		
		if ( $termlist_iterator ne $doc->termlist_end )
		{
			my $term = $termlist_iterator->get_termname();
			
			if ($term =~ /^date:/)
			{
				my $date = substr $term, 5, 4;
				#
				# skip if there is an error in the date
				#
				if ($date > 1900)
				{
					$fetch_timeline->{timepoints}->{$date}->{value}++;
					$year_min = $date if $date < $year_min;
					$year_max = $date if $date > $year_max;
				}
				else
				{
					print STDERR "Possible error in date: $date\n";
				}
			}
		}
	}
	
	$fetch_timeline->{year_min} = $year_min;
	$fetch_timeline->{year_max} = $year_max;
	
	foreach my $t (keys %{ $fetch_timeline->{timepoints} })
	{
		my $value = $fetch_timeline->{timepoints}->{$t}->{value};
		$max = $value if $value > $max;
	}
	
	$fetch_timeline->{value_max} = $max;
	
	return $fetch_timeline;
}

sub normalize_timelines
{
	my ($terms) = @_;
	
	my $max = 0;
	
	foreach my $termid (keys %$terms)
	{
		my $value_max = $terms->{$termid}->{timeline}->{value_max};
		$max = $value_max if $value_max > $max;
	}
	
	foreach my $termid (keys %$terms)
	{
		my $normalize_timeline = $terms->{$termid}->{timeline};
		
		foreach my $t (keys %{ $normalize_timeline->{timepoints} })
		{
			my $value = $normalize_timeline->{timepoints}->{$t}->{value} / $max;
			$value = sprintf("%.3f", $value);
			$normalize_timeline->{timepoints}->{$t}->{value} = $value;
		}
		
		$terms->{$termid}->{timeline} = $normalize_timeline;
	}
	
	return $terms;
}



sub get_edges
{
	my ( $nodes, $edge_count ) = @_;

	my $edges;
	
	foreach my $nodeid1 (keys %$nodes)
	{
		foreach my $nodeid2 (keys %$nodes)
		{
			if ($nodeid2 != $nodeid1 )
			{
				my $weight = get_edgeweight( $nodes->{$nodeid1},$nodes->{$nodeid2} );
				if ($weight > 0)
				{
					$edges->{$edge_count}->{from} = $nodeid1;
					$edges->{$edge_count}->{to} = $nodeid2;
					$edges->{$edge_count}->{weight} = $weight;
					
					$nodes->{$nodeid1}->{edgecount}++;
					$nodes->{$nodeid2}->{edgecount}++;
					
					$edge_count++;
					
				}
			}
		}
	}
	
	return ($nodes, $edges);
}


sub get_edgeweight
{
	my ($node1, $node2) = @_;
	
	my $diff;
	
	my $distance_weight_map = [
		{ 'l' => 1, 'u' => 1, 'w' => 4},
		{ 'l' => 2, 'u' => 5, 'w' => 2},
		{ 'l' => 6, 'u' => 10, 'w' => 1},
		{ 'l' => 11, 'u' => 99999999, 'w' => 0},
	];
		
	my $weight = 0;
	
	foreach my $pos1 (@{$node1->{positions}})
	{
		foreach my $pos2 (@{$node2->{positions}})
		{
			$diff = abs($pos2 - $pos1);
			if ($diff > 0) 
			{
				foreach my $m (@$distance_weight_map)
				{
					if ($diff >= $m->{'l'} && $diff <= $m->{'u'})
					{
						$weight += $m->{'w'};
					}
				}
			}
		}
	}
		
	return $weight;
}

sub graph_positions
{
	my ($terms, $param) = @_;
	
	my @angles;
	my $num_colors = $param->{num_colors};
	
	my $twopi = 6.28318531;
	my $radius_outer = 0.4;
	my $radius_inner = 0.05;
	
	my $range = ($radius_outer - $radius_inner) / $num_colors;
	
	my $sections = get_section_counts( $terms, $param);
	
	for (my $i = 0; $i < $num_colors; $i++)
	{
		$angles[$i] = 0;
	}
	
	foreach my $termid (sort { $terms->{$a}->{first_position} <=> $terms->{$b}->{first_position} } keys %$terms )
	{
		my $c = $terms->{$termid}->{colorref} - 1;
		my $radius = $radius_inner + $range * $c;
		
		my $angle = $angles[$c] / $sections->{$c + 1}->{count} * $twopi;
		
		my $x = 0.5 + $radius * cos( $angle );
		my $y = 0.5 + $radius * sin( $angle );
		
		$x = sprintf("%.3f", $x);
		$y = sprintf("%.3f", $y);
		
		$terms->{$termid}->{x} = $x;
		$terms->{$termid}->{y} = $y;
		
		$angles[$c]++;
	}
	
	return ($terms);
}

sub assign_colors
{
	my ($terms, $param) = @_;
	
	my $num_colors = $param->{num_colors} - 1;
	
	my ($min,$max) = get_edgecount_ranges( $terms );
	
	my $range = $max - $min;
	my $section = 1.001 * ($range / $num_colors);

	$section = 1 if ($section == 0);
	
	# assign the colorid to the terms
	foreach my $termid (keys %$terms)
	{
		if ($terms->{$termid}->{colorref} == 0)
		{
			my $e = $terms->{$termid}->{edgecount} - $min;
			$terms->{$termid}->{colorref} = $num_colors - int( $e / $section);
		}
	}
	
	return $terms;
}

sub get_edgecount_ranges
{
	my ($terms) = @_;
	
	my $min = 9999999;
	my $max = 0;
	
	# determine highest and lowest edgecount
	foreach my $termid (keys %$terms)
	{
		my $e = $terms->{$termid}->{edgecount};
		$min = $e if $e < $min;
		$max = $e if $e > $max;
	}
	
	return ($min,$max);
}

#
# get counts of terms per section
#
sub get_section_counts
{
	my ($terms, $param) = @_;
	
	my $sections;
	
	my $num_sections = $param->{num_colors};
	
	for (my $i = 1; $i <= $num_sections; $i++)
	{
		$sections->{$i}->{count} = 0;
	}
	
	foreach my $termid (keys %$terms)
	{
		my $section_id = $terms->{$termid}->{colorref};
		$sections->{$section_id}->{count}++;
	}
	
	return $sections;
}



sub save_graph
{
	my ($plugin, $eprintid, $terms, $edges) = @_;
	
	my $session = $plugin->{session};
	my $verbose = $plugin->{param}->{verbose};
	
	
	if ($verbose)
	{
		my $term_count = scalar (keys %$terms);
		my $edge_count = scalar (keys %$edges);
		print STDERR "Trendterms for eprint $eprintid: $term_count terms, $edge_count edges\n";
	}

	my $dir = $session->get_repository->get_conf( "htdocs_path" )."/trendterms_data";
		
	write_xml_terms( $plugin, $eprintid, $terms, $dir );
	write_xml_edges( $plugin, $eprintid, $edges, $dir );
	
	return;
}


sub write_xml_terms
{
	my ($plugin, $eprintid, $terms, $dir) = @_;
	
	my $param = $plugin->{param};
	
	my $year_min = $param->{year_min};
	my $year_max = $param->{year_max};
	
	my $year_count = $year_max - $year_min + 1;
	
	my $term_count = scalar (keys %$terms);
	my $optimize = "true";
	$optimize = "false" if ($term_count > 100);

	my $terms_target = $dir . "/terms_" . $eprintid . ".xml";
	
	my $xmldoc = XML::LibXML::Document->new('1.0','utf-8');
	
	my $element_graph = $xmldoc->createElement( "graph" );
	
	my $element_optimize = $xmldoc->createElement( "optimize" );
	$element_optimize->setAttribute( "value", $optimize );
	$element_graph->appendChild( $element_optimize );
	
	#
	# write baseline for timeline
	#
	my $element_timeline = $xmldoc->createElement( "timeline" );
	$element_timeline->setAttribute( "count", $year_count );
	my $dates = '';
	for ( my $i = $year_min; $i <= $year_max; $i++ )
	{
		$dates .= $i;
		$dates .= "," if $i < $year_max;
	}
    $element_timeline->setAttribute( "dates", $dates );
	$element_graph->appendChild( $element_timeline );
	
	#
	# write terms and their timelines
	#
	my $element_terms = $xmldoc->createElement( "terms" );
	
	foreach my $termid (keys %$terms)
	{
		my $term_value = $terms->{$termid}->{term};
		my $colorref = $terms->{$termid}->{colorref};
		my $doccount =  $terms->{$termid}->{doccount};
		
		my $x = $terms->{$termid}->{x};
		my $y = $terms->{$termid}->{y};
		
		my $element_term = $xmldoc->createElement( "term" );
		$element_term->setAttribute( "id", $termid );
		$element_term->setAttribute( "value", $term_value );
		$element_term->setAttribute( "x", $x );
		$element_term->setAttribute( "y", $y );
		$element_term->setAttribute( "colorref", $colorref );
		
		#
		# write timeline
		#
		my $timeline = $terms->{$termid}->{timeline};
		
		my $element_trend = $xmldoc->createElement( "trend" );
		$element_trend->setAttribute( "count", $year_count );
		
		my $data = '';
		for ( my $i = $year_min; $i <= $year_max; $i++ )
		{
			my $value = $timeline->{timepoints}->{$i}->{value};
			if (defined $value)
			{
				$data .= $value;
			}
			else
			{
				$data .= "0";
			}
			$data .= "," if $i < $year_max;
		}
		$element_trend->setAttribute( "data", $data );
		
		$element_term->appendChild( $element_trend);
		$element_terms->appendChild( $element_term);
	}
	
	$element_graph->appendChild( $element_terms );
	
    $xmldoc->setDocumentElement( $element_graph );
	my $xmldoc_string = $xmldoc->toString(1);
	
	open my $xmlout, ">", $terms_target or die "Cannot open > $terms_target\n";
	print $xmlout $xmldoc_string;
	close $xmlout;
	
	return;
}

sub write_xml_edges
{
	my ( $plugin, $eprintid, $edges, $dir ) = @_;
	
	my $edge_count = scalar (keys %$edges);

	my $edges_target = $dir . "/edges_" . $eprintid . ".xml";

	my $xmldoc = XML::LibXML::Document->new('1.0','utf-8');
	
	my $element_graph = $xmldoc->createElement( "graph" );
	my $element_edges = $xmldoc->createElement( "edges" );
	$element_edges->setAttribute( "count", $edge_count );
	
	foreach my $edgeid (keys %$edges)
	{
		my $element_edge = $xmldoc->createElement( "e" );
		
		my $from = $edges->{$edgeid}->{from};
		my $to = $edges->{$edgeid}->{to};
		my $w = $edges->{$edgeid}->{weight};
		
		$element_edge->setAttribute( "id", $edgeid );
		$element_edge->setAttribute( "f", $from );
		$element_edge->setAttribute( "t", $to );
		$element_edge->setAttribute( "w", $w );
		
		$element_edges->appendChild( $element_edge );
	}
	
	$element_graph->appendChild( $element_edges );
	
	$xmldoc->setDocumentElement( $element_graph );
	my $xmldoc_string = $xmldoc->toString(1);
	
	open my $xmlout, ">", $edges_target or die "Cannot open > $edges_target\n";
	print $xmlout $xmldoc_string;
	close $xmlout;
	
	return;
}


sub get_stopwords
{
	my @STOPWORDS = qw(
		a
		about
		above
		abstract
		across
		after
		again
		against
		all
		almost
		alone
		along
		already
		also
		although
		always
		among
		an
		analysis
		analyzed
		and
		another
		any
		anybody
		anyone
		anything
		anywhere
		are
		area
		areas
		around
		as
		ask
		asked
		asking
		asks
		associated
		at
		available
		away
		b
		back
		backed
		backing
		backs
		based
		be
		became
		because
		become
		becomes
		been
		before
		began
		behind
		being
		beings
		best
		better
		between
		big
		both
		but
		by
		c
		came
		can
		cannot
		case
		cases
		certain
		certainly
		clear
		clearly
		come
		compared
		considered
		could
		d
		demonstrate
		demonstrated
		described
		did
		differ
		different
		differently
		discussed
		do
		does
		done
		down
		down
		downed
		downing
		downs
		due
		during
		e
		each
		early
		eight
		either
		end
		ended
		ending
		ends
		enough
		establish
		established
		establishes
		evaluated
		even
		evenly
		ever
		every
		everybody
		everyone
		everything
		everywhere
		f
		face
		faces
		fact
		facts
		far
		felt
		few
		find
		findings
		finds
		first
		five
		for
		four
		from
		full
		fully
		further
		furthered
		furthering
		furthers
		g
		gave
		general
		generally
		get
		gets
		give
		given
		gives
		go
		going
		good
		goods
		got
		great
		greater
		greatest
		group
		grouped
		grouping
		groups
		h
		had
		has
		have
		having
		he
		her
		here
		herself
		high
		high
		high
		higher
		highest
		him
		himself
		his
		how
		however
		i
		if
		ii
		iii
		important
		improve
		improved
		in
		including
		increased
		interest
		interested
		interesting
		interests
		into
		is
		it
		its
		itself
		j
		just
		k
		keep
		keeps
		kind
		knew
		know
		known
		knows
		l
		large
		largely
		last
		later
		latest
		least
		less
		let
		lets
		like
		likely
		long
		longer
		longest
		m
		made
		make
		making
		man
		many
		may
		me
		member
		members
		men
		method
		might
		more
		moreover
		most
		mostly
		mr
		mrs
		much
		must
		my
		myself
		n
		near
		necessary
		need
		needed
		needing
		needs
		never
		new
		new
		newer
		newest
		next
		nine
		no
		nobody
		non
		noone
		not
		nothing
		now
		nowhere
		number
		numbers
		o
		obtained
		of
		off
		often
		old
		older
		oldest
		on
		once
		one
		only
		open
		opened
		opening
		opens
		or
		order
		ordered
		ordering
		orders
		other
		others
		our
		out
		over
		p
		part
		parted
		particular
		parting
		parts
		per
		perhaps
		place
		places
		point
		pointed
		pointing
		points
		possible
		potentially
		present
		presented
		presenting
		presents
		problem
		problems
		produced
		proposed
		provided
		provides
		put
		puts
		q
		quite
		r
		rather
		really
		recent
		related
		report
		reported
		required
		result
		results
		right
		right
		room
		rooms
		s
		said
		same
		saw
		say
		says
		second
		seconds
		see
		seem
		seemed
		seeming
		seems
		sees
		seven
		several
		shall
		she
		should
		show
		showed
		showing
		shows
		side
		sides
		since
		six
		small
		smaller
		smallest
		so
		some
		somebody
		someone
		something
		somewhere
		state
		states
		still
		study
		such
		suggest
		sure
		t
		take
		taken
		ten
		than
		that
		the
		their
		them
		then
		there
		therefore
		these
		they
		thing
		things
		think
		thinks
		this
		those
		though
		thought
		thoughts
		three
		through
		thus
		to
		today
		together
		too
		took
		toward
		turn
		turned
		turning
		turns
		two
		u
		under
		until
		up
		upon
		us
		use
		used
		uses
		using
		v
		various
		very
		w
		want
		wanted
		wanting
		wants
		was
		way
		ways
		we
		well
		wells
		went
		were
		what
		when
		where
		whether
		which
		whichever
		while
		who
		whole
		whose
		why
		will
		with
		within
		without
		work
		worked
		working
		works
		would
		x
		y
		year
		years
		yet
		you
		young
		younger
		youngest
		your
		yours
		z		
		ab
		aber
		aber
		ach
		acht
		achte
		achten
		achter
		achtes
		ag
		alle
		allein
		allem
		allen
		aller
		allerdings
		alles
		allgemeinen
		als
		also
		am
		an
		andere
		anderen
		andern
		anders
		auch
		auf
		aus
		ausser
		außer
		ausserdem
		außerdem
		bald
		bei
		beide
		beiden
		beim
		beispiel
		bekannt
		bereits
		besonders
		besser
		besten
		bin
		bis
		bisher
		bist
		da
		dabei
		dadurch
		dafür
		dagegen
		daher
		dahin
		dahinter
		damals
		damit
		danach
		daneben
		dank
		dann
		daran
		darauf
		daraus
		darf
		darfst
		darin
		darüber
		darum
		darunter
		das
		das
		dasein
		daselbst
		dass
		daß
		dasselbe
		davon
		davor
		dazu
		dazwischen
		dein
		deine
		deinem
		deiner
		dem
		dementsprechend
		demgegenüber
		demgemäss
		demgemäß
		demselben
		demzufolge
		den
		denen
		denn
		denn
		denselben
		der
		deren
		derjenige
		derjenigen
		dermassen
		dermaßen
		derselbe
		derselben
		des
		deshalb
		desselben
		dessen
		deswegen
		d.h
		dich
		die
		diejenige
		diejenigen
		dies
		diese
		dieselbe
		dieselben
		diesem
		diesen
		dieser
		dieses
		dir
		doch
		dort
		drei
		drin
		dritte
		dritten
		dritter
		drittes
		du
		durch
		durchaus
		dürfen
		dürft
		durfte
		durften
		eben
		ebenso
		ehrlich
		ei
		eigen
		eigene
		eigenen
		eigener
		eigenes
		ein
		einander
		eine
		einem
		einen
		einer
		eines
		einige
		einigen
		einiger
		einiges
		einmal
		einmal
		eins
		elf
		ende
		endlich
		entweder
		entweder
		er
		ernst
		erst
		erste
		ersten
		erster
		erstes
		es
		etwa
		etwas
		euch
		früher
		fünf
		fünfte
		fünften
		fünfter
		fünftes
		für
		gab
		ganz
		ganze
		ganzen
		ganzer
		ganzes
		gar
		gedurft
		gegen
		gegenüber
		gehabt
		gehen
		geht
		gekannt
		gekonnt
		gemacht
		gemocht
		gemusst
		genug
		gerade
		gern
		gesagt
		gesagt
		geschweige
		gewesen
		gewollt
		geworden
		gibt
		ging
		gleich
		gross
		groß
		grosse
		große
		grossen
		großen
		grosser
		großer
		grosses
		großes
		gut
		gute
		guter
		gutes
		habe
		haben
		habt
		hast
		hat
		hatte
		hätte
		hatten
		hätten
		heisst
		her
		heute
		hier
		hin
		hinter
		hoch
		ich
		ihm
		ihn
		ihnen
		ihr
		ihre
		ihrem
		ihren
		ihrer
		ihres
		im
		immer
		in
		indem
		infolgedessen
		ins
		irgend
		ist
		ja
		jahr
		jahre
		jahren
		je
		jede
		jedem
		jeden
		jeder
		jedermann
		jedermanns
		jedoch
		jemand
		jemandem
		jemanden
		jene
		jenem
		jenen
		jener
		jenes
		jetzt
		kam
		kann
		kannst
		kaum
		kein
		keine
		keinem
		keinen
		keiner
		kleine
		kleinen
		kleiner
		kleines
		kommen
		kommt
		können
		könnt
		konnte
		könnte
		konnten
		kurz
		lang
		lange
		lange
		leicht
		leide
		lieber
		los
		machen
		macht
		machte
		mag
		magst
		mahn
		man
		manche
		manchem
		manchen
		mancher
		manches
		mann
		mehr
		mein
		meine
		meinem
		meinen
		meiner
		meines
		mensch
		menschen
		mich
		mir
		mit
		mittel
		mochte
		möchte
		mochten
		mögen
		möglich
		mögt
		morgen
		muss
		muß
		müssen
		musst
		müsst
		musste
		mussten
		na
		nach
		nachdem
		nahm
		natürlich
		neben
		nein
		neue
		neuen
		neun
		neunte
		neunten
		neunter
		neuntes
		nicht
		nicht
		nichts
		nie
		niemand
		niemandem
		niemanden
		noch
		nun
		nun
		nur
		ob
		oben
		oder
		offen
		oft
		oft
		ohne
		Ordnung
		recht
		rechte
		rechten
		rechter
		rechtes
		richtig
		rund
		sa
		sache
		sagt
		sagte
		sah
		satt
		schlecht
		Schluss
		schon
		sechs
		sechste
		sechsten
		sechster
		sechstes
		sehr
		sei
		sei
		seid
		seien
		sein
		seine
		seinem
		seinen
		seiner
		seines
		seit
		seitdem
		selbst
		sich
		sie
		sieben
		siebente
		siebenten
		siebenter
		siebentes
		sind
		so
		solang
		solche
		solchem
		solchen
		solcher
		solches
		soll
		sollen
		sollte
		sollten
		sondern
		sonst
		sowie
		später
		statt
		tag
		tage
		tagen
		tat
		teil
		tel
		tritt
		trotzdem
		tun
		über
		überhaupt
		übrigens
		uhr
		um
		und
		uns
		unser
		unsere
		unserer
		unter
		vergangenen
		viel
		viele
		vielem
		vielen
		vielleicht
		vier
		vierte
		vierten
		vierter
		viertes
		vom
		von
		vor
		wahr
		während
		währenddem
		währenddessen
		wann
		war
		wäre
		waren
		wart
		warum
		was
		wegen
		weil
		weit
		weiter
		weitere
		weiteren
		weiteres
		welche
		welchem
		welchen
		welcher
		welches
		wem
		wen
		wenig
		wenig
		wenige
		weniger
		weniges
		wenigstens
		wenn
		wenn
		wer
		werde
		werden
		werdet
		wessen
		wie
		wie
		wieder
		will
		willst
		wir
		wird
		wirklich
		wirst
		wo
		wohl
		wollen
		wollt
		wollte
		wollten
		worden
		wurde
		würde
		wurden
		würden
		zehn
		zehnte
		zehnten
		zehnter
		zehntes
		zeit
		zu
		zuerst
		zugleich
		zum
		zum
		zunächst
		zur
		zurück
		zusammen
		zwanzig
		zwar
		zwar
		zwei
		zweite
		zweiten
		zweiter
		zweites
		zwischen
		zwölf
		à
		â
		abord
		afin
		ah
		ai
		aie
		ainsi
		allaient
		allo
		allô
		allons
		après
		assez
		attendu
		au
		aucun
		aucune
		aujourd
		aujourd'hui
		auquel
		aura
		auront
		aussi
		autre
		autres
		aux
		auxquelles
		auxquels
		avaient
		avais
		avait
		avant
		avec
		avoir
		ayant
		bah
		beaucoup
		bien
		bigre
		boum
		bravo
		brrr
		ça
		car
		ce
		ceci
		cela
		celle
		celle-ci
		celle-là
		celles
		celles-ci
		celles-là
		celui
		celui-ci
		celui-là
		cent
		cependant
		certain
		certaine
		certaines
		certains
		certes
		ces
		cet
		cette
		ceux
		ceux-ci
		ceux-là
		chacun
		chaque
		cher
		chère
		chères
		chers
		chez
		chiche
		chut
		ci
		cinq
		cinquantaine
		cinquante
		cinquantième
		cinquième
		clac
		clic
		combien
		comme
		comment
		compris
		concernant
		contre
		couic
		crac
		da
		dans
		de
		debout
		dedans
		dehors
		delà
		depuis
		derrière
		des
		dès
		désormais
		desquelles
		desquels
		dessous
		dessus
		deux
		deuxième
		deuxièmement
		devant
		devers
		devra
		différent
		différente
		différentes
		différents
		dire
		divers
		diverse
		diverses
		dix
		dix-huit
		dixième
		dix-neuf
		dix-sept
		doit
		doivent
		donc
		dont
		douze
		douzième
		dring
		du
		duquel
		durant
		effet
		eh
		elle
		elle-même
		elles
		elles-mêmes
		en
		encore
		entre
		envers
		environ
		es
		ès
		est
		et
		etant
		étaient
		étais
		était
		étant
		etc
		été
		etre
		être
		eu
		euh
		eux
		eux-mêmes
		excepté
		façon
		fais
		faisaient
		faisant
		fait
		feront
		fi
		flac
		floc
		font
		gens
		ha
		hé
		hein
		hélas
		hem
		hep
		hi
		ho
		holà
		hop
		hormis
		hors
		hou
		houp
		hue
		hui
		huit
		huitième
		hum
		hurrah
		il
		ils
		importe
		je
		jusqu
		jusque
		la
		là
		laquelle
		le
		lequel
		les
		lès
		lesquelles
		lesquels
		leur
		leurs
		longtemps
		lorsque
		lui
		lui-même
		ma
		maint
		mais
		malgré
		me
		même
		mêmes
		merci
		mes
		mien
		mienne
		miennes
		miens
		mille
		mince
		moi
		moi-même
		moins
		mon
		moyennant
		na
		ne
		néanmoins
		neuf
		neuvième
		ni
		nombreuses
		nombreux
		non
		nos
		notre
		nôtre
		nôtres
		nous
		nous-mêmes
		nul
		ô
		oh
		ohé
		olé
		ollé
		on
		ont
		onze
		onzième
		ore
		ou
		où
		ouf
		ouias
		oust
		ouste
		outre
		paf
		pan
		par
		parmi
		partant
		particulier
		particulière
		particulièrement
		pas
		passé
		pendant
		personne
		peu
		peut
		peuvent
		peux
		pff
		pfft
		pfut
		pif
		plein
		plouf
		plus
		plusieurs
		plutôt
		pouah
		pour
		pourquoi
		premier
		première
		premièrement
		près
		proche
		psitt
		puisque
		qu
		quand
		quant
		quanta
		quant-à-soi
		quarante
		quatorze
		quatre
		quatre-vingt
		quatrième
		quatrièmement
		que
		quel
		quelconque
		quelle
		quelles
		quelque
		quelques
		quelqu'un
		quels
		qui
		quiconque
		quinze
		quoi
		quoique
		revoici
		revoilà
		rien
		sa
		sacrebleu
		sans
		sapristi
		sauf
		se
		seize
		selon
		sept
		septième
		sera
		seront
		ses
		si
		sien
		sienne
		siennes
		siens
		sinon
		six
		sixième
		soi
		soi-même
		soit
		soixante
		son
		sont
		sous
		stop
		suis
		suivant
		sur
		surtout
		ta
		tac
		tant
		te
		té
		tel
		telle
		tellement
		telles
		tels
		tenant
		tes
		tic
		tien
		tienne
		tiennes
		tiens
		toc
		toi
		toi-même
		ton
		touchant
		toujours
		tous
		tout
		toute
		toutes
		treize
		trente
		très
		trois
		troisième
		troisièmement
		trop
		tsoin
		tsouin
		tu
		un
		une
		unes
		uns
		va
		vais
		vas
		vé
		vers
		via
		vif
		vifs
		vingt
		vivat
		vive
		vives
		vlan
		voici
		voilà
		vont
		vos
		votre
		vôtre
		vôtres
		vous
		vous-mêmes
		vu
		zut
		del
		el
		las
		una
	);
	
	return @STOPWORDS;
}

1;

=head1 AUTHOR

Martin Brändle <martin.braendle@id.uzh.ch>, Zentrale Informatik, University of Zurich

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2015- University of Zurich.

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of ZORA based on EPrints L<http://www.eprints.org/>.

EPrints is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

EPrints is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints.  If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

