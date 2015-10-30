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
    $!buffer.line($!offset-y + ($i // $!y)).chars;
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
    $*term.fgcolor(235);
    for 0 ..^ $!height-2 -> $l {
        $*term.move-to($!pos-x + $!pad, $!pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print($line ~ ' ' x $!width-$line.chars);
    }
}

method update-cursor {
    $*term.move-to($!pos-x + $!x + $!pad, $!pos-y + $!y + 1);
}

method move-to($x, $y) {
    my $redraw = 0;
    if $x.defined {
        if $x < $!offset-x {
            $!offset-x = $x;
            $!x = 0;
            $redraw = 1;
        } elsif $x > $!offset-x + $!width + $!x {
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
        } elsif $x > $!offset-y + $!height + $!y {
            $!offset-y = $x - ($!height/2).ceiling;
            $!x = ($!height/2).floor;
            $redraw = 1;
        } else {
            $!y = $y - $!offset-y;
        }
    }
    self.update-header;
    self.redraw-lines if $redraw;
    self.update-cursor;
}

method move($dx is copy, $dy) {
    my $redraw = 0;
    if $!y + $dy >= self.visible-lines {
        # do nothing
    } elsif $!y + $dy > $!height - 1 {
        $!offset-y += $dy;
        $redraw = 1;
    } elsif $!y + $dy < 0 {
        if $!offset-y + $dy >= 0 {
            $!offset-y += $dy;
            $redraw = 1;
        }
    } else {
        $!y += $dy;
    }
    if $!x + $dx > self.visible-line-length {
        if $dx {
            $dx = self.line-length - $!offset-x - $!x;
        }
    }
    if $!x + $dx > $!width + $!pad * 2 {
        $!offset-x += $dx;
        $redraw = 1;
    } elsif $!x + $dx < 0 {
        if $!offset-x + $dx >= 0 {
            $!offset-x += $dx;
            $redraw = 1;
        } elsif $!y+$!offset-y > 1 {
            self.move-to($!buffer.line($!y+$!offset-y-1).chars,$!y+$!offset-y-1);
            return;
        }
    } else {
        $!x += $dx;
    }
    self.update-header;
    self.redraw-lines if $redraw;
    self.update-cursor;
}

method message($s) {
    $*term.move-to(0,$*term.rows-4);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x $*term.cols * 3);
    $*term.move-to(1,$*term.rows-3);
    $*term.print($s);
    $*term.bgcolor(253);
    self.update-cursor;
}
