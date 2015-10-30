unit class Qwe::View;

has $.buffer;
has $.start-x is rw = 0;
has $.start-y is rw = 0;
has $.width is rw;
has $.height is rw;

method line($i) {
    my $l = $!buffer.line($i+$!start-y);
    return '' if $!start-x >= $l.chars;
    $l.substr($!start-x,$!width);
}
