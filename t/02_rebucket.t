use strict;
use warnings;
use Test::More tests => 12;
use Algorithm::ConsistentHash::JumpHash;

my $DEFAULT_NUM_KEYS = 100_000;

# default threshold could be scaled to the number of keys
my $DEFAULT_THRESHOLD = 0.001;

my $is_consistent = sub {
    my ( $from_buckets, $to_buckets, $num_keys, $first_key, $threshold ) = @_;

    $from_buckets ||= 4;
    $to_buckets   ||= $from_buckets + 1;
    $num_keys     ||= $DEFAULT_NUM_KEYS;
    $threshold    ||= $DEFAULT_THRESHOLD;
    $first_key    ||= 0;

    my $key_limit = ( $first_key + $num_keys );

    my $ideal;
    if ( $from_buckets < $to_buckets ) {
        $ideal = ( $from_buckets * 1.0 ) / ( $to_buckets * 1.0 );
    }
    else {
        $ideal = ( $to_buckets * 1.0 ) / ( $from_buckets * 1.0 );
    }
    my $stayed = 0;
    my $moved  = 0;
    my ( $key, $first, $next );
    for ( $key = $first_key ; $key < $key_limit ; ++$key ) {
        $first = Algorithm::ConsistentHash::JumpHash::jumphash_numeric( $key,
            $from_buckets );
        $next = Algorithm::ConsistentHash::JumpHash::jumphash_numeric( $key,
            $to_buckets );
        if ( $first == $next ) {
            ++$stayed;
        }
        else {
            ++$moved;
        }
    }
    my $ratio = ( $stayed * 1.0 ) / ( ( $moved + $stayed ) * 1.0 );
    my $diff = ( $ratio >= $ideal ) ? $ratio - $ideal : $ideal - $ratio;
    my $fail = ( $diff < $threshold ) ? 0 : 1;

    my $msg = <<"EOL";

        tested $num_keys keys ($first_key <= $key_limit)
        with $from_buckets buckets and $to_buckets buckets
        $stayed stayed in the same bucket
        $moved moved buckets
        for a ratio of $ratio, ideal would be $ideal
        ratio diff from ideal: $diff, threshold: $threshold

EOL

    is( $fail, 0, "FAIL: diff == $diff, expected < $threshold\n$msg" );
};

# $is_consistent->(
#    $from_buckets, $to_buckets, $num_keys, $first_key, $threshold
# );
$is_consistent->( 1,  2 );
$is_consistent->( 2,  3 );
$is_consistent->( 3,  7 );
$is_consistent->( 4,  8 );
$is_consistent->( 5,  11 );
$is_consistent->( 6,  12 );
$is_consistent->( 7,  13 );
$is_consistent->( 8,  16 );

# going to fewer buckets
$is_consistent->( 16, 8 );
$is_consistent->( 5, 4 );
$is_consistent->( 3, 2 );

# lager number of keys, a higher threshold, over keys in a range above 2^32
$is_consistent->( 4, 5, 10_000_000, 2**34, 0.00001 );
