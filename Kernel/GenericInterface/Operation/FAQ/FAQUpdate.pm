# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::FAQ::FAQUpdate;

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
        ErrorCode    => 'FAQUpdate.AuthFail',
        ErrorMessage => 'FAQUpdate: Could not authenticate.',
    ) if !$UserID;

    # FAQ is a soft dependency.
    my $FAQObject;
    eval {
        $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'FAQUpdate.ModuleNotAvailable',
            ErrorMessage => 'FAQUpdate: FAQ module is not installed.',
        );
    }

    my $ItemID = $Param{Data}{ItemID};

    return $Self->ReturnError(
        ErrorCode    => 'FAQUpdate.MissingParameter',
        ErrorMessage => 'FAQUpdate: ItemID is required.',
    ) if !$ItemID;

    # Fetch existing FAQ data (FAQGet returns a hash, not hashref).
    my %Existing = $FAQObject->FAQGet(
        ItemID     => $ItemID,
        ItemFields => 1,
        UserID     => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'FAQUpdate.NotFound',
        ErrorMessage => "FAQUpdate: FAQ item with ID $ItemID not found.",
    ) if !%Existing || !$Existing{Title};

    # Merge caller-supplied fields over existing data.
    for my $Key (qw(Title CategoryID StateID LanguageID ContentType
        Field1 Field2 Field3 Field4 Field5 Field6 Keywords ValidID)) {
        if ( defined $Param{Data}{$Key} ) {
            $Existing{$Key} = $Param{Data}{$Key};
        }
    }

    my $Success = $FAQObject->FAQUpdate(
        ItemID      => $ItemID,
        Title       => $Existing{Title},
        CategoryID  => $Existing{CategoryID},
        StateID     => $Existing{StateID},
        LanguageID  => $Existing{LanguageID},
        ContentType => $Existing{ContentType} || 'text/html',
        Field1      => $Existing{Field1} || '',
        Field2      => $Existing{Field2} || '',
        Field3      => $Existing{Field3} || '',
        Field4      => $Existing{Field4} || '',
        Field5      => $Existing{Field5} || '',
        Field6      => $Existing{Field6} || '',
        Keywords    => $Existing{Keywords} || '',
        ValidID     => $Existing{ValidID} || 1,
        UserID      => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'FAQUpdate.UpdateFailed',
        ErrorMessage => "FAQUpdate: Could not update FAQ item with ID $ItemID.",
    ) if !$Success;

    return {
        Success => 1,
        Data    => {
            ItemID => $ItemID,
        },
    };
}

1;
