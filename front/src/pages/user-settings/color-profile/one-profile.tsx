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
}

/**
 * Map onEdit props to onEditButton without argument.
 */
const mapProps = withProps(({ profile, onEdit }: IPropOneProfile) => ({
  onEditButton: () => onEdit(profile),
}));

export const OneProfile = mapProps(({ profile, onEditButton }) => {
  const isDefaultProfile = profile.id == null;
  return (
    <ProfileWrapper defaultProfile={isDefaultProfile}>
      <ProfileName>{profile.name}</ProfileName>
      <div>
        <Button onClick={onEditButton}>
          <FontAwesomeIcon icon="pen" />
          編集
        </Button>
        <Button disabled={isDefaultProfile}>
          <FontAwesomeIcon icon="trash-alt" />
          削除
        </Button>
      </div>
    </ProfileWrapper>
  );
});
