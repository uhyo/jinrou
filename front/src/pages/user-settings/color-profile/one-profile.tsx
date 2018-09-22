import * as React from 'react';
import { ProfileWrapper, ProfileName, Button } from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { withProps } from 'recompose';
import { TranslationFunction } from 'i18next';
import { ColorProfileData } from '../../../defs/color-profile';

export interface IPropOneProfile {
  t: TranslationFunction;
  profile: ColorProfileData;
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
  ({ t, profile, onEditButton, onDeleteButton, onUseButton }) => {
    const isDefaultProfile = profile.id == null;
    return (
      <ProfileWrapper defaultProfile={isDefaultProfile}>
        <ProfileName>{profile.name}</ProfileName>
        <div>
          <Button onClick={onUseButton}>{t('color.useButton')}</Button>
          <Button onClick={onEditButton}>
            <FontAwesomeIcon icon="pen" />
            {t('color.editButton')}
          </Button>
          <Button disabled={isDefaultProfile} onClick={onDeleteButton}>
            <FontAwesomeIcon icon="trash-alt" />
            {t('color.deleteButton')}
          </Button>
        </div>
      </ProfileWrapper>
    );
  },
);
