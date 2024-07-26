## no critic (RequireExtendedFormatting, ProhibitComplexRegexes)
use strict;
use warnings;

use Test::Fatal qw( exception );
use Test::More import => [ qw( BAIL_OUT can_ok is_deeply like plan require_ok subtest ) ], tests => 5;

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

subtest 'without command-line test args' => sub {
  plan tests => 2;

  my $app_prove = App::Prove->new;
  $app_prove->process_args( qw( t/foo.t t/bar.t ) );
  $app_prove->state_manager( $app_prove->state_class->new( { store => App::Prove->STATE_FILE } ) );
  $plugin_name->load( { app_prove => $app_prove, args => [ 't/config.yml' ] } );

  is_deeply $app_prove->test_args, { 'foo once' => [ qw( ABC DEF ) ], 'foo twice' => [], 'foo thrice' => [ 'GHI' ] },
    'check test args';

  is_deeply [ $app_prove->_get_tests ],
    [ [ 't/foo.t', 'foo once' ], [ 't/foo.t', 'foo twice' ], [ 't/foo.t', 'foo thrice' ], [ 't/bar.t', 't/bar.t' ] ],
    'check tests';
};

subtest 'with command-line test args' => sub {
  plan tests => 2;

  my $app_prove = App::Prove->new;
  $app_prove->process_args( qw( t/foo.t t/bar.t :: --url http://example.com ) );
  $app_prove->state_manager( $app_prove->state_class->new( { store => App::Prove->STATE_FILE } ) );
  $plugin_name->load( { app_prove => $app_prove, args => [ 't/config.yml' ] } );

  is_deeply $app_prove->test_args,
    {
    'foo once'   => [ qw( ABC DEF ) ],
    'foo twice'  => [ qw( --url http://example.com ) ],
    'foo thrice' => [ 'GHI' ]
    },
    'check test args';

  is_deeply [ $app_prove->_get_tests ],
    [ [ 't/foo.t', 'foo once' ], [ 't/foo.t', 'foo twice' ], [ 't/foo.t', 'foo thrice' ], [ 't/bar.t', 't/bar.t' ] ],
    'check tests';
};
