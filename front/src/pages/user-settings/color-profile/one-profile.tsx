import * as React from 'react';
import { ColorProfileData } from '../defs';
import { ProfileWrapper, ProfileName, Button } from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { withProps } from 'recompose';

export interface IPropOneProfile {
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
  ({ profile, onEditButton, onDeleteButton }) => {
    const isDefaultProfile = profile.id == null;
    return (
      <ProfileWrapper defaultProfile={isDefaultProfile}>
        <ProfileName>{profile.name}</ProfileName>
        <div>
          <Button onClick={onEditButton}>
            <FontAwesomeIcon icon="pen" />
            編集
          </Button>
          <Button disabled={isDefaultProfile} onClick={onDeleteButton}>
            <FontAwesomeIcon icon="trash-alt" />
            削除
          </Button>
        </div>
      </ProfileWrapper>
    );
  },
);
