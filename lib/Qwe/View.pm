unit class Qwe::View;

has $.buffer;
has $.window is rw handles <pad update-header update-cursor>;

has $.offset-x is rw = 0;
has $.offset-y is rw = 0;
has $.x is rw = 0;
has $.y is rw = 0;

has $.insert-mode = 1;

method line($i) {
    my $l = $!buffer.line($i + $!offset-y);
    return '' if $!offset-x + self.pad >= $l.chars;
    $l.substr($!offset-x, $!window.width - self.pad * 2);
}

method visible-line-length($i?) {
    self.line($i // $!y).chars;
}

method line-length($i?) {
    $!buffer.line($i // ($!offset-y + $!y)).chars;
}

method visible-lines {
    $!buffer.numlines - $!offset-y;
}

method input-text($s) {
    if $!insert-mode {
        $!buffer.insert-chars-undo($!offset-x + $!x, $!offset-y + $!y, $s);
        $*term.print("\e[{$s.chars}@"~$s);
    } else {
        $!buffer.set-chars-undo($!offset-x + $!x, $!offset-y + $!y, $s);
        $*term.print($s);
    }
    $!x += $s.chars;
}

method undo {
    my ($x,$y) = $!buffer.undo;
    if $x.defined {
        self.move-to($x, $y, :redraw);
    } else {
        self.message("nothing to undo");
    }
}

method toggle-insert-mode {
    $!insert-mode .= not;
    self.update-header;
    self.update-cursor;
}

