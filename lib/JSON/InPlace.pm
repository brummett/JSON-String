use strict;
use warnings;

package JSON::InPlace;

use Carp qw(croak);
use JSON;

use JSON::InPlace::ARRAY;
use JSON::InPlace::HASH;

sub new {
    my($class, $ref) = @_;

    my $data = _validate_string_ref($ref);
    return _construct_object($data, $ref);
}

sub _construct_object {
    my($data, $str_ref, $encoder) = @_;

    return $data unless ref $data;

    $encoder = _create_encoder($data, $str_ref) unless $encoder;

    my $self;
    if (ref($data) eq 'ARRAY') {
        $self = [];
        tie @$self, 'JSON::InPlace::ARRAY', data => $data, encoder => $encoder;
    } elsif (ref($data) eq 'HASH') {
        $self = {};
        tie %$self, 'JSON::InPlace::HASH', data => $data, encoder => $encoder;
    } else {
        croak('Cannot handle '.ref($data). ' reference');
    }

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

sub _create_encoder {
    my($data, $str_ref) = @_;

    my $codec = codec;
    return sub {
        $$str_ref = $codec->encode($data);
    };
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

1;
