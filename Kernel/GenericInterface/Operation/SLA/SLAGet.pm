# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::SLA::SLAGet;

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
            ErrorCode    => 'SLAGet.InternalError',
            ErrorMessage => 'SLAGet: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'SLAGet.AuthFail',
        ErrorMessage => 'SLAGet: Could not authenticate.',
    ) if !$UserID;

    # Check group permission.
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'ro',
    );

    return $Self->ReturnError(
        ErrorCode    => 'SLAGet.AccessDenied',
        ErrorMessage => 'SLAGet: User does not have access.',
    ) if !$HasPermission;

    # Validate required params.
    my $SLAID = $Param{Data}{SLAID};

    return $Self->ReturnError(
        ErrorCode    => 'SLAGet.MissingParameter',
        ErrorMessage => 'SLAGet: SLAID is required.',
    ) if !$SLAID;

    my %SLAData = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
        SLAID  => $SLAID,
        UserID => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'SLAGet.NotFound',
        ErrorMessage => "SLAGet: SLA with ID $SLAID not found.",
    ) if !%SLAData || !$SLAData{Name};

    return {
        Success => 1,
        Data    => {
            SLA => \%SLAData,
        },
    };
}

1;
