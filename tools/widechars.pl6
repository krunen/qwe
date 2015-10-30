#!/usr/bin/env perl6

my $prev = 0;
my $start = 0;
my $i = 0;
my @ranges;
for "EastAsianWidth.txt".IO.lines -> $line {
    if $line ~~ /^ (<[0..9A..F]>+) [ '..' (<[0..9A..F]>+) ]? ';W' / {
        my $st = :16(~$0);
        my $en = :16($1 ?? ~$1 !! ~$0);
        #say "#   $st .. $en";
        if $st > $prev + 1 {
            #say "$start .. $prev" if $start;
            @ranges.push([$start,$prev]) if $start;
            $start = $st;
        }
        $prev = $en;
        #last if $i++ > 4;
    }
}
#say "$start .. $prev";
@ranges.push([$start,$prev]);

say '<[' ~ @ranges.map({ $_[0] == $_[1] ?? "\\c[{$_[0]}]" !! "\\c[{$_[0]}]..\\c[{$_[1]}]" }).join("\n        ") ~ ']>';
