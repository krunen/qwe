unit class Qwe::Buffer;
use Qwe::View;

has @!lines;
has $.filename;
has $.name;
has $.syntax;
has $.cfg;
has @!meta;

method line($i) { @!lines[$i] // '' }
method numlines { +@!lines }
method line-meta($i) { @!meta[$i] // {} }

method insert-chars($x,$y,$s) {
  self.extend-to-line($y);
  @!lines[$y].substr-rw($x,0) = $s;
}

method set-chars($x,$y,$s) {
  self.extend-to-line($y);
  @!lines[$y].substr-rw($x,$s.chars) = $s;
}

method extend-to-line($i) {
  for @!lines .. $i { @!lines.append('') }
}

method load-file($f) {
  die "Can't open file $f" unless $f.IO.e;

  @!lines = $f.IO.lines;
  $!filename = $f;
  $!name = $f.IO.basename;
}

method new-view(*%h) {
  Qwe::View.new(:buffer(self), |%h);
}

method meta($x,$y) {
  @!meta[$y]{$x} //= {};
  @!meta[$y]{$x}
}

method set-syntax($s) {
  if $!cfg.syntax($s) {
    $!syntax = $s;
  }
}

