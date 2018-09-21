import * as React from 'react';
import { ColorProfileData } from '../defs';

export interface IPropOneProfile {
  profile: ColorProfileData;
}

export const OneProfile: React.StatelessComponent<IPropOneProfile> = ({
  profile,
}) => {
  return <div>{profile.name}</div>;
};
