unit class Qwe;
use Qwe::Terminal;
use Qwe::Buffer;
use Qwe::View;
use fatal;

has $!term;

method start {
    $!term = Qwe::Terminal.new;
    $!term.init;
    $!term.alt-screen;
    $!term.bgcolor(253);
    $!term.clear-screen;
    END { $!term.normal-screen }
    CATCH { default { $!term.normal-screen; die $_.perl } }

    my $*term = $!term;

    my $buf = Qwe::Buffer.new(:qwe(self));
    $buf.load-file('t/testfile.txt');
    
    my $view = Qwe::View.new(:buffer($buf), :width($!term.cols), :height($!term.rows), :pad(1));
    $view.redraw;

    #sub col($n) { $n <= 7  ?? "\e[{$n+30}m" !! $n <= 15 ?? "\e[{$n+82}m" !! "\e[38;5;{$n}m" }
    #sub norm {col(238)}
    #sub blue {col(24)}
    #sub blue2 {col(31)}
    #sub red {col(88)}
    #sub green {col(28)}
    
    my $term-events = $!term.terminal-events($!term.parse-utf8-bytes($!term.stdin-bytes));

    react {
        whenever $term-events -> $event {
            my $code = $event[0];
            my %param = grep {$_ ~~ Pair}, @$event;
            given $code {
                when '^Q' | 'q'  { return }
                when 'UP'        { $view.move(0,-1) }
                when 'DOWN'      { $view.move(0,1) }
                when 'LEFT'      { $view.move(-1,0) }
                when 'RIGHT'     { $view.move(1,0) }
                when 'HOME'
                   | '^A'        { $view.move-to(0,Nil) }
                when 'END'
                   | '^E'        { $view.move-to($view.line-length,Nil) }
                when '^L'        { $view.redraw }
                when 'MOUSEUP'   { $view.move-to(%param<x>-1, %param<y>-1, :view) }
                when 'MOUSEDN'   { }
                when 'MOUSEMOVE' { }
                default {
                    $view.message("unknown event $event");
                }
            }
            CATCH { default { $view.message($_.gist) } }
        }
    }
}
