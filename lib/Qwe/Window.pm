unit class Qwe::Window;

has $.view handles <buffer line x y offset-x offset-y line-length
                    visible-lines visible-line-length input-text
                    insert-mode toggle-insert-mode undo>;
has $.pos-x is rw;
has $.pos-y is rw;
has $.width is rw;
has $.height is rw;
has $.pad is rw = 0;
has $!message-lines;

method set-view($v) {
    $v.window = self;
    $!view = $v;
}

method update-header {
    $*term.move-to(self.pos-x, self.pos-y);
    $*term.fgcolor(0);
    
    my $fnw = self.width - 15 - self.pad * 2;
    my $s = sprintf("%-{$fnw}.{$fnw}s %14.14s",
        self.buffer.filename,
        (self.insert-mode ?? 'I' !! 'O') ~
        ' ' ~
        $*term.italic('l') ~ self.y+self.offset-y+1 ~ ' ' ~
        $*term.italic('c') ~ self.x+self.offset-x+1);
    
    $*term.print(' ' x self.pad ~ $*term.underline($s));
}

method redraw {
    self.update-header;
    self.redraw-lines;
    self.update-cursor;
}

method redraw-lines {
    $*term.fgcolor(233);
    for 0 ..^ self.height-2 -> $l {
        $*term.move-to(self.pos-x, self.pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print((' ' x self.pad) ~ $line ~ ' ' x self.width-$line.chars);
    }
    $*term.print(' ' x self.width-1);
}

method update-cursor {
    $*term.move-to(self.pos-x + self.x + self.pad, self.pos-y + self.y + 1);
}

method move-to($x is copy, $y is copy, :$view=0, :$redraw is copy = 0) {
    if $view {
        return if $x < self.pad || $x > self.width - self.pad || $y < 1 || $y >= self.height-1;
        $x += self.offset-x - 1;
        $y += self.offset-y - 1;
    }
    if $x.defined {
        if $x < self.offset-x {
            self.offset-x = $x;
            self.x = 0;
            $redraw = 1;
        } elsif $x >= self.offset-x + self.width - self.pad * 2 {
            self.offset-x = $x - (self.width/2).ceiling;
            self.x = (self.width/2).floor;
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
        } elsif $y > self.offset-y + self.height + self.y {
            self.offset-y = $y - (self.height/2).ceiling;
            self.y = (self.height/2).floor;
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
    my $l = ($s2.chars / self.width).ceiling;
    if $l > 6 {
        $l = 6;
        $s2 = $s2.substr(0,self.width * $l - 3) ~ '...';
    }
    $*term.move-to(0, self.offset-y + self.height - $l);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x self.width * $l);
    $*term.move-to(0, self.offset-y + self.height - $l);
    $*term.print($s2);
    $*term.bgcolor(253);
    $!message-lines = $l;
    self.update-cursor;
}

method ask($s) {
    my $s2 = $s;
    $s2 ~~ s:g/\n/ /;
    my $l = ($s2.chars / self.width).ceiling;
    if $l > 6 {
        $l = 6;
        $s2 = $s2.substr(0,self.width * $l - 3) ~ '...';
    }
    $*term.move-to(0, self.offset-y + self.height - $l);
    $*term.bgcolor(88);
    $*term.fgcolor(15);
    $*term.print(' ' x self.width * $l);
    $*term.move-to(0, self.offset-y + self.height - $l);
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
    for self.height - $!message-lines - 1 .. self.height - 1 -> $l {
        $*term.move-to(self.pos-x, self.pos-y + $l + 1);
        my $line = self.line($l);
        $*term.print((' ' x self.pad) ~ $line ~ ' ' x self.width-$line.chars-1);
    }
    $*term.move-to(self.pos-x, self.pos-y + self.height);
    $*term.print(' ' x self.width-1);
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
