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

truncate_db($dbix_new);
migrate_annotators($dbix_old, $dbix_new);
migrate_options($dbix_old, $dbix_new);
migrate_languages($dbix_old, $dbix_new);
migrate_scheme($dbix_old, $dbix_new);
migrate_resources($dbix_old, $dbix_new);
update_shachi_id($dbix_new);
update_identifier($dbix_new);
update_relation($dbix_new);
# migrate_title_list($dbix_old, $dbix_new);

sub truncate_db {
    my ($dbix_new) = @_;
    warn "Truncate Tables";
    my $tables = $dbix_new->dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
    $dbix_new->dbh->do("truncate table `$_`") for map { $_->{TABLE_NAME} } @$tables;
}

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
        $data->{order_num} = $data->{id} * 10; # あとから追加しやすいように10倍しておく
        if ( $data->{name} eq 'identifier_doi' ) {
            $data->{order_num} = 501;
        } elsif ( $data->{name} eq 'identifier_islrn' ) {
            $data->{order_num} = 502;
        } elsif ( $data->{name} eq 'title_abbreviation' ) {
            $data->{order_num} = 15;
        }
        $dbix_new->table('metadata')->insert({
            id => $data->{id},
            name => $data->{name},
            label => $data->{label},
            order_num => $data->{order_num},
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
            # date_issued が複数になっているのをまとめる
            if ( $meta->{data}->{name} eq 'date_issued' ) {
                my $content = '';
                my @descriptions;
                foreach my $item ( split /\|\|\|QEUSNEIAN\|\|/, $value ) {
                    my ($val, @texts) = split /,/, $item;
                    $content = $val unless $val eq '--'; # -- は削除
                    push @descriptions, join ",", @texts;
                }
                my $description = join ", ", @descriptions;
                # ., は . だけにする
                $description =~ s/\.\, /. /;
                $value = $content . "," . $description;
            }
            # date_createdで複数項目ある一部のリソースを修正
            if ( $meta->{data}->{name} eq 'date_created' ) {
                if ( $data->{id} == 803 ) {
                    $value = '2001-00-00 2004-00-00,collected in 1977-1978, annotated in 2001-2004';
                } elsif ( $data->{id} == 869 ) {
                    $value = '1988-00-00 1990-00-00,1993-1995';
                } elsif ( $data->{id} == 1592 ) {
                    $value = '2001-00-00 0000-00-00,The corpus consists of two subcorpora, one collected in 2001, and the other at differenct times since 1997';
                }
            }
            # 複数に分割されているdescriptionをまとめる
            if ( $meta->{data}->{name} eq 'description' ) {
                my @contents;
                foreach my $item ( split /\|\|\|QEUSNEIAN\|\|/, $value ) {
                    my ($val, @texts) = split /,/, $item;
                    push @contents, join ",", @texts;
                }
                $value = "," . join("\n", @contents);
            }
            foreach my $item ( split /\|\|\|QEUSNEIAN\|\|/, $value ) {
                $item =~ s/\!\!BNSDLSIFNELS\!\!/|/g;
                $item =~ s/\!\!AFELISNFELIS\!\!/"|/g;
                my ($val, @texts) = split /,/, $item;
                my $text = join ",", @texts;
                next unless $val || $text;
                $text =~ s/^\s+// if $text;

                my ($value_id, $content, $desc) = _meta_value($dbix_new, $meta, $val, $text);
                # date_modifiedの'--'とdate_createdの'-- --'は除去
                if ( $meta->{data}->{name} eq 'date_modified' && $content eq '--' ) {
                    $content = '';
                } elsif ( $meta->{data}->{name} eq 'date_created' && $content eq '-- --' ) {
                    $content = '';
                }

                # 追加要素がない場合はスキップ
                if ( !$value_id && !$content && !$desc ) {
                    print $data->{id}, "\t", $meta->{data}->{name}, "\t", $item, "\n";
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

# SHACHI ID を最新にする
sub update_shachi_id {
    my ($dbix_new) = @_;
    warn "UPDATE SHACHI ID";

    my $shachi_id_type = sub {
        my ($resource_subjects) = @_;
        return 'N' unless $resource_subjects && @$resource_subjects;
        foreach my $resource_subject ( @$resource_subjects ) {
            my $value = $dbix_new->table('metadata_value')->search({
                id => $resource_subject->{data}->{value_id}
            })->single or next;
            return 'C' if $value->value eq 'corpus';
            return 'D' if $value->value eq 'dictionary';
            return 'G' if $value->value eq 'glossary';
            return 'T' if $value->value eq 'thesaurus';
        }
        return 'O';
    };

    my @resources = $dbix_new->table('resource')->all;
    foreach my $resource ( @resources ) {
        my @resource_subjects = $dbix_new->table('resource_metadata')->search({
            metadata_name => 'subject_resourceSubject', resource_id => $resource->{data}->{id},
        })->all;
        my $type = $shachi_id_type->(\@resource_subjects);
        my $shachi_id = sprintf '%s-%06d', $type, $resource->{data}->{id};
        if ( $resource->{data}->{shachi_id} ne $shachi_id ) {
            # warn $resource->{data}->{shachi_id}, "\t", $shachi_id;
            $dbix_new->table('resource')->search({
                id => $resource->{data}->{id}
            })->update({ shachi_id => $shachi_id });
        }
    }
}

# identifierの形式を整える
sub update_identifier {
    my ($dbix_new) = @_;
    warn "UPDATE IDENTIFIER";

    my @identifiers = $dbix_new->table('resource_metadata')->search({
        metadata_name => 'identifier',
    })->all;

    foreach my $identifier ( @identifiers ) {
        my $content = $identifier->{data}->{content} or next;
        my $new_content;
        if ( $content =~ /http/ ) {
        } elsif ( $content =~ /ELRA ?[:-] ?([A-Z0-9-]+)/ ) {
            $new_content = 'ELRA-' . $1;
            $new_content =~ s/ELRA-ELRA/ELRA/;
        } elsif ( $content =~ /ELRA Catalog Reference ?: ?([A-Z0-9-]+)/ ) {
            $new_content = 'ELRA-' . $1;
        } elsif ( $content =~ /CLDC[:-]([A-Z0-9-]+)/ ) {
            $new_content = 'CLDC-' . $1;
        } elsif ( $content =~ /LDC[:]?([A-Z0-9-]+)/ ) {
            $new_content = 'LDC' . $1;
        } elsif ( $content =~ /ISBN[:：]?(?:ISBN)?(?: +)?([A-Za-z0-9-]+)/ ) {
            $new_content = 'ISBN:' . $1;
            $new_content = $content if $content =~ /\(.+\)/;
        } elsif ( $content =~ /NIST/ ) {
        }
        if ( $new_content && $new_content ne $content ) {
            # print $content, "\t", $new_content, "\n";
            $dbix_new->table('resource_metadata')->search({
                id => $identifier->{data}->{id},
            })->update({ content => $new_content });
        }
    }
}

# relationの形式を変更
# SHACHI ID がついていないものにIDを付与
sub update_relation {
    my ($dbix_new) = @_;
    warn "FIX AND ARRANGE RELATION";

    my @relations = $dbix_new->table('resource_metadata')->search({
        metadata_name => 'relation',
    })->all;

    my $get_resource = sub {
        my ($id) = @_;
        $dbix_new->table('resource')->search({ id => $id })->single;
    };
    my $get_title = sub {
        my ($args) = @_;
        $args ||= {};
        return if !$args->{resource_id} && !$args->{content};
        $dbix_new->table('resource_metadata')->search({
            metadata_name => 'title',
            $args->{resource_id} ? (resource_id => $args->{resource_id}) : (),
            $args->{content} ? (content => $args->{content}) : (),
        })->single;
    };
    my $get_identifier = sub {
        my ($content) = @_;
        $dbix_new->table('resource_metadata')->search({
            metadata_name => 'identifier', content => { '-like' => '%' . $content . '%' },
        })->single;
    };
    my $get_value = sub {
        my ($id) = @_;
        return unless $id;
        $dbix_new->table('metadata_value')->search({ id => $id })->single;
    };

    foreach my $relation ( @relations ) {
        my $value = $get_value->($relation->{data}->{value_id});
        my $is_referenced_by = $value && $value->value eq 'isReferencedBy';
        my ($tag, $resource, $title, $identifier);
        next unless $relation->{data}->{description};
        if ( $relation->{data}->{description} =~ /^[NCDGTOSWL]-(\d{6}),/ ) {
            my $id = $1;
            $tag = "[ID]";
            $resource = $get_resource->($id);
            $title = $get_title->({ resource_id => $id });
        } elsif ( $title = $get_title->({ content => $relation->{data}->{description} }) ) {
            $tag = "[TITLE]";
            $resource = $get_resource->($title->{data}->{resource_id});
        } elsif ( $relation->{data}->{description} =~ /(LDC\d+[A-Z]\d+(?:-\d)?)/ ) {
            my $ldcid = $1;
            $identifier = $get_identifier->($ldcid);
            if ( $identifier && !$is_referenced_by ) {
                $tag = "[LDC]";
                $resource = $get_resource->($identifier->{data}->{resource_id});
                $title = $get_title->({ resource_id => $resource->{data}->{id} });
            } else {
                $tag = "[NO:LDC]";
            }
        } elsif ( $relation->{data}->{description} =~ /([A-Z]\d{4}(?:-\d+)?)/ ) {
            my $elra_id = $1;
            $identifier = $get_identifier->($elra_id);
            if ( $identifier && !$is_referenced_by ) {
                $tag = "[ELRA]";
                $resource = $get_resource->($identifier->{data}->{resource_id});
                $title = $get_title->({ resource_id => $resource->{data}->{id} });
            } else {
                $tag = "[NO:ELRA]";
            }
        } else {
            $tag = "[NO]";
        }
        # print $relation->{data}->{resource_id};
        # print $tag;
        # printf "[%s]", $value ? $value->{data}->{value} : '';
        # print $relation->{data}->{description};
        # print "\t", $resource->{data}->{shachi_id} if $resource;
        # print ":", $title->{data}->{content} if $title;
        # print "\t", $identifier->{data}->{content} if $identifier;
        # print "\n";

        if ( $resource && $title ) {
            my $description = sprintf '%s: %s', $resource->{data}->{shachi_id}, $title->{data}->{content};
            $dbix_new->table('resource_metadata')->search({
                id => $relation->{data}->{id}
            })->update({ description => $description });
        }
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
