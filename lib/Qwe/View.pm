unit class Qwe::View;

has $.buffer;
has $.offset-x is rw = 0;
has $.offset-y is rw = 0;
has $.pos-y is rw = 0;
has $.pos-x is rw = 0;
has $.width is rw;
has $.height is rw;
has $.x = 0;
has $.y = 0;
has $.pad = 0;

has $.insert-mode = 1;

method line($i) {
    my $l = $!buffer.line($i + $!offset-y);
    return '' if $!offset-x + $!pad >= $l.chars;
    $l.substr($!offset-x, $!width - $!pad * 2);
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

method update-header {
    $*term.move-to($!pos-x, $!pos-y);
    $*term.fgcolor(0);
    
    my $fnw = $!width - 15 - $!pad * 2;
    my $s = sprintf("%-{$fnw}.{$fnw}s %14.14s",
        $!buffer.filename,
        'I ' ~
        $*term.italic('l') ~ $!y+$!offset-y+1 ~ ' ' ~
        $*term.italic('c') ~ $!x+$!offset-x+1);
    
    $*term.print(' ' x $!pad ~ $*term.underline($s));
}

method redraw {
    self.update-header;
    self.redraw-lines;
    self.update-cursor;
}

method redraw-lines {
    $*term.fgcolor(233);
    for 0 ..^ $!height-2 -> $l {
        $*term.move-to($!pos-x + $!pad, $!pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print($line ~ ' ' x $!width-$line.chars);
    }
    $*term.print(' ' x $!width-1);
}

method update-cursor {
    $*term.move-to($!pos-x + $!x + $!pad, $!pos-y + $!y + 1);
}

method move-to($x is copy, $y is copy, :$view=0) {
    if $view {
        return if $x < $!pad || $x > $!width-$!pad || $y < 1 || $y >= $!height-1;
        $x += $!offset-x - 1;
        $y += $!offset-y - 1;
    }
    my $redraw = 0;
    if $x.defined {
        if $x < $!offset-x {
            $!offset-x = $x;
            $!x = 0;
            $redraw = 1;
        } elsif $x >= $!offset-x + $!width - $!pad * 2 {
            $!offset-x = $x - ($!width/2).ceiling;
            $!x = ($!width/2).floor;
            $redraw = 1;
        } else {
            $!x = $x - $!offset-x;
        }
    }
    if $y.defined {
        if $y < $!offset-y {
            $!offset-y = $y;
            $!y = 0;
            $redraw = 1;
        } elsif $y > $!offset-y + $!height + $!y {
            $!offset-y = $y - ($!height/2).ceiling;
            $!y = ($!height/2).floor;
            $redraw = 1;
        } else {
            $!y = $y - $!offset-y;
        }
    }
    self.update-header;
    self.redraw-lines if $redraw;
    self.update-cursor;
}

method move($dx, $dy) {
    my $nx = $!offset-x + $!x + $dx;
    my $ny = $!offset-y + $!y + $dy;
    my $domove = 1;
    if $nx < 0 {
        $ny--;
        $nx = self.line-length($ny);
    } elsif $nx > self.line-length($ny) {
        if $dx > 0 {
            $nx = 0;
            $ny++;
        } elsif $dx < 0 {
            $nx = self.line-length($ny);
        }
    }
    if $ny < 0 || $ny >= $!buffer.numlines {
        $domove = 0;
    }
    self.move-to($nx, $ny) if $domove;
}

method message($s) {
    my $s2 = $s;
    $s2 ~~ s:g/\n/ /;
    my $l = ($s2.chars / $!width).ceiling;
    if $l > 6 {
        $l = 6;
        $s2 = $s2.substr(0,$!width * $l - 3) ~ '...';
    }
    $*term.move-to(0,$*term.rows-$l);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x $*term.cols * $l);
    $*term.move-to(0,$*term.rows-$l);
    $*term.print($s2);
    $*term.bgcolor(253);
    self.update-cursor;
}
