# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::ConfigItem::ConfigItemCreate;

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
        ErrorCode    => 'ConfigItemCreate.AuthFail',
        ErrorMessage => 'ConfigItemCreate: Could not authenticate.',
    ) if !$UserID;

    # ITSMConfigurationManagement is a soft dependency.
    my $ConfigItemObject;
    eval {
        $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'ConfigItemCreate.ModuleNotAvailable',
            ErrorMessage => 'ConfigItemCreate: ITSMConfigurationManagement module is not installed.',
        );
    }

    # Validate required params.
    my $CommonObject = $Kernel::OM->Get('Kernel::GenericInterface::Operation::Extensions::Common');
    my $Validation = $CommonObject->ValidateRequiredParams(
        Data     => $Param{Data},
        Required => [ 'Class', 'Name', 'DeplState', 'InciState' ],
    );

    if ( !$Validation->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'ConfigItemCreate.MissingParameter',
            ErrorMessage => "ConfigItemCreate: $Validation->{MissingParameter} is required.",
        );
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # Lookup Class name → ClassID.
    my $ClassItem = $GeneralCatalogObject->ItemGet(
        Class => 'ITSM::ConfigItem::Class',
        Name  => $Param{Data}{Class},
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemCreate.InvalidParameter',
        ErrorMessage => "ConfigItemCreate: Class '$Param{Data}{Class}' not found in GeneralCatalog.",
    ) if !$ClassItem || !$ClassItem->{ItemID};

    my $ClassID = $ClassItem->{ItemID};

    # Lookup DeplState name → DeplStateID.
    my $DeplStateItem = $GeneralCatalogObject->ItemGet(
        Class => 'ITSM::ConfigItem::DeploymentState',
        Name  => $Param{Data}{DeplState},
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemCreate.InvalidParameter',
        ErrorMessage => "ConfigItemCreate: DeplState '$Param{Data}{DeplState}' not found in GeneralCatalog.",
    ) if !$DeplStateItem || !$DeplStateItem->{ItemID};

    my $DeplStateID = $DeplStateItem->{ItemID};

    # Lookup InciState name → InciStateID.
    my $InciStateItem = $GeneralCatalogObject->ItemGet(
        Class => 'ITSM::Core::IncidentState',
        Name  => $Param{Data}{InciState},
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemCreate.InvalidParameter',
        ErrorMessage => "ConfigItemCreate: InciState '$Param{Data}{InciState}' not found in GeneralCatalog.",
    ) if !$InciStateItem || !$InciStateItem->{ItemID};

    my $InciStateID = $InciStateItem->{ItemID};

    # Get latest DefinitionID for this class.
    my $Definition = $ConfigItemObject->DefinitionGet(
        ClassID => $ClassID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemCreate.InvalidParameter',
        ErrorMessage => "ConfigItemCreate: No definition found for class '$Param{Data}{Class}'.",
    ) if !$Definition || !$Definition->{DefinitionID};

    # Step 1: Create the config item shell.
    my $ConfigItemID = $ConfigItemObject->ConfigItemAdd(
        ClassID => $ClassID,
        UserID  => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'ConfigItemCreate.CreateFailed',
        ErrorMessage => 'ConfigItemCreate: Could not create config item.',
    ) if !$ConfigItemID;

    # Step 2: Create the initial version with data.
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
        ErrorCode    => 'ConfigItemCreate.VersionFailed',
        ErrorMessage => "ConfigItemCreate: Config item $ConfigItemID created but initial version failed.",
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
