# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::SLA::SLAList;

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
            ErrorCode    => 'SLAList.InternalError',
            ErrorMessage => 'SLAList: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'SLAList.AuthFail',
        ErrorMessage => 'SLAList: Could not authenticate.',
    ) if !$UserID;

    # Check group permission.
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'ro',
    );

    return $Self->ReturnError(
        ErrorCode    => 'SLAList.AccessDenied',
        ErrorMessage => 'SLAList: User does not have access.',
    ) if !$HasPermission;

    my $Valid = defined $Param{Data}{Valid} ? $Param{Data}{Valid} : 1;

    my %SLAListParams = (
        UserID => $UserID,
        Valid  => $Valid,
    );

    if ( defined $Param{Data}{ServiceID} && $Param{Data}{ServiceID} ne '' ) {
        $SLAListParams{ServiceID} = $Param{Data}{ServiceID};
    }

    my %SLAList = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
        %SLAListParams,
    );

    return {
        Success => 1,
        Data    => {
            SLAList => \%SLAList,
        },
    };
}

1;
