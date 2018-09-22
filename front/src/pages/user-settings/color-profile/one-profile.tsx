import * as React from 'react';
import { ColorProfileData } from '../defs';
import { ProfileWrapper, ProfileName, Button } from './elements';

export interface IPropOneProfile {
  profile: ColorProfileData;
}

export const OneProfile: React.StatelessComponent<IPropOneProfile> = ({
  profile,
}) => {
  return (
    <ProfileWrapper>
      <ProfileName>{profile.name}</ProfileName>
      <div>
        <Button>編集</Button>
        <Button>削除</Button>
      </div>
    </ProfileWrapper>
  );
};
