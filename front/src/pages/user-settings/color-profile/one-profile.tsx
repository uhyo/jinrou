import * as React from 'react';
import { ColorProfileData } from '../defs';
import { ProfileWrapper, ProfileName, Button } from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { withProps } from 'recompose';
import { TranslationFunction } from 'i18next';

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
}

/**
 * Map onEdit props to onEditButton without argument.
 */
const mapProps = withProps(
  ({ profile, onEdit, onDelete }: IPropOneProfile) => ({
    onEditButton: () => onEdit(profile),
    onDeleteButton: () => onDelete(profile),
  }),
);

export const OneProfile = mapProps(
  ({ t, profile, onEditButton, onDeleteButton }) => {
    const isDefaultProfile = profile.id == null;
    return (
      <ProfileWrapper defaultProfile={isDefaultProfile}>
        <ProfileName>{profile.name}</ProfileName>
        <div>
          <Button>
            <FontAwesomeIcon icon="pen" />
            {t('color.useButton')}
          </Button>
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
