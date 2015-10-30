#perl6
use Test;
use Qwe::Buffer;
use Qwe::View;

my $buf = Qwe::Buffer.new();
lives-ok {$buf.load-file('t/testfile.txt')}, 'testfile loaded';

my $view = $buf.new-view(:width(5), :height(5));
is $buf, $view.buffer, "View's buffer is \$buf";
is $view.offset-x, 0, 'offset-x is 0';
is $view.width, 5, 'width is 5';

is $view.line(0), 'Oft h', 'line 0 is correct';
$view.offset-x = 10;
is $view.line(0), 'haga ', 'line 0 with offset-x 10 is correct';

$view.offset-y = 32;
$view.offset-x = 1;
is $view.line(0), 'el bi', 'Last line in file is correct after moving window';
is $view.line(1), '', 'Getting line beyond end of file is ok';

done-testing;
