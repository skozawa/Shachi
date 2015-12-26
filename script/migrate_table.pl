use strict;
use warnings;
use utf8;

use DBIx::Lite;
use Data::Dumper;
use List::MoreUtils qw(any);

# shachi_old:
#  annotators, languages, options, resources, scheme
# shachi:
#  annotator, language, option, metadata, resource, resource_metadata

my $dbix_old = DBIx::Lite->connect(
    "dbi:mysql:dbname=shachi_old;host=localhost",
    "root", "", { mysql_enable_utf8 => 1 },
);

my $dbix_new = DBIx::Lite->connect(
    "dbi:mysql:dbname=shachi;host=localhost",
    "root", "", { mysql_enable_utf8 => 1 },
);

migrate_annotators($dbix_old, $dbix_new);
migrate_options($dbix_old, $dbix_new);
migrate_languages($dbix_old, $dbix_new);
migrate_scheme($dbix_old, $dbix_new);
migrate_resources($dbix_old, $dbix_new);
# migrate_title_list($dbix_old, $dbix_new);

# 旧annotatorsテーブルの要素を新annotatorテーブルに移行
sub migrate_annotators {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate Annotators";

    my @annotators = $dbix_old->table('annotators')->all;
    foreach my $annotator ( @annotators ) {
        my $data = $annotator->{data};
        $data->{mail} =~ s/^\s+//g;
        $dbix_new->table('annotator')->insert({
            id => $data->{id},
            name => $data->{name},
            mail => $data->{mail},
            organization => $data->{organization},
        });
    }
}

# 旧optionsテーブルの要素を新metadata_valueテーブルに移行
sub migrate_options {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate Options";

    my @options = $dbix_old->table('options')->all;
    foreach my $option ( @options ) {
        my $data = $option->{data};
        $dbix_new->table('metadata_value')->insert({
            id => $data->{id},
            value_type => $data->{class},
            value => $data->{value},
        });
    }
}

# 旧languagesテーブルの要素を新languageテーブルに移行
sub migrate_languages {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate Languages";

    my @languages = $dbix_old->table('languages')->all;
    foreach my $language ( @languages ) {
        my $data = $language->{data};
        my $value = $dbix_new->table('metadata_value')->insert({
            value_type => "language",
            value => $data->{name},
        });
        $dbix_new->table('language')->insert({
            id => $data->{id},
            code => $data->{code},
            name => $data->{name},
            area => $data->{area},
            value_id => $dbix_new->dbh->last_insert_id(undef, undef, 'metadata_value', undef),
        });
    }
}


# 旧schemeテーブルの要素を新metadataテーブルに移行
sub migrate_scheme {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate Scheme";

    my @items = $dbix_old->table('scheme')->all;
    foreach my $item ( @items ) {
        my $data = $item->{data};
        $dbix_new->table('metadata')->insert({
            id => $data->{id},
            name => $data->{name},
            label => $data->{label},
            order_num => $data->{id} * 10, # あとから追加しやすいように10倍しておく
            shown => 1,
            multi_value => $data->{multi_value} ? 1 : 0,
            input_type => $data->{type},
            value_type => $data->{type} eq 'language' ? 'language' : $data->{options},
            color => $data->{color},
        });
    }

    # 旧metadata要素もshown=0にして追加しておく
    my $data = [
        {
            name => 'contributor_motherTongue',
            label => 'contributor.attribute.motherTongue',
            order_num => 201,
            shown => 0,
            multi_value => 1,
            input_type => 'select',
            value_type => 'motherTongue',
            color => '#ffcccc',
        },
        {
            name => 'contributor_dialect',
            label => 'contributor.attribute.dialect',
            order_num => 202,
            shown => 0,
            multi_value => 1,
            input_type => 'select',
            value_type => 'dialect',
            color => '#ffcccc',
        },
        {
            name => 'contributor_level',
            label => 'contributor.attribute.level',
            order_num => 203,
            shown => 0,
            multi_value => 1,
            input_type => 'select',
            value_type => 'level',
            color => '#ffcccc',
        },
        {
            name => 'contributor_age',
            label => 'contributor.attribute.age',
            order_num => 204,
            shown => 0,
            multi_value => 1,
            input_type => 'select',
            value_type => 'age',
            color => '#ffcccc',
        },
        {
            name => 'contributor_gender',
            label => 'contributor.attribute.gender',
            order_num => 205,
            shown => 0,
            multi_value => 1,
            input_type => 'select',
            value_type => 'gender',
            color => '#ffcccc',
        },
    ];

    foreach my $item ( @$data ) {
        $dbix_new->table('metadata')->insert($item);
    }
}

# 旧resourcesテーブルの要素を新resourceテーブルとresource_metadataに移行
sub migrate_resources {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate Resources";

    my $status_map = {
        new => 'new',
        ed => 'editing',
        tipp => 'pending',
        revised => 'revised',
        inspected => 'proofed',
        inspected2 => 'proofed',
    };

    my $jpn_language_id = 2726;
    my $eng_language_id = 1819;

    my @metadata = $dbix_new->table('metadata')->all;

    my @resources = $dbix_old->table('resources')->all;
    foreach my $resource ( @resources ) {
        my $data = $resource->{data};
        my $status = $data->{is_public} ? 'public' :
            $data->{identifier} =~ /,LDC/ ? 'limited_by_LDC' :
                $data->{identifier} =~ /,ELRA/ ? 'limited_by_ELRA' : 'private';
        $dbix_new->table('resource')->insert({
            id => $data->{id},
            shachi_id => $data->{shachi_id},
            status => $status,
            annotator_id => $data->{annotator},
            edit_status => $status_map->{$data->{status}},
            created => $data->{created},
            modified => $data->{modified},
        });

        foreach my $meta ( @metadata ) {
            my $value = $data->{$meta->{data}->{name}} or next;

            # 誤っていそうなデータを個別に修正
            if ( $value eq 'childchildren between the ages of six and twelve,' ) {
                $value = 'child,children between the ages of six and twelve'
            } elsif ( $value eq 'native,|non_native(English learners),' ) {
                $value = 'native,|non_native,English learners';
            } elsif ( $value eq 'adult,|children,' ) {
                $value = 'adult,|child,';
            }

            my @sample_ids = (
                95,380,381,383,385,386,387,392,393,394,398,
                402,404,405,406,407,408,409,415,568,576,580,
                598,622,663,751,752,769,778,780,783,786,810,
                818,821,825,859,865,936,937,939,955,968,969,
                988,995,1002,1036,1042,1237,1616,1674,1675,1687,
                1688,1689,1690,1691,1696,1697,1698,1703,1705,1711,
                1712,3107,3114,3119,4047,4361,4362,4363,4370,4373,
                4374,4377,4378,4380,4381,4382,4385,4387
            );
            # \|, "| を|で区切られないように置換
            $value =~ s/\\\|/!!BNSDLSIFNELS!!/g;
            $value =~ s/\"\|/!!AFELISNFELIS!!/g;
            # type_sample, type_annotationSample で|で区切るとおかしいデータがあるので対処
            if ( $meta->{data}->{name} eq 'type_sample' ||
                     $meta->{data}->{name} eq 'type_annotationSample' ) {
                # 1711の言語資源は |,\d を置換
                $value =~ s/\|,(\d)/|/g if $data->{id} == 1711;
                if ( any { $data->{id} == $_ }  @sample_ids ) {
                    $value =~ s/\|,//g;
                } else {
                    $value =~ s/\|,/|||QEUSNEIAN||,/g;
                }
            } else {
                $value =~ s/\|/|||QEUSNEIAN||/g;
            }
            foreach my $item ( split /\|\|\|QEUSNEIAN\|\|/, $value ) {
                $item =~ s/\!\!BNSDLSIFNELS\!\!/|/g;
                $item =~ s/\!\!AFELISNFELIS\!\!/"|/g;
                my ($val, @texts) = split /,/, $item;
                my $text = join ",", @texts;
                next unless $val || $text;
                $text =~ s/^\s+// if $text;

                my ($value_id, $content, $desc) = _meta_value($dbix_new, $meta, $val, $text);

                # 追加要素がない場合はスキップ
                if ( !$value_id && !$content && !$desc ) {
                    print $data->{id}, "\t", $meta->{data}->{id}, "\t", $item, "\n";
                    next;
                }

                $dbix_new->table('resource_metadata')->insert({
                    resource_id => $data->{id},
                    metadata_name => $meta->{data}->{name},
                    language_id => $eng_language_id,
                    value_id => $value_id,
                    $content ? (content => $content) : (),
                    $desc ? (description => $desc) : (),
                });
            }
        }
    }
}

# resource_metadataの要素を作成
sub _meta_value {
    my ($dbix_new, $meta, $val, $text) = @_;
    my $input_type = $meta->{data}->{input_type};
    if ( $input_type eq 'text' || $input_type eq 'textarea' ) {
        return (0, $text);
    } elsif ( $input_type eq 'select' || $input_type eq 'select_only' || $input_type eq 'relation') {
        my $val_id = !$val ? 0 : do {
            my $mv = $dbix_new->table('metadata_value')->search({
                value_type => $meta->{data}->{value_type},
                value => $val,
            })->single;
            $mv && $mv->{data}->{id};
        };
        # warn $val, "\t", $meta->{data}->{input_type}, "\t", $meta->{data}->{class} || '' if !defined $val_id && $meta->{data}->{class} ne 'motherTongue' && $meta->{data}->{class} ne 'con_role';
        return ($val_id || 0, undef, $text);
    } elsif ( $input_type eq 'language' ) {
        my $val_id = !$val ? 0 : do {
            my $lang = $dbix_new->table('language')->search({
                code => $val,
            })->single;
            $lang && $lang->{data}->{value_id};
        };
        return ($val_id || 0, undef, $text);
    } elsif ( $input_type eq 'date' || $input_type eq 'range' ) {
        return (0, $val, $text);
    }
}

# 旧title_listテーブルの要素を新title_listテーブルに移行
sub migrate_title_list {
    my ($dbix_old, $dbix_new) = @_;
    warn "Migrate title_list";

    my @titles = $dbix_old->table('title_list')->all;
    foreach my $title ( @titles ) {
        my $data = $title->{data};
        $dbix_new->table('title_list')->insert({
            resource_id => $data->{id},
            title => $data->{title},
            mid => $data->{MID},
            common_title => $data->{common_title},
            candidate1 => $data->{candidate1},
            candidate2 => $data->{candidate2},
            candidate3 => $data->{candidate3},
        });
    }
}
