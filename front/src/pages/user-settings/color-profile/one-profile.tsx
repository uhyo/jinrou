import * as React from 'react';
import { ProfileWrapper, ProfileName } from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { withProps } from 'recompose';
import { TranslationFunction } from 'i18next';
import { ColorProfileData } from '../../../defs/color-profile';
import { Button, ActiveButton } from '../commons/button';

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
        <ProfileName>{profile.name}</ProfileName>
        <div>
          {used ? (
            <ActiveButton disabled>
              <FontAwesomeIcon icon="check" />
              {t('color.usedButtonLabel')}
            </ActiveButton>
          ) : (
            <Button onClick={onUseButton}>{t('color.useButton')}</Button>
          )}
          {edited ? (
            <ActiveButton onClick={onEditButton}>
              <FontAwesomeIcon icon="pen" />
              {t('color.editButton')}
            </ActiveButton>
          ) : (
            <Button onClick={onEditButton}>
              <FontAwesomeIcon icon="pen" />
              {t('color.editButton')}
            </Button>
          )}
          <Button disabled={isDefaultProfile} onClick={onDeleteButton}>
            <FontAwesomeIcon icon="trash-alt" />
            {t('color.deleteButton')}
          </Button>
        </div>
      </ProfileWrapper>
    );
  },
);
