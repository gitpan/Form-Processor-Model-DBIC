package BookDB::Controller::Author;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

BookDB::Controller::Author - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BookDB::Controller::Author in Author.');
}


=head1 AUTHOR

Gerda Shank

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
