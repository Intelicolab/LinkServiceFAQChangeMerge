# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::LinkObject::LinkAdd;

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
            ErrorCode    => 'LinkAdd.InternalError',
            ErrorMessage => 'LinkAdd: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'LinkAdd.AuthFail',
        ErrorMessage => 'LinkAdd: Could not authenticate.',
    ) if !$UserID;

    # Check group permission (rw required for write operations).
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'rw',
    );

    return $Self->ReturnError(
        ErrorCode    => 'LinkAdd.AccessDenied',
        ErrorMessage => 'LinkAdd: User does not have write access.',
    ) if !$HasPermission;

    # Validate required params.
    my $CommonObject = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common');
    my $Validation = $CommonObject->ValidateRequiredParams(
        Data     => $Param{Data},
        Required => [ 'SourceObject', 'SourceKey', 'TargetObject', 'TargetKey', 'Type' ],
    );

    if ( !$Validation->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'LinkAdd.MissingParameter',
            ErrorMessage => "LinkAdd: $Validation->{MissingParameter} is required.",
        );
    }

    my $Success = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkAdd(
        SourceObject => $Param{Data}{SourceObject},
        SourceKey    => $Param{Data}{SourceKey},
        TargetObject => $Param{Data}{TargetObject},
        TargetKey    => $Param{Data}{TargetKey},
        Type         => $Param{Data}{Type},
        State        => $Param{Data}{State} || 'Valid',
        UserID       => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'LinkAdd.OperationFailed',
        ErrorMessage => 'LinkAdd: Could not create link.',
    ) if !$Success;

    return {
        Success => 1,
        Data    => {
            Success => 1,
        },
    };
}

1;
