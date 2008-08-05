package Form::Processor::Model::DBIC;
use strict;
use warnings;
use base 'Form::Processor';
use Carp;

our $VERSION = '0.04';

=head1 NAME

Form::Processor::Model::DBIC - Model class for Form Processor using DBIx::Class

=head1 SYNOPSIS

You need to create a form class, templates, and call F::P from a controller.

Create a Form, subclassed from Form::Processor::Model::DBIC

    package MyApp:Form::User;
    use strict;
    use base 'Form::Processor::Model::DBIC';

    # Associate this form with a DBIx::Class result class
    sub object_class { 'MyDB::User' } # Where 'MyDB' is the Catalyst model name

    # Define the fields that this form will operate on
    # Field names must be column or relationship names in your
    # DBIx::Class result class
    sub profile {
        return {
            fields => {
                name        => {
                   type => 'Text',
                   label => 'Name:',
                   required => 1,
                   noupdate => 1,
                },
                age         => {
                    type => 'PosInteger',
                    label    => 'Age:',
                    required => 1,
                },
                sex         => {
                    type => 'Select',
                    label => 'Gender:',
                    required => 1,
                },
                birthdate   => '+MyApp::Field::Date', # customized field class
                hobbies     =>  {
                    type => 'Multiple',
                    size => 5,
                },
                address     => 'Text',
                city        => 'Text',
                state       => 'Select',
            },

            dependency => [
                ['address', 'city', 'state'],
            ],
        };

Then in your template:

For an input field:

   <p>
   [% f = form.field('address') %]
   <label class="label" for="[% f.name %]">[% f.label || f.name %]</label>
   <input type="text" name="[% f.name %]" id="[% f.name %]">
   </p>


For a select list provide a relationship name as the field name, or provide
an options_<field_name> subroutine in the form. (field attributes: sort_order, 
label_column, active_column). TT example:

   <p>
   [% f = form.field('sex') %]
   <label class="label" for="[% f.name %]">[% f.label || f.name %]</label>
   <select name="[% f.name %]">
     [% FOR option IN f.options %]
       <option value="[% option.value %]" [% IF option.value == f.value %]selected="selected"[% END %]>[% option.label | html %]</option>
     [% END %] 
   </select>
   </p>

A multiple select list where 'hobbies' is the 'has_many' relationship for
a 'many_to_many' pseudo-relationship. (field attributes: sort_order, label_column,
active_column).

   <p>
   [% f = form.field('hobbies') %]
   <label class="label" for="[% f.name %]">[% f.label || f.name %]</label>
   <select name="[% f.name %]" multiple="multiple" size="[% f.size %]">
     [% FOR option IN f.options %]
       <option value="[% option.value %]" [% FOREACH selval IN f.value %][% IF selval == option.value %]selected="selected"[% END %][% END %]>[% option.label | html %]</option>
     [% END %] 
   </select>
   </p>

For a complex, widget-based TT setup, see the examples directory in the
L<Catalyst::Plugin::Form::Processor> CPAN download.
 
Then in a Catalyst controller (with Catalyst::Plugin::Form::Processor):

    package MyApp::Controller::User;
    use strict;
    use warnings;
    use base 'Catalyst::Controller';

    # Create or edit
    sub edit : Local {
        my ( $self, $c, $user_id ) = @_;
        $c->stash->{template} = 'user/edit.tt'; 
        # Validate and insert/update database. Args = pk, form name
        return unless $c->update_from_form( $user_id, 'User' );
        # Form validated.
        $c->stash->{user} = $c->stash->{form}->item;
        $c->res->redirect($c->uri_for('profile'));
    }

With the Catalyst plugin the schema is retrieved from the Catalyst context 
($c->model()...), but it can also be set by passing in the schema on "new",
or setting with $form->schema($schema)

In MyApp.pm (the application root controller) config Catalyst::Plugin::F::P:

    BookDB->config->{form} = {
        no_fillin         => 0,  # Set if you don't want FillInForm
                                 # to fill in your form values 
        pre_load_forms    => 1,  # don't set pre_load if using auto fields
        form_name_space   => 'MyApp::Form',
        debug             => 1,
    };

=head1 DESCRIPTION

Form::Processor is a form handling class primarily useful for getting HMTL form
data into the database. It provides attributes on fields that can be used
for creating a set of widgets and highly automatic templates, but does
not actually create the templates themselves. There is a illustrative
example of a widgetized template setup in the L<Catalyst::Plugin::Form::Processor>
distribution, and it should be fairly easy to write utilities or scripts 
to create templates automatically. And cut-and-paste always works...

This DBIC model will save form fields automatically to the database, will
retrieve selection lists from the database (with type => 'Select' and a 
fieldname containing a single relationship, or type => 'Multiple' and a
has_many relationship), and will save the selected values (one value for 
'Select', multiple values in a mapping table for a 'Multiple' field). 

The 'form' is a Perl subclass of the model class, and in it you define
your fields (with many possible attributes), and initialization
and validation routines. Because it's a Perl class, you have a lot of 
flexibility.

You can, of course, define your own L<Form::Processor::Field> classes to
create your own field types, and perform specialized validation. And you
can subclass the methods in Form::Processor::Model::DBIC and 
Form::Processor.

This package includes a working example using a SQLite database and a
number of forms. The templates are straightforward and unoptimized to
make it easier to see what they're doing.

=head1 Combined reference for Form::Processor

Form::Processor has a lot of options and many ways to customize your forms.
I've collected a list of them here to make them easier to find. More complete
documentation can be found at L<Form::Processor>, L<Form::Processor::Field>,
L<Catalyst::Plugin::Form::Processor>, and in the individual field classes.

=head2 Attributes for fields defined in your form:

   name          Field name. Must be the same as database column name or rel
   type          Field type. From a F::P::Field class: 'Text', 'Select', etc
   required      Field is required
   required_message  If this field is required, the message to display on failure 
   id            Useful for javascript that requires unique id. Set in Field.
   label         Text label. Not used by F::P, but useful in templates 
   order         Set the order for fields. Used by sorted_fields, templates. 
   widget        Used by templates to decide widget usage. Set by field classes.
   style         Style to use for css formatting. Not used by F::P, for templates.
   value_format  Sprintf format to use when converting input to value
   password      Remove from params and do not display in forms. 
   disabled      HTML hint to not do updates (for templates) Init: 0
   readonly      HTML hint to make the field readonly (for templates) Init: 0 
   clear         Don't validate and remove from database
   noupdate      Don't update this field in the database
   writeonly     Do not call field class's "format_value" routine. 
   errors        Errors associated with this field 
   label_column  Select lists: column to use for labels (default: name)
   active_column Select lists: which values to list
   sort_order    Select lists: column to use for sorting (default: label_column)
   sub_form      The field is made up of a sub-form (only dates at this point)
   size          Text & select fields. Validated for text.
   minlength     Text fields. Used in validation
   range_start   Range start for number fields 
   range_end     Range end for number fields    

=head2 Field attributes not set in a user form

These attributes are usually accessed in a subroutine or in a template.

   init_value    Initial value from the database (or see init_value_$fieldname) 
   value         The value of your field. Initially, init_value, then from input.
   input         Input value from parameter
   options       Select lists. Sorted array of hashes, keys: "value", "label"

=head2 Other form settings

   dependency    Array of arrays of field names. If one name has a value, all
                       fields in the list are set to 'required'
   unique        Arrayref of field names that should be unique in db
                     or Hashref that also sets message 

=head2 Subroutines for your form (not subclassed)

   object_class             Required for Form::Processor::Model::DBIC (& CDBI)
   schema                   If you're not using the schema from a Catalyst model
   options_$fieldname       Provides a list of key value pairs for select lists
   validate_$fieldname      Validation routine for field 
   init_value_$fieldname    Overrides initial value for the field
   cross_validate           For validation after individual fields are validated 
   active_column            For all select lists in the form
   init_object              Provide different but similar object to init form 
                               such as default values (field names must match)
   field_counter            Increment in templates (see Field & C::P::F::P example)
   Plus any subroutine you care to write...
   
=head2 Methods you might want to subclass from Form::Processor::Model::DBIC

   model_validate    Add additional database type validation
   update_model      To add additional actions on update
   guess_field_type  To create better field type assignment for auto forms 
   many_to_many      If your multiple select list mapping table is not standard
     
=head2 Particularly useful in a template

   errors            [% FOREACH error IN form.errors %]
   error_fields      [% FOREACH field IN form.error_fields %]
   error_field_names [% FOREACH name IN form.error_field_names %]
   sorted_fields     [% FOREACH field IN form.sorted_fields %]
   uuid              subroutine that returns a uuid
   fif               value="[% form.fif.title %]"
   params            Same as fif, but password fields aren't stripped
   
=head2 L<Form::Processor::Field> subroutines to subclass in a Field class

   validate          Main part of Field subclasses. Generic validation that
                       applies to all fields of this type.
   trim_value        If you don't want beginning and ending whitespace trimmed
   input_to_value    To process the field before storing, after validation
   validate_field    If you don't want invalid fields cleared, subclass & restore 
   Add your own field attributes in your custom Field classes.
    
=head1 METHODS

=head2 schema

The schema method is primarily intended for non-Catalyst users, so
that they can pass in their DBIx::Class schema object.

=cut

use Rose::Object::MakeMethods::Generic (
   scalar => ['schema' => { interface => 'get_set_init'},
              'source_name' => {},],
);

=head2 update_from_form

    my $validated = $form->update_from_form( $parameter_hash );

This is not the same as the routine called with $c->update_from_form. That
is a Catalyst plugin routine that calls this one. This routine updates or
creates the object from values in the form.

All fields that refer to columns and have changed will be updated. Field names
that are a single relationship will be updated. Any field names that are related 
to the class by "has_many" are assumed to have a mapping table and will be 
updated.  Validation is run unless validation has already been run.  
($form->clear might need to be called if the $form object stays in memory
between requests.)

The actual update is done in the C<update_model> method.  Your form class can
override that method (but don't forget to call SUPER) if you wish to do additional
database inserts or updates.  This is useful when a single form updates 
multiple tables, or there are secondary tables to update.

Returns false if form does not validate, otherwise returns 1.  Very likely dies on database errors.

=cut

sub update_from_form
{
   my ( $self, $params ) = @_;
   return unless $self->validate($params);
   $self->update_model;
   return 1;
}

=head2 model_validate

The place to put validation that requires database-specific lookups.
Subclass this method in your form.

=cut

sub model_validate
{
   my ($self) = @_;
   return unless $self->validate_unique;
   return 1;
}

=head2 update_model

This is where the database row is updated. If you want to do some extra
database processing (such as updating a related table) this is the
method to subclass in your form.

It currently assumes that any "has_many" relationship name used as a
field in your form is for a "multiple" select list. This will probably
change in the future.

=cut

sub update_model
{
   my ($self) = @_;
   my $item   = $self->item;
   my $source = $self->source;

   # get a hash of all fields, skipping fields marked 'noupdate'
   my %fields = map { $_->name, $_ } grep { !$_->noupdate } $self->fields;
   my %data;
   my $field;
   my $value;

   # First process the normal and has_a columns
   # as that data is directly stored in the object
   foreach my $col ( $source->columns )
   {
      next unless exists $fields{$col};
      $field = delete $fields{$col};

      # If the field is flagged "clear" then set to NULL.
      $value = $field->clear ? undef : $field->value;

      if ($item)
      {
         my $cur = $item->$col;
         next unless $value || $cur;
         next if ( ( $value && $cur ) && ( $value eq $cur ) );
         $item->$col($value);
      }
      else
      {
         $data{$col} = $value;
      }
   }

   if ($item)
   {
      $item->update;
      $self->updated_or_created('updated');
   }
   else
   {

      # create new item
      $item = $self->resultset->create( \%data );
      $self->item($item);
      $self->updated_or_created('created');
   }

   # All non-rel columns and 'has_a' columns have been deleted
   # from fields hash, so all fields left should be 'has_many' (Multiple)
   if ( $source->relationships )
   {
      for my $field_name ( keys %fields )
      {
         next
           unless ( ( $source->has_relationship($field_name) )
            && ( $source->relationship_info($field_name)->{attrs}->{accessor} eq 'multi' ) );

         # This is a has_many/many_to_many relationship
         my ( $self_rel, $self_col, $foreign_rel, $foreign_col, $m2m_rel ) =
           $self->many_to_many($field_name);

         $field = delete $fields{$field_name};
         $value = $field->value;
         my %keep;
         %keep = map { $_ => 1 } ref $value ? @$value : ($value)
           if defined $value;

         if ( $self->updated_or_created eq 'updated' )
         {
            for ( $item->$field_name->all )
            {

               # delete old selections
               $_->delete unless delete $keep{ $_->$foreign_col };
            }
         }

         # Add new related
         $item->create_related( $field_name, { $foreign_col => $_ } ) for keys %keep;
      }    # end of key processing loop
   }

   # Save item in form object
   $self->item($item);
   $self->reset_params;    # force reload of parameters from values
   return $item;
}

=head2 guess_field_type

This subroutine is only called for "auto" fields, defined like:
    return {
       auto_required => ['name', 'age', 'sex', 'birthdate'],
       auto_optional => ['hobbies', 'address', 'city', 'state'],
    };

Pass in a column and it will guess the field type and return it.

Currently returns:
    DateTimeDMYHM   - for a has_a relationship that isa DateTime
    Select          - for a has_a relationship
    Multiple        - for a has_many

otherwise:
    DateTimeDMYHM   - if the field ends in _time
    Text            - otherwise

Subclass this method to do your own field type assignment based
on column types. Don't use "pre_load_forms" if using auto fields.
The DBIx::Class schema isn't available yet.

=cut

sub guess_field_type
{
   my ( $self, $column ) = @_;
   my $source = $self->source;
   my @return;

   #  TODO: Should be able to use $source->column_info

   # Is it a direct has_a relationship?
   if (
      $source->has_relationship($column)
      && (  $source->relationship_info($column)->{attrs}->{accessor} eq 'single' ||
            $source->relationship_info($column)->{attrs}->{accessor} eq 'filter' )
     )
   {
      my $f_class = $source->related_class($column);
      @return =
        $f_class->isa('DateTime')
        ? ('DateTimeDMYHM')
        : ('Select');
   }

   # Else is it has_many?
   elsif ( $source->has_relationship($column)
      && $source->relationship_info($column)->{attrs}->{accessor} eq 'multi' )
   {
      @return = ('Multiple');
   }
   elsif ( $column =~ /_time$/ )    # ends in time, must be time value
   {
      @return = ('DateTimeDMYHM');
   }
   else                             # default: Text
   {
      @return = ('Text');
   }

   return wantarray ? @return : $return[0];
}

=head2 lookup_options

This method is used with "Single" and "Multiple" field select lists 
("single", "filter", and "multi" relationships).
It returns an array reference of key/value pairs for the column passed in.
The column name defined in $field->label_column will be used as the label.
The default label_column is "name".  The labels are sorted by Perl's cmp sort.

If there is an "active" column then only active values are included, except 
if the form (item) has currently selected the inactive item.  This allows
existing records that reference inactive items to still have those as valid select
options.  The inactive labels are formatted with brackets to indicate in the select
list that they are inactive.

The active column name is determined by calling:
    $active_col = $form->can( 'active_column' )
        ? $form->active_column
        : $field->active_column;

This allows setting the name of the active column globally if
your tables are consistantly named (all lookup tables have the same
column name to indicate they are active), or on a per-field basis.

The column to use for sorting the list is specified with "sort_order". 
The currently selected values in a Multiple list are grouped at the top
(by the Multiple field class).

=cut

sub lookup_options
{
   my ( $self, $field ) = @_;
   my $field_name = $field->name;

   # if this field doesn't refer to a foreign key, return
   my $rel_info = $self->source->relationship_info($field_name);
   my $f_class;
   $f_class = $self->source->related_class($field_name)
     if $self->source->has_relationship($field_name);
   return unless $f_class;

   # This field refers to foreign table, so continue.

   my $source = $self->schema->source($f_class);

   # this is a bit messy, but leaving here for now since
   # it will probably get even more complicated in the future...
   if ( $field->type eq 'Multiple' ||
      ( $field->type eq 'Auto' && $rel_info->{attrs}{accessor} eq 'multi' ) )
   {

      # This is a 'has_many' relationship with a mapping table
      my ( $self_rel, $self_col, $foreign_rel, $foreign_col ) =
        $self->many_to_many( $field->name );

      $f_class = $source->related_class($foreign_rel);
      $source  = $source->related_source($foreign_rel);
   }

   my $label_column = $field->label_column;
   return unless $source->has_column($label_column);

   my $active_col =
       $self->can('active_column')
     ? $self->active_column
     : $field->active_column;

   $active_col = '' unless $source->has_column($active_col);
   my $sort_col = $field->sort_order;
   $sort_col = defined $sort_col && $source->has_column($sort_col) ? $sort_col : $label_column;

   my ($primary_key) = $source->primary_columns;

   # If there's an active column, only select active OR items already selected
   my $criteria = {};
   if ($active_col)
   {
      my @or = ( $active_col => 1 );

      # But also include any existing non-active
      push @or, ( "$primary_key" => $field->init_value )
        if $self->item && defined $field->init_value;
      $criteria->{'-or'} = \@or;
   }

   # get an array of row objects
   my @rows = $self->schema->resultset($source->source_name)->search( $criteria, { order_by => $sort_col } )->all;

   return [
      map {
         my $label = $_->$label_column;
         $_->id, $active_col && !$_->$active_col ? "[ $label ]" : "$label"
        } @rows
   ];

}

=head2 init_value

This method return's a field's value (for $field->value) with
either a scalar or an array ref from the object stored in $form->item.

This method is not called if a method "init_value_$field_name" is found 
in the form class - that method is called instead.
This allows overriding specific fields in your form class.

=cut

sub init_value
{
   my ( $self, $field, $item ) = @_;

   my $column = $field->name;
   $item ||= $self->item;
   return                  unless $item;
   return $item->{$column} unless $item->isa('DBIx::Class');
   return                  unless $item->can($column);
   return                  unless defined $item->$column;

   my $source = $self->source;

   if ( !$source->has_relationship($column) )    # We already know it "can" $column
   {
      return ($item->$column);
   }
   elsif ( $source->relationship_info($column)->{attrs}->{accessor} eq 'single' ||
           $source->relationship_info($column)->{attrs}->{accessor} eq 'filter' )
   {
      return ($item->$column->id);
   }

   # this is a 'has_many' relationship and we must return an array of row objects
   elsif ( $source->relationship_info($column)->{attrs}->{accessor} eq 'multi' )
   {
      my ( $self_rel, $self_col, $foreign_rel, $foreign_col ) = $self->many_to_many($column);
      my @rows = $item->search_related($column)->all;
      my @values = map { $_->$foreign_col } @rows;
      return @values;
   }
   else
   {
      $field->add_error("Could not identify column or relationship.");
   }
}

=head2 validate_unique

For fields that are marked "unique", checks the database for uniqueness.

   arraryref:
        unique => ['user_id', 'username']

   or hashref:
        unique => {
            username => 'That username is already taken',
        }

=cut

sub validate_unique
{
   my ($self) = @_;

   my $unique      = $self->profile->{unique} || return 1;
   my $item        = $self->item;
   my $rs          = $self->resultset;
   my $found_error = 0;

   my @unique_fields;
   my $error_message;
   if ( ref($unique) eq 'ARRAY' ) 
   {
      @unique_fields = @$unique;
      $error_message = 'Value must be unique in the database';
   } 
   elsif ( ref($unique) eq 'HASH' ) 
   {
       @unique_fields = keys %$unique;
   } 
   else 
   {
      return;
   }

   for my $field ( map { $self->field($_) } @unique_fields )
   {

      next if $field->errors;
      my $value = $field->value;
      next unless defined $value;
      my $name = $field->name;

      # unique means there can only be one in the database like it.
      my $count = $rs->search( { $name => $value } )->count;

      next if $count < 1;
        $field->add_error($error_message
           || $self->profile->{'unique'}->{$name});
      $found_error++;
   }

   return $found_error;
}

=head2 init_item

This is called first time $form->item is called.
If using the Catalyst plugin, it sets the DBIx::Class schema from
the Catalyst context, and the model specified as the first part
of the object_class in the form. If not using Catalyst, it uses
the "schema" passed in on "new".

It then does:  

    return $self->resultset->find( $self->item_id );

It also validates that the item id matches /^\d+$/.  Override this method
in your form class (or form base class) if your ids do not match that pattern.

=cut

sub init_item
{
   my $self = shift;
   my $item_id = $self->item_id or return;
   return unless $item_id =~ /^\d+$/;
   return $self->resultset->find($item_id);
}


=head2 init_schema

Initializes the DBIx::Class schema. User may override. Non-Catalyst
users should pass schema in on new:  
$my_form_class->new(item_id => $id, schema => $schema)

=cut

sub init_schema
{
   my $self = shift;
   return if defined $self->{schema};
   if ( my $c = $self->user_data->{context} ) 
   {
       # starts out <model>::<source_name>
       my $schema = $c->model( $self->object_class )->result_source->schema;
       # change object_class to source_name
       $self->source_name( $c->model( $self->object_class )->result_source->source_name );
       return $schema;
   }
   die "Unable to find DBIx::Class schema";

}

=head2 source

Returns a DBIx::Class::ResultSource object for this Result Class.

=cut

sub source
{
   my ( $self, $f_class ) = @_;
   return $self->schema->source($self->source_name || $self->object_class);
}

=head2 resultset

This method returns a resultset from the "object_class" specified
in the form, or from the foreign class that is retrieved from
a relationship.

=cut

sub resultset
{
   my ( $self, $f_class ) = @_;
   return $self->schema->resultset($self->source_name || $self->object_class);
}

=head2 many_to_many

When passed the name of the has_many relationship for a many_to_many
pseudo-relationship, this subroutine returns the relationship and column
name from the mapping table to the current table, and the relationship and
column name from the mapping table to the foreign table.

This code assumes that the mapping table has only two columns 
and two relationships, and you must have correct DBIx::Class relationships
defined.

For different table arrangements you could subclass 
this method to return the correct relationship and column names. 

=cut

sub many_to_many
{
   my ( $self, $has_many_rel ) = @_;

   # get rel and col pointing to self from reverse
   my $source     = $self->source;
   my $rev_rel    = $source->reverse_relationship_info($has_many_rel);
   my ($self_rel) = keys %{$rev_rel};
   my ($cond)     = values %{ $rev_rel->{$self_rel}{cond} };
   my ($self_col) = $cond =~ m/^self\.(\w+)$/;

   # assume that the other rel and col are for foreign table
   my @rels = $source->related_source($has_many_rel)->relationships;
   my $foreign_rel;
   foreach (@rels) { $foreign_rel = $_ if $_ ne $self_rel; }
   my $foreign_col;
   my @cols = $source->related_source($has_many_rel)->columns;
   foreach (@cols) { $foreign_col = $_ if $_ ne $self_col; }

   return ( $self_rel, $self_col, $foreign_rel, $foreign_col );
}

=head2 build_form and _build_fields

These methods from Form::Processor are subclassed here to allow 
combining "required" and "optional" lists in one "fields" list, 
with "required" set like other field attributes.

=cut

sub build_form
{
   my $self    = shift;
   my $profile = $self->profile;
   croak "Please define 'profile' method in subclass" unless ref $profile eq 'HASH';

   for my $group ( 'required', 'optional', 'fields' )
   {
      my $required = 'required' eq $group;
      $self->_build_fields( $profile->{$group}, $required );
      my $auto_fields = $profile->{ 'auto_' . $group } || next;
      $self->_build_fields( $auto_fields, $required );
   }
}

sub _build_fields
{
   my ( $self, $fields, $required ) = @_;
   return unless $fields;
   my $field;
   if ( ref($fields) eq 'ARRAY' )
   {
      for (@$fields)
      {
         $field = $self->make_field( $_, 'Auto' ) || next;
         $field->required($required) unless ( exists $field->{required} );
         $self->add_field($field);
      }
      return;
   }
   while ( my ( $name, $type ) = each %$fields )
   {
      $field = $self->make_field( $name, $type ) || next;
      $field->required($required) unless ( exists $field->{required} );
      $self->add_field($field);
   }
}

=head1 SUPPORT

The author can be contacted through the L<Catalyst> or L<DBIx::Class> mailing 
lists or IRC channels (gshank).

=head1 SEE ALSO

L<Form::Processor>
L<Form::Processor::Field>
L<Form::Processor::Model::CDBI>
L<Catalyst::Plugin::Form::Processor>
L<Rose::Object>

=head1 AUTHOR

Gerda Shank

=head1 CONTRIBUTORS

Based on L<Form::Processor::Model::CDBI> written by Bill Moseley.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
