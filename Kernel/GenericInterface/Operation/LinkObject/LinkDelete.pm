# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::LinkObject::LinkDelete;

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
            ErrorCode    => 'LinkDelete.InternalError',
            ErrorMessage => 'LinkDelete: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'LinkDelete.AuthFail',
        ErrorMessage => 'LinkDelete: Could not authenticate.',
    ) if !$UserID;

    # Check group permission (rw required for write operations).
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'rw',
    );

    return $Self->ReturnError(
        ErrorCode    => 'LinkDelete.AccessDenied',
        ErrorMessage => 'LinkDelete: User does not have write access.',
    ) if !$HasPermission;

    # Validate required params.
    # Uses Object1/Key1/Object2/Key2 (not Source/Target) because LinkDelete is direction-agnostic.
    my $CommonObject = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common');
    my $Validation = $CommonObject->ValidateRequiredParams(
        Data     => $Param{Data},
        Required => [ 'Object1', 'Key1', 'Object2', 'Key2', 'Type' ],
    );

    if ( !$Validation->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'LinkDelete.MissingParameter',
            ErrorMessage => "LinkDelete: $Validation->{MissingParameter} is required.",
        );
    }

    my $Success = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkDelete(
        Object1 => $Param{Data}{Object1},
        Key1    => $Param{Data}{Key1},
        Object2 => $Param{Data}{Object2},
        Key2    => $Param{Data}{Key2},
        Type    => $Param{Data}{Type},
        UserID  => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'LinkDelete.OperationFailed',
        ErrorMessage => 'LinkDelete: Could not delete link.',
    ) if !$Success;

    return {
        Success => 1,
        Data    => {
            Success => 1,
        },
    };
}

1;
