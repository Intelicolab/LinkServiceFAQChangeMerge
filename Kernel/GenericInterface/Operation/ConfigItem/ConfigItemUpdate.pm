# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::ConfigItem::ConfigItemUpdate;

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
        ErrorCode    => 'ConfigItemUpdate.AuthFail',
        ErrorMessage => 'ConfigItemUpdate: Could not authenticate.',
    ) if !$UserID;

    # ITSMConfigurationManagement is a soft dependency.
    my $ConfigItemObject;
    eval {
        $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'ConfigItemUpdate.ModuleNotAvailable',
            ErrorMessage => 'ConfigItemUpdate: ITSMConfigurationManagement module is not installed.',
        );
    }

    my $ConfigItemID = $Param{Data}{ConfigItemID};

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.MissingParameter',
        ErrorMessage => 'ConfigItemUpdate: ConfigItemID is required.',
    ) if !$ConfigItemID;

    # Validate required params.
    my $CommonObject = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common');
    my $Validation = $CommonObject->ValidateRequiredParams(
        Data     => $Param{Data},
        Required => [ 'Name', 'DeplState', 'InciState' ],
    );

    if ( !$Validation->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'ConfigItemUpdate.MissingParameter',
            ErrorMessage => "ConfigItemUpdate: $Validation->{MissingParameter} is required.",
        );
    }

    # Verify the config item exists (ConfigItemGet returns hashref).
    my $ConfigItem = $ConfigItemObject->ConfigItemGet(
        ConfigItemID => $ConfigItemID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.NotFound',
        ErrorMessage => "ConfigItemUpdate: Config item with ID $ConfigItemID not found.",
    ) if !$ConfigItem || !$ConfigItem->{ConfigItemID};

    my $ClassID = $ConfigItem->{ClassID};
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # Lookup DeplState name → DeplStateID.
    my $DeplStateItem = $GeneralCatalogObject->ItemGet(
        Class => 'ITSM::ConfigItem::DeploymentState',
        Name  => $Param{Data}{DeplState},
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.InvalidParameter',
        ErrorMessage => "ConfigItemUpdate: DeplState '$Param{Data}{DeplState}' not found in GeneralCatalog.",
    ) if !$DeplStateItem || !$DeplStateItem->{ItemID};

    my $DeplStateID = $DeplStateItem->{ItemID};

    # Lookup InciState name → InciStateID.
    my $InciStateItem = $GeneralCatalogObject->ItemGet(
        Class => 'ITSM::Core::IncidentState',
        Name  => $Param{Data}{InciState},
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.InvalidParameter',
        ErrorMessage => "ConfigItemUpdate: InciState '$Param{Data}{InciState}' not found in GeneralCatalog.",
    ) if !$InciStateItem || !$InciStateItem->{ItemID};

    my $InciStateID = $InciStateItem->{ItemID};

    # Get latest DefinitionID for this class.
    my $Definition = $ConfigItemObject->DefinitionGet(
        ClassID => $ClassID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.InvalidParameter',
        ErrorMessage => "ConfigItemUpdate: No definition found for ClassID $ClassID.",
    ) if !$Definition || !$Definition->{DefinitionID};

    # Create a new version (OTOBO updates CIs by adding versions).
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ConfigItemID,
        Name         => $Param{Data}{Name},
        DefinitionID => $Definition->{DefinitionID},
        DeplStateID  => $DeplStateID,
        InciStateID  => $InciStateID,
        XMLData      => $Param{Data}{XMLData} || [],
        UserID       => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemUpdate.UpdateFailed',
        ErrorMessage => "ConfigItemUpdate: Could not create new version for config item $ConfigItemID.",
    ) if !$VersionID;

    return {
        Success => 1,
        Data    => {
            ConfigItemID => $ConfigItemID,
            VersionID    => $VersionID,
        },
    };
}

1;
