use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use JSON::String;

sub expected_error {
    my $expected = shift;

    my(undef, $file, $line) = caller();
    $line--;
    my $expected_error = quotemeta(sprintf('%s at %s line %s.',
                                    $expected, $file, $line));
    return qr(^$expected_error$);
}

subtest 'from string' => sub {
    plan tests => 2;

    my $string = '[1]';
    my $obj = JSON::String->new($string);
    ok($obj, 'new');

    $obj->[0] = 2;
    is($string, '[2]', 'changed value');
};

subtest 'from array elt' => sub {
    my $array = ['[1]'];
    my $obj = JSON::String->new($array->[0]);
    ok($obj, 'new');

    $obj->[0] = 2;
    is_deeply($array,
            ['[2]'],
            'changed value');
};

subtest 'from hash value' => sub {
    my $hash = { key => '[1]' };
    my $obj = JSON::String->new($hash->{key});
    ok($obj, 'new');

    $obj->[0] = 2;
    is_deeply($hash,
            { key => '[2]' },
            'changed value');
};

subtest 'errors' => sub {
    plan tests => 5;

    throws_ok { JSON::String->new() }
        expected_error 'Expected string, but got <undef>',
        'no args';

    throws_ok { JSON::String->new('') }
        expected_error 'Expected non-empty string',
        'empty string';

    throws_ok { JSON::String->new(q(["1"])) }
        expected_error 'String is not writable',
        'non-writable string';

    throws_ok { my $str = []; JSON::String->new($str) }
        expected_error 'Expected plain string, but got reference',
        'ref';

    throws_ok { my $str = 'bad json'; JSON::String->new($str) }
        qr(malformed JSON string),
        'bad json';
};
