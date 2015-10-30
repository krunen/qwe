
sub MAIN($string) {
    my $s = '';
    for $string.uc.comb(/<-[AEIOU]>*<[AEIOU]>+/) -> $syl {
        my $chars = '';
	$syl ~~ /(<-[AEIOU]>*)(<[AEIOU]>+)/;
	my ($cons, $vow) = $0, $1;
	if $cons {
	    try {
	        my $name = "DEVANAGARI LETTER {$cons}A";
	        say "looking for $name";
    	        my $ch = EVAL "\"\\c[{$name}]\"";
    	        if $ch {
    	            say "found $ch";
    	            $chars ~= $ch;
                }
            }
            if !$chars && $cons.chars == 2 {
                my @c = $cons.comb;
                my $name = "\\c[DEVANAGARI LETTER {@c[0]}A]\\c[DEVANAGARI SIGN VIRAMA]\\c[DEVANAGARI LETTER {@c[1]}A]";
                say "looking for $name";
                my $ch = EVAL "\"{$name}\"";
                if $ch {
                    say "found $ch";
                    $chars ~= $ch;
                }
            }
	}
	if $cons && $vow ne 'A' {
	    try {
                my $name = "DEVANAGARI VOWEL SIGN {$vow}";
                say "looking for $name";
                my $ch = EVAL "\"\\c[$name]\"";
                if ($ch) {
	            say "found $ch";
	            $chars ~= $ch;
                }
            }
        } elsif !$cons {
	    try {
                my $name = "DEVANAGARI LETTER {$vow}";
                say "looking for $name";
                my $ch = EVAL "\"\\c[$name]\"";
                if ($ch) {
	            say "found $ch";
	            $chars ~= $ch;
                }
            }
        }
        $s ~= $chars;
    }
    say "result: $s";
    say "chars:  {$s.chars}";
}
