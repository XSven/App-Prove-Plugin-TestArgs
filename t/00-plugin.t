## no critic (RequireExtendedFormatting, ProhibitComplexRegexes)
use strict;
use warnings;

use Test::Fatal qw( exception );
use Test::More import => [ qw( BAIL_OUT can_ok is_deeply like note plan require_ok subtest ) ], tests => 8;

use App::Prove ();

my $plugin_name = 'App::Prove::Plugin::TestArgs';

require_ok( $plugin_name ) or BAIL_OUT "Cannot require plugin '$plugin_name'!";

can_ok( $plugin_name, 'load' );

subtest 'provoke fatal perl diagnostics' => sub {
  plan tests => 3;

  like exception { $plugin_name->load }, qr/\ACan't use an undefined value as/, 'pass no aruments';

  like exception { $plugin_name->load( [] ) }, qr/\ANot a HASH reference/, 'pass wrong reference type';

  like exception { $plugin_name->load( 'file' ) }, qr/\ACan't use string/, 'pass string(scalar) argument';
};

sub wocta {
  my ( $config_file ) = @_;

  plan tests => 2;

  my $app_prove = App::Prove->new;
  $app_prove->process_args( qw( t/foo.t t/bar.t ) );
  $app_prove->state_manager( $app_prove->state_class->new( { store => App::Prove->STATE_FILE } ) );
  $plugin_name->load( { app_prove => $app_prove, args => [ $config_file ] } );

  is_deeply $app_prove->test_args, { 'foo once' => [ qw( ABC DEF ) ], 'foo twice' => [], 'foo thrice' => [ 'GHI' ] },
    'check test args';

  is_deeply [ $app_prove->_get_tests ],
    [ [ 't/foo.t', 'foo once' ], [ 't/foo.t', 'foo twice' ], [ 't/foo.t', 'foo thrice' ], [ 't/bar.t', 't/bar.t' ] ],
    'check tests';
}

sub wcta {
  my ( $config_file ) = @_;

  plan tests => 2;

  my $app_prove = App::Prove->new;
  $app_prove->process_args( qw( t/foo.t t/bar.t :: UVW XYZ ) );
  $app_prove->state_manager( $app_prove->state_class->new( { store => App::Prove->STATE_FILE } ) );
  $plugin_name->load( { app_prove => $app_prove, args => [ $config_file ] } );

  is_deeply $app_prove->test_args,
    {
    'foo once'   => [ qw( ABC DEF ) ],
    'foo twice'  => [ qw( UVW XYZ ) ],
    'foo thrice' => [ 'GHI' ]
    },
    'check test args';

  is_deeply [ $app_prove->_get_tests ],
    [ [ 't/foo.t', 'foo once' ], [ 't/foo.t', 'foo twice' ], [ 't/foo.t', 'foo thrice' ], [ 't/bar.t', 't/bar.t' ] ],
    'check tests';
}

for ( qw( t/config.yml t/config_scripts.yml ) ) {
  note 'config file: ', $_;
  subtest 'without command-line test args' => \&wocta, $_;
  subtest 'with command-line test args'    => \&wcta,  $_;
}

subtest 'named' => sub {
  my ( $config_file ) = 't/config_name_scripts.yml';

  plan tests => 2;

  my $app_prove = App::Prove->new;
  $app_prove->process_args( qw( t/foo.t t/bar.t :: UVW XYZ ) );
  $app_prove->state_manager( $app_prove->state_class->new( { store => App::Prove->STATE_FILE } ) );
  $plugin_name->load( { app_prove => $app_prove, args => [ $config_file ] } );

  is_deeply $app_prove->test_args,
    {
    't/foo.t (foo once)'   => [ qw( ABC DEF ) ],
    't/foo.t (foo twice)'  => [ qw( UVW XYZ ) ],
    't/foo.t (foo thrice)' => [ 'GHI' ]
    },
    'check test args';

  is_deeply [ $app_prove->_get_tests ],
    [
    [ 't/foo.t', 't/foo.t (foo once)' ],
    [ 't/foo.t', 't/foo.t (foo twice)' ],
    [ 't/foo.t', 't/foo.t (foo thrice)' ],
    [ 't/bar.t', 't/bar.t' ]
    ],
    'check tests';
};
