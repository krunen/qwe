#perl6
use Test;
use Qwe::Terminal;

my $term = Qwe::Terminal.new;
sub utf8parse($list) {
    $term.parse-utf8-bytes($list.Supply).list;
}

sub test-parse($s) {
    my $s2 = $s;
    $s2 ~~ s:g/<:!L+:!N+:!S+:!P>/./;
    my @parse = utf8parse($s.encode('utf8').list);
    if (@parse eq $s.comb) {
        ok 1, "'$s2' parsed (unconverted)";
    } else {
        is @parse.join('').NFC, $s.NFC, "'$s2' parsed (NFC converted)";
    }
}

ok $term, 'Got Terminal object';
test-parse("ABCD");
test-parse("Æ");
test-parse("Æa");
test-parse("ÆØÅabcæøå");
test-parse("സന്തോഷകരമായ ക്രിസ്മസ്");

is utf8parse(["æ".encode('utf8').list.Slip, 150, 'a'.ord]), ['æ', 150, 'a'], "æ<150>a parsed correcly";

sub eventparse ($list) {
    $term.terminal-events($list.Supply).list;
}

is eventparse(<a b c d>), <a b c d>, "Normal string event-parsed";
is eventparse(«a \e [ 1 A b»), ['a', ['UP'], 'b'], "simple CSI event-parsed";
is eventparse(«a \e [ 2 5 ; 3 ; 5 + R b»), ['a',['CSI-R',25,3,5,'+'],'b'], "complex CSI event-parsed";

is eventparse(«\x7 \x1b \x1b \x0 \x1b a \x1b \x7»), ['^G', '^[', '^@', '@a', '@^G'], 'control/alt codes parsed correctly';

done-testing;
