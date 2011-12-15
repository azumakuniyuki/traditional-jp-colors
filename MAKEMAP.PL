#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $map = 'COLOR-NAME-MAP';
my $rgb = 'data';

my $page = [];
my $data = {};
my $move = { '_葡萄色' => 'ぶどう色', '_菖蒲色' => 'あやめ色', '_褐色' => '搗色' };

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
			'hex' => q(), 'dec' => 0, 'r' => 0, 'g' => 0, 'b' => 0 };

	if( $_ =~ m{^<td style="background-color:#(.{6}).+title="(.+)\s#[0-9A-Za-z]{6}.+<span>(.+)</span>} )
	{
		$temp->{'name'} = $2; $temp->{'name'} =~ y{ }{_};
		$temp->{'kana'} = $3;
		$temp->{'roman'} = $data->{ $temp->{'name'} };
		$temp->{'hex'} = '#'.$1;

		if( $temp->{'hex'} =~ m{\A[#](..)(..)(..)\z} )
		{
			$temp->{'r'} = hex($1);
			$temp->{'g'} = hex($2);
			$temp->{'b'} = hex($3);
			$temp->{'dec'} = ( $temp->{'r'} << 16 | $temp->{'g'} << 8 | $temp->{'b'} );
		}

		# Fix same color name
		$temp->{'name'} = $move->{ $temp->{'name'} } if $temp->{'name'} =~ m{\A_};

		push( @$page, $temp );
	}
}
close($pagehandle);

foreach my $c ( @$page )
{
	printf("%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\n",
		$c->{'name'}, $c->{'kana'}, $c->{'roman'}, $c->{'hex'},
		$c->{'dec'}, $c->{'r'}, $c->{'g'}, $c->{'b'} );
}

__END__
