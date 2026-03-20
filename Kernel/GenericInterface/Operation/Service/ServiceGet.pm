# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Service::ServiceGet;

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
            ErrorCode    => 'ServiceGet.InternalError',
            ErrorMessage => 'ServiceGet: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'ServiceGet.AuthFail',
        ErrorMessage => 'ServiceGet: Could not authenticate.',
    ) if !$UserID;

    # Check group permission.
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'ro',
    );

    return $Self->ReturnError(
        ErrorCode    => 'ServiceGet.AccessDenied',
        ErrorMessage => 'ServiceGet: User does not have access.',
    ) if !$HasPermission;

    # Validate required params.
    my $ServiceID = $Param{Data}{ServiceID};

    return $Self->ReturnError(
        ErrorCode    => 'ServiceGet.MissingParameter',
        ErrorMessage => 'ServiceGet: ServiceID is required.',
    ) if !$ServiceID;

    my %ServiceData = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
        ServiceID => $ServiceID,
        UserID    => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ServiceGet.NotFound',
        ErrorMessage => "ServiceGet: Service with ID $ServiceID not found.",
    ) if !%ServiceData || !$ServiceData{ServiceID};

    return {
        Success => 1,
        Data    => {
            Service => \%ServiceData,
        },
    };
}

1;
