unit class Qwe;
use Qwe::Terminal;

has $!term;

method start {

    $!term = Qwe::Terminal.new;
    $!term.init;
    $!term.alt-screen;
    LEAVE { $!term.normal-screen }

    $!term.bgcolor(252);
    $!term.clear-screen;

    $!term.fgcolor(0);
    #print "\r\n";
    my $logo = $!term.italic("Qwe");
    my $s = sprintf("%-30.30s" ~ (' ' x $!term.cols-52) ~ "%20.20s",
        "lib/Qwe/Terminal.pm", $!term.italic('l') ~ "43 " ~ $!term.italic('c') ~ "25 I M  $logo");
    print " ";
    print $!term.underline($s);
    print "\r\n";

    sub col($n) { $n <= 7  ?? "\e[{$n+30}m" !! $n <= 15 ?? "\e[{$n+82}m" !! "\e[38;5;{$n}m" }
    sub norm {col(238)}
    sub blue {col(24)}
    sub blue2 {col(31)}
    sub red {col(88)}
    sub green {col(28)}
    
    print " {norm}use {blue}Qwe::Buffer{norm};\r\n";
    print " {norm}class {blue}MyClass {norm}\{\r\n";
    print " {red }    # Testing testing\r\n";
    print " {norm}    has {blue2}\$!do-test{norm} = {green}\"Should I test or should I not?\"{norm};\r\n";
    print " {norm}    \r\n";
    print "\r\n" x 15;
    $!term.fgcolor(0);
    print " " ~ $!term.underline(sprintf("%-40.40s%20.20s",
        "t/mytest1.t", $!term.italic('l') ~ "43 " ~ $!term.italic('c') ~ "25 I M  $logo")) ~
        " " ~ $!term.underline(sprintf("%-40.40s%20.20s",
        "lib/Qwe/View.pm", $!term.italic('l') ~ "43 " ~ $!term.italic('c') ~ "25 I M  $logo"))
         ~ "\r\n";

    print " {norm}use {blue}Test{norm};\r\n";
    print " {red}# whatever shall we do?\r\n";
    print "\e[23;62H" ~ " {norm}class {blue}Qwe::View{norm} \{";
    print "\e[24;62H" ~ " {norm}    has {blue2}\$!buffer{norm};";

    my $keys = $!term.terminal-events($!term.parse-utf8-bytes($!term.stdin-bytes));
    #say "Start...\r";
    $keys.tap( -> $x {
        return if $x eq 'q';
        #say "got {$x.gist}\r";
    });

}
