unit class Qwe;
use Qwe::Terminal;
use Qwe::Buffer;
use Qwe::View;
use Qwe::Window;

has $!term;
has @!buffers;
has @!views;
has $!current-window;
has @!windows;

method start(@filenames?) {
    $!term = Qwe::Terminal.new;
    $!term.init;
    $!term.alt-screen;
    $!term.bgcolor(253);
    $!term.clear-screen;
    my $*term = $!term;

    END { $!term.normal-screen }
    CATCH { default { $!term.normal-screen; die $_.gist } }

    if @filenames {
        for @filenames -> $fn {
            my $buf = Qwe::Buffer.new(:qwe(self));
            $buf.load-file('t/testfile.txt');
            @!buffers.push($buf);
        }
    } else {
        # Project mode, find files in project
        if "META6.json".IO.e {
            # Perl 6 project
            for (find-files("lib", rx/\.pm6?$/),
                 find-files("bin", rx/<[a..z]>$/),
                 find-files("t",   rx/t$/)).flat
                -> $f {
                my $buf = Qwe::Buffer.new(:qwe(self));
                $buf.load-file($f);
                @!buffers.push($buf);
            }
        }
    }

    # Create views for files
    @!views.push(Qwe::View.new(:buffer($_), :pad(1))) for @!buffers;

    # Create window with first file
    $!current-window = Qwe::Window.new(:width($!term.cols), :height($!term.rows), :pos-x(0), :pos-y(0), :pad(1));
    $!current-window.set-view(@!views[0]);
    @!windows.push($!current-window);
    $!current-window.redraw;

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
                when '^Q' {
                    return;
                }
                default {
                    if $!current-window {
                        $!current-window.process-event($code,%param);
                    }
                }
            }
            CATCH { default { $!current-window.message($_.gist) } }
        }
    }
}

sub find-files($dir, $re) {
    my @res; my @sd;
    for $dir.IO.dir -> $e {
        if $e.f && $e ~~ $re {
            push @res, $e;
        }
        if $e.d {
            @sd.append(find-files($e, $re));
        }
    }
    return (@res,@sd).flat;
}
