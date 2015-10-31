unit class Qwe::Window;

has $.view handles <buffer line x y offset-x offset-y line-length
                    visible-lines visible-line-length input-text
                    insert-mode toggle-insert-mode undo>;
has $.pos-x;
has $.pos-y;
has $.width;
has $.height;
has $.pad = 0;
has $!message-lines;

method set-view($v) {
    $v.window = self;
    $!view = $v;
}

method update-header {
    $*term.move-to($!pos-x, $!pos-y);
    $*term.fgcolor(0);
    
    my $fnw = $!width - 15 - $!pad * 2;
    my $s = sprintf("%-{$fnw}.{$fnw}s %14.14s",
        self.buffer.filename,
        (self.insert-mode ?? 'I' !! 'O') ~
        ' ' ~
        $*term.italic('l') ~ self.y+self.offset-y+1 ~ ' ' ~
        $*term.italic('c') ~ self.x+self.offset-x+1);
    
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
        $*term.move-to($!pos-x, $!pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print((' ' x $!pad) ~ $line ~ ' ' x $!width-$line.chars);
    }
    $*term.print(' ' x $!width-1);
}

method update-cursor {
    $*term.move-to($!pos-x + self.x + $!pad, $!pos-y + self.y + 1);
}

method move-to($x is copy, $y is copy, :$view=0, :$redraw is copy = 0) {
    if $view {
        return if $x < $!pad || $x > $!width-$!pad || $y < 1 || $y >= $!height-1;
        $x += self.offset-x - 1;
        $y += self.offset-y - 1;
    }
    if $x.defined {
        if $x < self.offset-x {
            self.offset-x = $x;
            self.x = 0;
            $redraw = 1;
        } elsif $x >= self.offset-x + $!width - $!pad * 2 {
            self.offset-x = $x - ($!width/2).ceiling;
            self.x = ($!width/2).floor;
            $redraw = 1;
        } else {
            self.x = $x - self.offset-x;
        }
    }
    if $y.defined {
        if $y < self.offset-y {
            self.offset-y = $y;
            self.y = 0;
            $redraw = 1;
        } elsif $y > self.offset-y + $!height + self.y {
            self.offset-y = $y - ($!height/2).ceiling;
            self.y = ($!height/2).floor;
            $redraw = 1;
        } else {
            self.y = $y - self.offset-y;
        }
    }
    self.update-header;
    self.redraw-lines if $redraw;
    self.update-cursor;
}

method move($dx, $dy) {
    my $nx = self.offset-x + self.x + $dx;
    my $ny = self.offset-y + self.y + $dy;
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
    if $ny < 0 || $ny >= self.buffer.numlines {
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
    $*term.move-to(0, self.offset-y + $!height - $l);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x $!width * $l);
    $*term.move-to(0, self.offset-y + $!height - $l);
    $*term.print($s2);
    $*term.bgcolor(253);
    $!message-lines = $l;
    self.update-cursor;
}

method ask($s) {
    my $s2 = $s;
    $s2 ~~ s:g/\n/ /;
    my $l = ($s2.chars / $!width).ceiling;
    if $l > 6 {
        $l = 6;
        $s2 = $s2.substr(0,$!width * $l - 3) ~ '...';
    }
    $*term.move-to(0, self.offset-y + $!height - $l);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x $!width * $l);
    $*term.move-to(0, self.offset-y + $!height - $l);
    print($s2);
    
    my $ans = join '', gather loop { my $c = $*IN.getc; last if $c ~~ /\n/; print($c); take $c }

    $*term.bgcolor(253);
    $!message-lines = $l;
    self.update-cursor;
    $ans;
}

method remove-message {
    return unless $!message-lines;
    $*term.fgcolor(233);
    $*term.bgcolor(253);
    for $!height - $!message-lines - 1 .. $!height - 1 -> $l {
        $*term.move-to($!pos-x, $!pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print((' ' x $!pad) ~ $line ~ ' ' x $!width-$line.chars-1);
    }
    $*term.move-to($!pos-x, $!pos-y + $!height);
    $*term.print(' ' x $!width-1);
    $!message-lines = 0;
    self.update-cursor;
}

method process-event($code,%param) {
    self.remove-message;
    given $code {
        when 'UP'        { self.move(0,-1) }
        when 'DOWN'      { self.move(0,1) }
        when 'LEFT'      { self.move(-1,0) }
        when 'RIGHT'     { self.move(1,0) }
        when 'HOME'
           | '^A'        { self.move-to(0,Nil) }
        when 'END'
           | '^E'        { self.move-to(self.line-length,Nil) }
        when '^L'        { self.redraw }
        when '^Z'	 { self.undo }
        when '^S'        { my $fn = self.ask("Filename: "); self.message("got: $fn"); }
        when 'MOUSEUP'   { self.move-to(%param<x>-1, %param<y>-1, :view) }
        when 'MOUSEDN'   { }
        when 'MOUSEMOVE' { }
        when 'INS'       { self.toggle-insert-mode }
        when .chars == 1 { self.input-text($code) }
        default {
            self.message("unknown event $code {%param}");
        }
    }
}
