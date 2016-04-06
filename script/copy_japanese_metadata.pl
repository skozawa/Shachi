use strict;
use warnings;
use utf8;
use Data::Dumper;
use Shachi::Database;
use Shachi::Service::Language;

$ENV{PLACK_ENV} ||= 'development';

my $db = Shachi::Database->new;

my $english = Shachi::Service::Language->find_by_code(db => $db, code => 'eng');
die 'Not Found english' unless $english;
my $japanese = Shachi::Service::Language->find_by_code(db => $db, code => 'jpn');
die 'Not Found japanese' unless $japanese;

my $ids = [
    4391, 4248, 4256, 4264, 4226, 4244, 4211, 3415, 4326, 4228, 3850,
    3826, 3374, 3849, 4213, 3381, 4216, 4252, 3366, 4212, 4259, 4245,
    4235, 4243, 4218, 4257, 3115, 3794, 4241, 4343, 4254, 4238, 4250,
    3856, 4249, 4217, 4341, 3858, 4239, 4236, 4253, 3853, 3806, 4314,
    4237, 4214, 4325, 4342, 4251, 3804, 3445, 4215, 4316, 4246, 4242,
    4255, 4310, 3558, 4313,  790, 4247, 4344, 4227, 4240, 4390, 3555,
    3651, 4258, 4263, 3838,
];

foreach my $id ( @$ids ) {
    warn $id;
    my $metadata_list = $db->shachi->table('resource_metadata')->search({
        resource_id => $id,
        language_id => $japanese->id,
    })->list;
    next unless @$metadata_list;

    my $data = [ map {
        +{
            resource_id => $_->resource_id,
            metadata_name => $_->metadata_name,
            value_id      => $_->value_id,
            content       => $_->content,
            description   => $_->description,
            language_id   => $english->id,
        }
    } @$metadata_list ];

    my $metadata_list = $db->shachi->table('resource_metadata')->search({
        resource_id => $id,
        language_id => $english->id,
    })->delete;
    $db->shachi->table('resource_metadata')->insert_multi($data);
}
