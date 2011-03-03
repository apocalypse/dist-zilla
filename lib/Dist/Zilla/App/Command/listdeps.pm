use strict;
use warnings;
package Dist::Zilla::App::Command::listdeps;
# ABSTRACT: print your distribution's prerequisites
use Dist::Zilla::App -command;

use Moose::Autobox;
use Version::Requirements;

=head1 SYNOPSIS

  dzil listdeps [ --author ]

=head1 DESCRIPTION

This command prints the prerequisites of your distribution. You could
pipe that list to a CPAN client like L<cpan> to install all of the dependecies
in one quick go.

=head1 EXAMPLE

  $ dzil listdeps
  $ dzil listdeps | cpan
  $ dzil listdeps --author

=head1 OPTIONS

=head2 --author

This will include author dependencies. (those listed under C<develop_requires>)

=head1 ACKNOWLEDGEMENTS

This code is more or less a direct copy of Marcel Gruenauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=cut

sub abstract { "print your distribution's prerequisites" }

sub opt_spec {
    [ 'author', 'include author dependencies' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->app->chrome->logger->mute;

  $_->before_build for $self->zilla->plugins_with(-BeforeBuild)->flatten;
  $_->gather_files for $self->zilla->plugins_with(-FileGatherer)->flatten;
  $_->prune_files  for $self->zilla->plugins_with(-FilePruner)->flatten;
  $_->munge_files  for $self->zilla->plugins_with(-FileMunger)->flatten;
  $_->register_prereqs for $self->zilla->plugins_with(-PrereqSource)->flatten;

  my $req = Version::Requirements->new;
  my $prereqs = $self->zilla->prereqs;

  my @phases = qw(build test configure runtime);
  push @phases, 'develop' if $opt->author;

  for my $phase (@phases) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') );
  }

  print "$_\n" for sort { lc $a cmp lc $b }
                   grep { $_ ne 'perl' }
                   $req->required_modules;
}

1;
