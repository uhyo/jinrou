import * as React from 'react';

import { UserSettingsStore } from './store';
import { observer } from 'mobx-react';

export interface IPropUserSettings {
  store: UserSettingsStore;
}

@observer
export class UserSettings extends React.Component<IPropUserSettings, {}> {
  public render() {
    return <h1>user settings</h1>;
  }
}
