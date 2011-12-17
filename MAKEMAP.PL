#!/usr/bin/perl
use strict;
use warnings;
use List::Util;

my $map = 'COLOR-NAME-MAP';
my $rgb = 'data';

my $page = [];
my $data = {};
my $move = { '_葡萄色' => 'ぶどう色', '_菖蒲色' => 'あやめ色', '_褐色' => '搗色' };
my $head = [ qw(ColorName Kana Roman Hex Dec R G B C M Y K H S V) ];

open( my $datahandle, '<', $map ) or die('cannot open '.$map );
while( <$datahandle> )
{
	if( $_ =~ m|\A"(.+)": [{] "name": "([A-Za-z0-9]+)"| )
	{
		$data->{$1} = lc $2;
	}
}
close($datahandle);
exit unless keys %$data;

open( my $pagehandle, '<', $rgb ) or die('cannot open '.$rgb);
while( <$pagehandle> )
{
	my $temp = { 'name' => q(), 'kana' => q(), 'roman' => q(),
			'hex' => q(), 'dec' => 0, 'r' => 0, 'g' => 0, 'b' => 0,
			'c' => 0, 'm' => 0, 'y' => 0, 'k' => 0, 'h' => 0, 's' => 0, 'v' => 0, };

	if( $_ =~ m{^<td style="background-color:#(.{6}).+title="(.+)\s#[0-9A-Za-z]{6}.+<span>(.+)</span>} )
	{
		$temp->{'name'} = $2; $temp->{'name'} =~ y{ }{_};
		$temp->{'kana'} = $3;
		$temp->{'roman'} = $data->{ $temp->{'name'} };
		$temp->{'hex'} = '#'.$1;

		if( $temp->{'hex'} =~ m{\A[#](..)(..)(..)\z} )
		{
			my $x = 0; my $y = 0;
			my $r = 0; my $g = 0; my $b = 0;

			# RGB
			$temp->{'r'} = hex($1); $r = $temp->{'r'} / 255;
			$temp->{'g'} = hex($2); $g = $temp->{'g'} / 255;
			$temp->{'b'} = hex($3); $b = $temp->{'b'} / 255;

			# CMYK
			$temp->{'k'} = List::Util::min( 1-$r, 1-$g, 1-$b );
			$temp->{'c'} = ( 1 - $r - $temp->{'k'} ) / ( 1 - $temp->{'k'} );
			$temp->{'m'} = ( 1 - $g - $temp->{'k'} ) / ( 1 - $temp->{'k'} );
			$temp->{'y'} = ( 1 - $b - $temp->{'k'} ) / ( 1 - $temp->{'k'} );
			$temp->{'dec'} = ( $temp->{'r'} << 16 | $temp->{'g'} << 8 | $temp->{'b'} );

			# Hue, Saturation, Value(Brightness)
			$x = List::Util::max( $r, $g, $b );
			$y = List::Util::min( $r, $g, $b );

			if( $x == $y )
			{
				$temp->{'h'} = 0;
				$temp->{'s'} = 0;
			}
			else
			{
				if( $x == $r )
				{
					$temp->{'h'} = 60 * ( $g - $b ) / ( $x - $y );
				}
				elsif( $x == $g )
				{
					$temp->{'h'} = 60 * ( $b - $r ) / ( $x - $y ) + 120;
				}
				elsif( $x == $b )
				{
					$temp->{'h'} = 60 * ( $r - $g ) / ( $x - $y ) + 240;
				}

				$temp->{'h'} += 360 if $temp->{'h'} < 0;
				$temp->{'s'} = ( $x - $y ) / $x;
			}

			$temp->{'v'} = $x;
		}

		# Fix same color name
		$temp->{'name'} = $move->{ $temp->{'name'} } if $temp->{'name'} =~ m{\A_};

		push( @$page, $temp );
	}
}
close($pagehandle);

printf("%s\n",join("\t", @$head) );
foreach my $c ( @$page )
{
	printf("%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\n",
		$c->{'name'}, $c->{'kana'}, $c->{'roman'}, $c->{'hex'},
		$c->{'dec'}, $c->{'r'}, $c->{'g'}, $c->{'b'},
		$c->{'c'}, $c->{'m'}, $c->{'y'}, $c->{'k'},
		$c->{'h'}, $c->{'s'}, $c->{'v'} );
}

__END__
