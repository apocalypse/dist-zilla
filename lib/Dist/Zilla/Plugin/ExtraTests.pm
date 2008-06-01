package Dist::Zilla::Plugin::ExtraTests;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name =~ m{\Axt/(smoke|author|release)/.+\.t\z};
  warn "NAME: >> " . $file->name . "\n";

  my $method = "_rewrite_$1\_test";

  $self->$method($file);
}

sub _rewrite_smoke_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTOMATED_TESTING', '"smoke bot" testing');
}

sub _rewrite_author_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTHOR_TESTING', 'testing by the author');
}

sub _rewrite_release_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'RELEASE_TESTING', 'release candidate testing');
}

sub _rewrite {
  my ($self, $file, $env, $msg) = @_;

  (my $name = $file->name) =~ s{^xt/smoke/}{t/smoke-};

  $file->name($name);

  my @lines = split /\n/, $file->content;
  my $after = $lines[0] =~ /\A#!/ ? 1 : 0;
  splice @lines, $after, 0, <<"END_SKIPPER";
BEGIN {
  unless (\$ENV{$env}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for $msg');
  }
}
END_SKIPPER

  $file->content(join "\n", @lines);
}

1;
