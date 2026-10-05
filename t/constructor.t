use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use JSON::String;

# Detect the line number reporting behaviour of this version of perl
our $use_block_end;
BEGIN {
    sub X { my (undef, undef, $line) = caller;
                $use_block_end++ if ($line != shift); }
    X __LINE__, # $use_block_end = 0
    sub { }     # $use_block_end = 1
};

 sub expected_error {
     my $expected = shift;

    my(undef, $file, $line) = caller();
    $line-- if $use_block_end;
    my $expected_error = quotemeta(sprintf('%s at %s line %s',
                                    $expected, $file, $line));
    return qr(^$expected_error);
}

subtest 'from string' => sub {
    plan tests => 2;

    my $string = '[1]';
    my $obj = JSON::String->tie($string);
    ok($obj, 'tie');

    $obj->[0] = 2;
    is($string, '[2]', 'changed value');
};

subtest 'from array elt' => sub {
    my $array = ['[1]'];
    my $obj = JSON::String->tie($array->[0]);
    ok($obj, 'tie');

    $obj->[0] = 2;
    is_deeply($array,
            ['[2]'],
            'changed value');
};

subtest 'from hash value' => sub {
    my $hash = { key => '[1]' };
    my $obj = JSON::String->tie($hash->{key});
    ok($obj, 'tie');

    $obj->[0] = 2;
    is_deeply($hash,
            { key => '[2]' },
            'changed value');
};

subtest 'errors' => sub {
    plan tests => 4;

    throws_ok { JSON::String->tie() }
        expected_error 'Expected string, but got <undef>',
        'no args';

    throws_ok { JSON::String->tie('') }
        expected_error 'Expected non-empty string',
        'empty string';

    throws_ok { my $str = []; JSON::String->tie($str) }
        expected_error 'Expected plain string, but got reference',
        'ref';

    throws_ok { my $str = 'bad json'; JSON::String->tie($str) }
        qr(malformed JSON string),
        'bad json';
};
