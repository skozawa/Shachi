package Shachi::Model::Metadata;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

use constant {
    METADATA_TITLE => 'title',
    METADATA_TITLE_ABBREVIATION => 'title_abbreviation',
    METADATA_TITLE_ALTERNATIVE => 'title_alternative',
    METADATA_DESCRIPTION => 'description',
    METADATA_DESCRIPTION_PRICE => 'description_price',
    METADATA_SUBJECT_RESOURCE_SUBJECT => 'subject_resourceSubject',
    METADATA_TYPE_PURPOSE => 'type_purpose',
    METADATA_LANGUAGE_AREA => 'language_area',
    METADATA_IDENTIFIER => 'identifier',
    METADATA_DATE_ISSUED => 'date_issued',
    METADATA_RELATION => 'relation',

    INPUT_TYPE_TEXT => 'text',
    INPUT_TYPE_TEXTAREA => 'textarea',
    INPUT_TYPE_SELECT => 'select',
    INPUT_TYPE_SELECTONLY => 'select_only',
    INPUT_TYPE_RELATION => 'relation',
    INPUT_TYPE_LANGUAGE => 'language',
    INPUT_TYPE_DATE => 'date',
    INPUT_TYPE_RANGE => 'range',

    VALUE_TYPE_ROLE => 'role',
    VALUE_TYPE_LINGUISTIC_FIELD => 'linguisticField',
    VALUE_TYPE_MONO_MULTILINGUAL => 'monoMultilingual',
    VALUE_TYPE_RESOURCE_SUBJECT => 'resourceSubject',
    VALUE_TYPE_LANGUAGE => 'language',
    VALUE_TYPE_INPUT_DEVICE => 'inputDevice',
    VALUE_TYPE_INPUT_ENVIRONMENT => 'inputEnvironment',
    VALUE_TYPE_SPEAKING_STYLE => 'speakingStyle',
    VALUE_TYPE_SPEECH_MODE => 'speechMode',
    VALUE_TYPE_ADDITIONAL_DATA => 'additionalData',
    VALUE_TYPE_CON_ROLE => 'con_role',
    VALUE_TYPE_MOTHER_TONGUE => 'motherTongue',
    VALUE_TYPE_DIALECT => 'dialect',
    VALUE_TYPE_LEVEL => 'level',
    VALUE_TYPE_AGE => 'age',
    VALUE_TYPE_GENDER => 'gender',
    VALUE_TYPE_SPEAKER_NUMBER => 'speakerNumber',
    VALUE_TYPE_TYPE => 'type',
    VALUE_TYPE_DISCOURSE_TYPE => 'discourseType',
    VALUE_TYPE_LINGUISTIC_TYPE => 'linguisticType',
    VALUE_TYPE_PURPOSE => 'purpose',
    VALUE_TYPE_STYLE => 'style',
    VALUE_TYPE_FORM => 'form',
    VALUE_TYPE_SENTENCE => 'sentence',
    VALUE_TYPE_ANNOTATION => 'annotation',
    VALUE_TYPE_LANGUAGE_AREA => 'language_area',
    VALUE_TYPE_RELATION => 'relation',
};

use constant METADATA_INPUT_TYPES => [
    INPUT_TYPE_TEXT, INPUT_TYPE_TEXTAREA, INPUT_TYPE_SELECT, INPUT_TYPE_SELECTONLY,
    INPUT_TYPE_RELATION, INPUT_TYPE_LANGUAGE, INPUT_TYPE_DATE, INPUT_TYPE_RANGE
];

use constant METADATA_VALUE_TYPES => [
    VALUE_TYPE_ROLE, VALUE_TYPE_LINGUISTIC_FIELD, VALUE_TYPE_MONO_MULTILINGUAL,
    VALUE_TYPE_RESOURCE_SUBJECT, VALUE_TYPE_LANGUAGE, VALUE_TYPE_INPUT_DEVICE,
    VALUE_TYPE_INPUT_ENVIRONMENT, VALUE_TYPE_SPEAKING_STYLE, VALUE_TYPE_SPEECH_MODE,
    VALUE_TYPE_ADDITIONAL_DATA, VALUE_TYPE_CON_ROLE, VALUE_TYPE_MOTHER_TONGUE,
    VALUE_TYPE_DIALECT, VALUE_TYPE_LEVEL, VALUE_TYPE_AGE,
    VALUE_TYPE_GENDER, VALUE_TYPE_SPEAKER_NUMBER, VALUE_TYPE_TYPE,
    VALUE_TYPE_DISCOURSE_TYPE, VALUE_TYPE_LINGUISTIC_TYPE, VALUE_TYPE_PURPOSE,
    VALUE_TYPE_STYLE, VALUE_TYPE_FORM, VALUE_TYPE_SENTENCE,
    VALUE_TYPE_ANNOTATION, VALUE_TYPE_LANGUAGE_AREA, VALUE_TYPE_RELATION,
];

use constant FACET_METADATA_NAMES => [qw/
    description_language language_area language type subject_monoMultilingual
    subject_resourceSubject type_style type_form type_sentence
    type_linguisticType type_discourseType type_purpose subject_linguisticField
    contributor_author_level contributor_speaker_level
    contributor_author_motherTongue contributor_speaker_motherTongue
    contributor_author_dialect contributor_speaker_dialect
    contributor_author_age contributor_speaker_age
    contributor_author_gender contributor_speaker_gender
    type_annotation
/];

use constant KEYWORD_SEARCH_METADATA_NAMES => [
    METADATA_TITLE, METADATA_TITLE_ABBREVIATION, METADATA_TITLE_ALTERNATIVE,
    METADATA_DESCRIPTION, METADATA_TYPE_PURPOSE
];

our @EXPORT = qw/
    METADATA_TITLE METADATA_TITLE_ABBREVIATION METADATA_TITLE_ALTERNATIVE
    METADATA_DESCRIPTION METADATA_DESCRIPTION_PRICE METADATA_SUBJECT_RESOURCE_SUBJECT
    METADATA_TYPE_PURPOSE METADATA_LANGUAGE_AREA METADATA_IDENTIFIER
    METADATA_DATE_ISSUED METADATA_RELATION

    INPUT_TYPE_TEXT INPUT_TYPE_TEXTAREA INPUT_TYPE_SELECT INPUT_TYPE_SELECTONLY
    INPUT_TYPE_RELATION INPUT_TYPE_LANGUAGE INPUT_TYPE_DATE INPUT_TYPE_RANGE
    METADATA_INPUT_TYPES

    VALUE_TYPE_ROLE VALUE_TYPE_LINGUISTIC_FIELD VALUE_TYPE_MONO_MULTILINGUAL
    VALUE_TYPE_RESOURCE_SUBJECT VALUE_TYPE_LANGUAGE VALUE_TYPE_INPUT_DEVICE
    VALUE_TYPE_INPUT_ENVIRONMENT VALUE_TYPE_SPEAKING_STYLE VALUE_TYPE_SPEECH_MODE
    VALUE_TYPE_ADDITIONAL_DATA VALUE_TYPE_CON_ROLE VALUE_TYPE_MOTHER_TONGUE
    VALUE_TYPE_DIALECT VALUE_TYPE_LEVEL VALUE_TYPE_AGE
    VALUE_TYPE_GENDER VALUE_TYPE_SPEAKER_NUMBER VALUE_TYPE_TYPE
    VALUE_TYPE_DISCOURSE_TYPE VALUE_TYPE_LINGUISTIC_TYPE VALUE_TYPE_PURPOSE
    VALUE_TYPE_STYLE VALUE_TYPE_FORM VALUE_TYPE_SENTENCE
    VALUE_TYPE_ANNOTATION VALUE_TYPE_LANGUAGE_AREA VALUE_TYPE_RELATION
    METADATA_VALUE_TYPES

    FACET_METADATA_NAMES
    KEYWORD_SEARCH_METADATA_NAMES
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id name label order_num shown multi_value input_type value_type color/],
    rw  => [qw/values no_metadata_resource_count/],
);

sub allow_statistics {
    my $self = shift;
    return 1 if $self->input_type eq INPUT_TYPE_SELECT ||
        $self->input_type eq INPUT_TYPE_SELECTONLY ||
            $self->input_type eq INPUT_TYPE_LANGUAGE;
    return 0;
}

1;
