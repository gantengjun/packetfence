package pf::Authentication::Source::ToutaticeSource;

=head1 NAME

pf::Authentication::Source::ToutaticeSource

=head1 DESCRIPTION

=cut

use pf::log;
use Moose;
extends 'pf::Authentication::Source::OAuthSource';
with 'pf::Authentication::CreateLocalAccountRole';

has '+type' => (default => 'Toutatice');
has '+class' => (default => 'external');
has 'client_id' => (isa => 'Str', is => 'rw', required => 1);
has 'client_secret' => (isa => 'Str', is => 'rw', required => 1);
has 'site' => (isa => 'Str', is => 'rw');
has 'access_token_path' => (isa => 'Str', is => 'rw');
has 'authorize_path' => (isa => 'Str', is => 'rw');
has 'scope' => (isa => 'Str', is => 'rw', default => 'openid');
has 'protected_resource_url' => (isa => 'Str', is => 'rw');
has 'redirect_url' => (isa => 'Str', is => 'rw', required => 1, default => 'https://<hostname>/oauth2/callback');
has 'domains' => (isa => 'Str', is => 'rw', required => 1);

=head2 dynamic_routing_module

Which module to use for DynamicRouting

=cut

sub dynamic_routing_module { 'Authentication::OAuth::Toutatice' }

=head2 available_attributes

=cut

sub available_attributes {
    my $self = shift;
    my $super_attributes = $self->SUPER::available_attributes;
    my @own_attributes = map { {value => $_, type => $Conditions::SUBSTRING}} qw(
      username
      title
      ENTPersonDateNaissance
      ENTPersonUid
      ENTPersonStructRattachRNE
      personalTitle
      ENTPersonFonctions
    );
    return [@$super_attributes, @own_attributes];
}

=head2 lookup_from_provider_info

Lookup the person information from the authentication hash received during the OAuth process

=cut

sub lookup_from_provider_info {
    my ( $self, $pid, $info ) = @_;

    # person_modify( $pid, firstname => $info->{first_name}, lastname => $info->{last_name}, email => $info->{mail}, gender => $info->{gender}, birthday => $info->{birthday}, locale => $info->{locale} );
    person_modify( $pid,
                   firstname => $info->{prenom},
                   lastname => $info->{sn},
                   email => $info->{mail},
                   title => $info->{title},
                   birthday => $info->{ENTPersonDateNaissance},
                   custom_field_1 => $info->{ENTPersonUid},
                   custom_field_2 => $info->{ENTPersonStructRattachRNE},
                   custom_field_3 => $info->{personalTitle},
                   custom_field_4 => $info->{ENTPersonFonctions}
               );
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2020 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};
1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
