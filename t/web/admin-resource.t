package t::Shachi::Web::Admin::Resource;
use t::test;
use JSON::XS;
use Shachi::Database;
use Shachi::Model::Resource;
use Shachi::Service::Resource;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::Admin::Resource';
}

sub update_status : Tests {
    subtest 'update normally' => sub {
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/status", {
            status => STATUS_PRIVATE,
        });
        my $res_json = decode_json($mech->res->content);
        is $res_json->{status}, STATUS_PRIVATE;

        my $db = Shachi::Database->new;
        my $updated_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        is $updated_resource->status, STATUS_PRIVATE;
    };
}

sub update_edit_status : Tests {
    subtest 'update normally' => sub {
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/edit_status", {
            edit_status => EDIT_STATUS_COMPLETE,
        });
        my $res_json = decode_json($mech->res->content);
        is $res_json->{edit_status}, EDIT_STATUS_COMPLETE;

        my $db = Shachi::Database->new;
        my $updated_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        is $updated_resource->edit_status, EDIT_STATUS_COMPLETE;
    };
}
