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

# Undo

$buf.clear();
is $buf.numlines, 0, "Buf.clear deletes lines";
is $buf.name, '<new buffer>', "Buf.clear deletes name";

$buf.insert-chars-undo(0,0,"Some chars");
is $buf.line(0), "Some chars", "insert-chars-undo inserts the chars";
$buf.undo();
is $buf.line(0), '', "undo removes the inserted chars";

$buf.insert-chars-undo(0,0,"ABC");
$buf.insert-chars-undo(0,0,"123");
$buf.delete-chars-undo(3,0,2);
is $buf.line(0), "123C", "insert,insert,delete gives correct string";
$buf.undo();
is $buf.line(0), "123ABC", "undo gives correct string";
$buf.undo();
is $buf.line(0), "ABC", "another undo gives correct string";

$buf.insert-chars-undo(0,1,"Another line");
$buf.delete-line-undo(0);
is $buf.numlines, 1, "delete-line-undo deletes";

#$buf.meta(0,0).<test> = 1;
#note $buf.meta(0,0);

done-testing;
