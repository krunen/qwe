unit class Qwe::Terminal;
use NativeCall;

has $.cols;
has $.rows;
has $.type;

method init {
  ($!cols,$!rows) = self.getwinsize;
}

method alt-screen {
  run <stty raw -echo>;
  print "\e7\e[?47h\e[?1002h\e[?1h\e[?66h";
  $!type = termtype();
  note "Termtype $!type\r";
}

method normal-screen {
  print "\e[?66l\e[?1l\e[?47l\e[?1002l\e8";
  run <stty cooked echo>;
}

method clear-screen {
  print "\e[2J\e[1;1H";
}

method move-to($x,$y) {
  print "\e[{$y+1};{$x+1}H";
}

method print($s) {
  print $s;
}

method fgcolor(Int $n) {
  print (
    $n <= 7  ?? "\e[{$n+30}m" !!
    $n <= 15 ?? "\e[{$n+82}m" !!
    "\e[38;5;{$n}m");
}

method bgcolor(Int $n) {
  print (
    $n <= 7  ?? "\e[{$n+40}m" !!
    $n <= 15 ?? "\e[{$n+92}m" !!
    "\e[48;5;{$n}m");
}

method underline($s) {
  $s.comb.map({$_ ~ chr(0x35f)}).join;
}

method italic($s is copy) {
    $s ~~ s:g/(<[A..Z]>)/{chr($0.ord - 'A'.ord + 0x1d434)}/;
    $s ~~ s:g/(<[a..z]>)/{chr($0.ord - 'a'.ord + 0x1d482)}/;
    $s;
}

method terminal-events(Supply $utf8-chars) {
    enum _mode <N CSI SS3 OSC M1 M2 M3>; 
    my $state = N;
    my $buf = '';
    my @param;
    my $esc;
    on -> $res {
        $utf8-chars => sub ($char) {
            if $state == N {
                if $char eq "\e" {
                    #note "got ESC";
                    if $esc {
                        $res.emit: '^[';
                        $esc = 0;
                    } else {
                        $esc = 1;
                    }
                } else {
                    if $char ~~ /<:Cc>/ {
                        if $char eq "\x7f" {
                            $res.emit: "^?";
                        } else {
                            $res.emit: ($esc ?? '@^' !! '^') ~ chr($char.ord+64);
                        }
                    } elsif $esc && $char eq '[' {
                        #note "got CSI";
                        $state = CSI;
                    } elsif $esc && $char eq 'O' {
                        #note "got SS3";
                        $state = SS3;
                    } else {
                        #note "got char $char";
                        $res.emit: ($esc ?? '@' !! '') ~ $char;
                    }
                    $esc = 0;
                }
            } elsif $state == CSI {
                if $char eq 'M' {
                    #note "mouse CSI, need 3 more bytes";
                    push @param, $buf if $buf;
                    $state = M1;
                } elsif $char ~~ /<[@..~]>/ {
                    #note "end CSI, $char: {@param} $buf";
                    $state = N;
                    $res.emit: event("CSI-$char", @param.Slip, $buf // ().Slip);
                    $buf = '';
                    @param = ();
                } elsif $char ~~ /<[0..9\ ../]>/ {
                    #note "continue CSI: $char";
                    if $char ~~ /<[\ ../]>/ {
                        push @param, $buf;
                        $buf = '';
                    }
                    $buf ~= $char;
                } elsif $char eq ';' {
                    push @param, $buf;
                    $buf = '';
                } else {
                    # illegal CSI combination
                    $res.emit: ['ILLEGAL', "\e[", @param, $buf, $char].grep(*.defined);
                    @param = ();
                    $buf = '';
                    $state = N;
                }
            } elsif $state == SS3 {
                $res.emit: event("SS3-$char");
                $state = N;
            } elsif $state == M1 {
                push @param, $char; $state = M2;
            } elsif $state == M2 {
                push @param, $char; $state = M3;
            } elsif $state == M3 {
                $res.emit: mouse(@param,$char);
                $buf = '';
                @param = ();
                $state = N;
            }
        }
    }
}

my %events = <
    CSI-A UP  CSI-B DOWN  CSI-C RIGHT  CSI-D LEFT  CSI-F END  CSI-H HOME
    SS3-A UP  SS3-B DOWN  SS3-C RIGHT  SS3-D LEFT  CSI-Z $TAB
    SS3-P F1  SS3-Q F2  SS3-R F3  SS3-S F4
    CSI-~-15 F5  CSI-~-17 F6  CSI-~-18 F7  CSI-~-19 F8
    CSI-~-20 F9  CSI-~-21 F10 CSI-~-23 F11 CSI-~-24 F12
    CSI-~-2  INS CSI-~-3  DEL CSI-~-5 PGUP CSI-~-6 PGDOWN
    CSI-~-1 HOME CSI-~-4  END
    SS3-H HOME SS3-F END
>;

sub event($codes,*@param) {
    my %p;
    my $hasmod;
    my $type;
    if %events{$codes} {
        $type = %events{$codes};
        $hasmod = 1;
    } elsif @param[0] && %events{$codes~'-'~@param[0]} {
        $type = %events{$codes~'-'~@param.shift};
        $hasmod = 1;
    } else {
        $type = $codes;
    }
    if $hasmod && @param {
        my $mb = pop @param;
        my $m = '';
        if    $mb == 2 { $m = '$' }
        elsif $mb == 3 { $m = '@' }
        elsif $mb == 4 { $m = '@$' }
        elsif $mb == 5 { $m = '^' }
        elsif $mb == 6 { $m = '^$' }
        elsif $mb == 7 { $m = '@^' }
        elsif $mb == 8 { $m = '@^$' }
        $type = $m~$type;
    }
    @param.shift if @param && @param[0] == 1;
    [$type,@param.Slip];
}

sub mouse(*@p) {
    my ($b,$x,$y) = @p[0].ord-32, @p[1].ord-32, @p[2].ord-32;
    my $but;
    if $b +& 3 == 3 {
        $but = -1;
    } else {
        $but = $b +& 3 + ($b +& 64 ?? 3 !! 0) + 1;
    }
    state $prevmb;
    if ($but == -1) {
        return ['MOUSEUP',:b($prevmb),:x($x),:y($y)];
    } elsif $b +& 32 {
        return ['MOUSEMOVE', :b($but),:x($x),:y($y)];
    } else {
        $prevmb = $but;
        return ['MOUSEDN',:b($but),:x($x),:y($y)];
    }
}


method stdin-bytes {
    supply {
        loop {
            emit $*IN.read(1)[0];
        }
    }
}


method parse-utf8-bytes(Supply $bytes) {
    my @bytes;
    my $bytenum;
    on -> $res {
        $bytes => sub ($byte) {
            #note "got byte {$byte.gist}";
            if !($byte +& 0b10000000) {
                # note "got ascii $byte";
                if @bytes {
                    # note "prev bytes were wrong: @bytes";
                    $res.emit($_) for @bytes;
                    @bytes = ();
                    $bytenum = 0;
                }
                $res.emit(chr($byte));
            } elsif $bytenum {
                # note "got following byte $byte";
                push @bytes, $byte;
                if $byte +& 0b11000000 == 0b10000000 {
                    if @bytes == $bytenum {
                        # note "emitting char";
                        $res.emit(utf8_char(@bytes));
                        @bytes = ();
                        $bytenum = 0;
                    }
                } else {
                    # note "got wrong byte $byte";
                    $res.emit($_) for @bytes;
                    @bytes = ();
                    $bytenum = 0;
                }
            } else {
                # note "got first byte $byte";
                push @bytes, $byte;
                $bytenum = utf8_byte_count($byte);
                if !$bytenum {
                    # note "not utf8!";
                    $res.emit($byte);
                    @bytes = ();
                }
            }
        }
    }
}

sub utf8_byte_count($first-byte) {
    return 2 if $first-byte +& 0b11100000 == 0b11000000;
    return 3 if $first-byte +& 0b11110000 == 0b11100000;
    return 4 if $first-byte +& 0b11111000 == 0b11110000;
    return 5 if $first-byte +& 0b11111100 == 0b11111000;
    return 6 if $first-byte +& 0b11111110 == 0b11111100;
}

sub utf8_char(@b) {
    chr(do given +@b {
        when 2 { @b[0] +& 31 +< 6   +  @b[1] +& 63 }
        when 3 { @b[0] +& 15 +< 12  +  @b[1] +& 63 +< 6   +  @b[2] +& 63 }
        when 4 { @b[0] +& 7  +< 18  +  @b[1] +& 63 +< 12  +  @b[2] +& 63 +< 6  +  @b[3] +& 63 }
        when 5 { @b[0] +& 3  +< 24  +  @b[1] +& 63 +< 18  +  @b[2] +& 63 +< 12 +  @b[3] +& 63 +< 6  +  @b[4] +& 63 }
        when 6 { @b[0] +& 1  +< 30  +  @b[1] +& 63 +< 24  +  @b[2] +& 63 +< 18 +  @b[3] +& 63 +< 12 +  @b[4] +& 63 +< 6  +  @b[5] +& 63 }
    })
}

my class _winsize is repr('CStruct') {
    has int16 $.row;
    has int16 $.col;
    has int16 $.xpixel;
    has int16 $.ypixel;
}
sub ioctl(int32, int32, _winsize) returns int32 is native {*};

method getwinsize {
    my $p := _winsize.new;
    my $i = ioctl(1, 0x5413, $p);
    return ($p.col,$p.row);
}

my %csi_c_id = (
    "\e[?1;2c" => 'konsole', #VT100 with advanced video
    "\e[?64...c" => 'xterm', #VT420
    "\e[?6c" => 'putty', #VT102
    "\e[?62;9c" => 'vte', #(gnome-terminal, xfce4-terminal) VT220
);
                                
sub termtype {
    print "\e[c";
    my $id = '';
    loop { my ($c) = $*IN.read(1)[0].chr; $id ~= $c; last if $c eq 'c' };
    return 'xterm' if $id ~~ /^ "\e[?64;"/;
    return %csi_c_id{$id} || die "Can't id term from {$id.perl}";
}
