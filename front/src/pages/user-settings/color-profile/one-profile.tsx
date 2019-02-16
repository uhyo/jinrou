import * as React from 'react';
import { ProfileWrapper, ProfileName } from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { withProps } from 'recompose';
import { ColorProfileData } from '../../../defs/color-profile';
import { Button, ActiveButton } from '../../../common/forms/button';
import { TranslationFunction } from '../../../i18n';
import {
  ControlsHeader,
  ControlsMain,
} from '../../../common/forms/controls-wrapper';

export interface IPropOneProfile {
  t: TranslationFunction;
  profile: ColorProfileData;
  /**
   * Whether this profile is currently used.
   */
  used: boolean;
  /**
   * Whether this profile is currently edited.
   */
  edited: boolean;
  /**
   * Request an edit of this profile.
   */
  onEdit(profile: ColorProfileData): void;
  /**
   * Request a delete of this profile.
   */
  onDelete(profile: ColorProfileData): void;
  /**
   * Request a use of this profile.
   */
  onUse(profile: ColorProfileData): void;
}

/**
 * Map onEdit props to onEditButton without argument.
 */
const mapProps = withProps(
  ({ profile, onEdit, onDelete, onUse }: IPropOneProfile) => ({
    onEditButton: () => onEdit(profile),
    onDeleteButton: () => onDelete(profile),
    onUseButton: () => onUse(profile),
  }),
);

export const OneProfile = mapProps(
  ({ t, profile, used, edited, onEditButton, onDeleteButton, onUseButton }) => {
    const isDefaultProfile = profile.id == null;
    return (
      <ProfileWrapper defaultProfile={isDefaultProfile}>
        <ControlsHeader>
          <ProfileName>{profile.name}</ProfileName>
        </ControlsHeader>
        <ControlsMain>
          <ActiveButton active={used} disabled={used} onClick={onUseButton}>
            {used ? (
              <>
                <FontAwesomeIcon icon="check" />
                {t('color.usedButtonLabel')}
              </>
            ) : (
              t('color.useButton')
            )}
          </ActiveButton>
          <ActiveButton onClick={onEditButton} active={edited}>
            <FontAwesomeIcon icon="pen" />
            {t('color.editButton')}
          </ActiveButton>
          <Button disabled={isDefaultProfile} onClick={onDeleteButton}>
            <FontAwesomeIcon icon="trash-alt" />
            {t('color.deleteButton')}
          </Button>
        </ControlsMain>
      </ProfileWrapper>
    );
  },
);
