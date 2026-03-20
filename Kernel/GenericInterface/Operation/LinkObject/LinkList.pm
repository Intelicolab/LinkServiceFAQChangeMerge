# --
# Copyright (C) 2026 Intelicolab
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::LinkObject::LinkList;

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
            ErrorCode    => 'LinkList.InternalError',
            ErrorMessage => 'LinkList: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'LinkList.AuthFail',
        ErrorMessage => 'LinkList: Could not authenticate.',
    ) if !$UserID;

    # Check group permission.
    my $HasPermission = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common')->CheckGroupPermission(
        UserID     => $UserID,
        GroupName  => 'users',
        Permission => 'ro',
    );

    return $Self->ReturnError(
        ErrorCode    => 'LinkList.AccessDenied',
        ErrorMessage => 'LinkList: User does not have access.',
    ) if !$HasPermission;

    # Validate required params.
    my $Object = $Param{Data}{Object};
    my $Key    = $Param{Data}{Key};

    return $Self->ReturnError(
        ErrorCode    => 'LinkList.MissingParameter',
        ErrorMessage => 'LinkList: Object is required.',
    ) if !$Object;

    return $Self->ReturnError(
        ErrorCode    => 'LinkList.MissingParameter',
        ErrorMessage => 'LinkList: Key is required.',
    ) if !$Key;

    # Build LinkList params.
    my %LinkListParams = (
        Object => $Object,
        Key    => $Key,
        State  => $Param{Data}{State}     || 'Valid',
        UserID => $UserID,
    );

    if ( defined $Param{Data}{Object2} && $Param{Data}{Object2} ne '' ) {
        $LinkListParams{Object2} = $Param{Data}{Object2};
    }

    if ( defined $Param{Data}{Direction} && $Param{Data}{Direction} ne '' ) {
        $LinkListParams{Direction} = $Param{Data}{Direction};
    }
    else {
        $LinkListParams{Direction} = 'Both';
    }

    if ( defined $Param{Data}{Type} && $Param{Data}{Type} ne '' ) {
        $LinkListParams{Type} = $Param{Data}{Type};
    }

    my %LinkList = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkList(
        %LinkListParams,
    );

    return {
        Success => 1,
        Data    => {
            LinkList => \%LinkList,
        },
    };
}

1;
