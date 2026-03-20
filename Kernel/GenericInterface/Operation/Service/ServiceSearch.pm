# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Service::ServiceSearch;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::GenericInterface::Operation::Common);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $Result = $Self->Init(
        WebserviceID => $Param{WebserviceID},
    );

    if ( !$Result->{Success} ) {
        $Self->ReturnError(
            ErrorCode    => 'ServiceSearch.InternalError',
            ErrorMessage => 'ServiceSearch: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'ServiceSearch.AuthFail',
        ErrorMessage => 'ServiceSearch: Could not authenticate.',
    ) if !$UserID;

    # Check group permission.
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'ro',
    );

    return $Self->ReturnError(
        ErrorCode    => 'ServiceSearch.AccessDenied',
        ErrorMessage => 'ServiceSearch: User does not have access.',
    ) if !$HasPermission;

    # Build search params — only include what was provided.
    my %SearchParams = (
        UserID => $UserID,
    );

    if ( defined $Param{Data}{Name} && $Param{Data}{Name} ne '' ) {
        $SearchParams{Name} = $Param{Data}{Name};
    }

    if ( defined $Param{Data}{Limit} && $Param{Data}{Limit} ne '' ) {
        $SearchParams{Limit} = $Param{Data}{Limit};
    }

    my @ServiceIDs = $Kernel::OM->Get('Kernel::System::Service')->ServiceSearch(
        %SearchParams,
    );

    return {
        Success => 1,
        Data    => {
            ServiceIDs => \@ServiceIDs,
        },
    };
}

1;
