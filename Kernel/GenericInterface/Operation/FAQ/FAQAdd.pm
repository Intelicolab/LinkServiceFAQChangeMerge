# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::FAQ::FAQAdd;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::GenericInterface::Operation::Common);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw(DebuggerObject WebserviceID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!",
            };
        }
        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'FAQAdd.AuthFail',
        ErrorMessage => 'FAQAdd: Could not authenticate.',
    ) if !$UserID;

    # FAQ is a soft dependency.
    my $FAQObject;
    eval {
        $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'FAQAdd.ModuleNotAvailable',
            ErrorMessage => 'FAQAdd: FAQ module is not installed.',
        );
    }

    # Validate required params.
    my $CommonObject = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common');
    my $Validation = $CommonObject->ValidateRequiredParams(
        Data     => $Param{Data},
        Required => [ 'Title', 'CategoryID', 'StateID', 'LanguageID', 'ContentType' ],
    );

    if ( !$Validation->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'FAQAdd.MissingParameter',
            ErrorMessage => "FAQAdd: $Validation->{MissingParameter} is required.",
        );
    }

    my $ItemID = $FAQObject->FAQAdd(
        Title       => $Param{Data}{Title},
        CategoryID  => $Param{Data}{CategoryID},
        StateID     => $Param{Data}{StateID},
        LanguageID  => $Param{Data}{LanguageID},
        ContentType => $Param{Data}{ContentType},
        Field1      => $Param{Data}{Field1} || '',
        Field2      => $Param{Data}{Field2} || '',
        Field3      => $Param{Data}{Field3} || '',
        Field6      => $Param{Data}{Field6} || '',
        Keywords    => $Param{Data}{Keywords} || '',
        ValidID     => $Param{Data}{ValidID} || 1,
        UserID      => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'FAQAdd.CreateFailed',
        ErrorMessage => 'FAQAdd: Could not create FAQ article.',
    ) if !$ItemID;

    return {
        Success => 1,
        Data    => {
            ItemID => $ItemID,
        },
    };
}

1;
