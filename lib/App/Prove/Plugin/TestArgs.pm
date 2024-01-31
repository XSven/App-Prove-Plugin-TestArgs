#<<<
use strict; use warnings;
#>>>

package App::Prove::Plugin::TestArgs;

#use App::Prove               qw();
use Carp                     qw( croak );
use Class::Method::Modifiers qw( around );
use Config::Any              qw();

our $VERSION = '0.001';

sub load {
  my $plugin_name = shift;
  my ( $app_prove, $plugin_args ) = @{ +shift }{ qw( app_prove args ) };

  croak "Either supply test script arguments at the command-line or use $plugin_name, stopped"
    if defined $app_prove->test_args;
  # initialize test args
  $app_prove->test_args( {} );

  my $config;
  {
    no warnings 'once'; ## no critic (ProhibitNoWarnings)
    local $YAML::Preserve = 1; ## no critic (ProhibitPackageVars)
    ( undef, $config ) =
      %{ Config::Any->load_files( { files => [ $plugin_args->[ 0 ] ], use_ext => 1, flatten_to_hash => 1 } ) };
  }

  my %test_script_has_alias;
  for my $test_script ( keys %$config ) {
    for ( @{ $config->{ $test_script } } ) {
      my ( $alias, $test_script_args ) = @{ $_ }{ qw( alias args ) };
      # update test args ("args" is optional)
      $app_prove->test_args->{ $alias } = $test_script_args if defined $test_script_args;
      push @{ $test_script_has_alias{ $test_script } }, [ $test_script, $alias ];
    }
  }

  around 'App::Prove::_get_tests' => sub {
    my $_get_tests_orig = shift;

    my @tests;
    for ( $_get_tests_orig->( @_ ) ) {
      if ( exists $test_script_has_alias{ $_ } ) {
        push @tests, @{ $test_script_has_alias{ $_ } };
      } else {
        push @tests, $_;
      }
    }
    return @tests;
  };
}

1;
