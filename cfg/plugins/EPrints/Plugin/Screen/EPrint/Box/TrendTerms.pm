######################################################################
#
#  Screen::EPrint::Box::TrendTerms plugin
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

Screen::EPrint::Box::TrendTerms plugin - display TrendTerms graph

=head1 DESCRIPTION

This plugin displays the TrendTerms graph for a given eprint

=cut

package EPrints::Plugin::Screen::EPrint::Box::TrendTerms;

use strict;
use warnings;

use base 'EPrints::Plugin::Screen::EPrint::Box';

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 if $self->{session}->get_secure;
	return 0 if( !defined $self->{processor}->{eprint} || !$self->{processor}->{eprint}->exists_and_set( 'eprintid' ) );

	return 1;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $eprint = $self->{processor}->{eprint};

	my $frag = $session->xml->create_document_fragment;
	
	if ( $eprint->is_set( "abstract" ) )
	{
		my $terms_div = $session->make_element( "div", id=>"trendterms_heading_div", class=>"hidden-print");
		my $terms_heading = $session->make_element( "h2", id=>"trendterms_heading");
		$terms_div->appendChild( $terms_heading );
		$terms_heading->appendChild( $session->html_phrase( "page:trendterms" ) );
		$terms_heading->appendChild( $session->html_phrase( "trendterms_graph:help_script" ) );
		$frag->appendChild( $terms_div );
		$frag->appendChild( $session->html_phrase( "trendterms_graph:help_detail",
			archive =>  $session->html_phrase( "archive_name" ),
			archive2 => $session->html_phrase( "archive_name" )
		) );
		$frag->appendChild( make_trendtermsbox( $eprint,$session ) );
	}

	return $frag;
}


sub make_trendtermsbox
{
	my ($eprint, $session ) = @_;

	my $eprintid = $eprint->get_value( "eprintid" );

	my $trendterms_div = $session->make_element( "div", id=>"trendterms", class=>"col-lg-12 col-md-12 col-sm-12 col-xs-12 summary-widget hidden-print", style=>"padding:0px;");
	my $canvas = $session->make_element( "canvas", 
		id => "TrendTerms", 
		"data-processing-myconfig" => "../trendterms/configuration.xml",
		"data-processing-mydata" => $eprintid, 
		"data-processing-sources" => "../trendterms/TrendTerms.pde",
		class => "trendterms"
	);

	my $page = $session->get_repository->html_phrase( "trendterms_graph:page_template", canvas => $canvas );
	
	$trendterms_div->appendChild( $page );

	return ( $trendterms_div );
}

1;
