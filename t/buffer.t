#perl6
use Test;
use Qwe::Buffer;

my $buf = Qwe::Buffer.new(:name('<new buffer>'));
ok $buf, 'Buffer object created';
is $buf.name, '<new buffer>', 'Name is <new buffer>';
is $buf.numlines, 0, 'Buffer has 0 lines';

$buf.insert-chars(0,0,'abcdefgh');
is $buf.numlines, 1, 'Line is added after insert-chars';
is $buf.line(0), 'abcdefgh', 'Text in line 1 in correct';

$buf.set-chars(6,0,'GHIJ');
is $buf.line(0), 'abcdefGHIJ', 'set-chars can extend line';

dies-ok {$buf.load-file('this-file-doesnt-exist')}, 'load-file dies with nonexistant file';

lives-ok {$buf.load-file('t/testfile.txt')}, 'load-file of testfile.txt is successful';
is $buf.numlines, 33, 'buf now has 33 lines';
is $buf.filename, 't/testfile.txt', 'buf filename is filename';
is $buf.name, 'testfile.txt', 'buf name is basename of filename';
is $buf.line(24), 'Eala byrnwiga!', 'line 25 is correct after load-file';

$buf.meta(0,0).<test> = 1;

note $buf.meta(0,0);

done-testing;
