use strict;
use warnings;

package JSON::InPlace;

use Carp qw(croak);
use JSON;
use Symbol;
use overload '@{}' => '_arrayref',
             '%{}' => '_hashref',
             'bool' => sub { 1 };

use JSON::InPlace::ARRAY;
use JSON::InPlace::HASH;

sub new {
    my($class, $ref) = @_;

    my $data = _validate_string_ref($ref);
    my $self = _construct_object($class, $ref, $data);
    return bless $self, $class;
}

sub _construct_object {
    my($invocant, $ref, $data) = @_;

    my $self = Symbol::gensym();
    my $inplace_obj = ref($invocant)
                        ? $invocant
                        : $self;

    if (ref($data) eq 'ARRAY') {
        *$self = [];
        tie @{*{$self}{ARRAY}}, 'JSON::InPlace::ARRAY', data => $data, inplace_obj => $inplace_obj;
    } else {
        *$self = {};
        tie %{*{$self}{HASH}}, 'JSON::InPlace::HASH', data => $data, inplace_obj => $inplace_obj;
    }

    *$self = $ref;
    return $self;
}

{
    my $codec = JSON->new->canonical;
    sub codec {
        shift;
        if (@_) {
            $codec = shift;
        }
        return $codec;
    }
}

sub encode {
    my $self = shift;

    my $it = *{$self}{ARRAY} || *{$self}{HASH};

    my $encoded = $self->codec->encode($it);
    my $ref = *{$self}{SCALAR};
    $$ref = $encoded;
}

sub _validate_string_ref {
    my $ref = shift;

    unless (ref $ref eq 'SCALAR') {
        my $error = 'Expected SCALAR ref, but got ';
        if (! defined $ref) {
            $error .= '<undef>';
        } elsif (! length $ref) {
            $error .= '<empty string>';
        } elsif (! ref $ref) {
            $error .= $ref;
        } else {
            $error .= ref($ref) . ' ref';
        }
        croak $error;
    }
    unless (length $$ref) {
        croak('SCALAR ref must point to a non-empty string');
    }
    my $error = do {
        local $@;
        eval { $$ref .= '' };
        $@;
    };
    if ($error) {
        croak('SCALAR ref is not writable');
    }

    my $data = codec()->decode($$ref);

    unless (ref($data) eq 'ARRAY' or ref($data) eq 'HASH') {
        croak('Expected JSON string to decode into ARRAY or HASH ref, but got ', ref($data));
    }
    return $data;
}

sub _arrayref {
    my $self = shift;
    return *{$self}{ARRAY};
}

sub _hashref {
    my $self = shift;
    return *{$self}{HASH};
}

1;
