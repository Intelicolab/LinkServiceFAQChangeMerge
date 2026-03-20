# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::FAQ::FAQGet;

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
            ErrorCode    => 'FAQGet.InternalError',
            ErrorMessage => 'FAQGet: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'FAQGet.AuthFail',
        ErrorMessage => 'FAQGet: Could not authenticate.',
    ) if !$UserID;

    # FAQ is a soft dependency — check if the module is available.
    my $FAQObject;
    eval {
        $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'FAQGet.ModuleNotAvailable',
            ErrorMessage => 'FAQGet: FAQ module is not installed.',
        );
    }

    # Validate required params.
    my $ItemID = $Param{Data}{ItemID};

    return $Self->ReturnError(
        ErrorCode    => 'FAQGet.MissingParameter',
        ErrorMessage => 'FAQGet: ItemID is required.',
    ) if !$ItemID;

    my %FAQData = $FAQObject->FAQGet(
        ItemID     => $ItemID,
        ItemFields => 1,
        UserID     => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'FAQGet.NotFound',
        ErrorMessage => "FAQGet: FAQ item with ID $ItemID not found.",
    ) if !%FAQData || !$FAQData{Title};

    # Optionally include attachment contents.
    if ( $Param{Data}{GetAttachmentContents} ) {
        my @Attachments;
        my @AttachmentIndex = $FAQObject->AttachmentIndex(
            ItemID => $ItemID,
            UserID => $UserID,
        );

        for my $Attachment (@AttachmentIndex) {
            my %File = $FAQObject->AttachmentGet(
                ItemID => $ItemID,
                FileID => $Attachment->{FileID},
                UserID => $UserID,
            );
            push @Attachments, \%File;
        }

        $FAQData{Attachment} = \@Attachments;
    }

    # Wrap in array for consistency with PublicFAQGet.
    return {
        Success => 1,
        Data    => {
            FAQItem => [ \%FAQData ],
        },
    };
}

1;
